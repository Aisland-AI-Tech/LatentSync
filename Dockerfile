# 使用適合 GPU 的基底映像檔，這裡選擇 NVIDIA 提供的 Python 映像檔
FROM nvidia/cuda:12.8.0-runtime-ubuntu20.04

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    libgl1 \
    git \
    wget \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh && \
    bash Miniconda3-py310_23.1.0-1-Linux-x86_64.sh -b -f -p /opt/conda && \
    rm -rf Miniconda3-py310_23.1.0-1-Linux-x86_64.sh && \
    /opt/conda/bin/conda clean -ya

# 設定 PATH
ENV PATH="/opt/conda/bin:$PATH"

# 建立並啟動新的 conda 環境
RUN conda create -y -n latentsync python=3.10.13

# 使用 conda 安裝 ffmpeg
RUN /opt/conda/bin/conda install -y -n latentsync -c conda-forge ffmpeg

# 安裝 Python 相依套件到 latentsync 環境中
COPY requirements.txt /tmp/requirements.txt
RUN /opt/conda/envs/latentsync/bin/pip install -r /tmp/requirements.txt

# 安裝 HuggingFace CLI 並下載模型
RUN /opt/conda/envs/latentsync/bin/pip install huggingface_hub && \
    /opt/conda/envs/latentsync/bin/huggingface-cli download ByteDance/LatentSync --local-dir checkpoints --exclude "*.git*" "README.md"

# 建立軟連結指向輔助模型
RUN mkdir -p ~/.cache/torch/hub/checkpoints && \
    ln -s /workspace/checkpoints/auxiliary/2DFAN4-cd938726ad.zip ~/.cache/torch/hub/checkpoints/2DFAN4-cd938726ad.zip && \
    ln -s /workspace/checkpoints/auxiliary/s3fd-619a316812.pth ~/.cache/torch/hub/checkpoints/s3fd-619a316812.pth && \
    ln -s /workspace/checkpoints/auxiliary/vgg16-397923af.pth ~/.cache/torch/hub/checkpoints/vgg16-397923af.pth

# 開放容器內部端口
EXPOSE 7860

# 設定工作目錄
WORKDIR /workspace

# 複製當前目錄下的所有文件到 /workspace 資料夾
COPY . /workspace/

# 使用特定的 Conda 環境來執行主程序
CMD ["/opt/conda/envs/latentsync/bin/python", "gradio_app.py"]