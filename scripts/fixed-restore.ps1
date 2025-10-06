# Fixed Enhanced Docker Volumes Restore Script with Rclone Integration
param(
    [string]$BackupFile,
    [string]$RemoteName = "gdrive",
    [string]$RemotePath = "container-volumes-backup-rclone",
    [string]$BackupDate = "latest",
    [string]$RclonePath = "C:\rclone\rclone.exe",
    [string]$LocalPath = ".\restored-backups",
    [switch]$FromCloud,
    [switch]$Force,
    [switch]$Verbose
)

Write-Host "Starting Enhanced Docker Volumes Restore..." -ForegroundColor Green

# Check if Rclone is available for cloud operations
if ($FromCloud -and -not (Test-Path $RclonePath)) {
    Write-Host "Rclone not found at $RclonePath" -ForegroundColor Red
    Write-Host "Please install Rclone or update the RclonePath parameter" -ForegroundColor Yellow
    exit 1
}

# Create local restore directory
if (-not (Test-Path $LocalPath)) {
    New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
    Write-Host "Created restore directory: $LocalPath" -ForegroundColor Yellow
}

# Define volumes to restore
$volumes = @(
    "local-llama-wsl2-server_agent_zero_data",
    "local-llama-wsl2-server_flowise_data", 
    "local-llama-wsl2-server_n8n_data",
    "local-llama-wsl2-server_postgres_data"
)

# Handle cloud download
if ($FromCloud) {
    Write-Host "Downloading from cloud storage..." -ForegroundColor Cyan
    Write-Host "   Remote: $RemoteName" -ForegroundColor White
    Write-Host "   Path: $RemotePath" -ForegroundColor White
    Write-Host "   Date: $BackupDate" -ForegroundColor White
    
    try {
        # List available backups
        Write-Host "Available backups:" -ForegroundColor Yellow
        $listCmd = "$RclonePath ls $RemoteName`:$RemotePath/"
        if ($Verbose) { Write-Host "Command: $listCmd" -ForegroundColor Gray }
        Invoke-Expression $listCmd
        
        # Download backup from cloud
        if ($BackupDate -eq "latest") {
            $remoteFile = "$RemoteName`:$RemotePath/latest/"
        } else {
            $remoteFile = "$RemoteName`:$RemotePath/$BackupDate/"
        }
        
        Write-Host "Downloading from $remoteFile..." -ForegroundColor Yellow
        $downloadCmd = "$RclonePath copy `"$remoteFile`" `"$LocalPath`" --progress"
        if ($Verbose) { Write-Host "Command: $downloadCmd" -ForegroundColor Gray }
        Invoke-Expression $downloadCmd
        
        # Find the downloaded backup file
        $downloadedFile = Get-ChildItem -Path $LocalPath -Filter "docker-volumes-*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($downloadedFile) {
            $BackupFile = $downloadedFile.FullName
            Write-Host "Downloaded: $($downloadedFile.Name)" -ForegroundColor Green
        } else {
            Write-Host "No backup file found in download" -ForegroundColor Red
            exit 1
        }
        
    } catch {
        Write-Host "Cloud download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check your Rclone configuration: $RclonePath config" -ForegroundColor Yellow
        exit 1
    }
}

# Check if backup file exists
if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
    Write-Host "Backup file not found: $BackupFile" -ForegroundColor Red
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host "   Local: .\fixed-restore.ps1 -BackupFile '.\backups\docker-volumes-2024-01-15-1430.tar.gz'" -ForegroundColor White
    Write-Host "   Cloud: .\fixed-restore.ps1 -FromCloud -BackupDate '2024-01-15-1430'" -ForegroundColor White
    Write-Host "   Latest: .\fixed-restore.ps1 -FromCloud -BackupDate 'latest'" -ForegroundColor White
    exit 1
}

Write-Host "Backup file: $BackupFile" -ForegroundColor Cyan
$fileSize = (Get-Item $BackupFile).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-Host "Size: $fileSizeMB MB" -ForegroundColor Cyan

# Check if volumes exist
Write-Host "Checking existing volumes..." -ForegroundColor Yellow
$existingVolumes = @()
foreach ($volume in $volumes) {
    $volumeExists = docker volume inspect $volume 2>$null
    if ($LASTEXITCODE -eq 0) {
        $existingVolumes += $volume
        Write-Host "  Warning: $volume already exists" -ForegroundColor Yellow
    } else {
        Write-Host "  OK: $volume will be created" -ForegroundColor Green
    }
}

if ($existingVolumes.Count -gt 0 -and -not $Force) {
    Write-Host "Warning: Some volumes already exist!" -ForegroundColor Red
    Write-Host "Existing volumes: $($existingVolumes -join ', ')" -ForegroundColor Red
    Write-Host "Use -Force flag to overwrite existing volumes" -ForegroundColor Yellow
    Write-Host "Example: .\fixed-restore.ps1 -BackupFile '$BackupFile' -Force" -ForegroundColor Cyan
    exit 1
}

if ($Force -and $existingVolumes.Count -gt 0) {
    Write-Host "Removing existing volumes..." -ForegroundColor Yellow
    foreach ($volume in $existingVolumes) {
        docker volume rm $volume
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Removed $volume" -ForegroundColor Green
        } else {
            Write-Host "  Failed to remove $volume" -ForegroundColor Red
        }
    }
}

# Create temporary directory for extraction
$tempDir = "$env:TEMP\docker-restore-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "Extracting backup..." -ForegroundColor Yellow
    $extractCommand = "tar -xzf `"$BackupFile`" -C `"$tempDir`""
    if ($Verbose) { Write-Host "Command: $extractCommand" -ForegroundColor Gray }
    Invoke-Expression $extractCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to extract backup file" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Backup extracted successfully" -ForegroundColor Green
    
    # Restore each volume
    foreach ($volume in $volumes) {
        Write-Host "Restoring $volume..." -ForegroundColor Yellow
        
        # Create volume if it doesn't exist
        docker volume create $volume | Out-Null
        
        # Copy data to volume
        $sourcePath = Join-Path $tempDir $volume
        if (Test-Path $sourcePath) {
            docker run --rm -v "${volume}:/target" -v "${sourcePath}:/source" alpine sh -c "cp -r /source/* /target/ 2>/dev/null || echo 'No data to copy'"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Success: $volume restored" -ForegroundColor Green
            } else {
                Write-Host "Warning: $volume restore completed with warnings" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Warning: No data found for $volume in backup" -ForegroundColor Yellow
        }
    }
    
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host "Cleaned up temporary files" -ForegroundColor Gray
    }
}

Write-Host "`nRestore completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Start your Docker Compose services: docker-compose up -d" -ForegroundColor White
Write-Host "  2. Verify data integrity" -ForegroundColor White
Write-Host "  3. Test application functionality" -ForegroundColor White
Write-Host "  4. Check logs: docker-compose logs" -ForegroundColor White
