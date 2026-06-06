# Build comfyui-catvton-flux:v9 locally and push to Docker Hub.
# Required: Docker Desktop running, logged in to Docker Hub (docker login).
# Runtime: 30-60 min depending on internet speed (downloads ~36 GB of models).
#
# Set your HF token in the environment before running:
#   $env:HF_TOKEN = "hf_..."
# Or it will be read from D:\my video studio\backend\.env

$ErrorActionPreference = "Stop"

# Read HF_TOKEN from env or .env file
$HF_TOKEN = $env:HF_TOKEN
if (-not $HF_TOKEN) {
    $envFile = Join-Path $PSScriptRoot "..\my video studio\backend\.env" | Resolve-Path -ErrorAction SilentlyContinue
    if (-not $envFile) {
        $envFile = "D:\my video studio\backend\.env"
    }
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match "^HF_TOKEN=" }
        if ($line) { $HF_TOKEN = $line.Split("=", 2)[1].Trim() }
    }
}
if (-not $HF_TOKEN) {
    Write-Error "HF_TOKEN not set. Run: `$env:HF_TOKEN = 'hf_...'"
    exit 1
}

$IMAGE = "mak15121991/comfyui-catvton-flux"
$TAG = "v18-full-bake"

Set-Location $PSScriptRoot

Write-Host "Building ${IMAGE}:${TAG} (downloads ~36 GB of HuggingFace models)..."
Write-Host "Estimated time: 30-60 minutes"
Write-Host ""

docker build `
  --build-arg HF_TOKEN=$HF_TOKEN `
  -f Dockerfile.catvton `
  -t "${IMAGE}:${TAG}" `
  -t "${IMAGE}:latest" `
  .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

Write-Host ""
Write-Host "Pushing ${IMAGE}:${TAG} ..."
docker push "${IMAGE}:${TAG}"
docker push "${IMAGE}:latest"

Write-Host ""
Write-Host "Done. Run update_template_v9.py then drain_workers.py to deploy."
