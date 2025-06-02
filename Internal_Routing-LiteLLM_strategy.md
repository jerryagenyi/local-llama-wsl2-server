# DevOps Solution: Internal Routing + LiteLLM Strategy

## Immediate Fix: Internal Docker Network Routing

### Phase 1: Fix N8N 403 Errors (No LiteLLM needed)

**Change N8N HTTP Request URLs from:**
```
https://llm.jerryagenyi.xyz/api/generate
```

**To:**
```
http://llama-nginx/api/generate
```

This creates an internal-only path:
```
N8N Container → llama-nginx Container → host.docker.internal:11434 → Ollama on Windows
```

**Why this works:**
- Traffic never leaves Docker network
- Bypasses Cloudflare entirely for internal requests
- Uses existing Nginx proxy configuration
- Zero additional infrastructure needed

## Phase 2: Enhanced Architecture with LiteLLM

### Benefits of Adding LiteLLM

1. **API Standardization**: OpenAI-compatible endpoints
2. **Better Error Handling**: Built-in retries and robust error management
3. **Multi-Backend Support**: Future-proof for additional models
4. **Request Logging**: Better observability
5. **Rate Limiting**: Built-in protection mechanisms

### Updated Docker Compose Configuration

```yaml
version: '3.8'

services:
  # Existing services...
  nginx:
    # ... existing config

  n8n:
    # ... existing config

  # NEW: LiteLLM Service
  litellm:
    image: ghcr.io/berriai/litellm:main-stable
    container_name: llama-litellm
    restart: unless-stopped
    environment:
      - LITELLM_PORT=4000
      - LITELLM_MODEL_LIST=[{"model_name": "llama3", "litellm_params": {"model": "ollama/llama3", "api_base": "http://host.docker.internal:11434"}}]
      - LITELLM_LOG_LEVEL=INFO
    ports:
      - "4000:4000"
    networks:
      - llama-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      - nginx

networks:
  llama-network:
    driver: bridge
```

### Updated Nginx Configuration

```nginx
upstream ollama_backend {
    server host.docker.internal:11434;
}

upstream n8n_backend {
    server n8n:5678;
}

upstream litellm_backend {
    server llama-litellm:4000;
    # Add backup server if needed
    # server llama-litellm-backup:4000 backup;
}

# N8N UI Server Block
server {
    listen 80;
    server_name n8n.jerryagenyi.xyz;
    
    location / {
        proxy_pass http://n8n_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Webhooks Server Block
server {
    listen 80;
    server_name webhooks.jerryagenyi.xyz;
    
    location / {
        proxy_pass http://n8n_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# LLM API Server Block (Public + Internal)
server {
    listen 80;
    server_name llm.jerryagenyi.xyz;
    
    # Health check endpoint
    location /health {
        proxy_pass http://litellm_backend/health;
        access_log off;
    }
    
    # Main API endpoints
    location / {
        proxy_pass http://litellm_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # Streaming support
        proxy_buffering off;
        proxy_cache off;
        
        # Timeout settings for LLM responses
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        proxy_connect_timeout 60s;
        
        # Error handling
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }
}
```

## Traffic Flow Patterns

### Internal Traffic (N8N → Ollama)
```
N8N Container → http://llama-litellm:4000/v1/chat/completions → LiteLLM → Ollama
```

### External Traffic (Public API)
```
Internet → Cloudflare → Tunnel → Nginx → LiteLLM → Ollama
```

## N8N Configuration Updates

### For HTTP Request Nodes in N8N:

**URL:** `http://llama-litellm:4000/v1/chat/completions`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer sk-1234" // Optional, if you configure LiteLLM with auth
}
```

**Body (OpenAI format):**
```json
{
  "model": "llama3",
  "messages": [
    {
      "role": "user",
      "content": "Your prompt here"
    }
  ],
  "max_tokens": 150,
  "temperature": 0.7
}
```

## Implementation Strategy

### Step 1: Quick Win (Internal Routing)
1. Update N8N workflows to use `http://llama-nginx/api/generate`
2. Test and verify 403 errors are resolved
3. Measure performance improvement

### Step 2: LiteLLM Integration
1. Add LiteLLM service to docker-compose.yml
2. Update Nginx configuration
3. Test internal LiteLLM connectivity
4. Update N8N to use LiteLLM endpoints
5. Test external API through Cloudflare

### Step 3: Monitoring & Optimization
1. Add logging to LiteLLM
2. Monitor Cloudflare analytics for bot detection
3. Implement rate limiting if needed
4. Add health checks and alerting

## Key Learnings from Referenced Projects

### From local-ai-packaged & llamatunnel:

1. **Service Isolation**: Keep internal communication separate from external
2. **Health Checks**: Implement proper health monitoring
3. **Graceful Degradation**: Handle service failures elegantly
4. **Configuration Management**: Use environment variables for flexibility

## Troubleshooting Guide

### Common Issues & Solutions:

1. **Container Communication Failures**
   - Verify all services are on same Docker network
   - Check service names match docker-compose service definitions
   - Use `docker exec -it container_name ping other_service_name`

2. **LiteLLM Connection Issues**
   - Verify Ollama is accessible from LiteLLM container
   - Check model configuration in LITELLM_MODEL_LIST
   - Review LiteLLM logs: `docker logs llama-litellm`

3. **Nginx Proxy Issues**
   - Test upstream connectivity: `docker exec -it nginx-container curl http://llama-litellm:4000/health`
   - Check Nginx error logs: `docker logs llama-nginx`

## Security Considerations

1. **Network Segmentation**: Keep internal traffic on Docker network
2. **API Authentication**: Consider adding API keys to LiteLLM
3. **Rate Limiting**: Implement at Nginx and/or LiteLLM level
4. **Monitoring**: Log and monitor API usage patterns

## Performance Benefits

- **Reduced Latency**: Internal calls bypass internet routing
- **No Cloudflare Overhead**: Internal traffic doesn't hit Cloudflare limits
- **Better Reliability**: Fewer network hops, fewer failure points
- **Improved Observability**: LiteLLM provides better logging and metrics