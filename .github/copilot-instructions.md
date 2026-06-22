# Copilot Instructions for Prometheus Exporters Installation

This repository contains one-line installation scripts for Prometheus exporters (Node Exporter for Linux, Windows Exporter for Windows).

## Architecture

### Script Structure Pattern

Both installers follow a consistent modular structure:

```
1. Configuration & Defaults
2. Helper Functions (logging, banners)
3. System Detection (OS/distro, architecture, init system)
4. Package Manager Installation (APT, DNF, YUM, Zypper, Pacman)
5. Binary/MSI Installation (fallback for unsupported distros/versions)
6. Service Setup (systemd, SysVinit, Windows Service)
7. Firewall Configuration (UFW, firewalld, Windows Firewall)
8. Uninstall Function
9. Verification & Summary
10. Main Flow
```

Each script is self-contained and must work when piped from `curl` or `irm` (PowerShell).

### Installation Flow

**Linux (install-node-exporter.sh):**
1. Detect OS/distro/architecture/init system
2. Try native package manager first (preferred)
3. Fall back to binary installation if package unavailable
4. Create dedicated `node_exporter` system user (non-root)
5. Set up systemd or SysVinit service
6. Configure firewall (UFW/firewalld) if active
7. Verify service is running and metrics endpoint is accessible

**Windows (install-windows-exporter.ps1):**
1. Detect architecture (amd64/386)
2. Download MSI from GitHub releases
3. Install MSI with custom port and collectors
4. Service is created automatically by MSI installer
5. Configure Windows Firewall rule
6. Verify service status and metrics endpoint

## Key Conventions

### Bash Scripts (Node Exporter)

- **Logging functions:** Use `log_info`, `log_success`, `log_warning`, `log_error` (defined in Helper Functions section)
- **Colors:** Use predefined color variables (`RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`)
- **Error handling:** Use `set -e` at the top; exit with non-zero on critical errors
- **Root check:** All installers must call `check_root()` in main flow
- **Service names:** Variable based on distro - APT uses `prometheus-node-exporter`, others use `node_exporter`
- **Binary installation path:** Always `/usr/local/bin/node_exporter`
- **Default port:** 9100 (configurable via `--port`)
- **Command detection:** Use `command -v <cmd> &> /dev/null` pattern
- **Section headers:** Separate major sections with comment blocks like:
  ```bash
  # -----------------------------------------------------------------------------
  # Section Name
  # -----------------------------------------------------------------------------
  ```

### PowerShell Scripts (Windows Exporter)

- **Logging functions:** Use `Write-Info`, `Write-Success`, `Write-Warning`, `Write-Error` (defined in Helper Functions section)
- **Error handling:** Set `$ErrorActionPreference = "Stop"` at the top
- **Admin check:** Use `#Requires -RunAsAdministrator` directive
- **Environment variables:** Read params from env vars for one-liner usage (VERSION, PORT, COLLECTORS, UNINSTALL), then clear them after reading
- **Installation path:** Always `C:\Program Files\windows_exporter`
- **Default port:** 9182 (configurable via `$env:PORT`)
- **Service name:** `windows_exporter`
- **MSI arguments:** Use array format with `/qn` (quiet, no UI) and log to temp
- **Section headers:** Match bash convention with `# ---------` separators

### Testing & Verification

- Both scripts include verification steps that:
  - Check service status
  - Verify port is listening
  - Test metrics endpoint with sample output
  - Display common management commands in summary

- When adding new features, test on multiple distributions:
  - **Linux:** Ubuntu/Debian (APT), RHEL/CentOS/Rocky (DNF/YUM), openSUSE (Zypper), Arch (Pacman)
  - **Windows:** Server 2016+, Windows 10+

### Documentation Structure

Each exporter folder contains:
- `README.md` - Quick start guide with examples
- `install-*.sh/ps1` - The installation script itself
- `*-installation.md` - Detailed manual installation guide for all supported platforms

Main README.md includes:
- Quick install commands for each exporter
- Supported platforms table
- Options/examples
- Repository structure diagram
- How to add to Prometheus targets

## Command-Line Options

### Node Exporter (Bash)

Parse using `while` loop:
```bash
while [[ $# -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --uninstall) UNINSTALL=true; shift ;;
        --help) show_help ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done
```

### Windows Exporter (PowerShell)

Read from environment variables for one-liner compatibility:
```powershell
$Version = if ($env:VERSION) { $env:VERSION } else { "latest" }
$Port = if ($env:PORT) { $env:PORT } else { "9182" }
```

## Adding a New Exporter

1. Create folder: `<exporter-name>/`
2. Add installation script: `install-<exporter-name>.sh` or `.ps1`
3. Follow the 10-section structure pattern
4. Add documentation: `README.md` and detailed guide
5. Update main README.md:
   - Add to "Available Exporters" table
   - Add quick install section
   - Add to "Repository Structure"
6. Test on multiple distros/versions

## Security Considerations

- **Linux:** Run exporters as dedicated non-root users (not `root`)
- **Windows:** Service runs as Local System by default (MSI installer controls this)
- **Firewall:** Scripts open required ports, but document how to restrict to Prometheus server IPs only
- **Downloads:** Always verify checksums when available; use HTTPS for all downloads
- **Service files:** Set minimal required permissions (755 for binaries, 644 for service files)

## GitHub Release Integration

Both scripts fetch the latest version from GitHub API:
- **Linux:** `curl -fsSL "https://api.github.com/repos/prometheus/node_exporter/releases/latest"`
- **Windows:** `Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/releases/latest"`

When version is "latest":
1. Query GitHub API for latest release
2. Parse `tag_name` field
3. Use fallback version if API fails (hard-coded stable version)

## Service Configuration Files

### Systemd (Linux)
- Location: `/etc/systemd/system/node_exporter.service`
- Key settings:
  - `User=node_exporter` (non-root)
  - `Type=simple`
  - `Restart=on-failure`
  - `ExecStart` with `--web.listen-address` flag

### Windows Service
- Created by MSI installer automatically
- Configuration via MSI properties: `LISTEN_PORT`, `ENABLED_COLLECTORS`
- Service name: `windows_exporter`

## URL Conventions

Scripts are designed to be downloaded and executed via one-liners:

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

Always use the GitHub raw URL pattern: `https://raw.githubusercontent.com/<owner>/<repo>/main/<path>`

## Common Pitfalls

1. **Service naming inconsistency:** APT packages use `prometheus-node-exporter`, others use `node_exporter`. Handle both in uninstall.
2. **Architecture detection:** Map various arch names (x86_64, amd64, aarch64, arm64) to consistent format.
3. **Init system:** Support both systemd and SysVinit. Detect with `systemctl --version` check.
4. **Windows port conflicts:** Check if port is in use before starting service; show diagnostic info if service fails to start.
5. **MSI logging:** Always log MSI installation to temp file for troubleshooting.
6. **Firewall detection:** Check if firewall is active before trying to configure it (avoid errors on systems without firewall).

## Metrics Verification

All scripts should verify the installation by:
1. Checking service is running
2. Confirming port is listening (use `ss -tlnp` on Linux, `Get-NetTCPConnection` on Windows)
3. Making HTTP request to `/metrics` endpoint
4. Displaying sample metric output (e.g., `node_exporter_build_info` or `windows_exporter_build_info`)

## Related Tools

- **Azure CLI:** Use `az` CLI for Azure-specific operations (per custom instructions)
- **Prometheus:** Installation scripts should guide users on adding targets to `prometheus.yml`
- **Package managers:** Prefer native package managers when available; fall back to binary/MSI only when necessary
