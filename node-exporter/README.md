# Prometheus Node Exporter Installer

One-line installation script for Prometheus Node Exporter on any Linux distribution.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/install-node-exporter.sh | sudo bash
```

## Features

- **Auto-detection** - Automatically detects your Linux distribution
- **Package Manager Support** - Uses native package managers (APT, DNF, YUM, Zypper, Pacman)
- **Binary Fallback** - Falls back to binary installation for unsupported distros
- **Service Setup** - Creates and configures systemd service automatically
- **Firewall Config** - Opens required ports in UFW/firewalld
- **Secure** - Runs as dedicated non-root user

## Supported Distributions

| Distribution | Package Manager | Tested Versions |
|--------------|-----------------|-----------------|
| Ubuntu | APT | 20.04, 22.04, 24.04 |
| Debian | APT | 10, 11, 12 |
| RHEL | DNF/YUM | 7, 8, 9 |
| CentOS | DNF/YUM | 7, Stream 8, Stream 9 |
| Rocky Linux | DNF | 8, 9 |
| AlmaLinux | DNF | 8, 9 |
| Fedora | DNF | 38, 39, 40 |
| openSUSE | Zypper | Leap 15.x, Tumbleweed |
| SLES | Zypper | 15 |
| Arch Linux | Pacman | Rolling |
| Any Linux | Binary | All with glibc |

## Usage Examples

### Install Latest Version

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/install-node-exporter.sh | sudo bash
```

### Install Specific Version

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --version 1.7.0
```

### Install with Custom Port

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --port 9101
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --uninstall
```

### Show Help

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | bash -s -- --help
```

## Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--version <version>` | Install a specific version | `latest` |
| `--port <port>` | Set custom listening port | `9100` |
| `--uninstall` | Remove node_exporter | - |
| `--help` | Show help message | - |

## After Installation

### Verify Installation

```bash
# Check service status
sudo systemctl status node_exporter

# Test metrics endpoint
curl http://localhost:9100/metrics

# Check version
node_exporter --version
```

### Common Commands

```bash
# Start service
sudo systemctl start node_exporter

# Stop service
sudo systemctl stop node_exporter

# Restart service
sudo systemctl restart node_exporter

# View logs
sudo journalctl -u node_exporter -f

# Enable on boot
sudo systemctl enable node_exporter
```

### Add to Prometheus

Add this to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['<server-ip>:9100']
```

## Files Installed

| Path | Description |
|------|-------------|
| `/usr/local/bin/node_exporter` | Binary executable |
| `/etc/systemd/system/node_exporter.service` | Systemd service file |

## Security

- Runs as dedicated `node_exporter` user (non-root)
- Minimal privileges required
- Consider firewall rules to restrict access to Prometheus server only

```bash
# Example: Allow only Prometheus server
sudo ufw allow from <prometheus-server-ip> to any port 9100
```

## Documentation

See [node-exporter-install.md](node-exporter-install.md) for detailed manual installation instructions covering all distributions.

## Folder Structure

```
node-exporter/
├── README.md                    # This file
├── install-node-exporter.sh     # Installation script
└── node-exporter-install.md     # Detailed documentation
```

## Related Links

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Node Exporter Releases](https://github.com/prometheus/node_exporter/releases)
