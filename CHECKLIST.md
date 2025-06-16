# Local LLM Server Setup & Troubleshooting Checklist

---

## 🟢 **Top Priority: Network & Access**

- [ ] **1. DNS Records**
    - [ ] Ensure A records for `llm.jerryagenyi.xyz`, `n8n.jerryagenyi.xyz`, and `flowise.jerryagenyi.xyz` point to your public IP (not CNAME to tunnel, unless using Cloudflare Tunnel setup)
    - [ ] If using Cloudflare proxy (orange cloud), temporarily disable proxy (set to DNS only) for initial Let's Encrypt certificate issuance
    - [ ] Confirm DNS propagation (use https://dnschecker.org)

- [ ] **2. Port Forwarding**
    - [ ] Log in to your home router
    - [ ] Forward external ports 80 (HTTP) and 443 (HTTPS) to your PC's local IP (e.g., 192.168.1.244)
    - [ ] Save and reboot router if needed
    - [ ] Confirm ports are open (use https://www.yougetsignal.com/tools/open-ports/)

---

## 🟡 **Service Security & Configuration**

- [ ] **3. Caddy Password Hash**
    - [ ] Open WSL2 Ubuntu terminal
    - [ ] Install Caddy if not present (see deployment guide)
    - [ ] Run `caddy hash-password` and enter your desired password
    - [ ] Copy the hash and paste it in `config/caddy/Caddyfile` where `{YOUR_HASH}` is indicated

- [ ] **4. Environment Variables**
    - [ ] Create `.env` file in project root with:
      ```
      N8N_AUTH_USER=your_n8n_username
      N8N_AUTH_PASSWORD=your_n8n_password
      FLOWISE_AUTH_USER=your_flowise_username
      FLOWISE_AUTH_PASSWORD=your_flowise_password
      FLOWISE_SECRET_KEY=your_flowise_secret_key
      ```
    - [ ] Remove any old/unused variables (e.g., CLOUDFLARE_TUNNEL_TOKEN, BASIC_AUTH_USER/PASS, etc.)

- [ ] **5. Start Services**
    - [ ] Run `docker compose up -d` in WSL2
    - [ ] Check logs for errors: `docker logs llama-caddy`, `docker logs desktop-n8n`, `docker logs desktop-flowise`

---

## 🟢 **Ollama & GPU**

- [ ] **6. Ollama Status**
    - [ ] Confirm Ollama is installed and running on Windows (it auto-starts)
    - [ ] Do NOT run `ollama serve` if already running (error: port in use)
    - [ ] Check GPU detection: open PowerShell and run `ollama serve` (if not already running), or check logs for `library=rocm` and your GPU name

---

## 🟡 **Service Access & Security**

- [ ] **7. Test Endpoints**
    - [ ] Access `https://llm.jerryagenyi.xyz` in browser (should prompt for basic auth)
    - [ ] Access `https://n8n.jerryagenyi.xyz` (should prompt for basic auth)
    - [ ] Access `https://flowise.jerryagenyi.xyz` (should prompt for basic auth)
    - [ ] Test API endpoints and webhooks

- [ ] **8. Rate Limiting & Abuse Prevention**
    - [ ] Confirm rate limiting is working (try rapid requests, should get 429 error)
    - [ ] Review Caddy logs for suspicious activity

---

## 🟠 **Future Improvements & Notes**

- [ ] **9. OAuth (Google/GitHub Login)**
    - [ ] Research and plan for OAuth2/OIDC integration (e.g., with oauth2-proxy or Caddy plugins)
    - [ ] Replace or supplement basic auth with OAuth for all services

- [ ] **10. Monitoring & Backups**
    - [ ] Set up regular backups for N8N and Flowise data
    - [ ] Consider Prometheus/Grafana for monitoring

- [ ] **11. Documentation**
    - [ ] Keep README, deployment guide, and this checklist up to date
    - [ ] Archive/remove old files that no longer fit the new approach

---

## 📝 **Troubleshooting Log**
- [ ] Document any issues encountered and solutions here for future reference

---

**Legend:**
- 🟢 = Must do first (blocks other steps)
- 🟡 = Important for security/function
- 🟠 = Optional/future improvements

---

**Tip:** Check off each item as you complete it. If you get stuck, document the issue in the troubleshooting log and we'll address it together! 