#!/bin/bash
# Health check script for Llama local server

echo "=== Llama Server Health Check ==="

# Check WSL2 resources
echo "System Resources:"
echo "  CPU: $(nproc) cores"
echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $7}') available"
echo "  GPU: $(rocm-smi --showhw | grep 'GPU\[' | wc -l) AMD GPU(s) detected"

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi
echo "✅ Docker is running"

# Check containers
CONTAINERS=("llama-ollama" "llama-nginx" "llama-tunnel")
for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q $container; then
        echo "✅ $container is running"
    else
        echo "❌ $container is not running"
    fi
done

# Check Ollama API
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama API is responding"
    echo "Models loaded:"
    curl -s http://localhost:11434/api/tags | jq -r '.models[].name' | sed 's/^/  - /'
else
    echo "❌ Ollama API is not responding"
fi

# Check GPU utilization
if command -v rocm-smi &> /dev/null; then
    echo "GPU Status:"
    rocm-smi --showuse | grep -E "GPU\[|Memory Usage|GPU Activity"
fi

# Check tunnel status
if docker logs llama-tunnel 2>&1 | grep -q "Connection established"; then
    echo "✅ Cloudflare tunnel is connected"
else
    echo "❌ Cloudflare tunnel connection issues"
fi

echo "=== Health Check Complete ==="
