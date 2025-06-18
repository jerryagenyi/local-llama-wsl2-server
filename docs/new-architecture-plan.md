# New Architecture Plan: Lean Local LLM Server

## Overview
This document outlines the simplified architecture for the local Llama server. The goal is to create a robust, scalable, and secure setup that supports both internal and external traffic while maintaining simplicity.

## Objectives
1. **Internal Traffic**: Use Docker's internal network for container-to-container communication.
2. **External Traffic**: Use Ngrok static domain for external access, with Basic Auth for security.
3. **Simplified Management**: Ensure the setup is easy to maintain and monitor.

## Architecture Diagram
```
[Internet] --> [Ngrok Static Domain] --> [Caddy] --> [n8n/Flowise]
[Internal Traffic] --> [Caddy] --> [n8n/Flowise]
[Ollama API] <-- [Local Machine]
```

## Services
### 1. Caddy
- Acts as a reverse proxy
- Handles Basic Auth
- Provides clean URLs for services

### 2. n8n
- Workflow automation
- Protected by Basic Auth
- Accessible via Ngrok static domain

### 3. Flowise
- LLM workflow interface
- Protected by Basic Auth
- Accessible via Ngrok static domain

### 4. Ollama
- Runs on Windows for GPU support
- Serves as the backend for LLM operations

## Steps to Implement
### Phase 1: Core Setup
1. Set up Docker Compose with:
   - Caddy
   - n8n
   - Flowise
2. Configure Basic Auth
3. Test internal traffic flow

### Phase 2: External Access
1. Set up Ngrok static domain
2. Configure as systemd service
3. Test external traffic flow

### Phase 3: Monitoring and Optimization
1. Add health checks for all services
2. Monitor service logs
3. Optimize configurations for performance

## Testing
1. Test internal traffic between services
2. Test external traffic via Ngrok
3. Verify Basic Auth protection

## Security Considerations
1. Basic Auth for all external services
2. Monitor access logs
3. Regular security updates

## Next Steps
1. Document the setup process
2. Create deployment guides
3. Add monitoring and alerting

## Comparison with Previous Architecture
### What Changed
- Removed Cloudflare Tunnel in favor of Ngrok
- Simplified service stack
- Removed LiteLLM for direct Ollama integration
- Added systemd service for Ngrok persistence

### What Worked Better
- Simpler setup and maintenance
- More reliable external access
- Easier debugging
- Lower resource usage

### What to Keep in Mind
- Security through Basic Auth
- Regular monitoring
- Backup strategies
- Documentation updates
