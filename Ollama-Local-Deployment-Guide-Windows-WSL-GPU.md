# Ollama Local Deployment Guide: Windows, WSL, and GPU Acceleration

## Abstract
This guide provides a comprehensive, step-by-step resource for deploying a local LLM server using Ollama with GPU acceleration on Windows. It details a hybrid architecture: Ollama runs natively on Windows for direct GPU access, while WSL2 (Ubuntu) hosts Docker containers for Nginx, Cloudflare Tunnel, and Watchtower. The guide covers hardware requirements, troubleshooting, and the rationale behind each architectural decision, based on real-world experience with AMD GPUs and Docker Desktop.

---

## Table of Contents
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
- [Hardware Upgrade Considerations](#hardware-upgrade-considerations)

---

## Hardware Assessment & Compatibility
Your system is excellent for GPU-accelerated 8B models (Llama 3, Qwen, Mixtral 8x7B):
- **CPU:** Ryzen 7 5800X (8c/16t)
- **RAM:** 32GB
- **GPU:** RX 6800 XT 16GB (ideal for 7B/8B models)
- **Storage:** NVMe SSD

For larger models (e.g., 70B+), VRAM is the limiting factor. 16GB VRAM is best for 7B/8B models; 24GB+ is needed for 70B+.

---

## Prerequisites & Installation
1. **Windows 11** (fully updated)
2. **AMD/NVIDIA GPU drivers** (latest, tested: AMD 32.0.21001.9024)
3. **WSL2 (Ubuntu 24.04)**
4. **Docker Desktop** (with WSL2 integration enabled for Ubuntu)
5. **Git**
6. **Cloudflare account** (for secure public access)
7. **Ollama (native Windows)**: Download from [ollama.com/download](https://ollama.com/download) and install on Windows. Confirm GPU detection by running `ollama serve` in PowerShell and checking logs for `library=rocm` and your GPU name.

---

## Expected/Original Setup: Containerised GPU
- **Goal:** Run Ollama in a Docker container on WSL2 with GPU passthrough (using `ollama/ollama:rocm` and mounting `/dev/kfd`, `/dev/dri`).
- **Why:** This is the standard approach for containerised LLMs with GPU.

---

## The Problem: GPU Passthrough in WSL2
- **Error:** `Error: no compatible GPUs were discovered` in the container.
- **Symptoms:** `/dev/kfd` and `/dev/dri` missing in WSL2, despite correct drivers, `.wslconfig`, and Docker Desktop GPU settings.
- **Conclusion:** WSL2/Docker Desktop cannot reliably pass through AMD GPUs for ROCm in containers on Windows.

---

## CPU-Only Workaround
- **Change:** Switched to `ollama/ollama:latest` (CPU-only), removed GPU-specific lines from `docker-compose.yml`.
- **Result:** Server worked, but performance was slow (Llama 3.2 3B: ~6s/response; Qwen 8B: ~1min/response).

---

## Breakthrough: Native Windows Ollama for GPU
- **Solution:** Install and run Ollama natively on Windows.
- **Verification:** `ollama serve` logs show `library=rocm` and GPU name (e.g., `AMD Radeon RX 6800 XT total="16.0 GiB"`).
- **Performance:** Qwen 8B model now responds in seconds, confirming GPU acceleration.

---

## Hybrid Architecture & Docker Compose
- **Architecture:**
  - Windows Host: Native Ollama (GPU)
  - WSL2/Docker: Nginx, Cloudflare Tunnel, Watchtower
  - Nginx connects to Ollama via `http://host.docker.internal:11434`

- **Final docker-compose.yml:**
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

---

## Model Selection & Performance
- **7B/8B models** (Llama 3 8B, Mixtral 8x7B, Qwen 8B) are ideal for 16GB VRAM.
- **Larger models** (70B+) require 24GB+ VRAM.
- **Performance:**
  - GPU: Qwen 8B responds in seconds
  - CPU: Qwen 8B takes ~1 minute/response

---

## Ollama Command Reference
- `ollama pull <model>`: Download a model (recommended for reliability)
- `ollama run <model>`: Pull and run a model interactively
- `ollama list`: List downloaded models
- `ollama serve`: Start Ollama server (API mode)
- `ollama --version`: Show Ollama version

---

## Troubleshooting
- **/dev/kfd and /dev/dri missing in WSL2:**
  - Native GPU passthrough for AMD is not supported in WSL2 Docker containers
  - Solution: Run Ollama natively on Windows
- **Docker Desktop Integration:**
  - Ensure Docker Desktop is running and WSL2 integration is enabled for Ubuntu
  - Test with `docker --version` in WSL2
- **Permissions:**
  - If you see `permission denied` for Docker, add your user to the docker group: `sudo usermod -aG docker $USER && newgrp docker`
- **Cloudflare Tunnel:**
  - Check tunnel health in the Cloudflare dashboard
  - Ensure Nginx is running before Cloudflared
- **Ollama GPU Detection:**
  - Check `ollama serve` logs for `library=rocm` and your GPU name
  - Model self-description is not reliable for GPU status
- **Model Download Issues:**
  - Use `ollama pull <model>` for best results

---

## Hardware Upgrade Considerations
- **Motherboard (B550):** Compatible with RTX 4090 (PCIe 4.0 x16)
- **PSU:** Upgrade to 850W+ for RTX 4090
- **Cooling:** Ensure good case airflow; monitor temps with high-end GPUs

---

## Summary
This guide documents the journey from attempted containerised GPU inference to a robust hybrid solution: native Windows Ollama for GPU acceleration, with all networking and public access managed in WSL2 Docker containers. This approach maximises performance and reliability for local LLM deployment on Windows with AMD GPUs.
