#!/bin/bash

# Fix Chrome installation on Oracle Linux 9
# Handle dependency conflicts and architecture issues

set -e

echo "🔧 Fixing Chrome installation on Oracle Linux 9..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clean up any previous Chrome installation attempts
print_status "Cleaning up previous Chrome installation..."
sudo dnf remove -y google-chrome-stable 2>/dev/null || true
sudo rm -f /etc/yum.repos.d/google-chrome.repo

# Install EPEL repository for additional packages
print_status "Installing EPEL repository..."
sudo dnf install -y epel-release

# Enable CodeReady Builder repository for development packages
print_status "Enabling CodeReady Builder repository..."
sudo dnf config-manager --set-enabled ol9_codeready_builder || true

# Install minimal Chrome dependencies that actually exist
print_status "Installing minimal Chrome dependencies..."
sudo dnf install -y \
    alsa-lib \
    atk \
    cairo \
    cups-libs \
    dbus-glib \
    fontconfig \
    freetype \
    gdk-pixbuf2 \
    glib2 \
    gtk3 \
    libX11 \
    libXcomposite \
    libXcursor \
    libXdamage \
    libXext \
    libXfixes \
    libXi \
    libXrandr \
    libXrender \
    libXss \
    libXtst \
    libdrm \
    libxcb \
    libxshmfence \
    mesa-libgbm \
    nss \
    pango \
    vulkan-loader \
    liberation-fonts

# Try alternative Chrome installation methods
print_status "Installing Chrome via direct download..."

# Method 1: Download Chrome RPM directly
CHROME_RPM="/tmp/google-chrome-stable.rpm"
if curl -L "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o "$CHROME_RPM"; then
    print_status "Downloaded Chrome RPM, attempting installation..."
    
    # Install with --nobest to handle dependency conflicts
    if sudo dnf install -y --nobest "$CHROME_RPM" 2>/dev/null; then
        print_status "✅ Chrome installed successfully via RPM"
    elif sudo rpm -ivh --force --nodeps "$CHROME_RPM" 2>/dev/null; then
        print_warning "Chrome installed with --force --nodeps"
    else
        print_error "Failed to install Chrome RPM"
    fi
    
    rm -f "$CHROME_RPM"
else
    print_error "Failed to download Chrome RPM"
fi

# Verify Chrome installation
if command -v google-chrome-stable &> /dev/null; then
    CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null || echo "Installed but version check failed")
    print_status "Chrome status: $CHROME_VERSION"
    
    # Test Chrome in headless mode
    if google-chrome-stable --headless --no-sandbox --disable-dev-shm-usage --dump-dom https://example.com >/dev/null 2>&1; then
        print_status "✅ Chrome headless test successful"
    else
        print_warning "Chrome installed but headless test failed"
    fi
else
    print_error "Chrome installation failed"
    
    # Fallback: Install Chromium instead
    print_status "Attempting Chromium installation as fallback..."
    if sudo dnf install -y chromium; then
        print_status "✅ Chromium installed as fallback"
        # Create symlink for compatibility
        sudo ln -sf /usr/bin/chromium-browser /usr/bin/google-chrome-stable 2>/dev/null || true
    fi
fi

echo "Chrome/Chromium installation completed."