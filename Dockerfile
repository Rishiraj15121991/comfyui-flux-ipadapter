FROM runpod/worker-comfyui:latest-flux1-dev-fp8

# Install XLabs FLUX IP-Adapter custom nodes
RUN mkdir -p /ComfyUI/custom_nodes && \
    cd /ComfyUI/custom_nodes && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui && \
    pip install -r x-flux-comfyui/requirements.txt

# Download XLabs IP-Adapter weights
RUN mkdir -p /ComfyUI/models/xlabs/ipadapters && \
    wget -q \
         "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors" \
         -O /ComfyUI/models/xlabs/ipadapters/ip_adapter.safetensors

# Download CLIP-L vision encoder from OpenAI, renamed as XLabs nodes expect
RUN mkdir -p /ComfyUI/models/clip_vision/flux && \
    wget -q \
         "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors" \
         -O /ComfyUI/models/clip_vision/flux/clip_vision_l.safetensors
