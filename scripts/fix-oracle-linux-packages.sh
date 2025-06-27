#!/bin/bash
# Fix Oracle Linux 9 Package Installation Issues
# Handles htop and other missing packages

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

log "Fixing Oracle Linux 9 package installation issues..."

# Enable EPEL repository first
info "Enabling EPEL repository..."
if ! dnf list installed epel-release >/dev/null 2>&1; then
    dnf install -y epel-release
    log "EPEL repository enabled"
else
    info "EPEL repository already enabled"
fi

# Update package cache
info "Updating package cache..."
dnf clean all
dnf makecache

# Install htop from EPEL
info "Installing htop from EPEL..."
if dnf install -y htop; then
    log "htop installed successfully"
else
    warn "htop installation failed, continuing without it"
fi

# Install other essential packages
info "Installing essential packages..."
PACKAGES=(
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
)

for package in "${PACKAGES[@]}"; do
    if ! dnf list installed "$package" >/dev/null 2>&1; then
        info "Installing $package..."
        if dnf install -y "$package"; then
            log "$package installed"
        else
            warn "$package installation failed, skipping"
        fi
    else
        info "$package already installed"
    fi
done

# Install Node.js
info "Installing Node.js..."
if ! command -v node >/dev/null 2>&1; then
    # Install Node.js 20
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs
    log "Node.js installed: $(node --version)"
else
    log "Node.js already installed: $(node --version)"
fi

# Install Chrome for production mode
info "Installing Google Chrome..."
if ! command -v google-chrome >/dev/null 2>&1; then
    # Add Google Chrome repository
    cat > /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    
    dnf install -y google-chrome-stable
    log "Google Chrome installed"
else
    log "Google Chrome already installed"
fi

# Install Chromium as fallback
info "Installing Chromium as fallback..."
if ! command -v chromium-browser >/dev/null 2>&1; then
    if dnf install -y chromium; then
        log "Chromium installed"
    else
        warn "Chromium installation failed"
    fi
else
    log "Chromium already installed"
fi

# Verify installations
log "Verifying installations..."
echo "================================"
echo "Node.js: $(node --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "npm: $(npm --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "Chrome: $(google-chrome --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "Chromium: $(chromium-browser --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "htop: $(htop --version 2>/dev/null | head -1 || echo 'NOT INSTALLED')"
echo "================================"

log "Package installation fixes completed!"
info "You can now proceed with BrowserShield installation"