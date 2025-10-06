# Rclone Backup Guide for Docker Volumes

## 🚀 **What is Rclone?**

Rclone is a command-line program to manage files on cloud storage. It's like rsync but for cloud storage services. It supports 70+ cloud storage providers including Google Drive, OneDrive, Dropbox, AWS S3, and many more.

## 📋 **Prerequisites**

- Rclone installed at `C:\rclone\rclone.exe`
- Docker volumes to backup
- Google Drive account configured
- Remote name: `gdrive`
- Remote path: `container-volumes-backup-rclone`

## 🔧 **Initial Setup**

### **1. Configure Your Google Drive Remote**

```powershell
# Navigate to rclone directory
cd C:\rclone

# Start configuration
.\rclone.exe config
```

**Follow the interactive setup:**

1. **Choose option**: `n` (New remote)
2. **Name your remote**: `googledrive`
3. **Choose storage type**: `drive` (Google Drive)
4. **Client ID**: Leave blank for default
5. **Client Secret**: Leave blank for default
6. **Scope**: Choose `drive` for full access
7. **Root folder**: Leave blank for root access
8. **Service account**: Leave blank
9. **Advanced config**: Choose `n` (No)
10. **Auto config**: Choose `y` (Yes) - opens browser for authentication
11. **Confirm**: Choose `y` (Yes) to confirm

### **2. Test Your Configuration**

```powershell
# List remotes
.\rclone.exe listremotes

# Test connection
.\rclone.exe lsd googledrive:

# List files in root
.\rclone.exe ls googledrive:

# Test specific folder
.\rclone.exe ls googledrive:container-volumes-backup-rclone/
```

## 📦 **Backup Strategy**

### **Directory Structure on Google Drive**
```
googledrive:container-volumes-backup-rclone/
├── 2024-01-15-1430/
│   ├── docker-volumes-2024-01-15-1430.tar.gz
│   └── backup-info-2024-01-15-1430.txt
├── 2024-01-16-0900/
│   ├── docker-volumes-2024-01-16-0900.tar.gz
│   └── backup-info-2024-01-16-0900.txt
└── latest/
    ├── docker-volumes-2024-01-16-0900.tar.gz
    └── backup-info-2024-01-16-0900.txt
```

## 🔄 **Using the Enhanced Backup Scripts**

### **Enhanced PowerShell Backup Script**

The scripts are located in the `scripts/` directory of this repository:

```powershell
# Navigate to project directory
cd C:\Users\Username\Documents\github\local-llama-wsl2-server

# Basic local backup
.\scripts\enhanced-backup.ps1

# Backup and upload to Google Drive
.\scripts\enhanced-backup.ps1 -UploadToCloud

# Backup, encrypt, and upload
.\scripts\enhanced-backup.ps1 -UploadToCloud -Encrypt

# Custom remote and path
.\scripts\enhanced-backup.ps1 -RemoteName "googledrive" -RemotePath "container-volumes-backup-rclone" -UploadToCloud
```

### **Restore from Google Drive**

```powershell
# Restore latest backup from Google Drive
.\scripts\enhanced-restore.ps1 -FromCloud -BackupDate "latest"

# Restore specific date from Google Drive
.\scripts\enhanced-restore.ps1 -FromCloud -BackupDate "2024-01-15-1430"

# Restore from local backup
.\scripts\enhanced-restore.ps1 -BackupFile ".\backups\docker-volumes-2024-01-15-1430.tar.gz"
```

## 🔐 **Security Best Practices**

### **Encryption Options**

1. **7-Zip Encryption** (Recommended for this setup)
```powershell
# Encrypt before upload
.\scripts\enhanced-backup.ps1 -UploadToCloud -Encrypt
```

2. **Rclone Crypt Remote** (Advanced)
```powershell
# Create encrypted remote
C:\rclone\rclone.exe config
# Choose 'crypt' as storage type
# Set password and salt
```

### **Access Control**

```powershell
# List all remotes
C:\rclone\rclone.exe listremotes

# Check remote configuration
C:\rclone\rclone.exe config dump

# Test access to your specific folder
C:\rclone\rclone.exe lsd googledrive:container-volumes-backup-rclone/
```

## 📊 **Monitoring and Maintenance**

### **Check Backup Status**

```powershell
# List backups in Google Drive folder
C:\rclone\rclone.exe ls googledrive:container-volumes-backup-rclone/

# Check backup sizes
C:\rclone\rclone.exe size googledrive:container-volumes-backup-rclone/

# List latest backups
C:\rclone\rclone.exe ls googledrive:container-volumes-backup-rclone/latest/
```

### **Cleanup Old Backups**

```powershell
# Delete backups older than 30 days
C:\rclone\rclone.exe delete googledrive:container-volumes-backup-rclone/ --min-age 30d

# Keep only last 10 backups
C:\rclone\rclone.exe delete googledrive:container-volumes-backup-rclone/ --max-age 10
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Authentication Failed**
```powershell
# Re-authenticate
C:\rclone\rclone.exe config reconnect googledrive
```

2. **Upload Failed**
```powershell
# Check connection
C:\rclone\rclone.exe about googledrive

# Test folder access
C:\rclone\rclone.exe lsd googledrive:container-volumes-backup-rclone/
```

3. **Download Failed**
```powershell
# List available files
C:\rclone\rclone.exe ls googledrive:container-volumes-backup-rclone/

# Download specific file
C:\rclone\rclone.exe copy googledrive:container-volumes-backup-rclone/backup.tar.gz .\restore\
```

## 📈 **Advanced Features**

### **Incremental Backups**

```powershell
# Sync only changed files
C:\rclone\rclone.exe sync .\backups\ googledrive:container-volumes-backup-rclone/ --update
```

### **Bandwidth Limiting**

```powershell
# Limit upload speed
C:\rclone\rclone.exe copy backup.tar.gz googledrive:container-volumes-backup-rclone/ --bwlimit 1M
```

### **Parallel Transfers**

```powershell
# Use multiple connections
C:\rclone\rclone.exe copy backup.tar.gz googledrive:container-volumes-backup-rclone/ --transfers 4
```

## 🔍 **Quick Diagnostics Commands**

```powershell
# Check what remotes you have configured
C:\rclone\rclone.exe listremotes

# Test connection to your remote
C:\rclone\rclone.exe lsd gdrive:

# List files in your backup folder
C:\rclone\rclone.exe ls gdrive:container-volumes-backup-rclone/

# Check backup folder size
C:\rclone\rclone.exe size gdrive:container-volumes-backup-rclone/

# View remote configuration
C:\rclone\rclone.exe config dump

# Test specific folder access
C:\rclone\rclone.exe lsd gdrive:container-volumes-backup-rclone/
```

## 🎯 **Quick Reference Commands**

```powershell
# Basic operations
C:\rclone\rclone.exe copy source destination
C:\rclone\rclone.exe move source destination
C:\rclone\rclone.exe sync source destination
C:\rclone\rclone.exe delete destination

# Information
C:\rclone\rclone.exe ls gdrive:container-volumes-backup-rclone/
C:\rclone\rclone.exe size gdrive:container-volumes-backup-rclone/
C:\rclone\rclone.exe about gdrive

# Configuration
C:\rclone\rclone.exe config
C:\rclone\rclone.exe config dump
C:\rclone\rclone.exe listremotes
```

## 🔄 **Automated Scheduling**

### **Windows Task Scheduler Setup**

1. **Open Task Scheduler**
2. **Create Basic Task**
3. **Name**: "Docker Volumes Backup"
4. **Trigger**: Daily at 2:00 AM
5. **Action**: Start a program
6. **Program**: `powershell.exe`
7. **Arguments**: `-File "C:\Users\Username\Documents\github\local-llama-wsl2-server\scripts\enhanced-backup.ps1" -UploadToCloud`

### **PowerShell Scheduled Job**

```powershell
# Create scheduled job
$trigger = New-JobTrigger -Daily -At 2:00AM
$action = New-ScheduledJobAction -Execute "powershell.exe" -Argument "-File C:\Users\Username\Documents\github\local-llama-wsl2-server\scripts\enhanced-backup.ps1 -UploadToCloud"
Register-ScheduledJob -Name "DockerBackup" -Trigger $trigger -Action $action

# View jobs
Get-ScheduledJob

# Remove job
Unregister-ScheduledJob -Name "DockerBackup"
```

This guide is now integrated into your repository and configured for your specific setup! 🚀
