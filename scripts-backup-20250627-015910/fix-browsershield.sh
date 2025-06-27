#!/bin/bash

# Fix BrowserShield service after failed Firefox installation
# Revert to working state and use Chromium

set -e

echo "🔧 Fixing BrowserShield service..."

APP_DIR="/home/browserapp/browsershield"
BACKUP_DIR="/home/browserapp/backup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Step 1: Stopping BrowserShield service..."
sudo systemctl stop browsershield.service

print_status "Step 2: Cleaning up failed Firefox installation..."
if [ -f "$APP_DIR/routes/profiles.js.backup" ]; then
    sudo -u browserapp cp "$APP_DIR/routes/profiles.js.backup" "$APP_DIR/routes/profiles.js"
    print_status "✅ Restored routes from backup"
fi

# Remove problematic packages
print_status "Step 3: Removing puppeteer-firefox..."
sudo -u browserapp bash -c "cd $APP_DIR && npm uninstall puppeteer-firefox" 2>/dev/null || true

print_status "Step 4: Installing Chromium..."
sudo dnf install -y epel-release
if sudo dnf install -y chromium; then
    CHROMIUM_PATH="/usr/bin/chromium"
elif sudo dnf install -y chromium-browser; then
    CHROMIUM_PATH="/usr/bin/chromium-browser"
    sudo ln -sf /usr/bin/chromium-browser /usr/bin/chromium 2>/dev/null || true
else
    print_warning "Chromium installation failed, using Mock mode"
    CHROMIUM_PATH=""
fi

print_status "Step 5: Updating BrowserShield configuration..."

if [ -n "$CHROMIUM_PATH" ] && [ -f "$CHROMIUM_PATH" ]; then
    # Switch to real BrowserService with Chromium
    sudo -u browserapp sed -i 's/MockBrowserService/BrowserService/g' "$APP_DIR/routes/profiles.js"
    
    # Update environment
    sudo -u browserapp sed -i '/FIREFOX_EXECUTABLE_PATH/d' "$APP_DIR/.env" 2>/dev/null || true
    sudo -u browserapp sed -i '/BROWSER_TYPE=firefox/d' "$APP_DIR/.env" 2>/dev/null || true
    sudo -u browserapp sed -i '/PUPPETEER_PRODUCT=firefox/d' "$APP_DIR/.env" 2>/dev/null || true
    sudo -u browserapp sed -i '/PUPPETEER_EXECUTABLE_PATH/d' "$APP_DIR/.env" 2>/dev/null || true
    
    sudo -u browserapp tee -a "$APP_DIR/.env" > /dev/null << EOF

# Chromium Configuration (Fixed)
PUPPETEER_EXECUTABLE_PATH=$CHROMIUM_PATH
BROWSER_TYPE=chromium
EOF
    
    print_status "✅ Configured for Chromium: $CHROMIUM_PATH"
else
    # Keep Mock mode if Chromium failed
    sudo -u browserapp sed -i 's/BrowserService/MockBrowserService/g' "$APP_DIR/routes/profiles.js"
    sudo -u browserapp sed -i 's/FirefoxBrowserService/MockBrowserService/g' "$APP_DIR/routes/profiles.js"
    print_warning "Using Mock mode (Chromium not available)"
fi

print_status "Step 6: Cleaning up environment..."
sudo -u browserapp bash -c "cd $APP_DIR && npm install" 2>/dev/null || true

print_status "Step 7: Starting BrowserShield service..."
sudo systemctl start browsershield.service

sleep 5

if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ BrowserShield service is running!"
    
    # Test service
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_status "✅ Service responding"
    elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
        print_status "✅ Web interface accessible"
    fi
    
    if [ -n "$CHROMIUM_PATH" ] && [ -f "$CHROMIUM_PATH" ]; then
        CHROMIUM_VERSION=$($CHROMIUM_PATH --version 2>/dev/null || echo "Version unknown")
        print_status "Browser: $CHROMIUM_VERSION"
        print_status "Mode: Production (Real browser automation)"
    else
        print_status "Mode: Mock (Demo mode)"
    fi
    
else
    print_error "❌ Service still not running. Checking logs..."
    sudo journalctl -u browsershield.service -n 20
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")

echo ""
echo "🔧 BrowserShield service fixed!"
echo ""
echo "🌐 Access: http://$SERVER_IP:5000"
echo "🔧 Status: sudo systemctl status browsershield.service"
echo "📋 Logs:   sudo journalctl -u browsershield.service -f"
echo ""