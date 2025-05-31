# Ollama Local Server: Windows + WSL2 Hybrid GPU Deployment

This project enables a robust, secure, and performant local LLM (Ollama) server on Windows, leveraging:

- **Native Windows Ollama** for direct GPU acceleration (AMD/ROCm or NVIDIA CUDA)
- **WSL2 (Ubuntu)** as the container host for:
  - Nginx (reverse proxy, authentication, CORS)
  - Cloudflare Tunnel (secure public access)
  - Watchtower (auto-updates)

**Key Architecture:**
- Ollama runs natively on Windows for full GPU access (no passthrough issues)
- Docker Desktop with WSL2 integration runs all networking and proxy services
- Nginx and Cloudflare Tunnel containers connect to Ollama via `http://host.docker.internal:11434`

**Why this hybrid approach?**
- WSL2/Docker cannot reliably pass through AMD GPUs for ROCm in containers
- Native Windows Ollama detects and uses the GPU directly
- All networking, security, and public access is containerised and managed in WSL2

**If you want a more precise project name:**
- `local-ollama-server-windows-wsl` best describes this hybrid architecture

See the full deployment and troubleshooting guide in `Ollama-Local-Deployment-Guide-Windows-WSL-GPU.md`.

---

## Quick Start

1. Clone this repository.
2. Review the [full setup guide](./llama-local-server-guide.md) for detailed instructions.
3. Follow the prerequisites and setup steps for your environment.
4. Use the automated Cloudflare token setup (recommended) for secure public access. Manual fallback instructions are provided in the guide.

---

## Prerequisites
- Windows 10/11 with WSL2 enabled
- Sufficient RAM (32GB+ recommended)
- Compatible GPU (see full guide for details)
- Cloudflare account

---

## Documentation

See the [llama-local-server-guide.md](./llama-local-server-guide.md) for:
- Architecture & rationale
- Environment configuration
- Step-by-step setup (WSL2, Docker, Cloudflare, Nginx, Ollama)
- Server management, troubleshooting, and optimization

---

## Credits & References
- [Cloudflare Tunnels Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Llama.cpp](https://github.com/ggerganov/llama.cpp)

---
