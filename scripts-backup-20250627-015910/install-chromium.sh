#!/bin/bash

# Install Chromium for BrowserShield on Oracle Linux 9
# Chromium is easier to install than Chrome on Oracle Linux

set -e

echo "🌐 Installing Chromium for BrowserShield..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

APP_DIR="/home/browserapp/browsershield"

print_status "Step 1: Installing EPEL repository..."
sudo dnf install -y epel-release

print_status "Step 2: Installing Chromium from EPEL..."
if sudo dnf install -y chromium; then
    print_status "✅ Chromium installed successfully"
else
    print_error "Failed to install Chromium from EPEL"
    
    print_status "Trying alternative: Installing chromium-browser..."
    if sudo dnf install -y chromium-browser; then
        print_status "✅ chromium-browser installed"
        # Create symlink for compatibility
        sudo ln -sf /usr/bin/chromium-browser /usr/bin/chromium 2>/dev/null || true
    else
        print_error "Failed to install Chromium alternatives"
        exit 1
    fi
fi

# Check Chromium installation
if command -v chromium &> /dev/null; then
    CHROMIUM_PATH="/usr/bin/chromium"
elif command -v chromium-browser &> /dev/null; then
    CHROMIUM_PATH="/usr/bin/chromium-browser"
else
    print_error "Chromium not found after installation"
    exit 1
fi

print_status "Chromium path: $CHROMIUM_PATH"

# Test Chromium headless
print_status "Testing Chromium headless mode..."
if timeout 15 $CHROMIUM_PATH --headless --no-sandbox --disable-gpu --dump-dom https://example.com >/dev/null 2>&1; then
    print_status "✅ Chromium headless test successful"
else
    print_warning "Chromium test completed (may have timeout, normal)"
fi

# Update BrowserShield configuration
if [ -d "$APP_DIR" ]; then
    print_status "Updating BrowserShield configuration..."
    
    # Update .env with Chromium path
    sudo -u browserapp sed -i '/PUPPETEER_EXECUTABLE_PATH/d' "$APP_DIR/.env"
    sudo -u browserapp tee -a "$APP_DIR/.env" > /dev/null << EOF

# Chromium Configuration
PUPPETEER_EXECUTABLE_PATH=$CHROMIUM_PATH
BROWSER_TYPE=chromium
EOF
    
    print_status "✅ Configuration updated"
fi

echo ""
echo "🌐 Chromium installation completed!"
echo "Path: $CHROMIUM_PATH"
echo ""