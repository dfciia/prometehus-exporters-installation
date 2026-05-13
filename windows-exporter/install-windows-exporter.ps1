<#
.SYNOPSIS
    Prometheus Windows Exporter Installer

.DESCRIPTION
    One-line installation script for Prometheus Windows Exporter.
    Downloads, installs, and configures Windows Exporter as a Windows Service.

.PARAMETER Version
    Specific version to install (e.g., "0.25.1"). Default: latest

.PARAMETER Port
    Port for the exporter to listen on. Default: 9182

.PARAMETER Collectors
    Comma-separated list of collectors to enable. Default: defaults

.PARAMETER Uninstall
    Uninstall Windows Exporter

.PARAMETER Help
    Show help message

.EXAMPLE
    # Install latest version
    irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

.EXAMPLE
    # Install specific version
    $env:VERSION="0.25.1"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

.EXAMPLE
    # Install with custom port
    $env:PORT="9183"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

.EXAMPLE
    # Uninstall
    $env:UNINSTALL="true"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

.NOTES
    Author: dfciia
    Repository: https://github.com/dfciia/prometehus-exporters-installation
#>

#Requires -RunAsAdministrator

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

# Read from environment variables (for one-liner usage)
$Version = if ($env:VERSION) { $env:VERSION } else { "latest" }
$Port = if ($env:PORT) { $env:PORT } else { "9182" }
$Collectors = if ($env:COLLECTORS) { $env:COLLECTORS } else { "" }
$Uninstall = if ($env:UNINSTALL -eq "true") { $true } else { $false }

# Installation paths
$InstallDir = "C:\Program Files\windows_exporter"
$ServiceName = "windows_exporter"
$ExeName = "windows_exporter.exe"
$GitHubRepo = "prometheus-community/windows_exporter"

# Clear environment variables after reading
$env:VERSION = $null
$env:PORT = $null
$env:COLLECTORS = $null
$env:UNINSTALL = $null

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Prometheus Windows Exporter Installer                  ║" -ForegroundColor Cyan
    Write-Host "║         https://github.com/prometheus-community/windows_exporter║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# -----------------------------------------------------------------------------
# Version Detection
# -----------------------------------------------------------------------------

function Get-LatestVersion {
    Write-Info "Fetching latest version from GitHub..."
    
    try {
        $releaseUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
        $response = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
        $latestVersion = $response.tag_name -replace '^v', ''
        Write-Info "Latest version: $latestVersion"
        return $latestVersion
    }
    catch {
        Write-Warning "Could not fetch latest version, using fallback: 0.25.1"
        return "0.25.1"
    }
}

function Get-Architecture {
    $arch = [System.Environment]::Is64BitOperatingSystem
    if ($arch) {
        return "amd64"
    }
    else {
        return "386"
    }
}

# -----------------------------------------------------------------------------
# Download and Install
# -----------------------------------------------------------------------------

function Get-WindowsExporter {
    param(
        [string]$Version
    )
    
    if ($Version -eq "latest") {
        $Version = Get-LatestVersion
    }
    
    $arch = Get-Architecture
    Write-Info "Architecture: $arch"
    
    # Construct download URL
    $fileName = "windows_exporter-$Version-$arch.msi"
    $downloadUrl = "https://github.com/$GitHubRepo/releases/download/v$Version/$fileName"
    
    Write-Info "Downloading from: $downloadUrl"
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "windows_exporter_install"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    $msiPath = Join-Path $tempDir $fileName
    
    try {
        # Download MSI
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        Write-Success "Downloaded successfully"
        return @{
            MsiPath = $msiPath
            Version = $Version
            TempDir = $tempDir
        }
    }
    catch {
        Write-Error "Failed to download: $_"
        throw
    }
}

function Install-WindowsExporter {
    param(
        [string]$MsiPath,
        [string]$Port,
        [string]$Collectors
    )
    
    Write-Info "Installing Windows Exporter..."
    
    # Build MSI arguments
    $msiArgs = @(
        "/i"
        "`"$MsiPath`""
        "/qn"
        "/norestart"
        "LISTEN_PORT=$Port"
    )
    
    # Add collectors if specified
    if ($Collectors) {
        $msiArgs += "ENABLED_COLLECTORS=$Collectors"
    }
    
    $msiArgs += "EXTRA_FLAGS=`"--log.format logger:eventlog?name=windows_exporter`""
    
    Write-Info "Running: msiexec $($msiArgs -join ' ')"
    
    # Run MSI installer
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Success "Installation completed successfully"
        return $true
    }
    elseif ($process.ExitCode -eq 3010) {
        Write-Success "Installation completed (reboot recommended)"
        return $true
    }
    else {
        Write-Error "Installation failed with exit code: $($process.ExitCode)"
        return $false
    }
}

# -----------------------------------------------------------------------------
# Service Management
# -----------------------------------------------------------------------------

function Test-ServiceExists {
    param([string]$Name)
    
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    return $null -ne $service
}

function Start-ExporterService {
    Write-Info "Starting $ServiceName service..."
    
    if (Test-ServiceExists -Name $ServiceName) {
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq "Running") {
            Write-Success "Service started successfully"
            return $true
        }
        else {
            Write-Warning "Service status: $($service.Status)"
            return $false
        }
    }
    else {
        Write-Warning "Service not found"
        return $false
    }
}

function Stop-ExporterService {
    Write-Info "Stopping $ServiceName service..."
    
    if (Test-ServiceExists -Name $ServiceName) {
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq "Running") {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        Write-Success "Service stopped"
    }
}

# -----------------------------------------------------------------------------
# Firewall Configuration
# -----------------------------------------------------------------------------

function Set-FirewallRule {
    param([string]$Port)
    
    Write-Info "Configuring firewall for port $Port..."
    
    $ruleName = "Prometheus Windows Exporter"
    
    # Remove existing rule if present
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existingRule) {
        Remove-NetFirewallRule -DisplayName $ruleName
    }
    
    # Create new rule
    try {
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $Port `
            -Action Allow `
            -Profile Any `
            -Description "Allow Prometheus to scrape Windows Exporter metrics" | Out-Null
        
        Write-Success "Firewall rule created for port $Port"
    }
    catch {
        Write-Warning "Could not create firewall rule: $_"
    }
}

function Remove-FirewallRule {
    $ruleName = "Prometheus Windows Exporter"
    
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existingRule) {
        Remove-NetFirewallRule -DisplayName $ruleName
        Write-Success "Firewall rule removed"
    }
}

# -----------------------------------------------------------------------------
# Uninstall
# -----------------------------------------------------------------------------

function Uninstall-WindowsExporter {
    Write-Info "Uninstalling Windows Exporter..."
    
    # Stop service
    Stop-ExporterService
    
    # Find and uninstall MSI
    $product = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*windows_exporter*" }
    
    if ($product) {
        Write-Info "Removing installed product: $($product.Name)"
        $product.Uninstall() | Out-Null
        Write-Success "Windows Exporter uninstalled"
    }
    else {
        # Try alternative uninstall method
        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        $found = $false
        foreach ($key in $uninstallKeys) {
            $products = Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*windows_exporter*" }
            foreach ($p in $products) {
                if ($p.UninstallString) {
                    Write-Info "Running uninstaller..."
                    $uninstallCmd = $p.UninstallString -replace "msiexec.exe", "" -replace "/I", "/X"
                    Start-Process "msiexec.exe" -ArgumentList "$uninstallCmd /qn /norestart" -Wait -NoNewWindow
                    $found = $true
                }
            }
        }
        
        if (-not $found) {
            Write-Warning "No installation found to uninstall"
        }
    }
    
    # Remove firewall rule
    Remove-FirewallRule
    
    # Clean up installation directory
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Removed installation directory"
    }
    
    Write-Success "Uninstallation complete"
}

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

function Test-Installation {
    param([string]$Port)
    
    Write-Host ""
    Write-Info "Verifying installation..."
    
    # Check service
    if (Test-ServiceExists -Name $ServiceName) {
        $service = Get-Service -Name $ServiceName
        Write-Success "Service exists: $ServiceName (Status: $($service.Status))"
    }
    else {
        Write-Warning "Service not found"
    }
    
    # Check port
    Start-Sleep -Seconds 2
    $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($listening) {
        Write-Success "Port $Port is listening"
    }
    else {
        Write-Warning "Port $Port is not listening yet"
    }
    
    # Test metrics endpoint
    Write-Info "Testing metrics endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/metrics" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "Metrics endpoint is accessible"
            
            # Show build info
            $buildInfo = $response.Content -split "`n" | Where-Object { $_ -match "windows_exporter_build_info" } | Select-Object -First 1
            if ($buildInfo) {
                Write-Host "  $buildInfo" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Warning "Could not reach metrics endpoint yet. It may take a moment to start."
    }
}

function Write-Summary {
    param([string]$Port)
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "           Installation Complete!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Windows Exporter is now running on port $Port"
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  - Check status:    Get-Service $ServiceName"
    Write-Host "  - Start service:   Start-Service $ServiceName"
    Write-Host "  - Stop service:    Stop-Service $ServiceName"
    Write-Host "  - Restart service: Restart-Service $ServiceName"
    Write-Host "  - View logs:       Get-EventLog -LogName Application -Source $ServiceName -Newest 20"
    Write-Host "  - Test metrics:    Invoke-WebRequest http://localhost:$Port/metrics"
    Write-Host ""
    Write-Host "Add this target to your Prometheus configuration:" -ForegroundColor Cyan
    Write-Host "  scrape_configs:"
    Write-Host "    - job_name: 'windows'"
    Write-Host "      static_configs:"
    Write-Host "        - targets: ['<this-server-ip>:$Port']"
    Write-Host ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

function Main {
    Write-Banner
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        Write-Host "Please run PowerShell as Administrator and try again."
        exit 1
    }
    
    Write-Info "Running as Administrator"
    
    # Handle uninstall
    if ($Uninstall) {
        Uninstall-WindowsExporter
        exit 0
    }
    
    # Check if already installed
    if (Test-ServiceExists -Name $ServiceName) {
        $service = Get-Service -Name $ServiceName
        Write-Warning "Windows Exporter is already installed (Status: $($service.Status))"
        Write-Host ""
        $response = Read-Host "Do you want to reinstall? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Installation cancelled"
            exit 0
        }
        
        # Stop and uninstall existing
        Uninstall-WindowsExporter
        Write-Host ""
    }
    
    try {
        # Download
        $downloadResult = Get-WindowsExporter -Version $Version
        
        # Install
        $installSuccess = Install-WindowsExporter -MsiPath $downloadResult.MsiPath -Port $Port -Collectors $Collectors
        
        if ($installSuccess) {
            # Configure firewall
            Set-FirewallRule -Port $Port
            
            # Verify installation
            Test-Installation -Port $Port
            
            # Show summary
            Write-Summary -Port $Port
        }
        
        # Cleanup
        if (Test-Path $downloadResult.TempDir) {
            Remove-Item -Path $downloadResult.TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Installation failed: $_"
        exit 1
    }
}

# Run main function
Main
