# Ollama Deployment Guide v2: Lean Approach

## Overview
This guide outlines the streamlined deployment of Ollama for local LLM operations. We focus on simplicity, reliability, and direct integration with workflow tools.

## Prerequisites
- Windows 10/11 with WSL2
- Docker Desktop
- NVIDIA GPU with latest drivers
- Basic understanding of Docker and WSL2

## Installation Steps

### 1. WSL2 Setup
```bash
# Install WSL2 if not already installed
wsl --install

# Set WSL2 as default
wsl --set-default-version 2

# Install Ubuntu
wsl --install -d Ubuntu

# Verify GPU support
nvidia-smi
```

### 2. Docker Configuration
```bash
# Create Docker network
docker network create llm-network

# Verify network creation
docker network ls

# Create a .env file for configuration
cat > .env << EOL
OLLAMA_HOST=host.docker.internal
OLLAMA_PORT=11434
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password
FLOWISE_BASIC_AUTH_USER=admin
FLOWISE_BASIC_AUTH_PASSWORD=your_secure_password
EOL
```

### 3. Ollama Installation
```bash
# Install Ollama on Windows
winget install ollama

# Start Ollama service
ollama serve

# Create a systemd service for automatic startup
sudo nano /etc/systemd/system/ollama.service
```

Add the following content:
```ini
[Unit]
Description=Ollama Service
After=network.target

[Service]
Type=simple
User=your_username
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

### 4. Model Download
```bash
# Download a base model (e.g., Mistral)
ollama pull mistral

# Verify installation
ollama list

# Test model
ollama run mistral "Hello, how are you?"
```

## Integration with Workflow Tools

### n8n Integration
1. Use HTTP Request node to connect to Ollama:
```javascript
{
  "url": "http://host.docker.internal:11434/api/generate",
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "model": "mistral",
    "prompt": "{{$node["Input"].json.prompt}}",
    "stream": false
  }
}
```

2. Error handling workflow:
```javascript
{
  "conditions": [
    {
      "value1": "={{$node["HTTP Request"].json.error}}",
      "operation": "exists"
    }
  ],
  "options": {}
}
```

### Flowise Integration
1. Configure Ollama node in Flowise:
```json
{
  "name": "Ollama",
  "type": "ollama",
  "parameters": {
    "model": "mistral",
    "temperature": 0.7,
    "maxTokens": 2000
  }
}
```

2. Add error handling:
```json
{
  "name": "Error Handler",
  "type": "errorHandler",
  "parameters": {
    "retryCount": 3,
    "retryDelay": 1000
  }
}
```

## Testing

### Basic API Test
```bash
# Test API endpoint
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Hello, how are you?"
}'

# Test streaming
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Hello, how are you?",
  "stream": true
}'

# Test model info
curl http://localhost:11434/api/tags
```

### Workflow Test
1. Create a simple n8n workflow:
```javascript
// Test workflow
{
  "nodes": [
    {
      "name": "Start",
      "type": "n8n-nodes-base.trigger",
      "parameters": {
        "triggerTimes": {
          "item": [
            {
              "mode": "everyX",
              "value": 1,
              "unit": "hours"
            }
          ]
        }
      }
    },
    {
      "name": "Ollama Request",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://host.docker.internal:11434/api/generate",
        "method": "POST",
        "body": {
          "model": "mistral",
          "prompt": "Test prompt"
        }
      }
    }
  ]
}
```

## Troubleshooting

### Common Issues
1. **Connection Refused**
   - Check if Ollama is running:
     ```bash
     systemctl status ollama
     ```
   - Verify port 11434 is accessible:
     ```bash
     netstat -tulpn | grep 11434
     ```
   - Check firewall settings:
     ```bash
     sudo ufw status
     ```

2. **GPU Not Detected**
   - Update NVIDIA drivers:
     ```bash
     sudo apt update
     sudo apt install nvidia-driver-535
     ```
   - Verify CUDA installation:
     ```bash
     nvcc --version
     ```
   - Check WSL2 GPU support:
     ```bash
     nvidia-smi
     ```

3. **Slow Response Times**
   - Monitor GPU usage:
     ```bash
     watch -n 1 nvidia-smi
     ```
   - Check model size:
     ```bash
     ollama list
     ```
   - Verify system resources:
     ```bash
     htop
     ```

4. **Memory Issues**
   - Check available memory:
     ```bash
     free -h
     ```
   - Monitor swap usage:
     ```bash
     swapon --show
     ```
   - Adjust model parameters:
     ```bash
     ollama run mistral --num-gpu 1 --num-thread 4
     ```

## Security

### Basic Auth Configuration
1. Generate password hash:
```bash
caddy hash-password
```

2. Configure Caddy:
```caddyfile
{
    admin off
}

:80 {
    basicauth {
        admin $2a$14$your_hashed_password
    }
    reverse_proxy n8n:5678
}
```

### API Security
1. Rate limiting:
```nginx
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
limit_req zone=one burst=5;
```

2. IP whitelisting:
```nginx
allow 192.168.1.0/24;
deny all;
```

### Model Security
1. Regular updates:
```bash
# Update all models
ollama pull mistral
ollama pull llama2
```

2. Model verification:
```bash
# Verify model integrity
ollama verify mistral
```

## Monitoring and Maintenance

### System Monitoring
1. Set up Prometheus:
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'ollama'
    static_configs:
      - targets: ['localhost:11434']
```

2. Configure Grafana dashboard:
```json
{
  "dashboard": {
    "panels": [
      {
        "title": "GPU Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "nvidia_gpu_utilization"
          }
        ]
      }
    ]
  }
}
```

### Log Management
1. Configure log rotation:
```bash
# /etc/logrotate.d/ollama
/var/log/ollama.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ollama ollama
}
```

2. Set up log monitoring:
```bash
# Install log monitoring tools
sudo apt install logwatch

# Configure daily reports
sudo logwatch --detail High --mailto your@email.com
```

### Backup Strategy
1. Model backups:
```bash
# Backup models
ollama export mistral > mistral_backup.tar

# Restore models
ollama import mistral_backup.tar
```

2. Configuration backups:
```bash
# Backup configuration
tar -czf ollama_config_backup.tar.gz /etc/ollama/

# Restore configuration
tar -xzf ollama_config_backup.tar.gz -C /
```

### Performance Optimization
1. GPU optimization:
```bash
# Set GPU memory limit
export CUDA_VISIBLE_DEVICES=0
export CUDA_MEMORY_FRACTION=0.8
```

2. Model optimization:
```bash
# Quantize model
ollama quantize mistral

# Set thread count
export OMP_NUM_THREADS=4
```

## Next Steps
1. Set up monitoring
2. Configure automated backups
3. Document custom workflows

## Resources
- [Ollama Documentation](https://ollama.ai/docs)
- [n8n Documentation](https://docs.n8n.io)
- [Flowise Documentation](https://docs.flowiseai.com)
- [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/)
- [WSL2 GPU Support](https://docs.microsoft.com/en-us/windows/wsl/tutorials/gpu-compute) 