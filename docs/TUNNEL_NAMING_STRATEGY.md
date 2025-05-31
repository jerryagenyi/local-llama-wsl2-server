# Cloudflare Tunnel & Service Naming Strategy

This document outlines the recommended naming conventions and architectural approach for managing Cloudflare Tunnels and exposing various services on your local Windows machine (via WSL2 Docker) and other remote servers. This strategy aims for clarity, scalability, and ease of management.

## 1. Core Principle: One Tunnel Per Machine/Location

The most robust and logical approach is to establish a dedicated Cloudflare Tunnel connection for each distinct physical machine or computing location where you host services.

* **Rationale:**
    * **Clear Ownership:** Each tunnel clearly identifies the machine it originates from.
    * **Independent Operation:** If one machine goes offline, only its tunnel is affected, not services on other machines.
    * **Simplified Troubleshooting:** Pinpointing network issues becomes easier when tunnels are tied to specific hosts.
    * **Security:** Each tunnel has its own unique token, limiting the blast radius if a token is compromised.

* **Naming Convention for Tunnels:**
    * **Format:** `<machine-name>-<location>-tunnel` (e.g., `desktop-home-lab-tunnel`, `vps-n8n-tunnel`)
    * **Example for Your Setup:**
        * **Your Desktop:** `desktop-home-lab-tunnel` (This will replace your current `wsl2-on-local-w11` tunnel).
        * **Future N8N VPS:** `vps-n8n-tunnel` (When you spin up your N8N instance on a VPS).

## 2. Public Hostnames Per Service/Application

Within each machine's dedicated tunnel, you will define multiple Public Hostnames in the Cloudflare Zero Trust Dashboard. Each hostname will correspond to a specific service or application you wish to expose.

* **Rationale:**
    * **Service-Oriented Access:** Users and applications connect directly to a meaningful hostname (e.g., `llm.yourdomain.com`) rather than a generic machine name.
    * **Flexibility:** Easily add or remove services without reconfiguring the underlying tunnel.
    * **Nginx Integration:** Centralises routing when multiple services are proxied through Nginx.

* **Naming Convention for Public Hostnames:**
    * **Format:** `<service-prefix>.<yourdomain.com>` (e.g., `llm.jerryagenyi.xyz`, `n8n.jerryagenyi.xyz`, `dashboard.jerryagenyi.xyz`)

### Example Mapping for Your Desktop (`desktop-home-lab-tunnel`)

This section details how various services running on your local Windows machine (via native install or WSL2 Docker) are exposed through the `desktop-home-lab-tunnel`.

| Service Type        | Public Hostname             | Internal Service Endpoint (from Tunnel) | Nginx Config `location` (if used) | Notes                                                                   |
| :------------------ | :-------------------------- | :-------------------------------------- | :---------------------------------- | :---------------------------------------------------------------------- |
| **LLM API (Ollama)**| `llm.jerryagenyi.xyz`       | `http://llama-nginx:80` (or `EXTERNAL_NGINX_PORT` from `.env`) | `/api/` path proxies to `http://ollama_backend:11434/api/` | Your primary LLM API endpoint. Use `/api/generate`, `/api/chat`, etc. |
| **N8N Automation** | `n8n.jerryagenyi.xyz`       | `http://n8n-container-name:5678`        | (Optional: see below)               | Your local N8N instance.                                                |
| **Nginx Health Check** | `llm.jerryagenyi.xyz` (root) | `http://llama-nginx:80`                 | `/` path returns "Ollama Nginx Proxy is running." | Provides a basic health check for the Nginx proxy itself.                   |
| **Personal Website**| `my-website.jerryagenyi.xyz`| `http://localhost:8000` (example)       | (Optional: see below)               | If you host a simple website locally.                                   |
| **Developer Dashboard**| `dash.jerryagenyi.xyz`      | `http://localhost:8081` (example)       | (Optional: see below)               | For tools like Portainer, custom monitoring.                            |

#### Important Considerations for Services:

1.  **Nginx as a Central Gateway:**
    * For services that benefit from a reverse proxy (e.g., handling `/api/` paths, adding security headers, rate limiting), you can route multiple public hostnames *through* your Nginx container.
    * **Example for N8N:**
        * If `n8n.jerryagenyi.xyz` points to `http://llama-nginx:80` in Cloudflare Dashboard.
        * Then, in your Nginx config (`./config/conf.d/default.conf`), you'd add:
            ```nginx
            server {
                listen 80;
                server_name n8n.jerryagenyi.xyz;

                location / {
                    proxy_pass http://n8n_container_name:5678/; # Replace with your N8N container name and port
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    # Add any other Nginx configurations specific to N8N (e.g., increased body size limits)
                }
            }
            ```
            You'd also add `upstream n8n_container_name { server n8n_container_name:5678; }` to your main Nginx `http` block.
    * **Pros of Nginx:** Centralised `http://` to `https://` redirection (handled by Cloudflare but Nginx can enforce), request logging, rate limiting, potentially adding authentication layers, handling CORS.
    * **Cons of Nginx:** Adds another layer of complexity.

2.  **Direct Tunnel to Service:**
    * For simpler services that don't need Nginx's features, you can configure the Cloudflare Tunnel to point directly to the service's internal endpoint.
    * **Example for N8N (if not using Nginx):**
        * In Cloudflare Zero Trust Dashboard, for `n8n.jerryagenyi.xyz`, set the service to `http://n8n-container-name:5678`.
    * **Pros of Direct Tunnel:** Simpler, fewer moving parts.
    * **Cons of Direct Tunnel:** Loses Nginx's advanced features, requires managing more ingress rules directly in Cloudflare.

**Recommendation for N8N:** Since you're learning and building, it's often simplest to start with a **Direct Tunnel to Service** for N8N. If you later find you need Nginx's features (e.g., specific header manipulation for N8N), you can route it through Nginx then. **However, it's crucial for N8N to be on the same Docker network as your tunnel if you put it in the same `docker-compose.yml`.**

## 3. Creating New Hostnames in Cloudflare Zero Trust Dashboard

1.  Log in to your Cloudflare Zero Trust Dashboard.
2.  Navigate to **Access** -> **Tunnels**.
3.  Select your **`desktop-home-lab-tunnel`** (or its current name).
4.  Go to the **Public Hostnames** tab.
5.  Click **"Add a public hostname"**.
6.  Configure the new hostname (e.g., `llm.jerryagenyi.xyz`), select your domain, and set the `Service` type (HTTP) and `URL` (e.g., `http://llama-nginx:80` for Ollama, or `http://n8n_container_name:5678` for N8N if direct).
7.  Save the hostname. Cloudflare will push this configuration to your running `cloudflared` container.

---

### Additional Hostnames

* **Nginx itself:** Nginx doesn't necessarily need its own public hostname. Its purpose in your current setup is to proxy requests *to* Ollama (and potentially other services). The `llm.jerryagenyi.xyz` hostname (or `wsl2-w11.jerryagenyi.xyz` currently) already points to your Nginx. So the Nginx is accessed via that hostname.
* **Other ideas:**
    * `dash.jerryagenyi.xyz`: For a local dashboard (e.g., Portainer, Grafana, custom monitoring).
    * `dev.jerryagenyi.xyz`: For a local development server or a specific project you're working on that needs to be temporarily exposed.
    * `files.jerryagenyi.xyz`: If you ever set up a local file server (e.g., Nextcloud, or a simple HTTP server to share files).
    * `home.jerryagenyi.xyz`: For a home automation dashboard (e.g., Home Assistant).

You can add these as you need them! Start with `llm.jerryagenyi.xyz` and `n8n.jerryagenyi.xyz` as your immediate priorities.

### Next Steps: N8N Local Setup

* **Setup N8N on Docker Locally:** This is a very sensible next step.
    * **Isolated or Together?** For simplicity and shared networking, it's often easiest to add N8N as a **new service in your existing `docker-compose.yml`**. This allows `llama-network` to be shared.
    * **N8N and Nginx Advanced Features:**
        * N8N usually doesn't *require* Nginx's advanced features for its basic operation. You can often point the Cloudflare Tunnel directly to the N8N container's internal port.
        * However, if you want to add things like:
            * Strict rate limiting on N8N's webhooks.
            * Custom headers for security.
            * Basic HTTP authentication at the Nginx layer before N8N.
            * Consolidating all web traffic through Nginx.
            ...then proxying N8N through Nginx (like you do Ollama) makes sense.
        * **My advice:** Start by adding N8N directly to the `docker-compose.yml` and configuring the Cloudflare Tunnel to point straight to it. Get it working. Then, if you see a specific need for Nginx features, you can refactor it to go through Nginx later.

### Instructions to Edit `.env` for New Tunnel Name

Here's what you'll need to do yourself before running the `docker compose up -d` after making changes in Cloudflare Dashboard:

1.  **Rename Tunnel in Cloudflare:** Go to your Cloudflare Zero Trust dashboard. Under "Tunnels," click on your `wsl2-on-local-w11` tunnel. You should find an option to "Configure" or "Rename" it to `desktop-home-lab-tunnel`.
2.  **Get New Tunnel Token (if renaming requires it):** Sometimes, renaming a tunnel can generate a new token. **Double-check the token** in your dashboard after renaming.
3.  **Update `.env` file:**
    * Open your `.env` file in your `local-llama-wsl2-server` project.
    * **Crucially, update the `CLOUDFLARE_TUNNEL_TOKEN` if it changed.**
    * No change needed for `CLOUDFLARED_OPTS` or `EXTERNAL_NGINX_PORT` (unless you also change that). The `CLOUDFLARED_OPTS` simply tells the `cloudflared` container to connect to an internal Nginx service, and Cloudflare dashboard handles the public hostname mapping.

