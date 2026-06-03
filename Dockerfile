FROM runpod/worker-comfyui:latest-flux1-dev-fp8

# Install XLabs FLUX IP-Adapter custom nodes into correct ComfyUI path
RUN mkdir -p /comfyui/custom_nodes && \
    cd /comfyui/custom_nodes && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui && \
    pip install -r x-flux-comfyui/requirements.txt

# Download XLabs IP-Adapter weights
RUN mkdir -p /comfyui/models/xlabs/ipadapters && \
    wget -q \
         "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors" \
         -O /comfyui/models/xlabs/ipadapters/ip_adapter.safetensors

# Download CLIP-L vision encoder from OpenAI, renamed as XLabs nodes expect
RUN mkdir -p /comfyui/models/clip_vision/flux && \
    wget -q \
         "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors" \
         -O /comfyui/models/clip_vision/flux/clip_vision_l.safetensors
