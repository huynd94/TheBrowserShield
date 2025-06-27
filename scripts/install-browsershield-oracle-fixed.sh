#!/bin/bash
# BrowserShield Installation Script for Oracle Linux 9 - FIXED VERSION
# Handles package availability issues and installation errors

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
APP_NAME="browsershield"
APP_USER="opc"
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"
PORT=5000
GITHUB_REPO="https://raw.githubusercontent.com/huynd94/TheBrowserShield/main"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

show_banner() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}  BrowserShield Auto-Installer for Oracle Linux 9${NC}"
    echo -e "${CYAN}  Fixed Version - Handles Package Issues${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root user (use sudo)"
        exit 1
    fi
}

check_system() {
    log "Checking system compatibility..."
    
    # Check Oracle Linux
    if ! grep -q "Oracle Linux" /etc/oracle-release 2>/dev/null; then
        warn "This script is optimized for Oracle Linux 9"
        warn "Continuing anyway, but some features may not work"
    else
        local version=$(grep -o 'release [0-9]*' /etc/oracle-release | cut -d' ' -f2)
        info "Detected Oracle Linux version: $version"
    fi
    
    # Check architecture
    local arch=$(uname -m)
    info "System architecture: $arch"
    
    # Check memory
    local memory=$(free -m | grep '^Mem:' | awk '{print $2}')
    info "Available memory: ${memory}MB"
    
    if [ "$memory" -lt 1024 ]; then
        warn "Low memory detected. BrowserShield may run slowly."
    fi
    
    # Check disk space
    local disk=$(df / | tail -1 | awk '{print $4}')
    info "Available disk space: $(df -h / | tail -1 | awk '{print $4}')"
}

setup_repositories() {
    log "Setting up package repositories..."
    
    # Enable EPEL repository
    info "Enabling EPEL repository..."
    if ! dnf list installed epel-release >/dev/null 2>&1; then
        dnf install -y epel-release
        log "EPEL repository enabled"
    else
        info "EPEL repository already enabled"
    fi
    
    # Add Google Chrome repository
    info "Adding Google Chrome repository..."
    cat > /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    
    # Update package cache
    info "Updating package cache..."
    dnf clean all
    dnf makecache
}

install_system_packages() {
    log "Installing system packages..."
    
    # Essential packages (skip htop if not available)
    local ESSENTIAL_PACKAGES=(
        "curl"
        "wget" 
        "unzip"
        "tar"
        "git"
        "nano"
        "vim"
        "net-tools"
        "lsof"
        "psmisc"
        "procps-ng"
        "firewalld"
    )
    
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        if ! dnf list installed "$package" >/dev/null 2>&1; then
            info "Installing $package..."
            if dnf install -y "$package"; then
                log "$package installed successfully"
            else
                warn "$package installation failed, continuing without it"
            fi
        else
            info "$package already installed"
        fi
    done
    
    # Try to install htop from EPEL (optional)
    info "Attempting to install htop..."
    if dnf install -y htop 2>/dev/null; then
        log "htop installed successfully"
    else
        warn "htop not available, using alternative monitoring tools"
    fi
}

install_nodejs() {
    log "Installing Node.js..."
    
    if command -v node >/dev/null 2>&1; then
        local current_version=$(node --version)
        info "Node.js already installed: $current_version"
        return 0
    fi
    
    # Install Node.js 20
    info "Adding Node.js repository..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    
    info "Installing Node.js..."
    dnf install -y nodejs
    
    # Verify installation
    if command -v node >/dev/null 2>&1; then
        log "Node.js installed successfully: $(node --version)"
        log "npm version: $(npm --version)"
    else
        error "Node.js installation failed"
        exit 1
    fi
}

install_chrome() {
    log "Installing Google Chrome..."
    
    if command -v google-chrome >/dev/null 2>&1; then
        info "Google Chrome already installed"
        return 0
    fi
    
    # Install Google Chrome
    info "Installing Google Chrome stable..."
    if dnf install -y google-chrome-stable; then
        log "Google Chrome installed successfully"
    else
        warn "Google Chrome installation failed, trying Chromium..."
        
        # Fallback to Chromium
        if dnf install -y chromium; then
            log "Chromium installed as fallback"
        else
            error "Neither Chrome nor Chromium could be installed"
            error "Production mode will not work without a browser"
        fi
    fi
}

create_user_setup() {
    log "Setting up application user..."
    
    # Switch to opc user for application setup
    if [ "$USER" = "root" ]; then
        info "Creating application directory for opc user..."
        if [ ! -d "$APP_DIR" ]; then
            sudo -u opc mkdir -p "$APP_DIR"
            log "Application directory created: $APP_DIR"
        fi
    fi
}

download_application() {
    log "Downloading BrowserShield application..."
    
    # Download as opc user
    sudo -u opc bash << EOF
cd /home/opc
if [ -d "browsershield" ]; then
    echo "Backing up existing installation..."
    mv browsershield browsershield-backup-\$(date +%Y%m%d_%H%M%S)
fi

echo "Cloning BrowserShield repository..."
if ! git clone https://github.com/huynd94/TheBrowserShield.git browsershield; then
    echo "Git clone failed, trying wget..."
    mkdir -p browsershield
    cd browsershield
    wget -q --timeout=30 --tries=3 "${GITHUB_REPO}/server.js" -O server.js
    wget -q --timeout=30 --tries=3 "${GITHUB_REPO}/package.json" -O package.json
    mkdir -p public routes services config middleware utils data
    echo "Application files downloaded"
fi
EOF
    
    if [ -f "$APP_DIR/server.js" ]; then
        log "Application downloaded successfully"
    else
        error "Application download failed"
        exit 1
    fi
}

install_dependencies() {
    log "Installing Node.js dependencies..."
    
    sudo -u opc bash << EOF
cd "$APP_DIR"
if [ -f "package.json" ]; then
    echo "Installing npm dependencies..."
    npm install --production
    echo "Dependencies installed"
else
    echo "package.json not found, creating minimal setup..."
    npm init -y
    npm install express cors uuid puppeteer-extra puppeteer-extra-plugin-stealth
fi
EOF
    
    log "Dependencies installation completed"
}

configure_firewall() {
    log "Configuring firewall..."
    
    # Start firewalld
    systemctl enable firewalld
    systemctl start firewalld
    
    # Open port 5000
    info "Opening port $PORT..."
    firewall-cmd --permanent --add-port=$PORT/tcp
    firewall-cmd --reload
    
    log "Firewall configured - port $PORT opened"
}

create_systemd_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$PORT
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    
    log "Systemd service created and enabled"
}

start_application() {
    log "Starting BrowserShield application..."
    
    # Start the service
    systemctl start $SERVICE_NAME
    
    # Wait for startup
    sleep 5
    
    # Check if service is running
    if systemctl is-active --quiet $SERVICE_NAME; then
        log "BrowserShield started successfully!"
        
        # Get public IP
        local ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")
        
        echo
        echo -e "${GREEN}================================${NC}"
        echo -e "${GREEN}  Installation Completed!${NC}"
        echo -e "${GREEN}================================${NC}"
        echo
        echo -e "Access BrowserShield at: ${CYAN}http://$ip:$PORT${NC}"
        echo -e "Service status: ${GREEN}systemctl status $SERVICE_NAME${NC}"
        echo -e "View logs: ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}"
        echo
        
    else
        error "BrowserShield failed to start"
        warn "Check logs: journalctl -u $SERVICE_NAME"
        exit 1
    fi
}

cleanup_installation() {
    log "Cleaning up installation files..."
    
    # Clean package cache
    dnf clean all
    
    # Remove temporary files
    rm -f /tmp/node_setup.sh
    
    log "Cleanup completed"
}

# Main installation process
main() {
    show_banner
    
    # Pre-flight checks
    check_root
    check_system
    
    # Installation steps
    setup_repositories
    install_system_packages
    install_nodejs
    install_chrome
    create_user_setup
    download_application
    install_dependencies
    configure_firewall
    create_systemd_service
    start_application
    cleanup_installation
    
    log "BrowserShield installation completed successfully!"
}

# Execute main function
main "$@"