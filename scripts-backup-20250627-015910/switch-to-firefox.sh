#!/bin/bash

# Switch BrowserShield from Chrome/Mock to Firefox
# For Oracle Linux 9 compatibility

set -e

echo "🦊 Switching BrowserShield to Firefox mode..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

APP_DIR="/home/browserapp/browsershield"

if [ ! -d "$APP_DIR" ]; then
    print_error "BrowserShield app directory not found: $APP_DIR"
    exit 1
fi

print_status "Step 1: Installing Firefox..."
sudo dnf install -y firefox

print_status "Step 2: Installing puppeteer-firefox..."
sudo -u browserapp bash -c "cd $APP_DIR && npm install puppeteer-firefox"

print_status "Step 3: Backing up current routes..."
sudo -u browserapp cp $APP_DIR/routes/profiles.js $APP_DIR/routes/profiles.js.backup

print_status "Step 4: Updating routes to use Firefox service..."
sudo -u browserapp sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/FirefoxBrowserService')/g" $APP_DIR/routes/profiles.js
sudo -u browserapp sed -i "s/require('..\/services\/BrowserService')/require('..\/services\/FirefoxBrowserService')/g" $APP_DIR/routes/profiles.js
sudo -u browserapp sed -i "s/new MockBrowserService()/new FirefoxBrowserService()/g" $APP_DIR/routes/profiles.js
sudo -u browserapp sed -i "s/new BrowserService()/new FirefoxBrowserService()/g" $APP_DIR/routes/profiles.js

print_status "Step 5: Updating environment for Firefox..."
sudo -u browserapp tee -a $APP_DIR/.env > /dev/null << 'EOF'

# Firefox Configuration
FIREFOX_EXECUTABLE_PATH=/usr/bin/firefox
BROWSER_TYPE=firefox
EOF

print_status "Step 6: Restarting BrowserShield service..."
sudo systemctl restart browsershield.service

sleep 3

if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ BrowserShield switched to Firefox successfully!"
    
    # Test Firefox functionality
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_status "✅ Service is responding"
    fi
    
    FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "Version check failed")
    print_status "Firefox: $FIREFOX_VERSION"
    
else
    print_error "❌ Service failed to start with Firefox"
    print_status "Checking logs..."
    sudo journalctl -u browsershield.service -n 10
    
    print_status "Reverting to backup..."
    sudo -u browserapp cp $APP_DIR/routes/profiles.js.backup $APP_DIR/routes/profiles.js
    sudo systemctl restart browsershield.service
fi

echo ""
echo "🦊 Firefox integration completed!"
echo ""
echo "🌐 Test the application:"
echo "   Web UI: http://$(curl -s ifconfig.me):5000"
echo "   Create a profile and start a Firefox browser session"
echo ""
echo "🔧 Service management:"
echo "   Status: sudo systemctl status browsershield.service"
echo "   Logs:   sudo journalctl -u browsershield.service -f"