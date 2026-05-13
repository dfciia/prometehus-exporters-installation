# Prometheus Node Exporter Installation Guide

This document provides step-by-step instructions for installing Prometheus Node Exporter on various Linux distributions.

---

## Quick Install (One-Line Command)

Install Node Exporter instantly using our installation script:

```bash
# Install latest version
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash

# Install specific version
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --version 1.7.0

# Install with custom port
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --port 9101

# Uninstall
curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/node-exporter/install-node-exporter.sh | sudo bash -s -- --uninstall
```

### What the Script Does

1. **Auto-detects** your Linux distribution (Ubuntu, Debian, RHEL, CentOS, Fedora, SUSE, Arch, etc.)
2. **Installs** via native package manager when possible, falls back to binary installation
3. **Creates** a dedicated system user for security
4. **Configures** systemd service automatically
5. **Opens** firewall port if UFW or firewalld is active
6. **Starts** the service and verifies it's running
7. **Shows** useful commands and Prometheus configuration

### Script Options

| Option | Description | Example |
|--------|-------------|---------|
| `--version <ver>` | Install specific version | `--version 1.7.0` |
| `--port <port>` | Use custom port (default: 9100) | `--port 9101` |
| `--uninstall` | Remove node_exporter completely | `--uninstall` |
| `--help` | Show help message | `--help` |

---

## Table of Contents
- [Quick Install (One-Line Command)](#quick-install-one-line-command)
- [Overview](#overview)
- [Installation Methods](#installation-methods)
  - [Ubuntu/Debian](#ubuntudebian)
  - [RHEL/CentOS/Rocky Linux/AlmaLinux](#rhelcentosrocky-linuxalmalinux)
  - [Fedora](#fedora)
  - [SUSE/openSUSE](#suseopensuse)
  - [Arch Linux](#arch-linux)
  - [Manual Installation (Universal)](#manual-installation-universal)
- [Running as a SystemD Service](#running-as-a-systemd-service)
- [Testing and Verification](#testing-and-verification)
- [Common Configuration Options](#common-configuration-options)
- [Troubleshooting](#troubleshooting)

---

## Overview

Prometheus Node Exporter is a Prometheus exporter for hardware and OS metrics exposed by *NIX kernels. It collects system metrics such as CPU, memory, disk, and network statistics.

**Default Port:** 9100  
**Official Repository:** https://github.com/prometheus/node_exporter

---

## Installation Methods

### Ubuntu/Debian

#### Using APT Package Manager

```bash
# Update package list
sudo apt update

# Install node exporter
sudo apt install prometheus-node-exporter -y

# The service starts automatically after installation
# Check status
sudo systemctl status prometheus-node-exporter
```

#### Using Snap (Ubuntu)

```bash
# Install via snap
sudo snap install prometheus-node-exporter

# Start the service
sudo snap start prometheus-node-exporter
```

---

### RHEL/CentOS/Rocky Linux/AlmaLinux

#### RHEL 8/9, CentOS Stream, Rocky Linux, AlmaLinux

```bash
# Enable EPEL repository
sudo dnf install epel-release -y

# Install node exporter
sudo dnf install node_exporter -y

# Enable and start the service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Check status
sudo systemctl status node_exporter
```

#### CentOS 7 (Legacy)

```bash
# Enable EPEL repository
sudo yum install epel-release -y

# Install node exporter
sudo yum install node_exporter -y

# Enable and start the service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

---

### Fedora

```bash
# Install node exporter
sudo dnf install golang-github-prometheus-node-exporter -y

# Enable and start the service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Check status
sudo systemctl status node_exporter
```

---

### SUSE/openSUSE

#### openSUSE Leap/Tumbleweed

```bash
# Install node exporter
sudo zypper install golang-github-prometheus-node_exporter -y

# Enable and start the service
sudo systemctl enable prometheus-node_exporter
sudo systemctl start prometheus-node_exporter

# Check status
sudo systemctl status prometheus-node_exporter
```

#### SUSE Linux Enterprise Server (SLES)

```bash
# Add the monitoring module (if not already added)
sudo SUSEConnect -p sle-module-basesystem/15.x/x86_64

# Install node exporter
sudo zypper install golang-github-prometheus-node_exporter -y

# Enable and start the service
sudo systemctl enable prometheus-node_exporter
sudo systemctl start prometheus-node_exporter
```

---

### Arch Linux

```bash
# Install node exporter from official repositories
sudo pacman -S prometheus-node-exporter

# Enable and start the service
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter

# Check status
sudo systemctl status prometheus-node-exporter
```

---

### Manual Installation (Universal)

This method works on any Linux distribution.

#### Step 1: Download the Latest Release

```bash
# Set the version (check https://github.com/prometheus/node_exporter/releases for latest)
NODE_EXPORTER_VERSION="1.7.0"

# Download the binary
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# For ARM64 systems, use:
# wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz
```

#### Step 2: Extract and Install

```bash
# Extract the archive
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Move binary to /usr/local/bin
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Verify installation
node_exporter --version

# Clean up
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*
```

#### Step 3: Create a Dedicated User

```bash
# Create a system user for node_exporter (no home directory, no login shell)
sudo useradd --no-create-home --shell /bin/false node_exporter

# Set ownership
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

---

## Running as a SystemD Service

### Create SystemD Service File

Create the service file at `/etc/systemd/system/node_exporter.service`:

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
```

### Service with Custom Options

For advanced configuration with collectors:

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \\
    --web.listen-address=:9100 \\
    --collector.systemd \\
    --collector.processes \\
    --no-collector.infiniband \\
    --no-collector.nfs \\
    --no-collector.nfsd

[Install]
WantedBy=multi-user.target
EOF
```

### Enable and Start the Service

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable node_exporter

# Start the service
sudo systemctl start node_exporter

# Check status
sudo systemctl status node_exporter
```

### Service Management Commands

```bash
# Start the service
sudo systemctl start node_exporter

# Stop the service
sudo systemctl stop node_exporter

# Restart the service
sudo systemctl restart node_exporter

# Check status
sudo systemctl status node_exporter

# View logs
sudo journalctl -u node_exporter -f

# View logs from last boot
sudo journalctl -u node_exporter -b

# Disable service from starting on boot
sudo systemctl disable node_exporter
```

---

## Testing and Verification

### Basic Health Check

```bash
# Check if the service is running
sudo systemctl status node_exporter

# Check if port 9100 is listening
sudo ss -tlnp | grep 9100

# Alternative using netstat
sudo netstat -tlnp | grep 9100
```

### Verify Metrics Endpoint

```bash
# Fetch metrics using curl
curl http://localhost:9100/metrics

# Get specific metrics (example: CPU)
curl -s http://localhost:9100/metrics | grep "node_cpu"

# Get memory metrics
curl -s http://localhost:9100/metrics | grep "node_memory"

# Get disk metrics
curl -s http://localhost:9100/metrics | grep "node_disk"

# Get network metrics
curl -s http://localhost:9100/metrics | grep "node_network"
```

### Check Node Exporter Version and Build Info

```bash
# Check version
node_exporter --version

# Get build info from metrics
curl -s http://localhost:9100/metrics | grep "node_exporter_build_info"
```

### Test from Remote Host

```bash
# Replace <server-ip> with your server's IP address
curl http://<server-ip>:9100/metrics

# Test connectivity
telnet <server-ip> 9100
```

### Verify Prometheus Scraping (if Prometheus is configured)

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="node") | {instance: .labels.instance, health: .health}'
```

---

## Common Configuration Options

### Available Command Line Flags

```bash
# View all available options
node_exporter --help

# Common flags:
# --web.listen-address=":9100"     - Address to listen on for web interface
# --web.telemetry-path="/metrics"  - Path under which to expose metrics
# --collector.<name>               - Enable specific collector
# --no-collector.<name>            - Disable specific collector
# --web.config.file=""             - Path to TLS/auth config file
```

### List Available Collectors

```bash
# List all collectors
node_exporter --help 2>&1 | grep -E "^\s+--collector\."

# Common collectors:
# cpu, diskstats, filesystem, loadavg, meminfo
# netdev, netstat, stat, time, uname, vmstat
```

### Enable/Disable Specific Collectors

```bash
# Enable systemd collector
node_exporter --collector.systemd

# Disable infiniband collector
node_exporter --no-collector.infiniband

# Multiple options
node_exporter --collector.systemd --no-collector.wifi --no-collector.infiniband
```

---

## Troubleshooting

### Common Issues

#### Port 9100 Already in Use

```bash
# Check what's using port 9100
sudo lsof -i :9100
sudo ss -tlnp | grep 9100

# Change port in service file
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9101
```

#### Permission Denied Errors

```bash
# Check ownership
ls -la /usr/local/bin/node_exporter

# Fix ownership
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter
```

#### Service Fails to Start

```bash
# Check logs for errors
sudo journalctl -u node_exporter -e

# Test running manually
sudo -u node_exporter /usr/local/bin/node_exporter
```

#### Firewall Blocking Port 9100

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 9100/tcp
sudo ufw reload

# RHEL/CentOS/Fedora (firewalld)
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

# SUSE (firewalld)
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

# Using iptables directly
sudo iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
```

#### SELinux Issues (RHEL/CentOS)

```bash
# Check SELinux status
sestatus

# If SELinux is blocking, create a custom policy
sudo ausearch -c 'node_exporter' --raw | audit2allow -M node_exporter_policy
sudo semodule -i node_exporter_policy.pp

# Or set permissive mode for troubleshooting (not recommended for production)
sudo setenforce 0
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Start service | `sudo systemctl start node_exporter` |
| Stop service | `sudo systemctl stop node_exporter` |
| Restart service | `sudo systemctl restart node_exporter` |
| Check status | `sudo systemctl status node_exporter` |
| Enable on boot | `sudo systemctl enable node_exporter` |
| Disable on boot | `sudo systemctl disable node_exporter` |
| View logs | `sudo journalctl -u node_exporter -f` |
| Check port | `sudo ss -tlnp \| grep 9100` |
| Test metrics | `curl http://localhost:9100/metrics` |
| Check version | `node_exporter --version` |

---

## Security Best Practices

1. **Run as non-root user** - Always run node_exporter as a dedicated system user
2. **Firewall rules** - Restrict access to port 9100 to only Prometheus server IPs
3. **TLS encryption** - Enable TLS for production environments using `--web.config.file`
4. **Network segmentation** - Keep monitoring traffic on a separate network if possible

### Enable TLS (Optional)

Create a web config file `/etc/node_exporter/web.yml`:

```yaml
tls_server_config:
  cert_file: /etc/node_exporter/node_exporter.crt
  key_file: /etc/node_exporter/node_exporter.key
```

Update service file:
```bash
ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/web.yml
```

---

**Document Version:** 1.0  
**Last Updated:** May 2026  
**Author:** DevOps Team
