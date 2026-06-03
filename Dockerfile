FROM runpod/worker-comfyui:latest-flux1-dev-fp8

# Install XLabs FLUX IP-Adapter custom nodes
RUN mkdir -p /comfyui/custom_nodes && \
    cd /comfyui/custom_nodes && \
    git clone https://github.com/XLabs-AI/x-flux-comfyui && \
    pip install -r x-flux-comfyui/requirements.txt

# Patch x-flux-comfyui for ComfyUI 5.x compatibility.
# ComfyUI 5.x calls DoubleStreamBlock.forward() with attn_mask=<mask>.
# The xflux DSBnew.forward() signature is (self, img, txt, vec, pe) — no attn_mask.
# We must patch this block-level forward to accept the new kwarg.
# We also patch the processor-level forwards (attn, img, txt, vec, pe, **kwargs)
# to guard against any other callers passing attn_mask.
RUN printf 'import subprocess\n\
# Patch 1: DoubleStreamBlock.forward (block level) — add attn_mask=None\n\
OLD1="def forward(self, img: Tensor, txt: Tensor, vec: Tensor, pe: Tensor) -> tuple[Tensor, Tensor]:"\n\
NEW1="def forward(self, img: Tensor, txt: Tensor, vec: Tensor, pe: Tensor, attn_mask=None) -> tuple[Tensor, Tensor]:"\n\
# Patch 2: processor forwards — add attn_mask=None before **attention_kwargs\n\
OLD2="def forward(self, attn, img, txt, vec, pe, **attention_kwargs):"\n\
NEW2="def forward(self, attn, img, txt, vec, pe, attn_mask=None, **attention_kwargs):"\n\
import os\n\
total = 0\n\
for root, dirs, files in os.walk("/comfyui/custom_nodes/"):\n\
    for fname in files:\n\
        if not fname.endswith(".py"): continue\n\
        path = os.path.join(root, fname)\n\
        txt = open(path).read()\n\
        patched = txt.replace(OLD1, NEW1).replace(OLD2, NEW2)\n\
        if patched != txt:\n\
            open(path, "w").write(patched)\n\
            count = patched.count("attn_mask=None")\n\
            print(f"Patched {count} signature(s) in {path}")\n\
            total += count\n\
print(f"Done — {total} total patches applied")\n\
' | python3

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
