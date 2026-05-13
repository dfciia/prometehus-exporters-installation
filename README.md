# Prometheus Exporters Installation Scripts

One-line installation scripts for Prometheus exporters on Linux and Windows systems.

[![GitHub](https://img.shields.io/badge/GitHub-dfciia-blue)](https://github.com/dfciia/prometehus-exporters-installation)

## Available Exporters

| Exporter | Platform | Description | Default Port | Quick Install |
|----------|----------|-------------|--------------|---------------|
| [Node Exporter](node-exporter/) | Linux | Hardware and OS metrics | 9100 | [Install](#node-exporter) |
| [Windows Exporter](windows-exporter/) | Windows | Windows system metrics | 9182 | [Install](#windows-exporter) |

---

## Node Exporter

Collects hardware and operating system metrics (CPU, memory, disk, network, etc.).

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash
```

### Options

```bash
# Install specific version
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --version 1.7.0

# Install with custom port
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --port 9101

# Uninstall
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --uninstall
```

📖 **[Full Documentation](node-exporter/README.md)**

---

## Windows Exporter

Collects Windows system metrics (CPU, memory, disk, network, services, IIS, SQL Server, etc.).

### Quick Install

Run as Administrator in PowerShell:

```powershell
irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

### Options

```powershell
# Install specific version
$env:VERSION="0.25.1"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Install with custom port
$env:PORT="9183"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Install with specific collectors
$env:COLLECTORS="cpu,memory,logical_disk,net,os,iis"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex

# Uninstall
$env:UNINSTALL="true"; irm https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/windows-exporter/install-windows-exporter.ps1 | iex
```

📖 **[Full Documentation](windows-exporter/README.md)**

---

## Repository Structure

```
prometehus-exporters-installation/
├── README.md                              # This file
├── node-exporter/                         # Node Exporter (Linux)
│   ├── README.md                          # Node Exporter documentation
│   ├── install-node-exporter.sh           # Bash installation script
│   └── node-exporter-install.md           # Detailed installation guide
├── windows-exporter/                      # Windows Exporter
│   ├── README.md                          # Windows Exporter documentation
│   ├── install-windows-exporter.ps1       # PowerShell installation script
│   └── windows-exporter-installation.md   # Detailed installation guide
└── ...
```

## Supported Platforms

### Linux Distributions (Node Exporter)

| Distribution | Package Manager | Versions |
|--------------|-----------------|----------|
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

### Windows Systems (Windows Exporter)

| System | Architecture | Versions |
|--------|--------------|----------|
| Windows Server | x64 | 2012 R2, 2016, 2019, 2022 |
| Windows Desktop | x64 | 8.1, 10, 11 |

## Features

- **Auto-detection** - Automatically detects your OS/distribution
- **Package Manager Support** - Uses native package managers when available
- **Binary/MSI Fallback** - Falls back to binary/MSI installation when needed
- **Service Setup** - Creates and configures services automatically (systemd/Windows Service)
- **Firewall Config** - Opens required ports in UFW/firewalld/Windows Firewall
- **Secure** - Runs exporters as dedicated non-root/system users

## Adding Prometheus Targets

After installing exporters, add them to your `prometheus.yml`:

```yaml
scrape_configs:
  # Linux servers (Node Exporter)
  - job_name: 'node'
    static_configs:
      - targets:
        - 'linux-server1:9100'
        - 'linux-server2:9100'

  # Windows servers (Windows Exporter)
  - job_name: 'windows'
    static_configs:
      - targets:
        - 'windows-server1:9182'
        - 'windows-server2:9182'
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-exporter`)
3. Add your exporter in a new folder following the existing structure
4. Test on multiple distributions
5. Submit a pull request

### Adding a New Exporter

1. Create a new folder: `<exporter-name>/`
2. Add installation script: `install-<exporter-name>.sh`
3. Add documentation: `README.md` and detailed guide
4. Update this main README with the new exporter

## License

MIT License - Feel free to use and modify.

## Related Links

- [Prometheus](https://prometheus.io/)
- [Prometheus Exporters](https://prometheus.io/docs/instrumenting/exporters/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [Windows Exporter](https://github.com/prometheus-community/windows_exporter)

---

**Maintained by:** [dfciia](https://github.com/dfciia)
