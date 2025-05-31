# Complete WSL2 + Llama 3.2 11B Local Server Setup Guide

## Table of Contents
- [Hardware Assessment & Compatibility](#hardware-assessment--compatibility)
- [Llama 3.2 11B Requirements](#llama-32-11b-requirements)
- [Container Decision: Docker vs Podman](#container-decision-docker-vs-podman)
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Environment Variables Configuration](#environment-variables-configuration)
- [Implementation Phase 1: Core WSL2 Setup](#implementation-phase-1-core-wsl2-setup)
- [Implementation Phase 2: Automated Docker & Dependencies](#implementation-phase-2-automated-docker--dependencies)
- [Implementation Phase 3: Multi-Container Setup](#implementation-phase-3-multi-container-setup)
- [Implementation Phase 4: Cloudflare & Security](#implementation-phase-4-cloudflare--security)
- [Implementation Phase 5: Monitoring & Health Checks](#implementation-phase-5-monitoring--health-checks)
- [Usage Instructions](#usage-instructions)
- [Server Management & Operations](#server-management--operations)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)

## Hardware Assessment & Compatibility

### Your System Analysis
**Your specs are PERFECT for Llama 3.2 11B:**
- **CPU**: Ryzen 7 5800X (8 cores/16 threads) - Excellent for inference
- **RAM**: 32GB - Sufficient for hybrid GPU/CPU inference
- **GPU**: RX6800 XT 16GB - **IDEAL** for Llama 3.2 11B
- **Storage**: NVMe SSD - Perfect for model loading

### Llama 3.2 11B Requirements
For optimal performance of Llama 3.2-11B, 24 GB of GPU memory (VRAM) is recommended, but **your 16GB RX6800 XT will work excellently** with:
- **GPU Acceleration**: 12-14GB for model weights
- **CPU Fallback**: Remaining layers in system RAM
- **Expected Performance**: 15-25 tokens/second (very usable)

### Why Skip Llama 4 (For Now)
Llama 4's "active parameters" concept means it uses sparse activation - only 17B params active from 109B/400B total. However:
- Model files are still 200GB+ (400B version)
- Memory requirements unclear and likely excessive
- Llama 3.2 11B gives 95% of the capability with your current hardware

## Container Decision: Docker vs Podman

**VERDICT: Stick with Docker** for this project because:

### Docker Advantages
- Wider ecosystem support
- Better AMD GPU integration (ROCm)
- Established Ollama/LLM tooling
- Simpler WSL2 integration

### Podman's Benefits Don't Apply Here
Podman offers better security with rootless containers and minimizes attack surfaces, but:
- You're running locally, not in production
- Docker appears to have an advantage over Podman in performance, at least in some cases
- LLM inference tools are Docker-first

## Architecture Overview

```
Windows 11 Host
└── WSL2 Ubuntu 22.04
    ├── Docker Engine
    ├── Ollama Container (Llama 3.2 11B)
    ├── Cloudflare Tunnel Container
    └── Nginx Reverse Proxy Container
```

## Project Structure

```
llama-local-server/
├── Makefile                    # Main orchestrator
├── .env.example               # Environment template
├── .env                       # Your secrets (gitignored)
├── docker-compose.yml         # Multi-container setup
├── scripts/
│   ├── setup-wsl2.ps1        # PowerShell script for Windows
│   ├── install-deps.sh       # Ubuntu dependencies
│   ├── configure-tunnel.sh   # Cloudflare setup
│   ├── setup-autostart.sh    # Windows service setup
│   └── health-check.sh       # System monitoring
├── config/
│   ├── nginx.conf            # Reverse proxy config
│   ├── ollama.env            # Ollama-specific settings
│   └── tunnel.yml            # Cloudflare tunnel config
├── models/                   # Model storage (gitignored)
└── logs/                     # Application logs
```

## Environment Variables Configuration

### `.env` File Structure
```bash
# === SYSTEM CONFIGURATION ===
COMPOSE_PROJECT_NAME=llama-server
DOCKER_BUILDKIT=1

# === MODEL CONFIGURATION ===
MODEL_NAME=llama3.2:11b-instruct-q4_K_M
MODEL_QUANTIZATION=q4_K_M
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_PARALLEL=2
OLLAMA_FLASH_ATTENTION=1

# === GPU CONFIGURATION ===
# AMD GPU (ROCm)
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCM_VERSION=5.7
GPU_MEMORY_FRACTION=0.9

# === NETWORKING ===
HOST_PORT=8080
INTERNAL_PORT=11434
NGINX_PORT=80
ALLOWED_ORIGINS=https://your-domain.com,chrome-extension://

# === CLOUDFLARE TUNNEL ===
# IMPORTANT: Get this token from Cloudflare Zero Trust Dashboard
# DO NOT let scripts auto-create tunnels - use manual token method
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here_from_dashboard
TUNNEL_NAME=llama-api
CLOUDFLARE_ACCOUNT_ID=your_account_id

# === SECURITY ===
# Generate a strong API key: openssl rand -hex 32
API_KEY=your_secure_api_key_here
BASIC_AUTH_USER=admin
# Generate password hash: htpasswd -n admin
BASIC_AUTH_PASS=your_secure_password

# === PATHS (WSL2) ===
# Change 'yourusername' to your actual Ubuntu username
MODELS_PATH=/home/yourusername/llama-server/models
CONFIG_PATH=/home/yourusername/llama-server/config
LOGS_PATH=/home/yourusername/llama-server/logs

# === PERFORMANCE TUNING ===
OLLAMA_KEEP_ALIVE=24h
OLLAMA_LOAD_TIMEOUT=300
MAX_REQUEST_SIZE=50MB
WORKER_PROCESSES=auto
```

## Implementation Phase 1: Core WSL2 Setup

### 1.1 Windows Prerequisites (Manual - One Time)
```powershell
# Run as Administrator in PowerShell
# Enable WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart required
Restart-Computer

# Set WSL2 as default
wsl --set-default-version 2

# Install Ubuntu 22.04
wsl --install -d Ubuntu-22.04
```

### 1.2 Automated WSL2 Configuration
Create `scripts/setup-wsl2.ps1`:
```powershell
# Configure WSL2 performance settings
$wslConfig = @"
[wsl2]
memory=24GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

[interop]
enabled=true
appendWindowsPath=false
"@

$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# Restart WSL2
wsl --shutdown
Start-Sleep 5
wsl -d Ubuntu-22.04
```

## Implementation Phase 2: Automated Docker & Dependencies

### 2.1 Main Makefile
```makefile
.PHONY: help setup install-deps download-model start stop restart logs clean health

# Default target
help:
	@echo "Llama 3.2 11B Local Server"
	@echo "=========================="
	@echo "setup          - Complete system setup"
	@echo "install-deps   - Install dependencies"
	@echo "download-model - Download Llama model"
	@echo "start         - Start all services"
	@echo "stop          - Stop all services"
	@echo "restart       - Restart all services"
	@echo "logs          - Show service logs"
	@echo "health        - Check system health"
	@echo "clean         - Clean up containers"

# Complete setup
setup: install-deps download-model
	@echo "Setup complete! Run 'make start' to begin."

# Install system dependencies
install-deps:
	@echo "Installing system dependencies..."
	sudo ./scripts/install-deps.sh
	@echo "Dependencies installed!"

# Download Llama model
download-model:
	@echo "Downloading Llama 3.2 11B model..."
	docker-compose run --rm ollama ollama pull $(MODEL_NAME)
	@echo "Model downloaded!"

# Start services
start:
	@echo "Starting Llama server..."
	docker-compose up -d
	@echo "Services starting... Check with 'make logs'"

# Stop services
stop:
	@echo "Stopping services..."
	docker-compose down
	@echo "Services stopped!"

# Restart services
restart: stop start

# Show logs
logs:
	docker-compose logs -f

# Health check
health:
	@./scripts/health-check.sh

# Clean up
clean:
	docker-compose down -v
	docker system prune -f
```

### 2.2 Dependency Installation Script
Create `scripts/install-deps.sh`:
```bash
#!/bin/bash

set -e

echo "=== Installing System Dependencies ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    htop \
    neofetch \
    ca-certificates \
    gnupg \
    lsb-release \
    make \
    unzip \
    jq

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Cloudflare Tunnel
echo "Installing Cloudflare Tunnel..."
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb

# Create directories
mkdir -p ~/llama-server/{models,config,logs}

# Set permissions
sudo chown -R $USER:$USER ~/llama-server

echo "=== Dependencies Installation Complete ==="
echo "Please run 'newgrp docker' or log out and back in to use Docker without sudo"
```

## Implementation Phase 3: Multi-Container Setup

### 3.1 Docker Compose Configuration
Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:rocm
    container_name: llama-ollama
    restart: unless-stopped
    ports:
      - "${INTERNAL_PORT}:11434"
    volumes:
      - "${MODELS_PATH}:/root/.ollama"
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
      - OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS}
      - OLLAMA_NUM_PARALLEL=${OLLAMA_NUM_PARALLEL}
      - OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE}
      - HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION}
      - ROCM_VERSION=${ROCM_VERSION}
    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri
    group_add:
      - video
    networks:
      - llama-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: llama-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT}:80"
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - ollama
    networks:
      - llama-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: llama-tunnel
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on:
      - nginx
    networks:
      - llama-network
    healthcheck:
      test: ["CMD", "cloudflared", "--version"]
      interval: 60s
      timeout: 10s
      retries: 3

  watchtower:
    image: containrrr/watchtower
    container_name: llama-watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *
    networks:
      - llama-network

volumes:
  ollama_data:
    driver: local

networks:
  llama-network:
    driver: bridge
```

### 3.2 Nginx Configuration
Create `config/nginx.conf`:
```nginx
events {
    worker_connections 4096;
    multi_accept on;
}

http {
    upstream ollama {
        server ollama:11434;
        keepalive 32;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=chat:10m rate=2r/s;

    # CORS and security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    server {
        listen 80;
        server_name _;

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # API endpoints with authentication
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            # Basic auth or API key
            auth_basic "Llama API";
            auth_basic_user_file /etc/nginx/.htpasswd;
            
            # Or API key in header
            # if ($http_authorization != "Bearer ${API_KEY}") {
            #     return 401 "Unauthorized";
            # }

            # CORS
            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
                return 204;
            }

            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;

            proxy_pass http://ollama;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Increase timeouts for large responses
            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
            
            # Streaming support
            proxy_buffering off;
            proxy_request_buffering off;
        }

        # Chat endpoint with stricter rate limiting
        location /api/chat {
            limit_req zone=chat burst=5 nodelay;
            
            proxy_pass http://ollama;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            
            # Streaming for chat
            proxy_buffering off;
            proxy_request_buffering off;
        }
    }
}
```

## Implementation Phase 4: Cloudflare & Security

### 4.1 Cloudflare Tunnel Setup (RECOMMENDED METHOD)

**Why Manual Token Method is Better:**
Based on your experience, auto-creating tunnels via scripts often fails due to authentication complexities, token storage issues, and permission problems. The manual dashboard method is more reliable.

#### Step-by-Step Cloudflare Setup:

1. **Login to Cloudflare Zero Trust Dashboard**
   - Go to https://dash.teams.cloudflare.com/
   - Navigate to **Access > Tunnels**

2. **Create New Tunnel**
   - Click **"Create a tunnel"**
   - Choose **"Cloudflared"**
   - Name: `llama-api` (or your preferred name)
   - Click **"Save tunnel"**

3. **Get Your Token**
   - Copy the tunnel token (long string starting with `eyJ...`)
   - Add this to your `.env` file as `CLOUDFLARE_TUNNEL_TOKEN`

4. **Configure Public Hostname**
   - Add public hostname: `api.yourdomain.com` (replace with your domain)
   - Service Type: **HTTP**
   - URL: `http://nginx:80` (internal Docker network)
   - Click **"Save tunnel"**

#### How Docker Container Works:
The Cloudflare tunnel container runs `cloudflared` daemon inside Docker, which:
- Connects to Cloudflare's edge servers using your token
- Creates secure outbound-only connections (no firewall changes needed)
- Routes traffic from `api.yourdomain.com` → Docker network → Nginx → Ollama
- Automatically handles SSL/TLS termination at Cloudflare edge

### 4.2 Alternative Script (If You Prefer Automation)
Create `scripts/configure-tunnel.sh` (only if manual method doesn't work):
Create `scripts/configure-tunnel.sh`:
```bash
#!/bin/bash

set -e

echo "=== Configuring Cloudflare Tunnel ==="

# Authenticate (first time only)
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "First time setup - please authenticate:"
    cloudflared tunnel login
fi

# Create tunnel
TUNNEL_NAME=${TUNNEL_NAME:-"llama-api"}
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}' || echo "")

if [ -z "$TUNNEL_ID" ]; then
    echo "Creating new tunnel: $TUNNEL_NAME"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
fi

echo "Tunnel ID: $TUNNEL_ID"

# Create DNS record
echo "Creating DNS record..."
cloudflared tunnel route dns $TUNNEL_NAME api.yourdomain.com

# Get tunnel token
TOKEN=$(cloudflared tunnel token $TUNNEL_NAME)
echo "Add this to your .env file:"
echo "CLOUDFLARE_TUNNEL_TOKEN=$TOKEN"

echo "=== Cloudflare Tunnel Configuration Complete ==="
```

### 4.2 Windows Auto-Start Setup
Create `scripts/setup-autostart.sh`:
```bash
#!/bin/bash

# Create Windows scheduled task for auto-start
cat > /tmp/llama-autostart.xml << 'EOF'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2">
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>DOMAIN\USERNAME</UserId>
    </LogonTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>wsl</Command>
      <Arguments>-d Ubuntu-22.04 -- bash -c "cd ~/llama-server && make start"</Arguments>
    </Exec>
  </Actions>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
</Task>
EOF

echo "Copy /tmp/llama-autostart.xml to Windows and import via Task Scheduler"
echo "Update USERNAME in the XML file first"
```

## Implementation Phase 5: Monitoring & Health Checks

### 5.1 Health Check Script
Create `scripts/health-check.sh`:
```bash
#!/bin/bash

echo "=== Llama Server Health Check ==="

# Check WSL2 resources
echo "System Resources:"
echo "  CPU: $(nproc) cores"
echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $7}') available"
echo "  GPU: $(rocm-smi --showhw | grep 'GPU\[' | wc -l) AMD GPU(s) detected"

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi
echo "✅ Docker is running"

# Check containers
CONTAINERS=("llama-ollama" "llama-nginx" "llama-tunnel")
for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q $container; then
        echo "✅ $container is running"
    else
        echo "❌ $container is not running"
    fi
done

# Check Ollama API
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama API is responding"
    echo "Models loaded:"
    curl -s http://localhost:11434/api/tags | jq -r '.models[].name' | sed 's/^/  - /'
else
    echo "❌ Ollama API is not responding"
fi

# Check GPU utilization
if command -v rocm-smi &> /dev/null; then
    echo "GPU Status:"
    rocm-smi --showuse | grep -E "GPU\[|Memory Usage|GPU Activity"
fi

# Check tunnel status
if docker logs llama-tunnel 2>&1 | grep -q "Connection established"; then
    echo "✅ Cloudflare tunnel is connected"
else
    echo "❌ Cloudflare tunnel connection issues"
fi

echo "=== Health Check Complete ==="
```

## What Can/Cannot Be Automated

### ✅ Fully Automated
- WSL2 Ubuntu configuration
- Docker and dependencies installation
- Model downloading
- Container orchestration
- Service startup/shutdown
- Health monitoring
- Auto-updates (via Watchtower)

### ⚠️ Semi-Automated (One-time manual setup)
- WSL2 initial installation (Windows features)
- Cloudflare account setup and first auth
- `.env` file creation with your secrets
- Windows scheduled task creation
- Domain DNS configuration

### ❌ Cannot Be Automated
- Initial Windows features enabling (requires admin/restart)
- Cloudflare tunnel first-time authentication (browser required)
- Hardware driver installation (if needed)
- Network firewall configuration
- Security certificate management

## Usage Instructions

### Initial Setup (One-time)

> **📁 Repository Setup:** First, create your own GitHub repository:
> 1. Go to GitHub and create new repository: `llama-local-server`
> 2. Clone it: `git clone https://github.com/yourusername/llama-local-server.git`
> 3. Replace `yourusername` with your actual GitHub username

1. **Enable WSL2** (manual): Run `scripts/setup-wsl2.ps1` as admin in PowerShell
2. **Install Ubuntu 22.04** via Microsoft Store or `wsl --install -d Ubuntu-22.04`
3. **Clone your repository** in WSL2: 
   ```bash
   git clone https://github.com/yourusername/llama-local-server.git
   cd llama-local-server
   ```
4. **Set up Cloudflare tunnel** (manual method recommended - see Phase 4)
5. **Configure environment**: 
   ```bash
   cp .env.example .env
   nano .env  # Edit with your values
   ```
6. **Run setup**: `make setup`
7. **Start services**: `make start`

## Server Management & Operations

### 24/7 Server Operation

Your server is designed to run 24/7 automatically. Here's what you need to know:

#### **Automatic Startup**
- Docker containers have `restart: unless-stopped` policy
- Services auto-start when WSL2 boots
- Windows scheduled task starts WSL2 on login/boot

#### **When You Need Manual Commands**

**Commands Location:** Run these inside WSL2 Ubuntu (not CMD/PowerShell):
```bash
# Open WSL2 terminal
wsl -d Ubuntu-22.04
cd ~/llama-local-server
```

**Scenarios requiring manual intervention:**

1. **Initial Setup Only:**
   ```bash
   make setup    # One-time system setup
   make start    # First startup
   ```

2. **Maintenance (Monthly):**
   ```bash
   make stop     # Before system updates
   make start    # After maintenance
   ```

3. **Model Updates (As needed):**
   ```bash
   make stop
   docker-compose run --rm ollama ollama pull llama3.2:11b-instruct-q4_K_M
   make start
   ```

4. **Troubleshooting:**
   ```bash
   make logs     # Check what's happening
   make health   # System diagnostics
   make restart  # Quick restart
   ```

#### **Maintenance Schedule**

| Task | Frequency | Command |
|------|-----------|---------|
| Health Check | Weekly | `make health` |
| System Updates | Monthly | `sudo apt update && sudo apt upgrade` |
| Container Updates | Monthly | `docker-compose pull && make restart` |
| Full Restart | Bi-weekly | `make restart` |
| Model Updates | As needed | Custom pull commands |

#### **Normal Operation**
Once set up, your server runs automatically. You typically don't need daily `make start/stop commands`. The server should:
- Start automatically when Windows boots
- Restart containers if they crash
- Handle API requests 24/7
- Update containers automatically (via Watchtower)

#### **Monitoring Your 24/7 Server**
```bash
# Quick status check
make health

# Detailed monitoring
htop                    # System resources
docker stats           # Container resources
docker-compose logs -f  # Live logs
```

### Team Access
Your team can connect to your API via:
- **Direct URL**: `https://api.yourdomain.com/api/chat`
- **API Key**: Include in Authorization header
- **Rate limits**: 10 req/s general, 2 req/s for chat

### Performance Optimization
- **Expected throughput**: 15-25 tokens/second
- **Memory usage**: ~14GB GPU + 8GB system RAM
- **Concurrent users**: 2-3 simultaneously with good performance
- **Model loading time**: 30-60 seconds on first request

## Troubleshooting

### Common Issues & Solutions

#### **Docker Permission Denied**
```bash
# Error: permission denied while trying to connect to Docker daemon
sudo usermod -aG docker $USER
newgrp docker
# Or logout and login again
```

#### **GPU Not Detected**
```bash
# Check ROCm installation
rocm-smi
# If command not found, install ROCm drivers:
sudo apt install rocm-dev rocm-libs
```

#### **Cloudflare Tunnel Connection Failed**
```bash
# Check tunnel logs
docker logs llama-tunnel

# Common fixes:
# 1. Verify token in .env file
# 2. Check if tunnel exists in CF dashboard
# 3. Ensure no port conflicts
sudo netstat -tlnp | grep :80
```

#### **API Returns 401 Unauthorized**
```bash
# Check nginx auth configuration
docker exec llama-nginx cat /etc/nginx/.htpasswd

# Generate new password hash
htpasswd -n admin

# Update nginx config with new hash
```

#### **Model Download Fails**
```bash
# Check available space
df -h

# Retry with specific model
docker-compose run --rm ollama ollama pull llama3.2:11b-instruct-q4_K_M

# Check model list
docker-compose run --rm ollama ollama list
```

#### **WSL2 Won't Start on Boot**
```bash
# Check Windows scheduled task exists
# Run in Windows PowerShell:
Get-ScheduledTask -TaskName "*llama*"

# Manual start WSL2
wsl -d Ubuntu-22.04
```

#### **High Memory Usage**
```bash
# Check container memory usage
docker stats

# Adjust Ollama memory settings in .env
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_KEEP_ALIVE=5m

# Restart containers
make restart
```

#### **Slow Performance**
```bash
# Check GPU utilization
rocm-smi --showuse

# Verify model quantization
# Q4_K_M is recommended for your 16GB GPU
# Avoid Q8_0 or unquantized models

# Check system load
htop
iostat -x 1
```

### Performance Optimization Notes

- **Expected Performance**: 15-25 tokens/second with Llama 3.2-11B Q4_K_M
- **Memory Usage**: ~14GB GPU VRAM + 8GB System RAM
- **Concurrent Users**: 2-3 users with good performance
- **Model Loading**: 30-60 seconds on first request

### Getting Help

1. **Check logs first**: `make logs`
2. **Run health check**: `make health`
3. **Check Docker status**: `docker ps -a`
4. **Monitor resources**: `htop` and `docker stats`
5. **Review Cloudflare dashboard** for tunnel status

### Emergency Recovery

If everything breaks:
```bash
# Nuclear option - clean slate
make clean
docker system prune -a -f
make setup
make start
```

**Backup Strategy**: Your models are stored in `~/llama-server/models/`. Back this up regularly as it's 7GB+ download.