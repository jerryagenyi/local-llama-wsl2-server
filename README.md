# Ollama Local Deployment on Windows & WSL2

A robust, production-ready local LLM server stack for Windows with AMD GPU acceleration, using a hybrid architecture: Ollama runs natively on Windows for direct GPU access, while WSL2 (Ubuntu) hosts Docker containers for Nginx, Cloudflare Tunnel, and Watchtower. This repository is the result of extensive real-world troubleshooting and is suitable for both solo and team use.

---

## High-Level Overview
- **Goal:** Deploy local LLMs with GPU acceleration on Windows, with secure public access and flexible API integration.
- **Architecture:** Native Windows Ollama for GPU inference; WSL2/Docker for networking, proxying, and public endpoints.
- **Key Technologies:** Ollama, Docker, WSL2, Nginx, Cloudflare Tunnel.

---

## Features
- **GPU-Accelerated LLM Inference** (AMD RX 6800 XT, 16GB VRAM, via native Windows Ollama)
- **Secure Public Access** via Cloudflare Tunnel and Nginx reverse proxy
- **Separation of Concerns:** Inference on Windows, networking/public access in WSL2 Docker
- **Production-Ready Scripts & Configs:** All scripts, configs, and environment files are up-to-date and well-documented
- **Comprehensive Guide:** Includes troubleshooting, hardware advice, and rationale for all architectural decisions
- **Best Practices:** LF line endings for shell scripts, sensitive files excluded, clear environment separation
- **Extensible:** Easily add new services (e.g., N8N, web UIs) and expose them via new hostnames

---

## Hardware Requirements (Summary)
- **GPU:** 16GB+ VRAM recommended (e.g., RX 6800 XT, RTX 4090 for larger models)
- **CPU:** 8+ cores recommended
- **RAM:** 32GB+ recommended
- **Storage:** NVMe SSD for fast model loading

---

## Getting Started (Quick Start)
1. **Install Prerequisites**
   - Windows 10/11 (fully updated)
   - WSL2 (Ubuntu 24.04 LTS recommended)
   - Docker Desktop for Windows (with WSL2 integration enabled)
   - Git
   - Ollama for Windows (download from [ollama.com/download](https://ollama.com/download))
   - AMD GPU drivers (see guide for recommended version)
2. **Clone this repository** (in WSL2 Ubuntu):
   ```bash
   git clone https://github.com/yourusername/local-llama-wsl2-server.git
   cd local-llama-wsl2-server
   ```
3. **Copy and edit environment files:**
   ```bash
   cp .env.example .env
   # Edit .env and config/ollama.env as needed
   ```
4. **Start Docker services (in WSL2):**
   ```bash
   docker compose up -d
   ```
5. **Start Ollama (on Windows):**
   - Ollama auto-starts on login; verify with Task Manager or by running `ollama serve` in PowerShell.
6. **Access the API:**
   - Locally: `http://host.docker.internal:11434`
   - Via Nginx: `http://localhost:<EXTERNAL_NGINX_PORT>`
   - Via Cloudflare Tunnel: Your public tunnel URL (see Cloudflare dashboard)

For full details, see the [main guide](./Ollama-Local-Deployment-Guide-Windows-WSL-GPU.md).

---

## Why This Setup? (The Journey)
- **GPU Passthrough Limitations:** WSL2/Docker Desktop cannot reliably pass through AMD GPUs for ROCm in containers on Windows.
- **Hybrid Solution:** Native Windows Ollama provides full GPU acceleration; WSL2 Docker enables robust, scriptable networking and public access.
- **Security & Flexibility:** Cloudflare Tunnel and Nginx provide secure, authenticated public endpoints.
- **Naming Strategy:** One tunnel per machine, hostnames per service. See [Tunnel Naming Strategy](./docs/TUNNEL_NAMING_STRATEGY.md).

---

## Contribution & Feedback
- All scripts and configs are commented and production-ready.
- Please use LF line endings for shell scripts (enforced via `.gitattributes`).
- Sensitive files (e.g., `.env`, tunnel tokens) are excluded from version control.
- Issues, pull requests, and feedback are welcome—especially regarding GPU passthrough on other platforms or ideas for future expansion.

---

## Acknowledgements
- [Ollama](https://ollama.com/)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Docker](https://www.docker.com/)

---

## Licence
MIT
