"""
Build-time import test for ComfyUI-CatvtonFluxWrapper.
This file is copied into the container by the Dockerfile and run as a build step.
It simulates what ComfyUI's custom node loader does — if ANY import in the chain
fails, the Docker build fails and the traceback is visible in the CI log.
"""
import sys
import types
import importlib.util
import traceback

# ── Set up Python path identical to ComfyUI runtime ──────────────────────────
sys.path.insert(0, "/comfyui")

# ── Mock comfy.* so we don't need a running ComfyUI / GPU ────────────────────
def _cpu():
    import torch
    return torch.device("cpu")

comfy_mod = types.ModuleType("comfy")
mm_mod = types.ModuleType("comfy.model_management")
mm_mod.get_torch_device = _cpu
mm_mod.unet_offload_device = _cpu
mm_mod.text_encoder_device = _cpu
mm_mod.text_encoder_offload_device = _cpu
mm_mod.intermediate_device = _cpu
mm_mod.vae_offload_device = _cpu
mm_mod.vae_device = _cpu
mm_mod.unet_dtype = lambda: None
mm_mod.VAE_DTYPE = None

comfy_utils = types.ModuleType("comfy.utils")
comfy_utils.load_torch_file = lambda *a, **kw: {}
comfy_detect = types.ModuleType("comfy.model_detection")
comfy_detect.model_config_from_unet = lambda *a, **kw: None
comfy_lora = types.ModuleType("comfy.lora")
comfy_lora.model_lora_keys_unet = lambda *a, **kw: ({}, {})

comfy_mod.model_management = mm_mod
comfy_mod.utils = comfy_utils
comfy_mod.model_detection = comfy_detect
comfy_mod.lora = comfy_lora
sys.modules["comfy"] = comfy_mod
sys.modules["comfy.model_management"] = mm_mod
sys.modules["comfy.utils"] = comfy_utils
sys.modules["comfy.model_detection"] = comfy_detect
sys.modules["comfy.lora"] = comfy_lora

# ── Load the wrapper package the way ComfyUI does ────────────────────────────
node_dir = "/comfyui/custom_nodes/catvton-flux-wrapper"
pkg_name = "catvton_flux_wrapper"

# Create the package namespace
pkg = types.ModuleType(pkg_name)
pkg.__path__ = [node_dir]
pkg.__package__ = pkg_name
pkg.__file__ = f"{node_dir}/__init__.py"
sys.modules[pkg_name] = pkg

spec = importlib.util.spec_from_file_location(
    pkg_name,
    f"{node_dir}/__init__.py",
    submodule_search_locations=[node_dir],
)
mod = importlib.util.module_from_spec(spec)
mod.__path__ = [node_dir]
mod.__package__ = pkg_name
sys.modules[pkg_name] = mod

try:
    spec.loader.exec_module(mod)
    keys = list(mod.NODE_CLASS_MAPPINGS.keys())
    print(f"CatvtonFluxWrapper import OK — nodes: {keys}")
except Exception as exc:
    print("CatvtonFluxWrapper import FAILED:")
    traceback.print_exc()
    sys.exit(1)
