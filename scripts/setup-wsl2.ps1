#!/bin/bash
# WSL2 configuration script for Llama local server

# PowerShell script for WSL2 setup
# See guide for full script

# Configure WSL2 performance settings
$wslConfig = @"
[wsl2]
memory=24GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

# [interop] section is deprecated in modern WSL2 (Ubuntu 24.04+), but shown here for reference:
# [interop]
# enabled=true
# appendWindowsPath=false
"@

$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8

# Restart WSL2
wsl --shutdown
Start-Sleep 5
# IMPORTANT: Update the distribution name below to match your installed Ubuntu version.
# Run 'wsl -l -v' in PowerShell to see available distributions.
wsl -d Ubuntu-24.04
