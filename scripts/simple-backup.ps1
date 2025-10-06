# Simple Docker Volumes Backup Script
Write-Host "Starting Docker Volumes Backup..." -ForegroundColor Green

# Create backup directory
$backupDir = ".\backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$backupFile = "$backupDir\docker-volumes-$timestamp.tar.gz"

Write-Host "Backup file: $backupFile" -ForegroundColor Cyan

# Create temporary directory
$tempDir = "$env:TEMP\docker-backup-$timestamp"
New-Item -ItemType Directory -Path $tempDir -Force

try {
    # Backup each volume
    $volumes = @(
        "local-llama-wsl2-server_agent_zero_data",
        "local-llama-wsl2-server_flowise_data", 
        "local-llama-wsl2-server_n8n_data",
        "local-llama-wsl2-server_postgres_data"
    )
    
    foreach ($volume in $volumes) {
        Write-Host "Backing up $volume..." -ForegroundColor Yellow
        docker run --rm -v "${volume}:/source" -v "${tempDir}:/backup" alpine sh -c "cp -r /source/* /backup/$volume/ 2>/dev/null || mkdir -p /backup/$volume"
    }
    
    # Create compressed archive
    Write-Host "Creating compressed archive..." -ForegroundColor Yellow
    tar -czf $backupFile -C $tempDir .
    
    if (Test-Path $backupFile) {
        $size = (Get-Item $backupFile).Length / 1MB
        Write-Host "Backup created successfully!" -ForegroundColor Green
        Write-Host "Location: $backupFile" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    } else {
        Write-Host "Failed to create backup!" -ForegroundColor Red
    }
    
} finally {
    # Clean up
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Backup completed!" -ForegroundColor Green
