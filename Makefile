.PHONY: help setup install-deps download-model start stop restart logs clean health

# Default target
help:
	@echo "Llama 3.2 11B Local Server (Ubuntu 24.04)"
	@echo "=========================="
	@echo "setup          - Complete system setup"
	@echo "install-deps   - Install dependencies"
	@echo "download-model - Download Llama model"
	@echo "start         - Start all services"
	@echo "stop          - Stop all services"
	@echo "restart       - Restart all services"
	@echo "logs          - Show service logs"
	@echo "health        - Check system health"
	@echo "clean         - Clean up containers"

# Complete setup
setup: install-deps download-model
	@echo "Setup complete! Run 'make start' to begin."

# Install system dependencies
install-deps:
	@echo "Installing system dependencies..."
	sudo ./scripts/install-deps.sh
	@echo "Dependencies installed!"

# Download Llama model
download-model:
	@echo "Downloading Llama 3.2 11B model..."
	docker-compose run --rm ollama ollama pull $(MODEL_NAME)
	@echo "Model downloaded!"

# Start services
start:
	@echo "Starting Llama server..."
	docker-compose up -d
	@echo "Services starting... Check with 'make logs'"

# Stop services
stop:
	@echo "Stopping services..."
	docker-compose down
	@echo "Services stopped!"

# Restart services
restart: stop start

# Show logs
logs:
	docker-compose logs -f

# Health check
health:
	@./scripts/health-check.sh

# Clean up
clean:
	docker-compose down -v
	docker system prune -f
