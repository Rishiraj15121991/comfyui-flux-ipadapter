FROM runpod/worker-comfyui:latest-flux1-dev-fp8

# Install XLabs FLUX IP-Adapter custom nodes
RUN mkdir -p /comfyui/custom_nodes && \
    cd /comfyui/custom_nodes && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui && \
    pip install -r x-flux-comfyui/requirements.txt

# Patch x-flux-comfyui for ComfyUI 5.x compatibility.
# x-flux-comfyui is unmaintained since Oct 2024. ComfyUI 5.x added attn_mask
# to DoubleStreamBlock.forward() but the IP-Adapter processor forward() methods
# don't accept it, causing TypeError. Adding attn_mask=None to each signature fixes it.
RUN sed -i 's/def forward(self, attn, img, txt, vec, pe, \*\*attention_kwargs):/def forward(self, attn, img, txt, vec, pe, attn_mask=None, \*\*attention_kwargs):/g' \
    /comfyui/custom_nodes/x-flux-comfyui/src/flux/layers.py && \
    grep -c "attn_mask=None" /comfyui/custom_nodes/x-flux-comfyui/src/flux/layers.py && \
    echo "layers.py patched successfully"

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
