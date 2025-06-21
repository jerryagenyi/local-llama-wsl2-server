# Local LLM Server with GPU Acceleration on Windows/WSL2

This project sets up a comprehensive local AI development environment on a Windows machine with an AMD or NVIDIA GPU. It uses Ollama running natively on Windows for maximum performance and a Docker Compose stack for running services like LiteLLM, n8n, and Flowise.

The entire stack is made securely accessible from the internet using a Cloudflare Tunnel, without requiring any firewall configuration.

## Final Architecture

The final architecture is designed for simplicity, performance, and easy management:

-   **Ollama (on Windows Host):** Ollama is installed directly on Windows to leverage the full power of the host's GPU (both NVIDIA and AMD are supported). This is the core engine that runs the Large Language Models.
-   **Docker Compose Services:** A `docker-compose.yml` file orchestrates the following containerized services:
    -   **LiteLLM:** Acts as a proxy and management layer for Ollama. It provides a unified API and a user-friendly Admin UI to manage models.
    -   **PostgreSQL:** A dedicated database container for LiteLLM. This allows models to be managed dynamically through the UI, with configurations stored persistently in the database.
    -   **n8n:** A workflow automation tool. It's configured to communicate with Ollama via LiteLLM.
    -   **Flowise:** A UI-based tool for building custom LLM-powered applications and chatbots.
    -   **Cloudflared:** Manages a secure, persistent tunnel from the services to the Cloudflare network, making them accessible via a public URL (e.g., `https://your-tunnel.jerryagenyi.xyz`).
-   **Networking:** All containers run on a shared Docker network. Services that need to communicate with the host's Ollama instance (like LiteLLM) do so by using the special DNS name `host.docker.internal`.

## Key Lessons Learned & Journey

This project evolved significantly from its initial concept. Here are some of the key takeaways from the process:

1.  **Ollama on Host is Best for Windows:** The initial idea was to containerize all services, including Ollama. However, getting a Docker container on Windows to properly access the host's GPU (especially AMD) for acceleration is notoriously difficult. The most effective and performant solution was to run Ollama natively on Windows and have the Docker containers communicate with it.

2.  **`host.docker.internal` is the Magic Bridge:** The primary networking challenge was connecting the containerized services (like LiteLLM and n8n) to the Ollama instance running on the host machine. The solution is to use `http://host.docker.internal:11434` as the API base URL in the container's configuration. `localhost` inside a container refers to the container itself, not the host machine.

3.  **Dynamic vs. Static Config for LiteLLM:** We initially used a static `config.yaml` file to define models for LiteLLM. This led to confusion because changes made in the LiteLLM Admin UI weren't reflected in the config file (and would be lost on restart). The superior approach was to remove the static config file entirely and add a PostgreSQL database. This makes the LiteLLM UI the single source of truth for model configuration, which is both more intuitive and robust.

4.  **Cloud Sync Drives Cause Development Headaches:** A major recurring issue was that files like `.gitignore` were being automatically and silently renamed to `.gitignore 2`. The root cause was identified as the project folder being located within **iCloud Drive**. Cloud syncing services are not designed for the rapid and numerous file changes of a development project and can interfere with dotfiles. **The permanent solution is to keep development projects in a standard, non-synced local directory (e.g., `C:\Users\Username\dev\`).**

## Setup Instructions

1.  **Prerequisites:**
    -   Windows 10/11 with WSL2 installed and enabled.
    -   Docker Desktop for Windows.
    -   [Ollama for Windows](https://ollama.com/download/windows) installed.
    -   A Cloudflare account and a configured Tunnel token.

2.  **Clone the Repository:**
    ```bash
    git clone https://github.com/jerryagenyi/local-llama-wsl2-server.git
    cd local-llama-wsl2-server
    ```
    *Note: Ensure the repository is cloned into a local directory, NOT a folder synced by iCloud, OneDrive, or Dropbox.*

3.  **Configure Environment Variables:**
    -   Rename `env.txt` to `.env`.
    -   Open the `.env` file and fill in the required values for your `CLOUDFLARE_TUNNEL_TOKEN`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, etc.

4.  **Run the Stack:**
    ```bash
    docker compose up -d
    ```

5.  **Configure LiteLLM:**
    -   Open your browser and navigate to the LiteLLM Admin UI at `http://localhost:4000`.
    -   Use the UI to add your Ollama models. The API Base should be `http://host.docker.internal:11434`.

Your services should now be running and accessible via their local ports and your public Cloudflare Tunnel URL.

## Features

- 🚀 GPU-accelerated LLM inference with Ollama
- 🔒 Automatic HTTPS with Caddy
- 🔐 Built-in security features:
  - Basic authentication for all endpoints
  - Rate limiting to prevent abuse
  - Bot detection bypass for legitimate automation
- 🤖 N8N integration for automation workflows
- 🎨 Flowise integration for visual LLM workflows
- 📊 JSON logging for monitoring

## Prerequisites

1. **Windows 10/11** (fully updated)
2. **WSL2 (Ubuntu 24.04 LTS)**
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```
3. **Docker Desktop for Windows** (with WSL2 integration)
4. **Ollama for Windows** (from [ollama.com/download](https://ollama.com/download))
5. **AMD GPU Drivers** (ROCm support)
6. **Domain Names** (already set up):
   - `llm.jerryagenyi.xyz`
   - `n8n.jerryagenyi.xyz`
   - `flowise.jerryagenyi.xyz`

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/local-llama-wsl2-server.git
   cd local-llama-wsl2-server
   ```

2. **Create Caddy credentials:**
   ```bash
   mkdir -p config/caddy
   caddy hash-password
   # Enter your desired password when prompted
   # Copy the output hash
   ```

3. **Update Caddyfile with your credentials:**
   ```bash
   # Edit config/caddy/Caddyfile and replace {YOUR_HASH} with the hash from step 2
   ```

4. **Start the services:**
   ```bash
   docker compose up -d
   ```

5. **Verify Ollama GPU detection:**
   ```powershell
   ollama serve
   # Check logs for "library=rocm" and your GPU name
   ```

## Security Features

### 1. Basic Authentication
All endpoints are protected with basic authentication. Update the credentials in `config/caddy/Caddyfile`.

### 2. Rate Limiting
- Ollama API: 10 requests/second with 20 burst
- N8N: 5 requests/second with 10 burst
- Flowise: 5 requests/second with 10 burst

### 3. Bot Detection Bypass
Custom headers are added to prevent false bot detection while maintaining security.

### 4. HTTPS Enforcement
All traffic is automatically upgraded to HTTPS with Let's Encrypt certificates.

## Service Endpoints

### Ollama API
- Base URL: `https://llm.jerryagenyi.xyz`
- Endpoints:
  - `/api/generate`
  - `/api/chat`
  - `/api/tags`

### N8N
- URL: `https://n8n.jerryagenyi.xyz`
- Webhook URL: `https://n8n.jerryagenyi.xyz/webhook`

### Flowise
- URL: `https://flowise.jerryagenyi.xyz`
- API: `https://flowise.jerryagenyi.xyz/api/v1`

## Monitoring

- Logs are stored in JSON format in the `caddy_data` volume
- View logs with:
  ```bash
  docker logs llama-caddy
  ```

## Troubleshooting

1. **Caddy Certificate Issues:**
   - Ensure ports 80 and 443 are forwarded to your machine
   - Check DNS A records point to your public IP

2. **Ollama GPU Detection:**
   - Verify AMD drivers are installed
   - Check `ollama serve` logs for ROCm support

3. **N8N/Flowise Access:**
   - Verify basic auth credentials
   - Check rate limiting if requests are blocked

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - see LICENSE file for details
