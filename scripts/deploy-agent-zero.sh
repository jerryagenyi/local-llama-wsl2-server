#!/bin/bash

# Agent Zero Deployment Script
# This script helps deploy Agent Zero with the existing Docker Compose setup

set -e

echo "🚀 Starting Agent Zero deployment..."

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Please install Docker Compose."
    exit 1
fi

# Check if .env file exists
if [ ! -f "misc/env.txt" ]; then
    echo "❌ Environment file not found. Please ensure misc/env.txt exists."
    exit 1
fi

echo "📋 Checking environment variables..."
source misc/env.txt

# Verify required environment variables
if [ -z "$AGENT_ZERO_LOGIN" ] || [ -z "$AGENT_ZERO_PASSWORD" ]; then
    echo "⚠️  Agent Zero credentials not set. Using defaults."
    echo "   Please update misc/env.txt with your preferred credentials."
fi

echo "🔧 Creating configuration directory..."
mkdir -p config/agent-zero

echo "📦 Pulling Agent Zero Docker image..."
docker-compose pull agent-zero

echo "🏗️  Building and starting services..."
docker-compose up -d agent-zero

echo "⏳ Waiting for Agent Zero to start..."
sleep 10

echo "🔍 Checking Agent Zero health..."
if docker-compose exec agent-zero curl -f http://localhost:80/healthz > /dev/null 2>&1; then
    echo "✅ Agent Zero is healthy!"
else
    echo "⚠️  Agent Zero health check failed. Check logs with: docker-compose logs agent-zero"
fi

echo "🌐 Service URLs:"
echo "   Local: http://localhost:8080"
echo "   Tunnel: https://a0.jerryagenyi.xyz (after tunnel configuration)"
echo ""
echo "🔐 Default credentials:"
echo "   Username: ${AGENT_ZERO_LOGIN:-admin}"
echo "   Password: ${AGENT_ZERO_PASSWORD:-admin123}"
echo ""
echo "📝 Next steps:"
echo "   1. Configure your Cloudflare tunnel to route a0.jerryagenyi.xyz to agent-zero:80"
echo "   2. Access Agent Zero via the Web UI"
echo "   3. Configure LLM providers in the Agent Zero settings"
echo "   4. Set up MCP servers if needed"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose logs agent-zero"
echo "   Restart: docker-compose restart agent-zero"
echo "   Stop: docker-compose stop agent-zero"
echo "   Update: docker-compose pull agent-zero && docker-compose up -d agent-zero"

echo "🎉 Agent Zero deployment completed!"
