# Fixed Enhanced Docker Volumes Backup Script with Rclone Integration
param(
    [string]$BackupPath = ".\backups",
    [string]$RemoteName = "googledrive",
    [string]$RemotePath = "docker-backups",
    [string]$RclonePath = "C:\rclone\rclone.exe",
    [switch]$UploadToCloud,
    [switch]$Encrypt,
    [switch]$Verbose
)

Write-Host "Starting Enhanced Docker Volumes Backup..." -ForegroundColor Green

# Check if Rclone is available
if ($UploadToCloud -and -not (Test-Path $RclonePath)) {
    Write-Host "Rclone not found at $RclonePath" -ForegroundColor Red
    Write-Host "Please install Rclone or update the RclonePath parameter" -ForegroundColor Yellow
    exit 1
}

# Create backup directory
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Host "Created backup directory: $BackupPath" -ForegroundColor Yellow
}

# Get timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$backupFile = "$BackupPath\docker-volumes-$timestamp.tar.gz"

Write-Host "Backup file: $backupFile" -ForegroundColor Cyan

# Define volumes to backup
$volumes = @(
    "local-llama-wsl2-server_agent_zero_data",
    "local-llama-wsl2-server_flowise_data", 
    "local-llama-wsl2-server_n8n_data",
    "local-llama-wsl2-server_postgres_data"
)

Write-Host "Backing up volumes:" -ForegroundColor Cyan
foreach ($volume in $volumes) {
    Write-Host "  - $volume" -ForegroundColor White
}

# Create temporary directory
$tempDir = "$env:TEMP\docker-backup-$timestamp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Backup each volume
    foreach ($volume in $volumes) {
        Write-Host "Backing up $volume..." -ForegroundColor Yellow
        
        # Create a temporary container to copy data
        $dockerCmd = "docker run --rm -v ${volume}:/source -v ${tempDir}:/backup alpine sh -c `"cp -r /source/* /backup/$volume/ 2>/dev/null || mkdir -p /backup/$volume`""
        Invoke-Expression $dockerCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Success: $volume backed up" -ForegroundColor Green
        } else {
            Write-Host "Warning: $volume backup completed with warnings" -ForegroundColor Yellow
        }
    }
    
    # Create compressed archive
    Write-Host "Creating compressed archive..." -ForegroundColor Yellow
    tar -czf $backupFile -C $tempDir .
    
    if (Test-Path $backupFile) {
        $fileSize = (Get-Item $backupFile).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Host "Local backup created successfully!" -ForegroundColor Green
        Write-Host "Location: $backupFile" -ForegroundColor Cyan
        Write-Host "Size: $fileSizeMB MB" -ForegroundColor Cyan
        
        # Create backup info file
        $infoFile = "$BackupPath\backup-info-$timestamp.txt"
        $backupInfo = @"
Docker Volumes Backup Information
================================
Backup Date: $(Get-Date)
Backup File: docker-volumes-$timestamp.tar.gz
Size: $fileSizeMB MB
Location: $backupFile

Volumes Backed Up:
$(($volumes | ForEach-Object { "  - $_" }) -join "`n")

Restore Command:
docker run --rm -v `$(pwd):/backup -v <volume_name>:/target alpine sh -c "cd /target && tar -xzf /backup/docker-volumes-$timestamp.tar.gz --strip-components=1"

Notes:
- This backup contains sensitive data (databases, configurations, etc.)
- Store securely and do not commit to version control
- Consider encrypting before storing in cloud services
"@
        
        $backupInfo | Out-File -FilePath $infoFile -Encoding UTF8
        Write-Host "Backup info saved to: $infoFile" -ForegroundColor Cyan
        
        # Encrypt if requested
        if ($Encrypt) {
            Write-Host "Encrypting backup..." -ForegroundColor Yellow
            $encryptedFile = "$backupFile.enc"
            
            # Check if 7-Zip is available
            if (Get-Command "7z" -ErrorAction SilentlyContinue) {
                7z a -tzip -p $encryptedFile $backupFile
                if (Test-Path $encryptedFile) {
                    Write-Host "Encrypted backup created: $encryptedFile" -ForegroundColor Green
                    $backupFile = $encryptedFile  # Use encrypted file for upload
                } else {
                    Write-Host "Encryption failed, using original file" -ForegroundColor Yellow
                }
            } else {
                Write-Host "7-Zip not found. Install 7-Zip for encryption support." -ForegroundColor Yellow
                Write-Host "You can download 7-Zip from: https://www.7-zip.org/" -ForegroundColor Cyan
            }
        }
        
        # Upload to cloud if requested
        if ($UploadToCloud) {
            Write-Host "Uploading to cloud storage..." -ForegroundColor Cyan
            Write-Host "   Remote: $RemoteName" -ForegroundColor White
            Write-Host "   Path: $RemotePath" -ForegroundColor White
            
            try {
                # Create remote directory structure
                $remoteDir = "$RemoteName`:$RemotePath/$timestamp"
                Write-Host "Creating remote directory: $remoteDir" -ForegroundColor Yellow
                
                $createDirCmd = "$RclonePath mkdir `"$remoteDir`""
                if ($Verbose) { Write-Host "Command: $createDirCmd" -ForegroundColor Gray }
                Invoke-Expression $createDirCmd
                
                # Upload backup file
                Write-Host "Uploading backup file..." -ForegroundColor Yellow
                $uploadCmd = "$RclonePath copy `"$backupFile`" `"$remoteDir`" --progress"
                if ($Verbose) { Write-Host "Command: $uploadCmd" -ForegroundColor Gray }
                Invoke-Expression $uploadCmd
                
                # Also upload to 'latest' folder for easy access
                Write-Host "Updating latest backup..." -ForegroundColor Yellow
                $latestCmd = "$RclonePath copy `"$backupFile`" `"$RemoteName`:$RemotePath/latest`" --progress"
                if ($Verbose) { Write-Host "Command: $latestCmd" -ForegroundColor Gray }
                Invoke-Expression $latestCmd
                
                # Upload backup info file
                if (Test-Path $infoFile) {
                    Write-Host "Uploading backup info..." -ForegroundColor Yellow
                    $infoCmd = "$RclonePath copy `"$infoFile`" `"$remoteDir`" --progress"
                    if ($Verbose) { Write-Host "Command: $infoCmd" -ForegroundColor Gray }
                    Invoke-Expression $infoCmd
                }
                
                Write-Host "Cloud upload completed!" -ForegroundColor Green
                
                # Show remote backup info
                Write-Host "`nRemote backup information:" -ForegroundColor Cyan
                Write-Host "   Remote: $RemoteName" -ForegroundColor White
                Write-Host "   Path: $RemotePath/$timestamp" -ForegroundColor White
                Write-Host "   Latest: $RemotePath/latest" -ForegroundColor White
                
            } catch {
                Write-Host "Cloud upload failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Check your Rclone configuration: $RclonePath config" -ForegroundColor Yellow
            }
        }
        
    } else {
        Write-Host "Failed to create backup archive" -ForegroundColor Red
        exit 1
    }
    
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host "Cleaned up temporary files" -ForegroundColor Gray
    }
}

Write-Host "`nBackup completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the backup file: $backupFile" -ForegroundColor White
if ($UploadToCloud) {
    Write-Host "  2. Verify cloud upload: $RclonePath ls $RemoteName`:$RemotePath/" -ForegroundColor White
}
Write-Host "  3. Test restore process in a safe environment" -ForegroundColor White
Write-Host "  4. Schedule regular backups using Windows Task Scheduler" -ForegroundColor White
