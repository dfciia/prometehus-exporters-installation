# Prometheus Exporters Installation Scripts

One-line installation scripts for Prometheus exporters on any Linux distribution.

[![GitHub](https://img.shields.io/badge/GitHub-dfciia-blue)](https://github.com/dfciia/prometehus-exporters-installation)

## Available Exporters

| Exporter | Description | Default Port | Quick Install |
|----------|-------------|--------------|---------------|
| [Node Exporter](node-exporter/) | Hardware and OS metrics | 9100 | [Install](#node-exporter) |

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

## Repository Structure

```
prometehus-exporters-installation/
├── README.md                           # This file
├── node-exporter/                      # Node Exporter
│   ├── README.md                       # Node Exporter documentation
│   ├── install-node-exporter.sh        # Installation script
│   └── node-exporter-install.md        # Detailed installation guide
├── <future-exporter>/                  # Future exporters will be added here
│   ├── README.md
│   └── install-<exporter>.sh
└── ...
```

## Supported Linux Distributions

All installation scripts support:

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

## Features

- **Auto-detection** - Automatically detects your Linux distribution
- **Package Manager Support** - Uses native package managers when available
- **Binary Fallback** - Falls back to binary installation for unsupported distros
- **Service Setup** - Creates and configures systemd service automatically
- **Firewall Config** - Opens required ports in UFW/firewalld
- **Secure** - Runs exporters as dedicated non-root users

## Adding Prometheus Targets

After installing exporters, add them to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
        - 'server1:9100'
        - 'server2:9100'
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

---

**Maintained by:** [dfciia](https://github.com/dfciia)
