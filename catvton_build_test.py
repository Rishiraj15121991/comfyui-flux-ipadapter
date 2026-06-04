"""
Build-time import test for ComfyUI-CatvtonFluxWrapper.
Uses the REAL comfy.* modules from /comfyui (no mocks) — they import fine
without a GPU because ComfyUI degrades gracefully to CPU.
"""
import sys
import types
import importlib.util
import traceback

# ── Use real ComfyUI modules ──────────────────────────────────────────────────
sys.path.insert(0, "/comfyui")

# ── Load the wrapper package the way ComfyUI does ────────────────────────────
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
