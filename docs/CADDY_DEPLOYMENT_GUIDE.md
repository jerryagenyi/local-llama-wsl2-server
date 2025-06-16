# Caddy-based Local LLM Server Deployment Guide

This guide provides a comprehensive walkthrough for deploying a secure, high-performance local LLM server using Ollama with GPU acceleration, Caddy for HTTPS and reverse proxy, and N8N/Flowise for automation workflows.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Security Configuration](#security-configuration)
- [Service Configuration](#service-configuration)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)

## Architecture Overview

### Components
1. **Ollama (Native Windows)**
   - GPU-accelerated LLM inference
   - Direct access to AMD GPU via ROCm
   - API endpoints for model interaction

2. **Caddy (Docker)**
   - Automatic HTTPS with Let's Encrypt
   - Reverse proxy for all services
   - Basic authentication
   - Rate limiting
   - Bot detection bypass

3. **N8N (Docker)**
   - Workflow automation
   - Secure webhook endpoints
   - Basic authentication

4. **Flowise (Docker)**
   - Visual LLM workflow builder
   - API integration
   - Basic authentication

### Network Flow
```
[Internet] <-- HTTPS --> [Caddy Reverse Proxy]
                              |
                              | (Internal Docker Network)
                              v
    [Ollama (Windows)] <-- [N8N/Flowise (Docker)]
```

## Prerequisites

1. **Windows 10/11**
   - Fully updated
   - WSL2 enabled
   - Docker Desktop installed

2. **Hardware**
   - AMD GPU with ROCm support
   - 16GB+ VRAM recommended
   - 32GB+ RAM recommended
   - NVMe SSD for fast model loading

3. **Software**
   - WSL2 (Ubuntu 24.04 LTS)
   - Docker Desktop for Windows
   - Ollama for Windows
   - AMD GPU Drivers (ROCm support)

4. **Domain Setup**
   - `llm.jerryagenyi.xyz`
   - `n8n.jerryagenyi.xyz`
   - `flowise.jerryagenyi.xyz`
   - DNS A records pointing to your public IP

## Installation Steps

1. **Prepare Environment**
   ```bash
   # Create necessary directories
   mkdir -p config/caddy
   ```

2. **Set Up Authentication**
   ```bash
   # Generate password hash for Caddy
   caddy hash-password
   # Copy the output hash
   ```

3. **Configure Caddy**
   - Edit `config/caddy/Caddyfile`
   - Replace `{YOUR_HASH}` with the hash from step 2
   - Adjust rate limits if needed

4. **Set Environment Variables**
   ```bash
   # Create .env file
   cat > .env << EOL
   N8N_AUTH_USER=your_n8n_username
   N8N_AUTH_PASSWORD=your_n8n_password
   FLOWISE_AUTH_USER=your_flowise_username
   FLOWISE_AUTH_PASSWORD=your_flowise_password
   FLOWISE_SECRET_KEY=your_flowise_secret_key
   EOL
   ```

5. **Start Services**
   ```bash
   docker compose up -d
   ```

6. **Verify Ollama GPU**
   ```powershell
   ollama serve
   # Check logs for "library=rocm" and GPU name
   ```

## Security Configuration

### 1. Basic Authentication
- All endpoints protected with basic auth
- Different credentials for each service
- Credentials stored in environment variables

### 2. Rate Limiting
- Ollama: 10 req/s (20 burst)
- N8N: 5 req/s (10 burst)
- Flowise: 5 req/s (10 burst)

### 3. HTTPS
- Automatic Let's Encrypt certificates
- HTTP to HTTPS redirection
- HSTS enabled

### 4. Bot Detection
- Custom headers for legitimate automation
- Rate limiting to prevent abuse
- IP-based blocking (optional)

## Service Configuration

### Ollama API
- Base URL: `https://llm.jerryagenyi.xyz`
- Endpoints:
  - `/api/generate`
  - `/api/chat`
  - `/api/tags`

### N8N
- URL: `https://n8n.jerryagenyi.xyz`
- Webhook: `https://n8n.jerryagenyi.xyz/webhook`
- Basic auth required

### Flowise
- URL: `https://flowise.jerryagenyi.xyz`
- API: `https://flowise.jerryagenyi.xyz/api/v1`
- Basic auth required

## Monitoring & Maintenance

### Logs
- JSON format logs in `caddy_data` volume
- View with: `docker logs llama-caddy`
- Separate logs for each service

### Updates
- Watchtower handles container updates
- Ollama updates via Windows package manager
- Regular security patches

### Backup
- Regular backups of:
  - N8N workflows
  - Flowise flows
  - Caddy certificates
  - Environment variables

## Troubleshooting

### Common Issues

1. **Certificate Issues**
   - Check port forwarding (80/443)
   - Verify DNS records
   - Check Caddy logs

2. **GPU Detection**
   - Verify AMD drivers
   - Check Ollama logs
   - Ensure ROCm support

3. **Authentication**
   - Verify credentials
   - Check rate limiting
   - Review access logs

4. **Service Access**
   - Check container health
   - Verify network connectivity
   - Review service logs

### Debug Commands
```bash
# Check container status
docker ps

# View Caddy logs
docker logs llama-caddy

# Check N8N logs
docker logs desktop-n8n

# Check Flowise logs
docker logs desktop-flowise

# Verify network
docker network inspect llama-network
```

## Next Steps

1. **Enhanced Security**
   - IP allowlisting
   - Advanced rate limiting
   - Request logging

2. **Monitoring**
   - Prometheus metrics
   - Grafana dashboards
   - Alerting

3. **Backup Strategy**
   - Automated backups
   - Disaster recovery plan
   - Version control

4. **Scaling**
   - Load balancing
   - Multiple Ollama instances
   - High availability 