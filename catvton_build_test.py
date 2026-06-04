"""
Build-time import test for ComfyUI-CatvtonFluxWrapper.

comfy.model_management initialises CUDA at module level, so the full wrapper
import only works on GPU hosts. In GitHub Actions (CPU-only) we skip that part
and verify only the diffusers import chain — the part that was actually broken.
"""
import sys
import types
import importlib.util
import traceback

import torch

# ── Always verify the diffusers imports that were causing the runtime failure ─
print("Checking required diffusers imports...")
try:
    from diffusers.models.attention_processor import FusedFluxAttnProcessor2_0
    from diffusers.models.embeddings import FluxPosEmbed
    from diffusers.models.normalization import AdaLayerNormZeroSingle
    from diffusers.utils import replace_example_docstring
    from diffusers.pipelines.pipeline_utils import DiffusionPipeline  # triggers FLAX_WEIGHTS_NAME
    print("diffusers imports OK (FusedFluxAttnProcessor2_0, FluxPosEmbed, DiffusionPipeline)")
except Exception as exc:
    traceback.print_exc()
    sys.exit(1)

# ── Full wrapper load requires GPU (comfy.model_management CUDA init) ─────────
if not torch.cuda.is_available():
    print("No CUDA in build environment — skipping full wrapper load (will run on GPU worker)")
    sys.exit(0)

# ── On GPU hosts: load the wrapper the way ComfyUI does ──────────────────────
sys.path.insert(0, "/comfyui")

node_dir = "/comfyui/custom_nodes/catvton-flux-wrapper"
pkg_name = "catvton_flux_wrapper"

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
