# Configuration Directory

This directory contains configuration files for the services in this Docker Compose setup.

## ⚠️ Important Setup Note

**Before using this stack, you must first configure LiteLLM and Agent Zero through their web interfaces:**
- **LiteLLM**: Access `http://localhost:4000` to add your Ollama models
- **Agent Zero**: Access `http://localhost:8080` to configure AI agent settings

These services require web UI configuration and cannot be fully configured through config files alone.

## 📁 Directory Structure

```
config/
├── litellm/           # LiteLLM configuration (uses config files)
│   └── config.yaml    # LiteLLM model configuration
├── agent-zero/        # Agent Zero configuration (uses web UI)
│   └── settings.json.backup  # Backup of old settings (not used)
└── README.md          # This file
```

## 🔧 Service Configuration Methods

### **LiteLLM** - Uses Config Files ✅
- **Configuration**: `config/litellm/config.yaml`
- **Method**: File-based configuration
- **Purpose**: Defines available Ollama models and their endpoints

### **Agent Zero** - Uses Web UI ✅
- **Configuration**: Web interface at `http://localhost:8080`
- **Method**: Web UI configuration (no config files needed)
- **Purpose**: Configure LLM providers, models, and agent settings

## 🚀 How to Configure Services

### **LiteLLM Configuration**
1. Edit `config/litellm/config.yaml` to add/remove models
2. Restart LiteLLM: `docker-compose restart litellm`

### **Agent Zero Configuration**
1. Access web interface: `http://localhost:8080`
2. Login with credentials from `.env` file
3. Go to Settings → Agent Settings
4. Configure:
   - **Chat Model**: Select provider and model
   - **Utility Model**: Select provider and model  
   - **Web Browser Model**: Select provider and model
   - **Embedding Model**: Select provider and model
5. Save settings

## 🔑 Environment Variables

All sensitive configuration (API keys, passwords) is stored in the `.env` file in the project root.

## 📝 Notes

- **Agent Zero** does not use config files - all configuration is done through the web UI
- **LiteLLM** uses the `config.yaml` file to define available models
- **Cloudflare Tunnel** is configured directly in `docker-compose.yml` using the tunnel token
- Backup files (`.backup` extension) are kept for reference but not used by the services
