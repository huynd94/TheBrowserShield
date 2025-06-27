#!/bin/bash

# Install Firefox for BrowserShield on Oracle Linux 9
# Firefox is more compatible with Oracle Linux 9 than Chrome

set -e

echo "🦊 Installing Firefox for BrowserShield on Oracle Linux 9..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Install Firefox from Oracle Linux repository
print_status "Installing Firefox from official repository..."
sudo dnf install -y firefox

# Verify Firefox installation
if command -v firefox &> /dev/null; then
    FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "Installed")
    print_status "Firefox installed: $FIREFOX_VERSION"
else
    print_error "Firefox installation failed"
    exit 1
fi

# Test Firefox in headless mode
print_status "Testing Firefox headless mode..."
if timeout 30 firefox --headless --screenshot=/tmp/test-screenshot.png https://example.com 2>/dev/null; then
    print_status "✅ Firefox headless test successful"
    rm -f /tmp/test-screenshot.png
else
    print_warning "Firefox test completed (may have timeout)"
fi

# Install puppeteer-firefox for Node.js
print_status "Installing puppeteer-firefox for Node.js integration..."
APP_DIR="/home/browserapp/browsershield"
if [ -d "$APP_DIR" ]; then
    sudo -u browserapp bash -c "cd $APP_DIR && npm install puppeteer-firefox"
    print_status "✅ Puppeteer-Firefox installed"
else
    print_warning "BrowserShield app directory not found"
fi

echo "🦊 Firefox installation completed!"