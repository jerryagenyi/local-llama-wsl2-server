#!/bin/bash
# Cloudflare tunnel setup script for Llama local server

set -e

echo "=== Configuring Cloudflare Tunnel ==="

# Authenticate (first time only)
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "First time setup - please authenticate:"
    cloudflared tunnel login
fi

# Create tunnel
TUNNEL_NAME=${TUNNEL_NAME:-"llama-api"}
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}' || echo "")

if [ -z "$TUNNEL_ID" ]; then
    echo "Creating new tunnel: $TUNNEL_NAME"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
fi

echo "Tunnel ID: $TUNNEL_ID"

# Create DNS record
cloudflared tunnel route dns $TUNNEL_NAME api.yourdomain.com

# Get tunnel token
TOKEN=$(cloudflared tunnel token $TUNNEL_NAME)
echo "Add this to your .env file:"
echo "CLOUDFLARE_TUNNEL_TOKEN=$TOKEN"

echo "=== Cloudflare Tunnel Configuration Complete ==="
