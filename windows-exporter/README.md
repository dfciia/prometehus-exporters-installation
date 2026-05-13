# Prometheus Windows Exporter Installer

One-line installation script for Prometheus Windows Exporter on Windows Server and Desktop.

## Quick Install

Run as Administrator in PowerShell:

```powershell
irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

## Features

- **Automatic Download** - Fetches latest version from GitHub
- **MSI Installation** - Uses official MSI installer
- **Service Setup** - Configures and starts Windows Service automatically
- **Firewall Config** - Opens required port in Windows Firewall
- **Custom Options** - Supports custom port, version, and collectors

## Supported Systems

| System | Architecture | Versions |
|--------|--------------|----------|
| Windows Server | x64 | 2012 R2, 2016, 2019, 2022 |
| Windows Desktop | x64 | 8.1, 10, 11 |
| Windows Server | x86 | 2012 R2+ (limited) |

## Usage Examples

### Install Latest Version

```powershell
irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Install Specific Version

```powershell
$env:VERSION="0.25.1"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Install with Custom Port

```powershell
$env:PORT="9183"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Install with Specific Collectors

```powershell
$env:COLLECTORS="cpu,memory,logical_disk,net,os,iis"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Combine Multiple Options

```powershell
$env:VERSION="0.25.1"; $env:PORT="9183"; $env:COLLECTORS="cpu,memory,os"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Uninstall

```powershell
$env:UNINSTALL="true"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VERSION` | Install a specific version | `latest` |
| `PORT` | Set custom listening port | `9182` |
| `COLLECTORS` | Comma-separated list of collectors | defaults |
| `UNINSTALL` | Set to "true" to uninstall | - |

## After Installation

### Verify Installation

```powershell
# Check service status
Get-Service windows_exporter

# Test metrics endpoint
Invoke-WebRequest http://localhost:9182/metrics

# Check listening port
Get-NetTCPConnection -LocalPort 9182
```

### Common Commands

```powershell
# Start service
Start-Service windows_exporter

# Stop service
Stop-Service windows_exporter

# Restart service
Restart-Service windows_exporter

# View logs
Get-EventLog -LogName Application -Source windows_exporter -Newest 20

# Enable on boot
Set-Service -Name windows_exporter -StartupType Automatic
```

### Add to Prometheus

Add this to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'windows'
    static_configs:
      - targets: ['<server-ip>:9182']
```

## Default Collectors

| Collector | Description |
|-----------|-------------|
| `cpu` | CPU usage metrics |
| `cs` | Computer system info |
| `logical_disk` | Disk space and I/O |
| `memory` | Memory usage |
| `net` | Network interface stats |
| `os` | OS information |
| `service` | Windows service status |
| `system` | System uptime and threads |

## Additional Collectors

Enable based on your needs:

| Collector | Use Case |
|-----------|----------|
| `iis` | IIS Web Server |
| `mssql` | SQL Server |
| `hyperv` | Hyper-V hosts |
| `ad` | Active Directory |
| `dns` | DNS Server |
| `exchange` | Exchange Server |
| `process` | Per-process metrics |
| `tcp` | TCP connections |

## Files Installed

| Path | Description |
|------|-------------|
| `C:\Program Files\windows_exporter\` | Installation directory |
| `C:\Program Files\windows_exporter\windows_exporter.exe` | Executable |

## Security

- Runs as Local System account
- Firewall rule created for specified port
- Consider restricting access to Prometheus server IP only

```powershell
# Restrict to Prometheus server only
Remove-NetFirewallRule -DisplayName "Prometheus Windows Exporter"
New-NetFirewallRule -DisplayName "Prometheus Windows Exporter" `
    -Direction Inbound -Protocol TCP -LocalPort 9182 `
    -RemoteAddress "10.0.0.100" -Action Allow
```

## Documentation

See [windows-exporter-installation.md](windows-exporter-installation.md) for detailed manual installation instructions, troubleshooting, and advanced configuration.

## Folder Structure

```
windows-exporter/
├── README.md                          # This file
├── install-windows-exporter.ps1       # Installation script
└── windows-exporter-installation.md   # Detailed documentation
```

## Related Links

- [Windows Exporter](https://github.com/prometheus-community/windows_exporter)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Windows Exporter Releases](https://github.com/prometheus-community/windows_exporter/releases)
