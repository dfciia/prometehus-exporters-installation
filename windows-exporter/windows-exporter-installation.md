# Prometheus Windows Exporter Installation Guide

This document provides step-by-step instructions for installing Prometheus Windows Exporter on Windows Server and Windows Desktop systems.

---

## Quick Install (One-Line Command)

Install Windows Exporter instantly using our installation script (run as Administrator):

```powershell
# Install latest version
irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Install specific version
$env:VERSION="0.25.1"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Install with custom port
$env:PORT="9183"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Install with specific collectors
$env:COLLECTORS="cpu,cs,logical_disk,memory,net,os,system"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Uninstall
$env:UNINSTALL="true"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### What the Script Does

1. **Downloads** the latest Windows Exporter MSI from GitHub
2. **Installs** via MSI with silent installation
3. **Configures** as a Windows Service (auto-start)
4. **Opens** firewall port for Prometheus access
5. **Starts** the service and verifies it's running
6. **Shows** useful commands and Prometheus configuration

### Script Options (Environment Variables)

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `VERSION` | Install specific version | `latest` | `$env:VERSION="0.25.1"` |
| `PORT` | Use custom port | `9182` | `$env:PORT="9183"` |
| `COLLECTORS` | Enable specific collectors | defaults | `$env:COLLECTORS="cpu,memory,os"` |
| `UNINSTALL` | Remove Windows Exporter | - | `$env:UNINSTALL="true"` |

---

## Table of Contents

- [Quick Install (One-Line Command)](#quick-install-one-line-command)
- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Method 1: MSI Installer (GUI)](#method-1-msi-installer-gui)
  - [Method 2: MSI Installer (Command Line)](#method-2-msi-installer-command-line)
  - [Method 3: Chocolatey](#method-3-chocolatey)
  - [Method 4: Winget](#method-4-winget)
  - [Method 5: Manual Installation](#method-5-manual-installation)
- [Service Configuration](#service-configuration)
- [Available Collectors](#available-collectors)
- [Firewall Configuration](#firewall-configuration)
- [Testing and Verification](#testing-and-verification)
- [Prometheus Configuration](#prometheus-configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

Prometheus Windows Exporter is a Prometheus exporter for Windows machines. It collects metrics about the Windows operating system, including CPU, memory, disk, network, and many other system metrics.

**Default Port:** 9182  
**Official Repository:** https://github.com/prometheus-community/windows_exporter

---

## System Requirements

- **Operating System:** Windows Server 2012 R2+ or Windows 8.1+
- **Architecture:** x64 (amd64) or x86
- **Privileges:** Administrator rights required for installation
- **PowerShell:** Version 5.1 or later (for script installation)
- **Network:** Port 9182 (or custom port) must be accessible

---

## Installation Methods

### Method 1: MSI Installer (GUI)

1. **Download the MSI installer** from the [releases page](https://github.com/prometheus-community/windows_exporter/releases)

2. **Run the installer** by double-clicking the MSI file

3. **Follow the installation wizard**:
   - Accept the license agreement
   - Choose installation directory (default: `C:\Program Files\windows_exporter`)
   - Select collectors to enable
   - Configure listening port (default: 9182)
   - Click Install

4. **Verify installation**:
   ```powershell
   Get-Service windows_exporter
   ```

---

### Method 2: MSI Installer (Command Line)

For automated/silent installation:

```powershell
# Download latest MSI (adjust version as needed)
$version = "0.25.1"
$arch = "amd64"
$url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-$arch.msi"
$msiPath = "$env:TEMP\windows_exporter.msi"

Invoke-WebRequest -Uri $url -OutFile $msiPath

# Install with default settings
msiexec /i $msiPath /qn /norestart

# Install with custom port
msiexec /i $msiPath /qn /norestart LISTEN_PORT=9183

# Install with specific collectors
msiexec /i $msiPath /qn /norestart ENABLED_COLLECTORS="cpu,cs,logical_disk,memory,net,os,system"

# Install with all options
msiexec /i $msiPath /qn /norestart LISTEN_PORT=9182 ENABLED_COLLECTORS="cpu,memory,logical_disk,net,os" EXTRA_FLAGS="--log.format logger:eventlog?name=windows_exporter"
```

---

### Method 3: Chocolatey

If you have Chocolatey installed:

```powershell
# Install Windows Exporter
choco install prometheus-windows-exporter.install -y

# Install specific version
choco install prometheus-windows-exporter.install --version=0.25.1 -y

# Upgrade to latest
choco upgrade prometheus-windows-exporter.install -y

# Uninstall
choco uninstall prometheus-windows-exporter.install -y
```

---

### Method 4: Winget

If you have Windows Package Manager (winget) installed:

```powershell
# Search for Windows Exporter
winget search windows_exporter

# Install
winget install prometheus-community.windows_exporter

# Uninstall
winget uninstall prometheus-community.windows_exporter
```

---

### Method 5: Manual Installation

For environments where MSI installation is not preferred:

#### Step 1: Download the Executable

```powershell
# Create installation directory
$installDir = "C:\Program Files\windows_exporter"
New-Item -ItemType Directory -Path $installDir -Force

# Download latest release
$version = "0.25.1"
$arch = "amd64"
$url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-$arch.exe"

Invoke-WebRequest -Uri $url -OutFile "$installDir\windows_exporter.exe"
```

#### Step 2: Create Windows Service

```powershell
# Create service using sc.exe
sc.exe create windows_exporter binPath= "\"C:\Program Files\windows_exporter\windows_exporter.exe\" --log.format logger:eventlog?name=windows_exporter" start= auto displayname= "Prometheus Windows Exporter"

# Set service description
sc.exe description windows_exporter "Prometheus exporter for Windows machines"

# Set service recovery options (restart on failure)
sc.exe failure windows_exporter reset= 86400 actions= restart/5000/restart/10000/restart/30000
```

#### Step 3: Start the Service

```powershell
# Start the service
Start-Service windows_exporter

# Verify it's running
Get-Service windows_exporter

# Check the listening port
netstat -ano | findstr :9182
```

---

## Service Configuration

### Default Service Configuration

The Windows Exporter service is configured with these defaults:

| Setting | Value |
|---------|-------|
| Service Name | `windows_exporter` |
| Display Name | `Prometheus Windows Exporter` |
| Startup Type | Automatic |
| Log On As | Local System |
| Listening Port | 9182 |

### Modify Service Settings

```powershell
# Stop the service
Stop-Service windows_exporter

# Change startup type
Set-Service -Name windows_exporter -StartupType Automatic

# View current configuration
Get-WmiObject -Class Win32_Service -Filter "Name='windows_exporter'" | Select-Object *
```

### Configure Service Recovery

```powershell
# Set recovery actions: restart after 5, 10, and 30 seconds
sc.exe failure windows_exporter reset= 86400 actions= restart/5000/restart/10000/restart/30000
```

### Customize Command Line Arguments

To change collectors or port, modify the service binary path:

```powershell
# Stop service
Stop-Service windows_exporter

# Update binary path with new arguments
sc.exe config windows_exporter binPath= "\"C:\Program Files\windows_exporter\windows_exporter.exe\" --web.listen-address=:9183 --collectors.enabled=cpu,memory,logical_disk,net,os --log.format logger:eventlog?name=windows_exporter"

# Start service
Start-Service windows_exporter
```

---

## Available Collectors

Windows Exporter provides many collectors. Here are the most commonly used:

### Default Collectors (Enabled by Default)

| Collector | Description |
|-----------|-------------|
| `cpu` | CPU usage metrics |
| `cs` | Computer system metrics (hostname, domain) |
| `logical_disk` | Logical disk metrics (space, I/O) |
| `memory` | Memory usage metrics |
| `net` | Network interface metrics |
| `os` | Operating system metrics |
| `service` | Windows service status |
| `system` | System metrics (uptime, threads) |

### Additional Collectors

| Collector | Description |
|-----------|-------------|
| `ad` | Active Directory metrics |
| `adcs` | Active Directory Certificate Services |
| `adfs` | Active Directory Federation Services |
| `dhcp` | DHCP Server metrics |
| `dns` | DNS Server metrics |
| `exchange` | Microsoft Exchange metrics |
| `hyperv` | Hyper-V metrics |
| `iis` | IIS Web Server metrics |
| `mssql` | Microsoft SQL Server metrics |
| `process` | Per-process metrics |
| `scheduled_task` | Scheduled task metrics |
| `tcp` | TCP connection metrics |
| `terminal_services` | Terminal Services (RDP) metrics |
| `textfile` | Custom metrics from text files |
| `vmware` | VMware guest metrics |

### Enable Specific Collectors

```powershell
# During MSI installation
msiexec /i windows_exporter.msi ENABLED_COLLECTORS="cpu,memory,logical_disk,net,os,iis,mssql"

# Using command line
windows_exporter.exe --collectors.enabled="cpu,memory,logical_disk,net,os,iis"
```

### List All Available Collectors

```powershell
& "C:\Program Files\windows_exporter\windows_exporter.exe" --collectors.print
```

---

## Firewall Configuration

### Using PowerShell (Recommended)

```powershell
# Create firewall rule
New-NetFirewallRule -DisplayName "Prometheus Windows Exporter" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 9182 `
    -Action Allow `
    -Profile Any `
    -Description "Allow Prometheus to scrape Windows Exporter metrics"

# View the rule
Get-NetFirewallRule -DisplayName "Prometheus Windows Exporter"

# Remove the rule
Remove-NetFirewallRule -DisplayName "Prometheus Windows Exporter"
```

### Using netsh (Legacy)

```cmd
# Add firewall rule
netsh advfirewall firewall add rule name="Prometheus Windows Exporter" dir=in action=allow protocol=tcp localport=9182

# Remove firewall rule
netsh advfirewall firewall delete rule name="Prometheus Windows Exporter"
```

### Restrict to Prometheus Server Only

```powershell
# Allow only from specific IP
New-NetFirewallRule -DisplayName "Prometheus Windows Exporter" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 9182 `
    -RemoteAddress "10.0.0.100" `
    -Action Allow `
    -Description "Allow Prometheus server only"
```

---

## Testing and Verification

### Check Service Status

```powershell
# Get service status
Get-Service windows_exporter

# Get detailed service info
Get-WmiObject -Class Win32_Service -Filter "Name='windows_exporter'" | 
    Select-Object Name, State, StartMode, PathName
```

### Check Listening Port

```powershell
# Using PowerShell
Get-NetTCPConnection -LocalPort 9182 -State Listen

# Using netstat
netstat -ano | findstr :9182

# Using Test-NetConnection
Test-NetConnection -ComputerName localhost -Port 9182
```

### Test Metrics Endpoint

```powershell
# Get metrics using PowerShell
Invoke-WebRequest -Uri http://localhost:9182/metrics -UseBasicParsing

# Get specific metrics
(Invoke-WebRequest -Uri http://localhost:9182/metrics -UseBasicParsing).Content | 
    Select-String "windows_os_info"

# Using curl (if available)
curl http://localhost:9182/metrics

# Test from another machine
Invoke-WebRequest -Uri http://<windows-server-ip>:9182/metrics -UseBasicParsing
```

### Check Windows Event Log

```powershell
# View Windows Exporter logs
Get-EventLog -LogName Application -Source windows_exporter -Newest 20

# View errors only
Get-EventLog -LogName Application -Source windows_exporter -EntryType Error -Newest 10
```

---

## Prometheus Configuration

Add Windows Exporter targets to your `prometheus.yml`:

### Basic Configuration

```yaml
scrape_configs:
  - job_name: 'windows'
    static_configs:
      - targets:
        - 'windows-server-1:9182'
        - 'windows-server-2:9182'
```

### With Labels

```yaml
scrape_configs:
  - job_name: 'windows'
    static_configs:
      - targets: ['web-server-1:9182']
        labels:
          environment: 'production'
          role: 'webserver'
      - targets: ['db-server-1:9182']
        labels:
          environment: 'production'
          role: 'database'
```

### Using Service Discovery (File-based)

```yaml
scrape_configs:
  - job_name: 'windows'
    file_sd_configs:
      - files:
        - '/etc/prometheus/targets/windows/*.yml'
        refresh_interval: 5m
```

### With Relabeling

```yaml
scrape_configs:
  - job_name: 'windows'
    static_configs:
      - targets: ['server1:9182', 'server2:9182']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '(.+):9182'
        replacement: '${1}'
```

---

## Troubleshooting

### Service Won't Start

```powershell
# Check service status
Get-Service windows_exporter | Select-Object *

# Check event log for errors
Get-EventLog -LogName Application -Source windows_exporter -EntryType Error -Newest 10

# Check if another process is using the port
Get-NetTCPConnection -LocalPort 9182

# Try running manually to see errors
& "C:\Program Files\windows_exporter\windows_exporter.exe"
```

### Port Already in Use

```powershell
# Find what's using port 9182
$connection = Get-NetTCPConnection -LocalPort 9182 -ErrorAction SilentlyContinue
if ($connection) {
    Get-Process -Id $connection.OwningProcess
}

# Change port in service configuration
Stop-Service windows_exporter
sc.exe config windows_exporter binPath= "\"C:\Program Files\windows_exporter\windows_exporter.exe\" --web.listen-address=:9183"
Start-Service windows_exporter
```

### Firewall Issues

```powershell
# Check if firewall rule exists
Get-NetFirewallRule -DisplayName "*windows*exporter*"

# Test connectivity from Prometheus server
Test-NetConnection -ComputerName <windows-server> -Port 9182

# Temporarily disable firewall for testing (not recommended for production)
# Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

### Permission Issues

```powershell
# Check service account
Get-WmiObject -Class Win32_Service -Filter "Name='windows_exporter'" | 
    Select-Object StartName

# Verify executable permissions
Get-Acl "C:\Program Files\windows_exporter\windows_exporter.exe" | Format-List
```

### Collector Errors

```powershell
# Check which collectors are enabled
& "C:\Program Files\windows_exporter\windows_exporter.exe" --collectors.print

# Test with minimal collectors
& "C:\Program Files\windows_exporter\windows_exporter.exe" --collectors.enabled="cpu,memory"
```

### High CPU/Memory Usage

```powershell
# Check process resource usage
Get-Process windows_exporter | Select-Object CPU, WorkingSet64, HandleCount

# Disable expensive collectors
Stop-Service windows_exporter
sc.exe config windows_exporter binPath= "\"C:\Program Files\windows_exporter\windows_exporter.exe\" --collectors.enabled=cpu,memory,os,system --no-collector.process"
Start-Service windows_exporter
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Start service | `Start-Service windows_exporter` |
| Stop service | `Stop-Service windows_exporter` |
| Restart service | `Restart-Service windows_exporter` |
| Check status | `Get-Service windows_exporter` |
| Enable on boot | `Set-Service -Name windows_exporter -StartupType Automatic` |
| View logs | `Get-EventLog -LogName Application -Source windows_exporter -Newest 20` |
| Check port | `Get-NetTCPConnection -LocalPort 9182` |
| Test metrics | `Invoke-WebRequest http://localhost:9182/metrics` |

---

## Security Best Practices

1. **Firewall Rules** - Restrict port 9182 to Prometheus server IPs only
2. **TLS Encryption** - Consider using a reverse proxy with TLS for production
3. **Network Segmentation** - Keep monitoring traffic on a separate network
4. **Collector Selection** - Only enable collectors you need to reduce attack surface
5. **Regular Updates** - Keep Windows Exporter updated for security patches

---

**Document Version:** 1.0  
**Last Updated:** May 2026  
**Author:** DevOps Team
