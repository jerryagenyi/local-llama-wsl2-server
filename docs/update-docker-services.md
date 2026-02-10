# Proper Docker Service Update Process

Use this process when updating any Docker service, especially those using the `:latest` image tag. It ensures you get a **fresh pull** instead of reusing a cached image.

---

## Quick reference (e.g. N8N with `:latest`)

If the service uses the official `:latest` image (e.g. `n8nio/n8n:latest`), do:

1. **Stop the specific service**
   ```bash
   docker compose down <service-name>
   ```

2. **Remove the old image to force fresh pull**
   ```bash
   docker image rm <image-name>:latest
   ```

3. **Start the service (will pull latest automatically)**
   ```bash
   docker compose up -d <service-name>
   ```

4. **Verify the update**
   ```bash
   docker compose logs <service-name> --tail=20
   ```

*In this project, n8n is a custom build (see below), so use the n8n section instead of the steps above for n8n.*

---

## For services using `:latest` (LiteLLM, Cloudflared, Flowise, Agent Zero)

### 1. Stop the specific service

```bash
docker compose down <service-name>
```

### 2. Remove the old image to force fresh pull

```bash
docker image rm <image-name>:latest
```

**Image names from this project:**

| Service     | Image to remove                         |
|------------|------------------------------------------|
| litellm    | `ghcr.io/berriai/litellm:main-latest`   |
| cloudflared| `cloudflare/cloudflared:latest`          |
| flowise    | `flowiseai/flowise:latest`               |
| agent-zero | `agent0ai/agent-zero:latest`            |

### 3. Start the service (will pull latest automatically)

```bash
docker compose up -d <service-name>
```

### 4. Verify the update

```bash
docker compose logs <service-name> --tail=20
```

---

## For n8n (custom build)

This project builds n8n from `Dockerfile.n8n` (based on `n8nio/n8n:1.123.4`), not from `n8nio/n8n:latest`. To update n8n:

1. **Optional:** Bump the base version in `Dockerfile.n8n` (e.g. `1.123.4` → `1.124.0`) if you want a newer n8n release.

2. **Stop n8n**
   ```bash
   docker compose down n8n
   ```

3. **Rebuild the image (no cache)**
   ```bash
   docker compose build --no-cache n8n
   ```

4. **Start n8n**
   ```bash
   docker compose up -d n8n
   ```

5. **Verify**
   ```bash
   docker compose logs n8n --tail=20
   ```

If you ever switch n8n to use the official `n8nio/n8n:latest` image directly in `docker-compose.yml`, use the **:latest** process above with image `n8nio/n8n:latest`.

---

## One-liner examples (Bash/WSL)

**Update a single :latest service (e.g. flowise):**

```bash
docker compose down flowise && docker image rm flowiseai/flowise:latest && docker compose up -d flowise && docker compose logs flowise --tail=20
```

**Update n8n (custom build):**

```bash
docker compose down n8n && docker compose build --no-cache n8n && docker compose up -d n8n && docker compose logs n8n --tail=20
```

---

**PowerShell script (Windows):** Run `.\scripts\update-docker-service.ps1 -Service n8n` (or `flowise`, `litellm`, `cloudflared`, `agent-zero`) to run the steps above for one service.

---

*Reference: Proper N8N Update Process for Future Reference (and any Docker service using `:latest`).*
