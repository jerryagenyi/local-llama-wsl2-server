# Setup script to populate Agent Zero MCP config with environment variables
# This replaces placeholders in the config file with actual values from .env

param(
    [string]$ConfigFile = "config/agent-zero/agentzero-mcp-config.json",
    [string]$ExampleFile = "config/agent-zero/agentzero-mcp-config.json.example"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Agent Zero MCP Config Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠ .env file not found!" -ForegroundColor Yellow
    Write-Host "Please create a .env file with the following variables:" -ForegroundColor White
    Write-Host "  GITHUB_PERSONAL_ACCESS_TOKEN=your_token" -ForegroundColor Cyan
    Write-Host "  BRAVE_API_KEY=your_key" -ForegroundColor Cyan
    Write-Host "  SERPAPI_TOKEN=your_token" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Load .env file
Write-Host "[1/3] Loading environment variables from .env..." -ForegroundColor Yellow
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $envVars[$key] = $value
    }
}

# Check if config file exists, if not copy from example
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[2/3] Config file not found, copying from example..." -ForegroundColor Yellow
    if (Test-Path $ExampleFile) {
        Copy-Item $ExampleFile $ConfigFile
        Write-Host "  ✓ Copied from example" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Example file not found!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[2/3] Config file found" -ForegroundColor Green
}

# Read config file
Write-Host "[3/3] Substituting environment variables..." -ForegroundColor Yellow
$configContent = Get-Content $ConfigFile -Raw

# Replace environment variable placeholders
$replacements = @{
    '\$\{GITHUB_PERSONAL_ACCESS_TOKEN\}' = $envVars['GITHUB_PERSONAL_ACCESS_TOKEN']
    '\$\{BRAVE_API_KEY\}' = $envVars['BRAVE_API_KEY']
    '\$\{SERPAPI_TOKEN\}' = $envVars['SERPAPI_TOKEN']
}

foreach ($placeholder in $replacements.Keys) {
    $value = $replacements[$placeholder]
    if ($value) {
        $configContent = $configContent -replace $placeholder, $value
        Write-Host "  ✓ Replaced $placeholder" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $placeholder not found in .env, leaving as placeholder" -ForegroundColor Yellow
    }
}

# Write updated config
$configContent | Set-Content $ConfigFile -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "Config file: $ConfigFile" -ForegroundColor White
Write-Host ""
Write-Host "⚠ Remember: Do NOT commit this file if it contains actual secrets!" -ForegroundColor Yellow
Write-Host "   Add to .gitignore if needed." -ForegroundColor Yellow
