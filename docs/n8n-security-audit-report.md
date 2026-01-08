# n8n Security Audit Report - CVE-2026-21858 "Ni8mare"

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Auditor:** DevOps Security Team  
**CVE:** CVE-2026-21858  
**Severity:** CRITICAL  
**Affected Versions:** n8n < 1.121.0

---

## Executive Summary

This report documents the security audit and remediation of n8n instances vulnerable to CVE-2026-21858, a critical unauthenticated remote code execution vulnerability in n8n's webhook and form handling functionality.

### Key Findings

- **Total Instances Discovered:** 1
- **Vulnerable Instances:** 1 (requires verification)
- **Publicly Exposed:** Yes (via Cloudflare tunnel)
- **Authentication:** Not configured
- **Risk Level:** CRITICAL

---

## 1. Discovery and Inventory

### Instance Details

| Property | Value |
|----------|-------|
| **Container Name** | n8n |
| **Host** | Local machine (WSL2/Docker) |
| **Image** | n8nio/n8n:latest (custom build) |
| **Version** | TBD (needs verification) |
| **Status** | Running (unhealthy) |
| **Deployment** | Docker Compose |
| **Environment** | Production |

### Network Exposure

- **Binding:** `0.0.0.0:5678` (⚠️ Exposed to all interfaces)
- **Public Access:** Yes, via Cloudflare tunnel
- **Domain:** `https://n8n.jerryagenyi.xyz`
- **Protocol:** HTTP (HTTPS terminated at Cloudflare)
- **Reverse Proxy:** Cloudflare Tunnel

### Configuration Assessment

| Setting | Status | Risk |
|---------|--------|------|
| Basic Auth | ❌ Not configured | HIGH |
| Encryption Key | ✅ Set (via env var) | - |
| HTTPS | ✅ Via Cloudflare | - |
| Localhost Binding | ❌ Bound to 0.0.0.0 | MEDIUM |
| Webhook URL | ✅ Configured | - |

---

## 2. Vulnerability Assessment

### CVE-2026-21858 Details

**Description:** Unauthenticated remote code execution vulnerability in n8n's webhook and form trigger handling. Attackers can execute arbitrary code on the n8n server without authentication.

**Attack Vector:**
- Public webhook endpoints
- Form triggers accepting untrusted input
- File upload handling

**Impact:**
- Complete server compromise
- Data exfiltration
- Lateral movement
- Credential theft

### Current Risk Status

⚠️ **HIGH RISK** - Instance is:
1. Using `latest` tag (version unknown, potentially vulnerable)
2. Publicly accessible via Cloudflare tunnel
3. No authentication configured
4. Bound to all network interfaces

---

## 3. Remediation Plan

### Phase 1: Immediate Actions (CRITICAL)

1. **Verify Version**
   ```bash
   docker exec n8n sh -c "cat /usr/local/lib/node_modules/n8n/package.json | grep version"
   ```

2. **Create Backup** (if version < 1.121.0)
   ```powershell
   .\scripts\n8n-backup.ps1
   ```

3. **Upgrade to Secure Version**
   - Update `Dockerfile.n8n` to use `n8nio/n8n:1.121.0` or newer
   - Rebuild and restart container

### Phase 2: Network Hardening

1. **Bind to Localhost Only**
   - Change `N8N_HOST=0.0.0.0` to `N8N_HOST=127.0.0.1`
   - Access only via Cloudflare tunnel

2. **Enable Authentication**
   - Configure `N8N_BASIC_AUTH_USER` and `N8N_BASIC_AUTH_PASSWORD`
   - Or implement OAuth/SSO via Cloudflare Access

3. **Review Webhook Security**
   - Audit all public webhooks
   - Add secret tokens to webhook URLs
   - Disable unused webhooks

### Phase 3: Secrets Rotation

1. **Rotate Encryption Key**
   - Generate new `N8N_ENCRYPTION_KEY`
   - Update environment variable
   - Restart container

2. **Rotate API Credentials**
   - Review all workflow credentials
   - Rotate third-party API keys
   - Update in n8n credential store

### Phase 4: Monitoring and Detection

1. **Enable Logging**
   - Configure centralized logging
   - Monitor webhook access patterns
   - Alert on suspicious activity

2. **Set Up Alerts**
   - New admin user creation
   - Workflow modifications
   - Code execution nodes added
   - Unusual outbound connections

---

## 4. Implementation Steps

### Step 1: Backup Current State

```powershell
# Run backup script
.\scripts\n8n-backup.ps1
```

### Step 2: Upgrade n8n

1. Update `Dockerfile.n8n`:
   ```dockerfile
   FROM n8nio/n8n:1.121.0
   ```

2. Rebuild and restart:
   ```bash
   docker-compose build n8n
   docker-compose up -d n8n
   ```

### Step 3: Harden Configuration

Update `docker-compose.yml`:
```yaml
environment:
  - N8N_HOST=127.0.0.1  # Changed from 0.0.0.0
  - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
  - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
```

### Step 4: Verify Upgrade

```bash
docker exec n8n sh -c "cat /usr/local/lib/node_modules/n8n/package.json | grep version"
# Should show version >= 1.121.0
```

---

## 5. Post-Remediation Checklist

- [ ] Version verified >= 1.121.0
- [ ] Backup created and tested
- [ ] Container bound to localhost only
- [ ] Authentication enabled
- [ ] Webhooks reviewed and secured
- [ ] Encryption key rotated
- [ ] API credentials rotated
- [ ] Logging configured
- [ ] Monitoring alerts set up
- [ ] Logs reviewed for suspicious activity

---

## 6. Recommendations

### Immediate (Critical)

1. **Upgrade immediately** if version < 1.121.0
2. **Enable authentication** before next restart
3. **Bind to localhost** to reduce attack surface

### Short-term (High Priority)

1. Implement Cloudflare Access for additional auth layer
2. Review and secure all public webhooks
3. Set up centralized logging
4. Rotate all secrets and credentials

### Long-term (Best Practices)

1. Implement infrastructure as code (IaC)
2. Set up automated security scanning
3. Regular security audits
4. Incident response plan

---

## 7. Log Review

### Suspicious Activity Indicators

Review logs for:
- Unusual webhook access patterns
- Repeated failed authentication attempts
- New admin users created
- Workflows modified with code execution nodes
- Unexpected file uploads
- Outbound connections to unknown IPs

### Log Locations

- Container logs: `docker logs n8n`
- n8n database: `/home/node/.n8n/database.sqlite`
- Cloudflare tunnel logs: Check Cloudflare dashboard

---

## 8. Contact and Escalation

For questions or issues during remediation:
- Review n8n security advisory: [n8n Security](https://docs.n8n.io/security/)
- CVE Details: CVE-2026-21858
- n8n GitHub: [n8n Security Issues](https://github.com/n8n-io/n8n/security)

---

**Report Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Next Review:** After remediation completion
