# n8n Security Hardening Script
# Applies security best practices to n8n instances

param(
    [switch]$DryRun = $false,
    [string]$ContainerName = "n8n"
)

$ErrorActionPreference = "Continue"

Write-Host "=== n8n Security Hardening Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as dry-run
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# 1. Check current configuration
Write-Host "[1/6] Analyzing current configuration..." -ForegroundColor Yellow

$composeFile = "docker-compose.yml"
if (-not (Test-Path $composeFile)) {
    Write-Host "  ✗ docker-compose.yml not found!" -ForegroundColor Red
    exit 1
}

$composeContent = Get-Content $composeFile -Raw
$needsUpdate = $false
$changes = @()

# Check N8N_HOST binding
if ($composeContent -match 'N8N_HOST=0\.0\.0\.0') {
    Write-Host "  ⚠ N8N_HOST is bound to 0.0.0.0 (all interfaces)" -ForegroundColor Red
    $needsUpdate = $true
    $changes += "Change N8N_HOST from 0.0.0.0 to 127.0.0.1"
} else {
    Write-Host "  ✓ N8N_HOST is properly configured" -ForegroundColor Green
}

# Check for authentication
if ($composeContent -notmatch 'N8N_BASIC_AUTH') {
    Write-Host "  ⚠ Basic authentication not configured" -ForegroundColor Red
    $needsUpdate = $true
    $changes += "Add N8N_BASIC_AUTH_USER and N8N_BASIC_AUTH_PASSWORD"
} else {
    Write-Host "  ✓ Basic authentication configured" -ForegroundColor Green
}

# Check protocol
if ($composeContent -match 'N8N_PROTOCOL=http') {
    Write-Host "  ⚠ Using HTTP protocol (HTTPS should be enforced at proxy)" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ Protocol configuration OK" -ForegroundColor Green
}

Write-Host ""

# 2. Display recommended changes
if ($needsUpdate) {
    Write-Host "[2/6] Recommended Changes:" -ForegroundColor Yellow
    foreach ($change in $changes) {
        Write-Host "  - $change" -ForegroundColor White
    }
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would apply the above changes" -ForegroundColor Yellow
        exit 0
    }
    
    # 3. Create backup before changes
    Write-Host "[3/6] Creating backup before changes..." -ForegroundColor Yellow
    $backupScript = "scripts/n8n-backup.ps1"
    if (Test-Path $backupScript) {
        & $backupScript
        Write-Host "  ✓ Backup completed" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Backup script not found, proceeding anyway" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # 4. Apply hardening changes
    Write-Host "[4/6] Applying security hardening..." -ForegroundColor Yellow
    
    # Read current compose file
    $lines = Get-Content $composeFile
    
    $newLines = @()
    $inN8nEnv = $false
    
    foreach ($line in $lines) {
        if ($line -match '^\s+environment:') {
            $inN8nEnv = $true
            $newLines += $line
        } elseif ($inN8nEnv -and $line -match '^\s+- N8N_HOST=0\.0\.0\.0') {
            $newLines += $line -replace 'N8N_HOST=0\.0\.0\.0', 'N8N_HOST=127.0.0.1'
            Write-Host "  ✓ Changed N8N_HOST to 127.0.0.1" -ForegroundColor Green
        } elseif ($inN8nEnv -and $line -match '^\s+- N8N_ENCRYPTION_KEY') {
            # Add basic auth after encryption key if not present
            $newLines += $line
            if ($composeContent -notmatch 'N8N_BASIC_AUTH_USER') {
                $newLines += "      - N8N_BASIC_AUTH_USER=`${N8N_BASIC_AUTH_USER}"
                $newLines += "      - N8N_BASIC_AUTH_PASSWORD=`${N8N_BASIC_AUTH_PASSWORD}"
                Write-Host "  ✓ Added basic authentication variables" -ForegroundColor Green
            }
        } elseif ($inN8nEnv -and $line -match '^\s+[a-zA-Z]' -and $line -notmatch '^\s+-') {
            $inN8nEnv = $false
            $newLines += $line
        } else {
            $newLines += $line
        }
    }
    
    # Write updated compose file
    $newLines | Set-Content $composeFile -Encoding UTF8
    Write-Host "  ✓ docker-compose.yml updated" -ForegroundColor Green
    Write-Host ""
    
    # 5. Check .env file
    Write-Host "[5/6] Checking .env file for required variables..." -ForegroundColor Yellow
    $envFile = ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile -Raw
        $envNeedsUpdate = $false
        
        if ($envContent -notmatch 'N8N_BASIC_AUTH_USER') {
            Write-Host "  ⚠ N8N_BASIC_AUTH_USER not found in .env" -ForegroundColor Yellow
            $envNeedsUpdate = $true
        }
        if ($envContent -notmatch 'N8N_BASIC_AUTH_PASSWORD') {
            Write-Host "  ⚠ N8N_BASIC_AUTH_PASSWORD not found in .env" -ForegroundColor Yellow
            $envNeedsUpdate = $true
        }
        
        if ($envNeedsUpdate) {
            Write-Host "  ⚠ Please add the following to your .env file:" -ForegroundColor Yellow
            Write-Host "    N8N_BASIC_AUTH_USER=your_username" -ForegroundColor White
            Write-Host "    N8N_BASIC_AUTH_PASSWORD=your_secure_password" -ForegroundColor White
        } else {
            Write-Host "  ✓ .env file has required variables" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠ .env file not found - create one with:" -ForegroundColor Yellow
        Write-Host "    N8N_BASIC_AUTH_USER=your_username" -ForegroundColor White
        Write-Host "    N8N_BASIC_AUTH_PASSWORD=your_secure_password" -ForegroundColor White
    }
    Write-Host ""
    
    # 6. Instructions for restart
    Write-Host "[6/6] Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Update .env file with authentication credentials" -ForegroundColor White
    Write-Host "  2. Restart n8n container:" -ForegroundColor White
    Write-Host "     docker-compose up -d n8n" -ForegroundColor Cyan
    Write-Host "  3. Verify changes:" -ForegroundColor White
    Write-Host "     docker exec n8n sh -c 'echo \$N8N_HOST'" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "  ✓ No hardening changes needed - configuration is secure" -ForegroundColor Green
    Write-Host ""
}

Write-Host "=== Hardening Complete ===" -ForegroundColor Green
