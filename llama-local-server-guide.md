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
└── WSL2 Ubuntu 24.04
    ├── Docker Engine
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
│   ├── ollama.env            # Ollama-specific settings (non-sensitive, committed)
│   └── tunnel.yml            # Cloudflare tunnel config (optional, for advanced use)
├── models/                   # Model storage (gitignored)
└── logs/                     # Application logs
```

### About `config/tunnel.yml`

- `config/tunnel.yml` is an **optional** configuration file for advanced Cloudflare Tunnel setups.
- Use it if you need to define custom ingress rules, multiple hostnames, or advanced tunnel options.
- By default, the Docker Compose stack uses the tunnel token method and does not require this file.
- If you want to use `tunnel.yml`, update the `cloudflared` service in `docker-compose.yml` to mount and reference this file:
  ```yaml
  volumes:
    - ./config/tunnel.yml:/etc/cloudflared/config.yml:ro
  command: tunnel --config /etc/cloudflared/config.yml run
  ```
- See [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/) for details.

## Environment Variables Configuration

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

### Environment Variable Separation: `.env` vs `config/ollama.env`

- **Sensitive variables** (API keys, passwords, Cloudflare tokens) are kept in `.env` (gitignored).
- **Ollama-specific, non-sensitive variables** (model name, quantization, performance tuning) are kept in `config/ollama.env` and committed to git.
- This separation improves security and clarity, and makes it easier to share non-sensitive config with collaborators or in public repos.
- Update `docker-compose.yml` to use `env_file: ./config/ollama.env` for the Ollama service.

#### Example: `config/ollama.env`
```env
# Ollama-specific configuration (non-sensitive)
MODEL_NAME=llama3.2:11b-instruct-q4_K_M
MODEL_QUANTIZATION=q4_K_M
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_PARALLEL=2
OLLAMA_FLASH_ATTENTION=1
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCM_VERSION=5.7
GPU_MEMORY_FRACTION=0.9
OLLAMA_KEEP_ALIVE=24h
OLLAMA_LOAD_TIMEOUT=300
MAX_REQUEST_SIZE=50MB
WORKER_PROCESSES=auto
```

- Remove these variables from `.env` and place them in `config/ollama.env`.
- Only keep sensitive and global variables in `.env`.

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

## Implementation Phase 1: Core WSL2 Setup

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

# Install Ubuntu 24.04
wsl --install -d Ubuntu-24.04
```

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

### 1.2 Automated WSL2 Configuration
Create `scripts/setup-wsl2.ps1`:
```powershell
# WSL2 configuration script for Llama local server

# PowerShell script for WSL2 setup
# See guide for full script

# Configure WSL2 performance settings
$wslConfig = @"
[wsl2]
memory=24GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

# [interop] section is deprecated in modern WSL2 (Ubuntu 24.04+), but shown here for reference:
# [interop]
# enabled=true
# appendWindowsPath=false
"@

$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# Restart WSL2
wsl --shutdown
Start-Sleep 5
# IMPORTANT: Update the distribution name below to match your installed Ubuntu version.
# Run 'wsl -l -v' in PowerShell to see available distributions.
wsl -d Ubuntu-24.04
```

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

---

## WSL2 Performance Tuning: .wslconfig

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

For WSL2 on Ubuntu 24.04 and later, **do not include an active `[interop]` section** in your `.wslconfig`. This section is not supported in modern WSL2 and will cause errors. It is shown below for reference only and should remain commented out.

Example `.wslconfig`:

```
[wsl2]
memory=24GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

# [interop]
# enabled=true
# appendWindowsPath=false
```

> **Note:** If you see errors about `[interop]` when running setup scripts or starting WSL2, remove or comment out that section and restart WSL2 with `wsl --shutdown`.

---

## WSL2 Distribution Name

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

If you see an error like `There is no distribution with the supplied name`, it means the script is trying to start a WSL2 distribution that does not exist on your system. To find your installed distributions, run:

```
wsl -l -v
```

Update the script to use the correct distribution name (e.g., `Ubuntu`, `Ubuntu-22.04`, or `Ubuntu-24.04`).

## Implementation Phase 2: Automated Docker & Dependencies

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

## Implementation Phase 3: Multi-Container Setup

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

## Implementation Phase 4: Cloudflare & Security

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

### 4.1 Cloudflare Tunnel Setup (RECOMMENDED: Automated Token Method)

> **This is the recommended, automated Cloudflare token setup.** It is the most reliable and industry-standard approach for most users. Manual/scripted methods are provided below only for troubleshooting or advanced customization.

#### Why Automated Token Method?
> The automated token method is the recommended and most reliable path for most users. It avoids authentication complexities, token storage issues, and permission problems that often occur with manual or scripted approaches. This structure mirrors robust open-source/public guides and makes your documentation easier for others to follow and maintain.

#### Step-by-Step Cloudflare Automated Token Setup:

1. **Login to Cloudflare Zero Trust Dashboard**
   - Go to https://dash.teams.cloudflare.com/
   - Navigate to **Access > Tunnels** (now under the "Networks" section)

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

> **Why:** The automated token method is the most reliable and secure for most users. Manual/scripted methods are included below for troubleshooting edge cases or if you require specific customizations.

#### How Docker Container Works:
The Cloudflare tunnel container runs `cloudflared` inside Docker, which:
- Connects to Cloudflare's edge servers using your token
- Creates secure outbound-only connections (no firewall changes needed)
- Routes traffic from `api.yourdomain.com` → Docker network → Nginx → Ollama
- Automatically handles SSL/TLS termination at Cloudflare edge

---

### 4.2 Manual/Scripted Method (Fallback)

> **Use this only if the automated method fails or you need advanced customization.**

If you prefer automation or need to troubleshoot, you can use the provided script. However, this method is less reliable due to authentication and permission complexities.

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
cloudflared tunnel route dns $TUNNEL_NAME api.yourdomain.com

# Get tunnel token
TOKEN=$(cloudflared tunnel token $TUNNEL_NAME)
echo "Add this to your .env file:"
echo "CLOUDFLARE_TUNNEL_TOKEN=$TOKEN"

echo "=== Cloudflare Tunnel Configuration Complete ==="
```

> **Why:** This manual/scripted method is provided for cases where automation fails or specific customization is required. It is not the default because it is more error-prone and requires more manual intervention.

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
      <Arguments>-d Ubuntu-24.04 -- bash -c "cd ~/llama-server && make start"</Arguments>
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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

## Implementation Phase 5: Monitoring & Health Checks

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

## What Can/Cannot Be Automated

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

### Initial Setup (One-time)

> **📁 Repository Setup:** First, create your own GitHub repository:
> 1. Go to GitHub and create new repository: `llama-local-server`
> 2. Clone it: `git clone https://github.com/yourusername/llama-local-server.git`
> 3. Replace `yourusername` with your actual GitHub username

1. **Enable WSL2** (manual): Run `scripts/setup-wsl2.ps1` as admin in PowerShell
2. **Install Ubuntu 24.04** via Microsoft Store or `wsl --install -d Ubuntu-24.04`
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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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
wsl -d Ubuntu-24.04
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

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

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
wsl -d Ubuntu-24.04
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

---

## Fixing Windows Line Endings in Shell Scripts (CRLF → LF)

[Return To Top](#complete-wsl2--llama-32-11b-local-server-setup-guide)

**If you see errors like `$'\r': command not found` or strange issues running shell scripts in WSL2/Ubuntu, your scripts likely have Windows (CRLF) line endings.**

### Why This Happens
- Windows uses CRLF (carriage return + line feed) for newlines, but Linux/WSL expects LF (line feed) only.
- Bash interprets the `\r` (carriage return) as part of the command, causing errors.

### How to Fix

#### 1. Check if dos2unix is installed
```bash
which dos2unix
```
If it returns a path (e.g., `/usr/bin/dos2unix`), it's installed. If not, install it:
```bash
sudo apt update
sudo apt install dos2unix
```

#### 2. Convert your scripts
Navigate to your scripts directory using the full Windows path (not `~/`):
```bash
cd /mnt/c/Users/Username/OneDrive/Documents/jerry-dev/github/local-llama-wsl2-server/scripts
```
Then run:
```bash
dos2unix *.sh
```

#### 3. Why not use `~/`?
`~/` refers to your WSL home directory, not your Windows user directory. Use `/mnt/c/...` for files on your Windows drive.

#### 4. Re-run your script
```bash
bash install-deps.sh
```

### Docker Desktop for Windows Context
- If you see messages about Docker Desktop for Windows, it means your WSL2 Ubuntu is using Docker Desktop’s managed VM for containers. This is secure and recommended for most users.
- You do **not** need to run Docker as root in WSL2, and you can safely use Docker Desktop’s integration.

### Summary
- Always fix line endings before running scripts in WSL2.
- Use the correct path for your files.
- Docker Desktop provides a secure, managed environment for most local development needs.

---

## Lessons from Gemini & Copilot: Cloudflare Tunnel, Architecture, and Security

- **Cloudflare Tunnel Setup:**
  - For Ubuntu on WSL2, always choose "Debian" and "64-bit" (amd64) when installing cloudflared. Do not use arm64 unless you are on ARM hardware.
  - Adding the Cloudflare GPG key and repository is standard and secure. The apt output about autoremove is informational and not a problem.
  - If you see `cloudflared is already the newest version`, you are up to date.

- **Tunnel Architecture:**
  - Creating dedicated tunnels for each service (e.g., Llama, SSH) is a best practice for isolation and resilience.
  - Each tunnel can have its own subdomain (e.g., llama.jerryagenyi.xyz for Llama, ssh.jerryagenyi.xyz for SSH).
  - If a tunnel goes down, only that service is affected.

- **Cloudflare Tunnel Service URL:**
  - The Service URL in your Cloudflare Tunnel should match the port your Nginx (or other service) is listening on in WSL2.
  - If your .env has HOST_PORT=8080, set the Service URL to `http://localhost:8080` in the Cloudflare dashboard.
  - Use `http://` (not `https://`) unless you have configured SSL on your local Nginx. Cloudflare provides HTTPS at the edge.

- **General Security & Best Practices:**
  - Never use wildcards or overly broad CORS origins. Be specific with ALLOWED_ORIGINS.
  - Always use strong, unique API keys and hashed passwords.
  - Keep your .env and secrets private.
  - Document your tunnel and service mappings for future reference.

- **Summary:**
  - Your approach of creating tunnels as needed, using dedicated subdomains, and following Copilot's .env advice is robust and secure.

  - Don't worry about apt informational messages or about having multiple tunnels—this is a good practice for service isolation.

---

## Additional Troubleshooting Lessons (from Gemini & Copilot)

### 1. Docker Compose Variable Expansion with Password Hashes

If you use a password hash (such as for `BASIC_AUTH_PASS`) that contains `$` symbols, Docker Compose will try to expand them as environment variables. This causes warnings like:

```
WARN[0000] The "apr1" variable is not set. Defaulting to a blank string.
```

**Solution:**

- Enclose the entire value in single quotes in your `.env` file:
  ```env
  BASIC_AUTH_PASS='admin:$apr1$UzN7IM2z$Kj04zZAt7LhWu1id0Q4GY0'
  ```
- This prevents Docker Compose from interpreting `$` as variable expansion.

### 2. Resolving Docker Container Name Conflicts

If you see errors like:

```
Error response from daemon: Conflict. The container name "/llama-ollama" is already in use by container ...
```

**Solution:**

1. Stop the container (if running):
   ```bash
   docker stop llama-ollama
   ```
2. Remove the container:
   ```bash
   docker rm llama-ollama
   ```

Repeat for any other conflicting containers (e.g., `llama-watchtower`).

### 3. WSL2 GPU Passthrough: /dev/kfd and /dev/dri

For AMD GPU acceleration in WSL2, the device files `/dev/kfd` and `/dev/dri` must exist in your Ubuntu environment. If they are missing, your containers will not be able to use the GPU.

**Check:**
```bash
ls -la /dev/kfd /dev/dri
```

If you see `No such file or directory`, try the following:

- Ensure you have installed the latest AMD drivers on Windows (use the full WHQL package and "factory reset" option).
- Reboot Windows after driver installation.
- Make sure Hyper-V, Virtual Machine Platform, and Windows Subsystem for Linux are enabled in Windows Features.
- Run `wsl --update` and `wsl --shutdown` from PowerShell.
- Open your Ubuntu WSL2 terminal and check again.

If the device files are still missing, you may need to:
- Check Device Manager for errors on your GPU.
- Consider a full WSL2 reset (unregister and reinstall the distro) as a last resort.

**Note:**
If `/dev/kfd` and `/dev/dri` are not present, GPU passthrough is not working and containers like Ollama will fail to start.

---

## Handling Line Endings and Script Files in Cross-Platform Development

### Why We Use `.gitattributes` for Shell Scripts
- The `.gitattributes` file in this repo contains:
  ```
  *.sh text eol=lf
  ```
- This enforces **LF (Unix-style) line endings** for all `.sh` files, regardless of which OS you use (Windows, macOS, Linux).
- **Why?**
  - Shell scripts require LF endings to run correctly in Linux/WSL2. Windows CRLF endings will cause errors like `$'\r': command not found`.
  - This prevents accidental introduction of CRLF endings when editing scripts on Windows.
- If you see warnings about line endings in git, or if you have trouble running scripts, use `dos2unix <script>` to convert them to LF.

### What Are These Script Files?

#### `get-docker.sh`
- This is the official Docker installation script, downloaded from https://get.docker.com.
- It is **not part of your repo** and should not be committed. It is only needed temporarily to install Docker Engine on Linux/WSL2.
- You can safely delete it after Docker is installed.

#### `configure-tunnel.sh`
- This is a project-specific script to automate Cloudflare Tunnel setup for your Llama server.
- It helps you authenticate, create a tunnel, set up DNS, and retrieve your tunnel token.
- This script **should remain in your repo** (it does not contain secrets).

### Best Practice
- Only keep project-specific, reusable scripts in your repo.
- Do not commit downloaded or one-time-use installation scripts like `get-docker.sh`.
- Use `.gitattributes` to enforce correct line endings for all collaborators.