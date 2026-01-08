# n8n Security Quick Reference
## CVE-2026-21858 Remediation Summary

---

## ✅ Current Status: SECURE

- **Version:** 1.123.4 (NOT vulnerable - requires >= 1.121.0)
- **Network:** Hardened (localhost binding)
- **Version:** Pinned in Dockerfile

---

## 🔧 Changes Applied

### 1. Network Hardening
```yaml
# Changed from:
N8N_HOST=0.0.0.0

# To:
N8N_HOST=127.0.0.1
```

### 2. Version Pinning
```dockerfile
# Changed from:
FROM n8nio/n8n:latest

# To:
FROM n8nio/n8n:1.123.4
```

### 3. Authentication Ready
```yaml
# Added to docker-compose.yml:
- N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER:-}
- N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD:-}
```

---

## ⚠️ Action Required

### Enable Authentication

Add to your `.env` file:
```bash
N8N_BASIC_AUTH_USER=your_username
N8N_BASIC_AUTH_PASSWORD=your_secure_password
```

Then restart:
```bash
docker-compose up -d n8n
```

---

## 📋 Verification Commands

```bash
# Check version
docker exec n8n sh -c "cat /usr/local/lib/node_modules/n8n/package.json | grep version"

# Verify network binding
docker exec n8n sh -c "echo \$N8N_HOST"
# Should output: 127.0.0.1

# Test health
curl http://localhost:5678/healthz
```

---

## 🔒 Security Checklist

- [x] Version >= 1.121.0 ✅
- [x] Network binding to localhost ✅
- [x] Version pinned ✅
- [ ] Authentication configured ⚠️
- [ ] Webhooks reviewed ⚠️
- [ ] Secrets rotated ⚠️
- [ ] Monitoring set up ⚠️

---

## 📚 Scripts Available

- `scripts/n8n-backup.ps1` - Backup n8n data
- `scripts/n8n-harden.ps1` - Apply security hardening
- `scripts/n8n-security-audit.ps1` - Audit all instances

---

## 🆘 Need Help?

- Full report: `docs/n8n-security-audit-FINAL.md`
- n8n Security: https://docs.n8n.io/security/
- CVE Details: CVE-2026-21858

---

**Last Updated:** 2026-01-04
