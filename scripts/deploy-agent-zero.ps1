# Agent Zero Deployment Script (PowerShell)
# This script helps deploy Agent Zero with the existing Docker Compose setup

Write-Host "🚀 Starting Agent Zero deployment..." -ForegroundColor Green

# Check if Docker Compose is available
try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose found" -ForegroundColor Green
} catch {
    Write-Host "❌ docker-compose not found. Please install Docker Compose." -ForegroundColor Red
    exit 1
}

# Check if .env file exists
if (-not (Test-Path "misc/env.txt")) {
    Write-Host "❌ Environment file not found. Please ensure misc/env.txt exists." -ForegroundColor Red
    exit 1
}

Write-Host "📋 Checking environment variables..." -ForegroundColor Yellow

Write-Host "🔧 Creating configuration directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "config/agent-zero" | Out-Null

Write-Host "📦 Pulling Agent Zero Docker image..." -ForegroundColor Yellow
docker-compose pull agent-zero

Write-Host "🏗️  Building and starting services..." -ForegroundColor Yellow
docker-compose up -d agent-zero

Write-Host "⏳ Waiting for Agent Zero to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "🔍 Checking Agent Zero health..." -ForegroundColor Yellow
try {
    docker-compose exec agent-zero curl -f http://localhost:80/healthz 2>$null
    Write-Host "✅ Agent Zero is healthy!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Agent Zero health check failed. Check logs with: docker-compose logs agent-zero" -ForegroundColor Yellow
}

Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
Write-Host "   Local: http://localhost:8080" -ForegroundColor White
Write-Host "   Tunnel: https://a0.jerryagenyi.xyz (after tunnel configuration)" -ForegroundColor White

Write-Host "🔐 Default credentials:" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: admin123" -ForegroundColor White

Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Configure your Cloudflare tunnel to route a0.jerryagenyi.xyz to agent-zero:80" -ForegroundColor White
Write-Host "   2. Access Agent Zero via the Web UI" -ForegroundColor White
Write-Host "   3. Configure LLM providers in the Agent Zero settings" -ForegroundColor White
Write-Host "   4. Set up MCP servers if needed" -ForegroundColor White

Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs: docker-compose logs agent-zero" -ForegroundColor White
Write-Host "   Restart: docker-compose restart agent-zero" -ForegroundColor White
Write-Host "   Stop: docker-compose stop agent-zero" -ForegroundColor White
Write-Host "   Update: docker-compose pull agent-zero; docker-compose up -d agent-zero" -ForegroundColor White

Write-Host "🛠 Optional: Add a Healthcheck or Debug Step" -ForegroundColor Cyan
Write-Host "If it is not working yet, try:" -ForegroundColor White
Write-Host "   docker-compose exec cloudflared-tunnel curl http://agent-zero:80/healthz" -ForegroundColor White
Write-Host "This checks if Cloudflared can reach Agent Zero inside the Docker network." -ForegroundColor White

Write-Host "🎉 Agent Zero deployment completed!" -ForegroundColor Green