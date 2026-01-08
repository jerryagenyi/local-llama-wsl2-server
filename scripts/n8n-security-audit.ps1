# n8n Security Audit Script for CVE-2026-21858 "Ni8mare"
# Comprehensive audit and hardening for n8n instances

param(
    [switch]$DryRun = $false,
    [switch]$BackupOnly = $false,
    [switch]$UpgradeOnly = $false
)

$ErrorActionPreference = "Continue"
$auditReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    instances = @()
    vulnerabilities = @()
    actions_taken = @()
    recommendations = @()
}

function Get-n8nVersion {
    param($ContainerName)
    
    try {
        # Try multiple methods to get version
        $version = docker exec $ContainerName sh -c "cat /usr/local/lib/node_modules/n8n/package.json 2>/dev/null | grep '\"version\"' | head -1 | cut -d'\"' -f4" 2>$null
        if (-not $version) {
            $version = docker exec $ContainerName sh -c "node -e 'console.log(require(\"/usr/local/lib/node_modules/n8n/package.json\").version)'" 2>$null
        }
        if (-not $version) {
            $version = "unknown"
        }
        return $version.Trim()
    } catch {
        return "unknown"
    }
}

function Test-VulnerableVersion {
    param($Version)
    
    if ($Version -eq "unknown" -or $Version -eq "") {
        return $true  # Assume vulnerable if we can't determine
    }
    
    # Parse version (e.g., "1.120.5" -> [1, 120, 5])
    $parts = $Version -split '\.'
    if ($parts.Count -lt 2) { return $true }
    
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    
    # Vulnerable if version < 1.121.0
    if ($major -lt 1) { return $true }
    if ($major -eq 1 -and $minor -lt 121) { return $true }
    
    return $false
}

function Get-ContainerExposure {
    param($ContainerName)
    
    $ports = docker port $ContainerName 2>$null
    $exposure = @{
        bound_to_all = $false
        exposed_ports = @()
        localhost_only = $false
    }
    
    if ($ports) {
        foreach ($port in $ports) {
            if ($port -match '0\.0\.0\.0') {
                $exposure.bound_to_all = $true
            }
            if ($port -match '127\.0\.0\.1|localhost') {
                $exposure.localhost_only = $true
            }
            $exposure.exposed_ports += $port
        }
    }
    
    return $exposure
}

function Get-n8nConfig {
    param($ContainerName)
    
    $config = @{
        has_auth = $false
        encryption_key_set = $false
        webhook_url = ""
        editor_base_url = ""
        protocol = "http"
    }
    
    $envVars = docker inspect $ContainerName --format '{{range .Config.Env}}{{println .}}{{end}}' 2>$null
    
    if ($envVars -match 'N8N_BASIC_AUTH') {
        $config.has_auth = $true
    }
    if ($envVars -match 'N8N_ENCRYPTION_KEY') {
        $config.encryption_key_set = $true
    }
    if ($envVars -match 'WEBHOOK_URL=([^\s]+)') {
        $config.webhook_url = $matches[1]
    }
    if ($envVars -match 'N8N_EDITOR_BASE_URL=([^\s]+)') {
        $config.editor_base_url = $matches[1]
    }
    if ($envVars -match 'N8N_PROTOCOL=([^\s]+)') {
        $config.protocol = $matches[1]
    }
    
    return $config
}

# Discovery Phase
Write-Host "=== n8n Security Audit: Discovery Phase ===" -ForegroundColor Cyan
Write-Host ""

# Find all n8n containers
$containers = docker ps -a --filter "ancestor=n8nio/n8n*" --format "{{.Names}}|{{.Image}}|{{.Status}}" 2>$null
$customContainers = docker ps -a --filter "name=n8n" --format "{{.Names}}|{{.Image}}|{{.Status}}" 2>$null

$allContainers = @()
if ($containers) { $allContainers += $containers }
if ($customContainers) { $allContainers += $customContainers }
$allContainers = $allContainers | Select-Object -Unique

if ($allContainers.Count -eq 0) {
    Write-Host "No n8n containers found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($allContainers.Count) n8n container(s):" -ForegroundColor Green
Write-Host ""

foreach ($containerInfo in $allContainers) {
    $parts = $containerInfo -split '\|'
    $name = $parts[0]
    $image = $parts[1]
    $status = $parts[2]
    
    Write-Host "  - $name ($image)" -ForegroundColor White
    
    $version = Get-n8nVersion -ContainerName $name
    $isVulnerable = Test-VulnerableVersion -Version $version
    $exposure = Get-ContainerExposure -ContainerName $name
    $config = Get-n8nConfig -ContainerName $name
    
    $instance = @{
        name = $name
        image = $image
        version = $version
        status = $status
        vulnerable = $isVulnerable
        exposure = $exposure
        config = $config
        host = $env:COMPUTERNAME
        environment = "production"  # TODO: Detect from context
    }
    
    $auditReport.instances += $instance
    
    $statusColor = if ($isVulnerable) { "Red" } else { "Green" }
    Write-Host "    Version: $version" -ForegroundColor $(if ($isVulnerable) { "Red" } else { "Green" })
    Write-Host "    Vulnerable: $isVulnerable" -ForegroundColor $statusColor
    Write-Host "    Exposed Ports: $($exposure.exposed_ports -join ', ')" -ForegroundColor Yellow
    Write-Host "    Bound to 0.0.0.0: $($exposure.bound_to_all)" -ForegroundColor $(if ($exposure.bound_to_all) { "Red" } else { "Green" })
    Write-Host "    Has Auth: $($config.has_auth)" -ForegroundColor $(if ($config.has_auth) { "Green" } else { "Red" })
    Write-Host "    Encryption Key Set: $($config.encryption_key_set)" -ForegroundColor $(if ($config.encryption_key_set) { "Green" } else { "Red" })
    Write-Host ""
    
    if ($isVulnerable) {
        $auditReport.vulnerabilities += @{
            instance = $name
            version = $version
            severity = "CRITICAL"
            cve = "CVE-2026-21858"
            description = "Unauthenticated RCE via webhook/form handling"
        }
    }
}

# Generate JSON report
$reportPath = "n8n-audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$auditReport | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8

Write-Host "=== Audit Report Saved: $reportPath ===" -ForegroundColor Cyan
Write-Host ""

# Summary
$vulnerableCount = ($auditReport.instances | Where-Object { $_.vulnerable }).Count
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "  Total Instances: $($auditReport.instances.Count)" -ForegroundColor White
Write-Host "  Vulnerable: $vulnerableCount" -ForegroundColor $(if ($vulnerableCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Secure: $($auditReport.instances.Count - $vulnerableCount)" -ForegroundColor Green
Write-Host ""

return $auditReport
