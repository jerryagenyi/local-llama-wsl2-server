# New Architecture Plan: LiteLLM Integration

## Overview
This document outlines the new architecture for the local Llama server with LiteLLM integration. The goal is to create a robust, scalable, and secure setup that supports both internal and external traffic.

## Objectives
1. **Internal Traffic**: Use Docker's internal network for container-to-container communication.
2. **External Traffic**: Use Cloudflare Tunnel for external access, with WAF rules to bypass bot detection.
3. **LiteLLM Integration**: Add LiteLLM for OpenAI-compatible endpoints, error handling, and better API compatibility.
4. **Simplified Management**: Ensure the setup is easy to maintain and monitor.

## Architecture Diagram
```
[Internet] --> [Cloudflare Tunnel] --> [Nginx] --> [LiteLLM] --> [Ollama API]
[Internal Traffic] --> [Nginx] --> [LiteLLM] --> [Ollama API]
```

## Services
### 1. LiteLLM
- Acts as an intermediary between Nginx and Ollama.
- Provides OpenAI-compatible endpoints.
- Handles retries, error management, and logging.

### 2. Nginx
- Routes traffic to LiteLLM and other services.
- Handles authentication and rate limiting.

### 3. Cloudflare Tunnel
- Exposes Nginx to the internet.
- Provides an additional layer of security.

### 4. Ollama
- Runs on Windows for GPU support.
- Serves as the backend for LiteLLM.

## Steps to Implement
### Phase 1: Core Setup
1. Create a new Docker Compose file with the following services:
   - LiteLLM
   - Nginx
   - Cloudflare Tunnel
2. Configure Nginx to route traffic to LiteLLM.
3. Test internal traffic flow.

### Phase 2: External Access
1. Enable Cloudflare Tunnel.
2. Create WAF rules to bypass bot detection for specific paths.
3. Test external traffic flow.

### Phase 3: Monitoring and Optimization
1. Add health checks for all services.
2. Monitor traffic using Cloudflare analytics.
3. Optimize Nginx and LiteLLM configurations for performance.

## Testing
1. Test internal traffic from n8n to LiteLLM.
2. Test external traffic via Cloudflare.
3. Verify API responses and error handling.

## Security Considerations
1. Use strong authentication for external access.
2. Monitor API usage for suspicious activity.
3. Implement rate limiting to prevent abuse.

## Next Steps
1. Build the new Docker Compose file.
2. Configure Nginx and LiteLLM.
3. Test the setup and iterate as needed.
