# Ollama Local Deployment Guide: Windows, WSL, and GPU Acceleration

## Table of Contents
- [Abstract](#abstract)
- [Command Environment Legend](#command-environment-legend)
- [High-Level Architecture & Workflow (At a Glance)](#high-level-architecture--workflow-at-a-glance)
- [Nginx Configuration for Ollama API Proxying](#nginx-configuration-for-ollama-api-proxying)
- [Hardware Assessment & Compatibility](#hardware-assessment--compatibility)
- [Prerequisites & Installation](#prerequisites--installation)
- [Expected/Original Setup: Containerised GPU](#expectedoriginal-setup-containerised-gpu)
- [The Problem: GPU Passthrough in WSL2](#the-problem-gpu-passthrough-in-wsl2)
- [CPU-Only Workaround](#cpu-only-workaround)
- [Breakthrough: Native Windows Ollama for GPU](#breakthrough-native-windows-ollama-for-gpu)
- [Hybrid Architecture & Docker Compose](#hybrid-architecture--docker-compose)
- [Model Selection & Performance](#model-selection--performance)
- [Ollama Command Reference](#ollama-command-reference)
- [Troubleshooting](#troubleshooting)
- [Tunnel & Service Naming Strategy](#tunnel--service-naming-strategy)
- [Hardware Upgrade Considerations](#hardware-upgrade-considerations)
- [Future Expansions & Capabilities](#future-expansions--capabilities)
- [Summary](#summary)

---

## Abstract
This guide provides a comprehensive, step-by-step resource for deploying a local LLM server using Ollama with GPU acceleration on Windows. It details a hybrid architecture: Ollama runs natively on Windows for direct GPU access, while WSL2 (Ubuntu) hosts Docker containers for Nginx, Cloudflare Tunnel, and Watchtower. The guide is based on real-world troubleshooting with AMD GPUs and Docker Desktop, and all instructions use British English with explicit command context.

[Return to Top](#table-of-contents)

---

## Command Environment Legend
- `command` (Windows PowerShell/CMD)
- `$ command` (WSL2 / Linux Terminal)
- `# explanation or output` (for comments or expected output)

[Return to Top](#table-of-contents)

---

## High-Level Architecture & Workflow (At a Glance)
This guide documents the journey to set up a robust local Large Language Model (LLM) server on Windows, specifically designed to leverage AMD GPU acceleration while utilising Windows Subsystem for Linux 2 (WSL2) and Docker Desktop for a flexible networking stack and secure public access.

### Architecture Comparison Table
| Approach         | Ollama Inference | GPU Acceleration | Networking Stack | Public Access | Status/Result |
|------------------|------------------|------------------|------------------|--------------|--------------|
| **Expected/Original** | WSL2 Docker        | Intended (ROCm)   | WSL2 Docker      | Cloudflare/Nginx | Not working (no GPU passthrough) |
| **Hybrid (Current)**     | Native Windows     | Yes (ROCm, AMD)   | WSL2 Docker      | Cloudflare/Nginx | Working, high performance |

### Workflow Diagram
```
[Internet] <-- Cloudflare DNS --> [Cloudflare Edge Network]
        ^                                      |
        | (Secure Tunnel)                      | (Ingress Rules)
        V                                      V
[Your PC (Windows Host)]                       [Cloudflare Tunnel Container (in WSL2 Docker)]
     ^   |                                            |
     |   | (http://localhost:11434)                   | (http://llama-nginx:80)
     |   |                                            V
     |   |                                 [Nginx Container (in WSL2 Docker)]
     |   |                                            |
     |   | (http://host.docker.internal:11434)       |
     |   |                                            |
     |   V                                            |
     | [Ollama Server (Native Windows, GPU)]  <------|
     |                                               ^
     | (Local applications/containers) --------------|
```

### Public API Endpoints
- **API base:** `https://llm.jerryagenyi.xyz/api/`
- **Generate endpoint:** `https://llm.jerryagenyi.xyz/api/generate`
- **Chat endpoint:** `https://llm.jerryagenyi.xyz/api/chat`
- **Tags (list models):** `https://llm.jerryagenyi.xyz/api/tags`

[Return to Top](#table-of-contents)

---

## Nginx Configuration for Ollama API Proxying
Your Nginx configuration must ensure all `/api/` paths are correctly proxied to the Ollama backend. Below is a recommended structure:

### Main Nginx Config (`./config/nginx.conf`)
```nginx
user nginx;
worker_processes auto;

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    upstream ollama_backend {
        # This points to the native Windows Ollama server from within the Docker Nginx container
        server host.docker.internal:11434;
    }

    # Include your site-specific configurations
    include /etc/nginx/conf.d/*.conf;
}
```

### Site-Specific Config (`./config/conf.d/default.conf`)
```nginx
server {
    listen 80;
    server_name llm.jerryagenyi.xyz localhost;

    location / {
        return 200 "Ollama Nginx Proxy is running.";
    }

    location /api/ {
        proxy_pass http://ollama_backend:11434/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        proxy_connect_timeout 300s;
    }

    # Example for /web/ endpoint if you add a UI later
    # location /web/ {
    #     proxy_pass http://some_ui_container:port/;
    #     proxy_set_header Host $host;
    # }
}
```
**Note:** `ollama_backend` is defined in the main config as pointing to `host.docker.internal:11434`.

[Return to Top](#table-of-contents)

---

## Hardware Assessment & Compatibility
Your system is excellent for GPU-accelerated 8B models (e.g., Llama 3, Qwen, Mixtral 8x7B) and capable of CPU-only for larger models. For larger models (e.g., 70B+), VRAM is the limiting factor. 16GB VRAM is best for 7B/8B models; 24GB+ is needed for 70B+.

### Hardware Upgrade Considerations
- **Adding a Second GPU (e.g., another RX 6800 XT):**
  - Not recommended on B550 motherboards due to limited PCIe lanes (second slot runs at x4, reducing performance).
  - Increases power and cooling requirements; may require a higher wattage PSU and improved airflow.
- **Single High-End GPU Upgrade (e.g., RTX 4090):**
  - B550 motherboards support PCIe 4.0 x16, which is fully compatible.
  - Upgrade PSU to at least 850W (from 750W) for stability.
  - Ensure your case has sufficient airflow and cooling for high-end GPUs.
- **RAM Upgrade (beyond 32GB):**
  - Limited benefit for GPU-accelerated inference, but useful for CPU-only larger models or heavy multitasking.

[Return to Top](#table-of-contents)

---

## Prerequisites & Installation
1. **Windows 10/11** (fully updated)
2. **WSL2 (Ubuntu 24.04 LTS recommended)**
   - `$ wsl --install -d Ubuntu-24.04` (PowerShell)
3. **Docker Desktop for Windows** (with WSL2 integration enabled for Ubuntu)
   - Download from [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - Enable WSL2 integration in Docker Desktop settings.
   - **Note:** Docker Desktop must be running for the Cloudflare Tunnel to be active. It is beneficial to set Docker Desktop to start at Windows login.
4. **Git**
   - `$ sudo apt install git` (WSL2)
5. **Ollama for Windows**
   - Download from [ollama.com/download](https://ollama.com/download) and install on Windows.
   - **Note:** The installer places a shortcut in `C:\Users\<YourUsername>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`, ensuring it auto-starts in the background on login (as `ollama.exe` in Task Manager). It does not appear as a Windows Service or tray icon.
6. **AMD GPU Drivers**
   - Use the specific driver version that worked: `whql-amd-software-adrenalin-edition-25.5.1-win11-may8-rdna.exe`.
   - Perform a clean install for ROCm support.
7. **Cloudflare Account & Zero Trust Tunnel Setup**
   - Create a Cloudflare account and follow [Cloudflare's Zero Trust Tunnel guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/) to generate a tunnel token.

[Return to Top](#table-of-contents)

---

## Expected/Original Setup: Containerised GPU
- **Goal:** Run Ollama in a Docker container on WSL2 with GPU passthrough (using `ollama/ollama:rocm` and mounting `/dev/kfd`, `/dev/dri`).
- **Why:** This is the standard approach for containerised LLMs with GPU.
- **Example (non-working) docker-compose.yml snippet:**
```yaml
ollama:
  image: ollama/ollama:rocm
  runtime: runc
  devices:
    - /dev/kfd
    - /dev/dri
  environment:
    - OLLAMA_HOST=0.0.0.0
  ports:
    - "11434:11434"
```
- **Result:**
  - This approach did not work due to GPU passthrough limitations in WSL2 on Windows (see below).

[Return to Top](#table-of-contents)

---

## The Problem: GPU Passthrough in WSL2
- **Error:** `Error: no compatible GPUs were discovered` in the container.
- **Symptoms:** `/dev/kfd` and `/dev/dri` missing in WSL2, despite correct drivers, `.wslconfig`, and Docker Desktop GPU settings.
- **Conclusion:** WSL2/Docker Desktop cannot reliably pass through AMD GPUs for ROCm in containers on Windows. This may differ on a pure Linux system—community feedback is welcome.

[Return to Top](#table-of-contents)

---

## CPU-Only Workaround
- **Change:** Switched to `ollama/ollama:latest` (CPU-only), removed GPU-specific lines from `docker-compose.yml`.
- **Result:** Server worked, but performance was slow:
  - Llama 3.2 3B: ~6 seconds per response
  - Qwen 8B: ~1 minute per response

[Return to Top](#table-of-contents)

---

## Breakthrough: Native Windows Ollama for GPU
- **Solution:** Install and run Ollama natively on Windows.
- **Verification:**
  - Open PowerShell and run:
    `ollama serve` (PowerShell)
  - Check the logs for `library=rocm` and your GPU name (e.g., `AMD Radeon RX 6800 XT total="16.0 GiB"`).
  - **Note:** The model's self-description is not reliable for GPU status—always check the Ollama server logs.
- **Performance:** Qwen 8B model now responds in seconds, confirming GPU acceleration.

[Return to Top](#table-of-contents)

---

## Hybrid Architecture & Docker Compose
### High-Level Architecture & Workflow (At a Glance)
- **Windows Host:** Native Ollama (GPU)
- **WSL2/Docker:** Nginx, Cloudflare Tunnel, Watchtower
- **Nginx connects to Ollama via** `http://host.docker.internal:11434`

#### Diagram
```
+-------------------+         +-------------------+         +-------------------+
|   Windows Host    |         |     WSL2 (Ubuntu) |         |   Cloudflare      |
|-------------------|         |-------------------|         |-------------------|
| Ollama (GPU)      | <-----> | Nginx (Docker)    | <-----> | Tunnel            |
|                   |         | Cloudflared       |         | (Public Access)   |
+-------------------+         +-------------------+         +-------------------+
```

#### Ideal (Non-Working) Approach
- Fully containerised Ollama with GPU in WSL2 Docker (not possible due to GPU passthrough limitations).

#### Successful (Working) Approach
- Native Windows Ollama for GPU, with all networking/public access managed in WSL2 Docker containers.

### Final docker-compose.yml
```yaml
# docker-compose.yml for Llama Local Server with GPU via native Windows Ollama
# This configuration assumes Ollama is installed directly on Windows and using the GPU.

services:
  nginx:
    image: nginx:alpine
    container_name: llama-nginx
    restart: unless-stopped
    ports:
      - "${EXTERNAL_NGINX_PORT}:80" # e.g., 8080:80
    environment:
      - OLLAMA_HOST=http://host.docker.internal:11434
    volumes:
      - ./config:/etc/nginx/conf.d:ro
    networks:
      - llama-network

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: llama-tunnel
    restart: unless-stopped
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
      - CLOUDFLARED_OPTS=--no-autoupdate tunnel --url http://llama-nginx:${EXTERNAL_NGINX_PORT}
    depends_on:
      - nginx
    networks:
      - llama-network

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
- **Key changes:**
  - Removed `ollama` service (now native on Windows)
  - Nginx uses `OLLAMA_HOST=http://host.docker.internal:11434`
  - Cloudflared depends on Nginx

#### To apply changes:
$ docker compose down
$ docker compose up -d

#### To verify Cloudflare Tunnel status:
- Check the Cloudflare Zero Trust dashboard for tunnel health.
- Logs for the `cloudflared` container can be viewed with:
  `$ docker logs llama-tunnel` (WSL2)

[Return to Top](#table-of-contents)

---

## Model Selection & Performance
- **7B/8B models** (Llama 3 8B, Mixtral 8x7B, Qwen 8B) are ideal for 16GB VRAM.
- **Larger models** (70B+) require 24GB+ VRAM.
- **Performance:**
  - GPU: Qwen 8B responds in seconds
  - CPU: Qwen 8B takes ~1 minute/response

[Return to Top](#table-of-contents)

---

## Ollama Command Reference
- `ollama pull <model>`: Download a model (recommended for reliability)
- `ollama run <model>`: Pull and run a model interactively
- `ollama list`: List downloaded models
- `ollama serve`: Start Ollama server (API mode)
- `ollama --version`: Show Ollama version

[Return to Top](#table-of-contents)

---

## Troubleshooting
- **/dev/kfd and /dev/dri missing in WSL2:**
  - Native GPU passthrough for AMD is not supported in WSL2 Docker containers
  - Solution: Run Ollama natively on Windows
- **Docker Desktop Integration:**
  - Ensure Docker Desktop is running and WSL2 integration is enabled for Ubuntu
  - Test with:
    `$ docker --version` (WSL2)
- **Permissions:**
  - If you see `permission denied` for Docker, add your user to the docker group:
    `$ sudo usermod -aG docker $USER && newgrp docker` (WSL2)
- **Cloudflare Tunnel:**
  - Check tunnel health in the Cloudflare dashboard
  - Ensure Nginx is running before Cloudflared
- **Ollama GPU Detection:**
  - Check `ollama serve` logs for `library=rocm` and your GPU name
  - Model self-description is not reliable for GPU status
- **Model Download Issues:**
  - Use `ollama pull <model>` for best results
- **General Advice:**
  - Ensure Windows, WSL2, and AMD drivers are fully up to date.
  - GPU passthrough issues may be specific to Windows/WSL2; pure Linux systems may behave differently. Community feedback is encouraged.

[Return to Top](#table-of-contents)

---

## Tunnel & Service Naming Strategy
This project uses a robust, scalable naming strategy for Cloudflare Tunnels and public hostnames:

### One Tunnel Per Machine/Location
- Each physical machine or server gets its own Cloudflare Tunnel (e.g., `desktop-home-lab-tunnel`).
- **Benefits:** Clear ownership, independent operation, easier troubleshooting, and security (unique tokens).

### Public Hostnames Per Service
- Each service is exposed via a dedicated public hostname (e.g., `llm.jerryagenyi.xyz`, `n8n.jerryagenyi.xyz`).
- **Benefits:** Service-oriented access, flexibility, and easier Nginx integration.

#### Example Mapping
| Service Type        | Public Hostname             | Internal Service Endpoint | Nginx Config `location` | Notes |
|---------------------|----------------------------|--------------------------|-------------------------|-------|
| LLM API (Ollama)    | `llm.jerryagenyi.xyz`      | `http://llama-nginx:80`  | `/api/` proxies to `http://ollama_backend:11434/api/` | Main LLM API endpoint |
| N8N Automation      | `n8n.jerryagenyi.xyz`      | `http://n8n-container:5678` | (optional) | Local N8N instance |
| Nginx Health Check  | `llm.jerryagenyi.xyz` (root) | `http://llama-nginx:80` | `/` returns health message | Nginx proxy health |
| Personal Website    | `my-website.jerryagenyi.xyz`| `http://localhost:8000`  | (optional) | Local website |
| Developer Dashboard | `dash.jerryagenyi.xyz`     | `http://localhost:8081`  | (optional) | Monitoring tools |

#### Creating New Hostnames in Cloudflare Zero Trust
1. Log in to Cloudflare Zero Trust Dashboard.
2. Go to **Access > Tunnels** and select your tunnel (e.g., `desktop-home-lab-tunnel`).
3. Under **Public Hostnames**, add a new hostname (e.g., `llm.jerryagenyi.xyz`) and set the service URL (e.g., `http://llama-nginx:80`).
4. Save and Cloudflare will push the config to your running `cloudflared` container.

#### N8N Integration
- You can expose N8N either directly (Cloudflare Tunnel points to `n8n-container:5678`) or via Nginx (for advanced features like rate limiting, auth, or logging).
- If using Nginx, add a new `server` block and `upstream` in your Nginx config as shown in the example.

[Return to Top](#table-of-contents)

---

## Hardware Upgrade Considerations
- **Motherboard (B550):** Compatible with RTX 4090 (PCIe 4.0 x16)
- **PSU:** Upgrade to 850W+ for RTX 4090
- **Cooling:** Ensure good case airflow; monitor temps with high-end GPUs
- **RAM:** 32GB is sufficient for most GPU-accelerated workloads; more may help with CPU-only or multitasking scenarios.

[Return to Top](#table-of-contents)

---

## Future Expansions & Capabilities
- **Hardware:**
  - Upgrade to higher VRAM GPUs for larger models (e.g., RTX 4090, A6000).
  - Consider NVMe RAID for even faster model loading.
  - Increase RAM for CPU-offloaded or very large models.
- **Ollama Software:**
  - Monitor for future support of containerised GPU inference on Windows/WSL2.
  - Explore Ollama’s custom model, fine-tuning, and system prompt features.
  - Use multi-modal models (e.g., LLaVA) for image understanding.
  - Automate model switching and management with scripts.
- **Cloudflare Tunnel/Zero Trust:**
  - Add authentication, rate limiting, or IP allowlists for public endpoints.
  - Integrate with Cloudflare Access for SSO, IdP login, MFA, and IP whitelisting.
  - Use multiple ingress rules to expose additional services (e.g., web UI, n8n) under different subdomains or paths.
- **Nginx Features:**
  - Add CORS, authentication, request logging, and advanced rate limiting as needed.
  - Implement caching or load balancing for future scaling.
  - Transform requests/responses for custom API needs.
  - **Expose a Web UI via Nginx:**
    - You can add a local or containerised web interface (e.g., Streamlit, text-generation-webui, custom dashboard) and expose it securely using a `/web/` endpoint in Nginx. See the Nginx config example:
      ```nginx
      # Example for /web/ endpoint if you add a UI later
      location /web/ {
          proxy_pass http://some_ui_container:port/;
          proxy_set_header Host $host;
      }
      ```
    - This allows you to provide a user-friendly interface for interacting with your LLM server, accessible via your public Cloudflare Tunnel URL (e.g., `https://llm.jerryagenyi.xyz/web/`).
- **Integration with Other Tools:**
  - Connect to VS Code, browser clients, or other LLM frontends via the public or local API endpoint.
  - Integrate with automation platforms (e.g., n8n, Home Assistant) for workflows like email summarisation or chat automation.
  - Add local UI dashboards (e.g., Streamlit, text-generation-webui) for user-friendly access.

[Return to Top](#table-of-contents)

---

## Summary
This guide documents the journey from attempted containerised GPU inference to a robust hybrid solution: native Windows Ollama for GPU acceleration, with all networking and public access managed in WSL2 Docker containers. This approach maximises performance and reliability for local LLM deployment on Windows with AMD GPUs.

[Return to Top](#table-of-contents)
