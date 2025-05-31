#!/bin/bash
# Dependency installation script for Llama local server

set -e

echo "=== Installing System Dependencies ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    htop \
    neofetch \
    ca-certificates \
    gnupg \
    lsb-release \
    make \
    unzip \
    jq

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Cloudflare Tunnel
echo "Installing Cloudflare Tunnel..."
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb

# Create directories
mkdir -p ~/llama-server/{models,config,logs}

# Set permissions
sudo chown -R $USER:$USER ~/llama-server

echo "=== Dependencies Installation Complete ==="
echo "Please run 'newgrp docker' or log out and back in to use Docker without sudo"
