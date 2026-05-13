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
    
    # Build MSI arguments - simpler configuration to avoid startup issues
    $msiArgs = @(
        "/i"
        "`"$MsiPath`""
        "/qn"
        "/norestart"
        "/l*v"
        "`"$env:TEMP\windows_exporter_install.log`""
        "LISTEN_PORT=$Port"
    )
    
    # Add collectors if specified
    if ($Collectors) {
        $msiArgs += "ENABLED_COLLECTORS=$Collectors"
    }
    
    # Note: Removed eventlog flag as it can cause startup issues
    # The service will log to stdout/stderr by default
    
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
        Write-Warning "MSI installation returned exit code: $($process.ExitCode)"
        Write-Info "Checking install log at: $env:TEMP\windows_exporter_install.log"
        
        # Try to show relevant log entries
        if (Test-Path "$env:TEMP\windows_exporter_install.log") {
            $logContent = Get-Content "$env:TEMP\windows_exporter_install.log" -Tail 20
            Write-Host "Last 20 lines of install log:" -ForegroundColor Yellow
            $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
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
        try {
            Start-Service -Name $ServiceName -ErrorAction Stop
            Start-Sleep -Seconds 3
            
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
        catch {
            Write-Warning "Failed to start service: $_"
            
            # Show diagnostic information
            Write-Info "Diagnosing the issue..."
            
            # Check service configuration
            $svcConfig = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
            if ($svcConfig) {
                Write-Host "  Service Path: $($svcConfig.PathName)" -ForegroundColor Gray
                Write-Host "  Start Mode: $($svcConfig.StartMode)" -ForegroundColor Gray
                Write-Host "  State: $($svcConfig.State)" -ForegroundColor Gray
            }
            
            # Check if exe exists
            $exePath = "C:\Program Files\windows_exporter\windows_exporter.exe"
            if (Test-Path $exePath) {
                Write-Host "  Executable exists: Yes" -ForegroundColor Gray
            }
            else {
                Write-Host "  Executable exists: No - This is the problem!" -ForegroundColor Red
            }
            
            # Check for port conflicts
            $portInUse = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
            if ($portInUse) {
                Write-Host "  Port $Port is already in use by PID: $($portInUse.OwningProcess)" -ForegroundColor Red
            }
            
            # Try to get Windows Event Log errors
            try {
                $events = Get-EventLog -LogName Application -Source "windows_exporter" -Newest 5 -ErrorAction SilentlyContinue
                if ($events) {
                    Write-Host "  Recent Event Log entries:" -ForegroundColor Yellow
                    $events | ForEach-Object { Write-Host "    $($_.Message)" -ForegroundColor Gray }
                }
            }
            catch { }
            
            return $false
        }
    }
    else {
        Write-Warning "Service not found - attempting manual service creation..."
        return Install-ServiceManually
    }
}

function Install-ServiceManually {
    Write-Info "Creating service manually..."
    
    $exePath = "C:\Program Files\windows_exporter\windows_exporter.exe"
    
    # Check if exe exists, if not download it
    if (-not (Test-Path $exePath)) {
        Write-Warning "Executable not found, downloading..."
        
        $version = Get-LatestVersion
        $arch = Get-Architecture
        $downloadUrl = "https://github.com/$GitHubRepo/releases/download/v$version/windows_exporter-$version-$arch.exe"
        
        # Create directory
        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }
        
        # Download exe directly
        Write-Info "Downloading from: $downloadUrl"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (-not (Test-Path $exePath)) {
            Write-Error "Failed to download executable"
            return $false
        }
        Write-Success "Downloaded executable"
    }
    
    # Remove existing service if it exists but is broken
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Info "Removing broken service..."
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $ServiceName | Out-Null
        Start-Sleep -Seconds 2
    }
    
    # Create new service with simple configuration
    Write-Info "Creating Windows service..."
    $binPath = "`"$exePath`" --web.listen-address=:$Port"
    
    $result = sc.exe create $ServiceName binPath= $binPath start= auto displayname= "Prometheus Windows Exporter"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create service: $result"
        return $false
    }
    
    # Set description
    sc.exe description $ServiceName "Prometheus exporter for Windows machines" | Out-Null
    
    # Set recovery options
    sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
    
    Write-Success "Service created successfully"
    
    # Start the service
    Write-Info "Starting service..."
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Success "Service is now running"
        return $true
    }
    else {
        Write-Warning "Service created but not running. Status: $($service.Status)"
        Write-Host "Try running manually: & `"$exePath`"" -ForegroundColor Yellow
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
    
    # Stop service first
    Stop-ExporterService
    
    # Try to remove service directly (works for manual installations)
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Info "Removing service..."
        sc.exe delete $ServiceName | Out-Null
        Start-Sleep -Seconds 2
    }
    
    # Find and uninstall MSI if installed via MSI
    $product = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*windows_exporter*" }
    
    if ($product) {
        Write-Info "Removing installed product: $($product.Name)"
        $product.Uninstall() | Out-Null
        Write-Success "Windows Exporter MSI uninstalled"
    }
    else {
        # Try alternative uninstall method via registry
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
        
        # Install via MSI
        $installSuccess = Install-WindowsExporter -MsiPath $downloadResult.MsiPath -Port $Port -Collectors $Collectors
        
        # Configure firewall (do this regardless)
        Set-FirewallRule -Port $Port
        
        if ($installSuccess) {
            # Try to start the service
            $serviceStarted = Start-ExporterService
            
            if ($serviceStarted) {
                # Verify installation
                Test-Installation -Port $Port
                
                # Show summary
                Write-Summary -Port $Port
            }
            else {
                Write-Warning "Service did not start. The installation may need manual intervention."
                Write-Host ""
                Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
                Write-Host "  1. Check service status: Get-Service windows_exporter"
                Write-Host "  2. Check for port conflicts: Get-NetTCPConnection -LocalPort $Port"
                Write-Host "  3. Try starting manually: Start-Service windows_exporter"
                Write-Host "  4. Check event log: Get-EventLog -LogName Application -Newest 20 | Where-Object {`$_.Source -like '*windows*'}"
                Write-Host ""
            }
        }
        else {
            Write-Warning "MSI installation had issues. Attempting fallback installation..."
            
            # Try manual/exe-based installation as fallback
            $manualSuccess = Install-ServiceManually
            
            if ($manualSuccess) {
                Test-Installation -Port $Port
                Write-Summary -Port $Port
            }
            else {
                Write-Error "Installation failed. Please check the logs above for details."
            }
        }
        
        # Cleanup
        if ($downloadResult.TempDir -and (Test-Path $downloadResult.TempDir)) {
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
