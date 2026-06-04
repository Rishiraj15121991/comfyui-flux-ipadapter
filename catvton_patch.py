"""
Patch diffusers 0.31.0 pipeline_loading_utils.py for compatibility with
transformers >= 4.47 where FLAX_WEIGHTS_NAME was removed.

The constant is just the string "flax_model.msgpack" — we inline it.
"""
import re
import pathlib
import sys

pipeline_utils = pathlib.Path(
    "/opt/venv/lib/python3.12/site-packages/diffusers/pipelines/pipeline_loading_utils.py"
)
if not pipeline_utils.exists():
    print("pipeline_loading_utils.py not found — skipping patch")
    sys.exit(0)

content = pipeline_utils.read_text()

if "FLAX_WEIGHTS_NAME" not in content:
    print("FLAX_WEIGHTS_NAME not present — no patch needed")
    sys.exit(0)

# Check if the import still resolves (transformers still has it)
try:
    from transformers.utils import FLAX_WEIGHTS_NAME  # noqa: F401
    print("transformers still exports FLAX_WEIGHTS_NAME — no patch needed")
    sys.exit(0)
except ImportError:
    pass

# Replace the broken import with an inline constant
patched = re.sub(
    r"from transformers\.utils import FLAX_WEIGHTS_NAME as TRANSFORMERS_FLAX_WEIGHTS_NAME\b[^\n]*",
    'TRANSFORMERS_FLAX_WEIGHTS_NAME = "flax_model.msgpack"  # compat: removed from transformers>=4.47',
    content,
)

if patched == content:
    print("Pattern not matched — patch not applied (may need manual review)")
    sys.exit(0)

pipeline_utils.write_text(patched)
print(f"Patched {pipeline_utils} — FLAX_WEIGHTS_NAME inlined")
