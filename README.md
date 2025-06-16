# Local LLM Server with Caddy, Ollama, and N8N

A secure, high-performance local LLM server setup using Ollama with GPU acceleration, Caddy for HTTPS and reverse proxy, and N8N for automation workflows.

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
