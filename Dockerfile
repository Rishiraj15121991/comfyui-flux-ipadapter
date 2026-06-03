FROM runpod/worker-comfyui:latest-flux1-dev-fp8

# Install XLabs FLUX IP-Adapter custom nodes
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui && \
    pip install -r x-flux-comfyui/requirements.txt

# Download XLabs IP-Adapter weights into the correct directory
RUN mkdir -p /ComfyUI/models/xlabs/ipadapters && \
    wget -q --show-progress \
         "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors" \
         -O /ComfyUI/models/xlabs/ipadapters/ip_adapter.safetensors

# Download CLIP vision encoder (required by IP-Adapter)
RUN mkdir -p /ComfyUI/models/clip_vision && \
    wget -q --show-progress \
         "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/pytorch_model.bin" \
         -O /ComfyUI/models/clip_vision/clip_vit_large_patch14.bin
