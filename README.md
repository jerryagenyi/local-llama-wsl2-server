# Local Llama Server (LlamaWSL-Serve)

A turnkey toolkit for running large language models (LLMs) locally on Windows WSL2 with secure remote access via Cloudflare Tunnels.

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
