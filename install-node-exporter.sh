#!/bin/bash
#
# Prometheus Node Exporter Installer
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/install-node-exporter.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/install-node-exporter.sh | bash -s -- --version 1.7.0
#   curl -fsSL https://raw.githubusercontent.com/dfciia/prometehus-exporters-installation/main/install-node-exporter.sh | bash -s -- --uninstall
#
# Options:
#   --version <version>   Install a specific version (default: latest)
#   --port <port>         Set custom port (default: 9100)
#   --uninstall           Uninstall node_exporter
#   --help                Show this help message
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NODE_EXPORTER_VERSION="latest"
NODE_EXPORTER_PORT="9100"
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="node_exporter"
SERVICE_USER="node_exporter"
UNINSTALL=false

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Prometheus Node Exporter Installer                     ║"
    echo "║         https://github.com/prometheus/node_exporter            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        echo "Please run: curl -fsSL <url> | sudo bash"
        exit 1
    fi
}

show_help() {
    echo "Prometheus Node Exporter Installer"
    echo ""
    echo "Usage:"
    echo "  curl -fsSL <script-url> | bash"
    echo "  curl -fsSL <script-url> | bash -s -- [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version <version>   Install a specific version (default: latest)"
    echo "  --port <port>         Set custom port (default: 9100)"
    echo "  --uninstall           Uninstall node_exporter"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Install latest version"
    echo "  curl -fsSL <script-url> | sudo bash"
    echo ""
    echo "  # Install specific version"
    echo "  curl -fsSL <script-url> | sudo bash -s -- --version 1.7.0"
    echo ""
    echo "  # Install with custom port"
    echo "  curl -fsSL <script-url> | sudo bash -s -- --port 9101"
    echo ""
    echo "  # Uninstall"
    echo "  curl -fsSL <script-url> | sudo bash -s -- --uninstall"
    exit 0
}

# -----------------------------------------------------------------------------
# System Detection
# -----------------------------------------------------------------------------

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        OS_VERSION="unknown"
    fi
    
    log_info "Detected OS: ${OS_NAME:-$OS} (${OS_VERSION})"
}

detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armhf)
            ARCH="armv7"
            ;;
        armv6l)
            ARCH="armv6"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    log_info "Detected architecture: $ARCH"
}

detect_init_system() {
    if command -v systemctl &> /dev/null && systemctl --version &> /dev/null; then
        INIT_SYSTEM="systemd"
    elif command -v service &> /dev/null; then
        INIT_SYSTEM="sysvinit"
    else
        INIT_SYSTEM="unknown"
    fi
    log_info "Init system: $INIT_SYSTEM"
}

# -----------------------------------------------------------------------------
# Package Manager Installation
# -----------------------------------------------------------------------------

install_via_apt() {
    log_info "Installing via APT package manager..."
    apt-get update -qq
    apt-get install -y prometheus-node-exporter
    
    # APT uses different service name
    SERVICE_NAME="prometheus-node-exporter"
    return 0
}

install_via_dnf() {
    log_info "Installing via DNF package manager..."
    
    # Install EPEL if needed (for RHEL-based distros)
    if ! rpm -q epel-release &> /dev/null; then
        log_info "Installing EPEL repository..."
        dnf install -y epel-release || true
    fi
    
    dnf install -y node_exporter
    return 0
}

install_via_yum() {
    log_info "Installing via YUM package manager..."
    
    # Install EPEL if needed
    if ! rpm -q epel-release &> /dev/null; then
        log_info "Installing EPEL repository..."
        yum install -y epel-release || true
    fi
    
    yum install -y node_exporter
    return 0
}

install_via_zypper() {
    log_info "Installing via Zypper package manager..."
    zypper install -y golang-github-prometheus-node_exporter
    SERVICE_NAME="prometheus-node_exporter"
    return 0
}

install_via_pacman() {
    log_info "Installing via Pacman package manager..."
    pacman -Sy --noconfirm prometheus-node-exporter
    SERVICE_NAME="prometheus-node-exporter"
    return 0
}

# -----------------------------------------------------------------------------
# Binary Installation (Universal)
# -----------------------------------------------------------------------------

get_latest_version() {
    log_info "Fetching latest version..."
    
    # Try using curl with GitHub API
    if command -v curl &> /dev/null; then
        LATEST=$(curl -fsSL "https://api.github.com/repos/prometheus/node_exporter/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    elif command -v wget &> /dev/null; then
        LATEST=$(wget -qO- "https://api.github.com/repos/prometheus/node_exporter/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    fi
    
    if [[ -z "$LATEST" ]]; then
        # Fallback to a known stable version
        LATEST="1.7.0"
        log_warning "Could not fetch latest version, using fallback: $LATEST"
    fi
    
    echo "$LATEST"
}

install_binary() {
    local version=$1
    
    if [[ "$version" == "latest" ]]; then
        version=$(get_latest_version)
    fi
    
    log_info "Installing Node Exporter version: $version"
    
    local download_url="https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-${ARCH}.tar.gz"
    local tmp_dir=$(mktemp -d)
    local archive_file="${tmp_dir}/node_exporter.tar.gz"
    
    log_info "Downloading from: $download_url"
    
    # Download
    if command -v curl &> /dev/null; then
        curl -fsSL "$download_url" -o "$archive_file"
    elif command -v wget &> /dev/null; then
        wget -q "$download_url" -O "$archive_file"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Extract
    log_info "Extracting archive..."
    tar xzf "$archive_file" -C "$tmp_dir"
    
    # Install binary
    log_info "Installing binary to ${INSTALL_DIR}..."
    mv "${tmp_dir}/node_exporter-${version}.linux-${ARCH}/node_exporter" "${INSTALL_DIR}/"
    chmod 755 "${INSTALL_DIR}/node_exporter"
    
    # Cleanup
    rm -rf "$tmp_dir"
    
    # Verify
    if [[ -x "${INSTALL_DIR}/node_exporter" ]]; then
        log_success "Binary installed successfully"
        ${INSTALL_DIR}/node_exporter --version
    else
        log_error "Failed to install binary"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Service Setup
# -----------------------------------------------------------------------------

create_user() {
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "User '$SERVICE_USER' already exists"
    else
        log_info "Creating system user: $SERVICE_USER"
        useradd --no-create-home --shell /bin/false "$SERVICE_USER"
    fi
    
    chown "$SERVICE_USER:$SERVICE_USER" "${INSTALL_DIR}/node_exporter"
}

create_systemd_service() {
    local port=$1
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    log_info "Creating systemd service file..."
    
    cat > "$service_file" <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${SERVICE_USER}
Group=${SERVICE_USER}
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=${INSTALL_DIR}/node_exporter --web.listen-address=:${port}

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload
    
    log_success "Systemd service created: $service_file"
}

create_sysvinit_service() {
    local port=$1
    local init_script="/etc/init.d/${SERVICE_NAME}"
    
    log_info "Creating SysVinit service script..."
    
    cat > "$init_script" <<'EOF'
#!/bin/bash
### BEGIN INIT INFO
# Provides:          node_exporter
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Prometheus Node Exporter
# Description:       Prometheus exporter for machine metrics
### END INIT INFO

NAME=node_exporter
DAEMON=/usr/local/bin/node_exporter
DAEMON_ARGS="--web.listen-address=:PORT_PLACEHOLDER"
PIDFILE=/var/run/$NAME.pid
USER=node_exporter

case "$1" in
    start)
        echo "Starting $NAME..."
        start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --chuid $USER --exec $DAEMON -- $DAEMON_ARGS
        ;;
    stop)
        echo "Stopping $NAME..."
        start-stop-daemon --stop --quiet --pidfile $PIDFILE
        rm -f $PIDFILE
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    status)
        if [ -f $PIDFILE ]; then
            if kill -0 $(cat $PIDFILE) 2>/dev/null; then
                echo "$NAME is running"
                exit 0
            fi
        fi
        echo "$NAME is not running"
        exit 1
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
EOF

    # Replace port placeholder
    sed -i "s/PORT_PLACEHOLDER/${port}/" "$init_script"
    chmod +x "$init_script"
    
    # Enable service
    if command -v update-rc.d &> /dev/null; then
        update-rc.d "$SERVICE_NAME" defaults
    elif command -v chkconfig &> /dev/null; then
        chkconfig --add "$SERVICE_NAME"
        chkconfig "$SERVICE_NAME" on
    fi
    
    log_success "SysVinit service created: $init_script"
}

start_service() {
    log_info "Starting ${SERVICE_NAME} service..."
    
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        systemctl enable "$SERVICE_NAME"
        systemctl start "$SERVICE_NAME"
        
        # Wait a moment and check status
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "Service started successfully"
        else
            log_error "Service failed to start. Check logs with: journalctl -u $SERVICE_NAME"
            exit 1
        fi
    else
        service "$SERVICE_NAME" start
    fi
}

# -----------------------------------------------------------------------------
# Firewall Configuration
# -----------------------------------------------------------------------------

configure_firewall() {
    local port=$1
    
    log_info "Configuring firewall for port $port..."
    
    # UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        ufw allow "$port/tcp" > /dev/null 2>&1 || true
        log_info "UFW: Allowed port $port/tcp"
    fi
    
    # Firewalld (RHEL/CentOS/Fedora)
    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-port="$port/tcp" > /dev/null 2>&1 || true
        firewall-cmd --reload > /dev/null 2>&1 || true
        log_info "Firewalld: Allowed port $port/tcp"
    fi
}

# -----------------------------------------------------------------------------
# Uninstall
# -----------------------------------------------------------------------------

uninstall() {
    log_info "Uninstalling Node Exporter..."
    
    # Stop and disable service
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl stop "prometheus-node-exporter" 2>/dev/null || true
        systemctl disable "$SERVICE_NAME" 2>/dev/null || true
        systemctl disable "prometheus-node-exporter" 2>/dev/null || true
        rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
        rm -f "/etc/systemd/system/prometheus-node-exporter.service"
        systemctl daemon-reload
    else
        service "$SERVICE_NAME" stop 2>/dev/null || true
        rm -f "/etc/init.d/${SERVICE_NAME}"
    fi
    
    # Remove binary
    rm -f "${INSTALL_DIR}/node_exporter"
    
    # Try removing package if installed via package manager
    if command -v apt-get &> /dev/null; then
        apt-get remove -y prometheus-node-exporter 2>/dev/null || true
    fi
    if command -v dnf &> /dev/null; then
        dnf remove -y node_exporter 2>/dev/null || true
    fi
    if command -v yum &> /dev/null; then
        yum remove -y node_exporter 2>/dev/null || true
    fi
    if command -v zypper &> /dev/null; then
        zypper remove -y golang-github-prometheus-node_exporter 2>/dev/null || true
    fi
    if command -v pacman &> /dev/null; then
        pacman -R --noconfirm prometheus-node-exporter 2>/dev/null || true
    fi
    
    # Remove user (optional - commented out to preserve if needed)
    # userdel "$SERVICE_USER" 2>/dev/null || true
    
    log_success "Node Exporter uninstalled successfully"
}

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

verify_installation() {
    local port=$1
    
    echo ""
    log_info "Verifying installation..."
    
    # Check service status
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        echo ""
        echo "Service Status:"
        systemctl status "$SERVICE_NAME" --no-pager -l | head -15
    fi
    
    # Check if port is listening
    echo ""
    if ss -tlnp | grep -q ":${port}"; then
        log_success "Port $port is listening"
    else
        log_warning "Port $port is not listening yet"
    fi
    
    # Test metrics endpoint
    echo ""
    log_info "Testing metrics endpoint..."
    sleep 2
    
    if curl -s "http://localhost:${port}/metrics" | head -5 > /dev/null 2>&1; then
        log_success "Metrics endpoint is accessible"
        echo ""
        echo "Sample metrics:"
        curl -s "http://localhost:${port}/metrics" | grep "node_exporter_build_info" | head -1
    else
        log_warning "Could not reach metrics endpoint yet. It may take a moment to start."
    fi
}

print_summary() {
    local port=$1
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Node Exporter is now running on port ${port}"
    echo ""
    echo "Useful commands:"
    echo "  - Check status:    sudo systemctl status ${SERVICE_NAME}"
    echo "  - View logs:       sudo journalctl -u ${SERVICE_NAME} -f"
    echo "  - Restart:         sudo systemctl restart ${SERVICE_NAME}"
    echo "  - Test metrics:    curl http://localhost:${port}/metrics"
    echo ""
    echo "Add this target to your Prometheus configuration:"
    echo "  scrape_configs:"
    echo "    - job_name: 'node'"
    echo "      static_configs:"
    echo "        - targets: ['<this-server-ip>:${port}']"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                NODE_EXPORTER_VERSION="$2"
                shift 2
                ;;
            --port)
                NODE_EXPORTER_PORT="$2"
                shift 2
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
    
    print_banner
    check_root
    
    # Detect system
    detect_os
    detect_arch
    detect_init_system
    
    # Handle uninstall
    if [[ "$UNINSTALL" == true ]]; then
        uninstall
        exit 0
    fi
    
    echo ""
    log_info "Starting installation..."
    
    # Try package manager first, fall back to binary installation
    INSTALLED_VIA_PKG=false
    
    case $OS in
        ubuntu|debian|linuxmint|pop)
            if [[ "$NODE_EXPORTER_VERSION" == "latest" ]]; then
                install_via_apt && INSTALLED_VIA_PKG=true || true
            fi
            ;;
        rhel|centos|rocky|almalinux|ol)
            if [[ "$NODE_EXPORTER_VERSION" == "latest" ]]; then
                if command -v dnf &> /dev/null; then
                    install_via_dnf && INSTALLED_VIA_PKG=true || true
                else
                    install_via_yum && INSTALLED_VIA_PKG=true || true
                fi
            fi
            ;;
        fedora)
            if [[ "$NODE_EXPORTER_VERSION" == "latest" ]]; then
                install_via_dnf && INSTALLED_VIA_PKG=true || true
            fi
            ;;
        opensuse*|sles|suse)
            if [[ "$NODE_EXPORTER_VERSION" == "latest" ]]; then
                install_via_zypper && INSTALLED_VIA_PKG=true || true
            fi
            ;;
        arch|manjaro|endeavouros)
            if [[ "$NODE_EXPORTER_VERSION" == "latest" ]]; then
                install_via_pacman && INSTALLED_VIA_PKG=true || true
            fi
            ;;
    esac
    
    # If package manager installation failed or specific version requested, use binary
    if [[ "$INSTALLED_VIA_PKG" == false ]]; then
        log_info "Using binary installation method..."
        install_binary "$NODE_EXPORTER_VERSION"
        create_user
        
        if [[ "$INIT_SYSTEM" == "systemd" ]]; then
            create_systemd_service "$NODE_EXPORTER_PORT"
        else
            create_sysvinit_service "$NODE_EXPORTER_PORT"
        fi
    fi
    
    # Configure firewall
    configure_firewall "$NODE_EXPORTER_PORT"
    
    # Start service
    start_service
    
    # Verify and print summary
    verify_installation "$NODE_EXPORTER_PORT"
    print_summary "$NODE_EXPORTER_PORT"
}

# Run main function
main "$@"
