# Update a single Docker Compose service (proper :latest / rebuild process)
# Usage: .\scripts\update-docker-service.ps1 -Service n8n
#        .\scripts\update-docker-service.ps1 -Service flowise
# See docs/update-docker-services.md for the full process.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("n8n", "litellm", "cloudflared", "flowise", "agent-zero")]
    [string]$Service
)

$ErrorActionPreference = "Stop"

# Image names for :latest services (n8n uses build, not image)
$imageMap = @{
    "litellm"    = "ghcr.io/berriai/litellm:main-latest"
    "cloudflared"= "cloudflare/cloudflared:latest"
    "flowise"    = "flowiseai/flowise:latest"
    "agent-zero" = "agent0ai/agent-zero:latest"
}

Write-Host "=== Updating service: $Service ===" -ForegroundColor Cyan

# Step 1: Stop the service
Write-Host "[1/4] Stopping $Service..." -ForegroundColor Yellow
docker compose down $Service
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Service -eq "n8n") {
    # n8n: rebuild (no image rm)
    Write-Host "[2/4] Rebuilding n8n (no cache)..." -ForegroundColor Yellow
    docker compose build --no-cache n8n
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    # :latest services: remove image to force fresh pull
    $image = $imageMap[$Service]
    Write-Host "[2/4] Removing image $image..." -ForegroundColor Yellow
    docker image rm $image 2>$null
    # Ignore error if image not found (e.g. first run)
}

Write-Host "[3/4] Starting $Service..." -ForegroundColor Yellow
docker compose up -d $Service
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[4/4] Logs (tail 20):" -ForegroundColor Yellow
docker compose logs $Service --tail=20

Write-Host "`nDone. Service $Service updated." -ForegroundColor Green
