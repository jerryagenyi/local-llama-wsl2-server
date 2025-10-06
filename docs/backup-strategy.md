# Docker Volumes Backup Strategy

## 🔒 **Security-First Approach**

**Never commit volume backups to GitHub!** These contain sensitive data including:
- Database contents (user data, configurations)
- API keys and secrets
- Session data and authentication tokens
- Application state and user files

## 📋 **Backup Scripts Created**

### **PowerShell (Windows)**
```powershell
# Create backup
.\scripts\backup-volumes.ps1

# Restore backup
.\scripts\restore-volumes.ps1 -BackupFile ".\backups\docker-volumes-2024-01-15-1430.tar.gz"
```

### **Bash (Linux/WSL)**
```bash
# Create backup
./scripts/backup-volumes.sh

# Restore backup
./scripts/restore-volumes.sh ./backups/docker-volumes-2024-01-15-1430.tar.gz
```

## 🗂️ **What Gets Backed Up**

- **Agent Zero Data**: Conversations, settings, knowledge base
- **n8n Data**: Workflows, credentials, execution history
- **Flowise Data**: Chatflows, credentials, conversation logs
- **PostgreSQL**: All application data and user files

## 🔐 **Secure Storage Options**

### **Option 1: Encrypted Local Storage**
```bash
# Encrypt backup before storing
gpg --symmetric --cipher-algo AES256 docker-volumes-2024-01-15.tar.gz
# Store: docker-volumes-2024-01-15.tar.gz.gpg
```

### **Option 2: Google Drive (Encrypted)**
1. **Encrypt first**: Use 7-Zip with password or GPG
2. **Upload encrypted file**: Never upload raw backups
3. **Store password separately**: Use a password manager

### **Option 3: Cloud Storage with Encryption**
- **AWS S3**: Server-side encryption enabled
- **Azure Blob**: Client-side encryption
- **Google Cloud**: Customer-managed encryption keys

## 📅 **Backup Schedule Recommendations**

### **Daily Backups** (Automated)
```powershell
# Add to Windows Task Scheduler
# Run: .\scripts\backup-volumes.ps1
# Schedule: Daily at 2 AM
```

### **Weekly Full Backups** (Manual)
- Test restore process
- Verify backup integrity
- Update encryption keys

### **Before Major Changes**
- Before Docker Compose updates
- Before service configuration changes
- Before system maintenance

## 🚨 **Security Best Practices**

### **✅ DO:**
- Encrypt backups before cloud storage
- Use strong, unique passwords for encryption
- Store encryption keys separately from backups
- Test restore process regularly
- Keep multiple backup versions
- Use secure transfer methods (SFTP, HTTPS)

### **❌ DON'T:**
- Commit volume backups to Git
- Store unencrypted backups in cloud
- Share backup files via email
- Store encryption keys with backups
- Use weak passwords for encryption

## 🔄 **Restore Process**

### **Safe Restore Testing**
```bash
# 1. Create test environment
docker-compose -f docker-compose.test.yml up -d

# 2. Restore to test volumes
./scripts/restore-volumes.sh backup-file.tar.gz

# 3. Verify functionality
# 4. Clean up test environment
```

### **Production Restore**
```bash
# 1. Stop all services
docker-compose down

# 2. Backup current state (just in case)
./scripts/backup-volumes.sh

# 3. Restore from backup
./scripts/restore-volumes.sh -BackupFile backup-file.tar.gz -Force

# 4. Start services
docker-compose up -d

# 5. Verify everything works
```

## 📊 **Backup Monitoring**

### **Check Backup Size**
```bash
du -h backups/
```

### **Verify Backup Integrity**
```bash
tar -tzf backup-file.tar.gz | head -20
```

### **List Backup Contents**
```bash
tar -tzf backup-file.tar.gz
```

## 🆘 **Emergency Recovery**

### **Quick Recovery Checklist**
1. ✅ Stop all services: `docker-compose down`
2. ✅ Identify latest good backup
3. ✅ Verify backup integrity
4. ✅ Restore volumes: `./scripts/restore-volumes.sh`
5. ✅ Start services: `docker-compose up -d`
6. ✅ Test critical functionality
7. ✅ Monitor logs for issues

### **Recovery Time Objectives**
- **RTO (Recovery Time)**: 15-30 minutes
- **RPO (Data Loss)**: Last backup (daily = 24 hours max)
- **Backup Retention**: 30 days (configurable)

## 🔧 **Automation Examples**

### **Windows Task Scheduler**
```xml
<!-- Daily backup at 2 AM -->
<Triggers>
    <CalendarTrigger>
        <StartBoundary>2024-01-01T02:00:00</StartBoundary>
        <Repetition>
            <Interval>P1D</Interval>
        </Repetition>
    </CalendarTrigger>
</Triggers>
```

### **Linux Cron Job**
```bash
# Add to crontab: crontab -e
0 2 * * * /path/to/scripts/backup-volumes.sh
```

## 📝 **Backup Logging**

The scripts create detailed logs:
- Backup timestamps
- Volume sizes
- Success/failure status
- Restore instructions
- Security warnings

## 🎯 **Recommended Workflow**

1. **Daily**: Automated backup to local encrypted storage
2. **Weekly**: Manual backup to encrypted cloud storage
3. **Monthly**: Test restore process
4. **Quarterly**: Review and update backup strategy

This approach ensures your data is safe while maintaining security best practices!
