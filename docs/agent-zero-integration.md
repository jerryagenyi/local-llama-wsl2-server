# Agent Zero Integration Guide

## Overview

This document explains how Agent Zero has been integrated into the existing Docker Compose setup alongside n8n, LiteLLM, Flowise, and PostgreSQL services.

## Architecture

Agent Zero is deployed as a containerized service that:
- Uses the official `agent0ai/agent-zero:latest` Docker image
- Runs on port 8080 (mapped to internal port 80)
- Connects to the existing `tunnel-network` for communication with other services
- Uses persistent storage via Docker volumes
- Integrates with the existing Cloudflare tunnel setup

## Configuration

### Docker Compose Service

```yaml
agent-zero:
  image: agent0ai/agent-zero:latest
  container_name: agent-zero
  ports:
    - "8080:80"
  volumes:
    - agent_zero_data:/a0
    - ./config/agent-zero/settings.json:/a0/tmp/settings.json:ro
  environment:
    - AUTH_LOGIN=${AGENT_ZERO_LOGIN:-admin}
    - AUTH_PASSWORD=${AGENT_ZERO_PASSWORD:-admin123}
  restart: unless-stopped
  networks:
    - tunnel-network
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:80/healthz"]
    interval: 30s
    timeout: 10s
    retries: 3
  depends_on:
    - litellm
```

### Environment Variables

Add to your `.env` file:
```bash
# Agent Zero Credentials
AGENT_ZERO_LOGIN=admin
AGENT_ZERO_PASSWORD=admin123
```

### Cloudflare Tunnel Configuration

To access Agent Zero via `a0.jerryagenyi.xyz`, you'll need to:

1. **Add a new hostname to your Cloudflare tunnel:**
   - Hostname: `a0.jerryagenyi.xyz`
   - Service: `http://agent-zero:80`
   - Path: `/` (root path)

2. **Update your Cloudflare tunnel configuration** to include the new service:
   ```yaml
   # Add this to your tunnel configuration
   - hostname: a0.jerryagenyi.xyz
     service: http://agent-zero:80
   ```

## Features

### Core Capabilities
- **Web UI**: Accessible via browser with authentication
- **AI Agent Framework**: Dynamic, organic agentic framework
- **MCP Integration**: Model Context Protocol server support
- **Backup/Restore**: Built-in backup and restore functionality
- **Multi-LLM Support**: Integration with various LLM providers via LiteLLM

### Integration Benefits
- **Shared Infrastructure**: Uses existing PostgreSQL and LiteLLM services
- **Unified Networking**: Connected to the same tunnel network
- **Persistent Storage**: Data survives container restarts
- **Health Monitoring**: Built-in health checks
- **Authentication**: Secure access control

## Usage

### Starting the Service
```bash
# Start all services including Agent Zero
docker-compose up -d

# Start only Agent Zero
docker-compose up -d agent-zero
```

### Accessing Agent Zero
- **Local Access**: http://localhost:8080
- **Tunnel Access**: https://a0.jerryagenyi.xyz (after tunnel configuration)
- **Default Credentials**: admin / admin123

### Configuration Management
- Settings are stored in `config/agent-zero/settings.json`
- Data persistence via Docker volume `agent_zero_data`
- Environment variables for authentication

## Integration with Existing Services

### LiteLLM Integration
Agent Zero can use the existing LiteLLM service for LLM provider abstraction:
- Configure API keys in the Agent Zero Web UI
- Use the same LLM providers as other services
- Benefit from centralized LLM management

### Database Integration
- Can connect to the existing PostgreSQL instance
- Shares database resources with other services
- Benefits from existing database backup strategies

### Network Integration
- Connected to the same `tunnel-network`
- Can communicate with other services internally
- Uses the existing Cloudflare tunnel for external access

## Troubleshooting

### Updating Agent Zero to the latest image

Use the project’s update process so a fresh image is pulled (see [update-docker-services.md](update-docker-services.md)):

- **PowerShell:** `.\scripts\update-docker-service.ps1 -Service agent-zero`
- **Manual:** `docker compose down agent-zero` → `docker image rm agent0ai/agent-zero:latest` → `docker compose up -d agent-zero`

### Search engine patch (KeyError: 'results')

If the agent hits **KeyError: 'results'** when using search, the SearXNG response may lack a `results` key (e.g. SearXNG down or wrong URL). This repo applies a patch by mounting `config/agent-zero/patches/search_engine.py` over the container’s `search_engine.py`, so the tool handles missing or malformed responses safely. No action needed unless you remove that volume.

### Common Issues

1. **Service Not Starting**
   ```bash
   # Check logs
   docker-compose logs agent-zero
   
   # Check if port is available
   netstat -tulpn | grep 8080
   ```

2. **Authentication Issues**
   - Verify environment variables are set correctly
   - Check the mounted settings.json file
   - Ensure proper file permissions

3. **Network Connectivity**
   ```bash
   # Test internal connectivity
   docker-compose exec agent-zero curl http://litellm:4000/health
   
   # Check network configuration
   docker network ls
   docker network inspect local-llama-wsl2-server_tunnel-network
   ```

### Health Checks
```bash
# Check service status
docker-compose ps agent-zero

# Test health endpoint
curl -f http://localhost:8080/healthz
```

## Security Considerations

1. **Change Default Credentials**: Update `AGENT_ZERO_LOGIN` and `AGENT_ZERO_PASSWORD`
2. **Network Security**: Agent Zero is only accessible through the tunnel network
3. **Data Persistence**: Sensitive data is stored in Docker volumes
4. **Authentication**: Built-in authentication prevents unauthorized access

## Next Steps

1. **Configure Cloudflare Tunnel**: Add the new hostname to your tunnel configuration
2. **Test Integration**: Verify Agent Zero is accessible via the tunnel
3. **Configure LLM Providers**: Set up API keys in the Agent Zero Web UI
4. **Customize Settings**: Modify the settings.json file as needed
5. **Monitor Performance**: Use health checks and logs to monitor the service

## References

- [Agent Zero vs OpenClaw: detailed comparison](agent-zero-vs-openclaw-comparison.md) (architecture, security, features, when to choose which)
- [Agent Zero GitHub Repository](https://github.com/agent0ai/agent-zero)
- [Agent Zero Documentation](https://github.com/agent0ai/agent-zero/tree/main/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
