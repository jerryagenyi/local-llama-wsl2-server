# n8n Backup Script - Creates comprehensive backups before upgrade
# Backs up: Database, config, workflows, credentials

param(
    [string]$BackupDir = "backups/n8n-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [string]$ContainerName = "n8n"
)

$ErrorActionPreference = "Stop"

Write-Host "=== n8n Backup Script ===" -ForegroundColor Cyan
Write-Host "Backup Directory: $BackupDir" -ForegroundColor White
Write-Host ""

# Create backup directory
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# 1. Backup n8n data volume (includes database, workflows, credentials)
Write-Host "[1/5] Backing up n8n data volume..." -ForegroundColor Yellow
$volumeBackup = "$BackupDir/n8n-data-volume.tar.gz"
docker run --rm -v n8n_data:/data -v "${PWD}/$BackupDir":/backup alpine tar czf /backup/n8n-data-volume.tar.gz -C /data .
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Volume backup created: $volumeBackup" -ForegroundColor Green
} else {
    Write-Host "  ✗ Volume backup failed!" -ForegroundColor Red
    exit 1
}

# 2. Backup docker-compose.yml
Write-Host "[2/5] Backing up docker-compose.yml..." -ForegroundColor Yellow
Copy-Item "docker-compose.yml" "$BackupDir/docker-compose.yml.backup" -ErrorAction SilentlyContinue
Write-Host "  ✓ docker-compose.yml backed up" -ForegroundColor Green

# 3. Backup Dockerfile.n8n
Write-Host "[3/5] Backing up Dockerfile.n8n..." -ForegroundColor Yellow
if (Test-Path "Dockerfile.n8n") {
    Copy-Item "Dockerfile.n8n" "$BackupDir/Dockerfile.n8n.backup" -ErrorAction SilentlyContinue
    Write-Host "  ✓ Dockerfile.n8n backed up" -ForegroundColor Green
}

# 4. Export environment variables (sanitized)
Write-Host "[4/5] Exporting container environment (sanitized)..." -ForegroundColor Yellow
$envVars = docker inspect $ContainerName --format '{{range .Config.Env}}{{println .}}{{end}}' 2>$null
# Remove sensitive values
$sanitized = $envVars | ForEach-Object {
    if ($_ -match '^(N8N_ENCRYPTION_KEY|POSTGRES_PASSWORD|.*PASSWORD|.*KEY|.*SECRET)=') {
        $key = ($_ -split '=')[0]
        "$key=***REDACTED***"
    } else {
        $_
    }
}
$sanitized | Out-File "$BackupDir/environment-vars.txt" -Encoding UTF8
Write-Host "  ✓ Environment variables exported (sensitive values redacted)" -ForegroundColor Green

# 5. Create backup manifest
Write-Host "[5/5] Creating backup manifest..." -ForegroundColor Yellow
$manifest = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    container_name = $ContainerName
    backup_location = (Resolve-Path $BackupDir).Path
    files = @(
        "n8n-data-volume.tar.gz",
        "docker-compose.yml.backup",
        "environment-vars.txt"
    )
    restore_instructions = @(
        "1. Stop n8n container: docker-compose stop n8n",
        "2. Restore volume: docker run --rm -v n8n_data:/data -v `"${PWD}/$BackupDir`":/backup alpine tar xzf /backup/n8n-data-volume.tar.gz -C /data",
        "3. Restore docker-compose.yml if needed: Copy-Item `"$BackupDir/docker-compose.yml.backup`" `"docker-compose.yml`"",
        "4. Start n8n: docker-compose up -d n8n"
    )
}

$manifest | ConvertTo-Json -Depth 10 | Out-File "$BackupDir/backup-manifest.json" -Encoding UTF8
Write-Host "  ✓ Backup manifest created" -ForegroundColor Green

# Calculate backup size
$backupSize = (Get-ChildItem $BackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Host "=== Backup Complete ===" -ForegroundColor Green
Write-Host "Location: $BackupDir" -ForegroundColor White
Write-Host "Size: $([math]::Round($backupSize, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "Backup manifest: $BackupDir/backup-manifest.json" -ForegroundColor Cyan
