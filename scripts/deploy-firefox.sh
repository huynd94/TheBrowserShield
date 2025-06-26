#!/bin/bash

# Deploy Firefox-powered BrowserShield to production
# Complete installation for Oracle Linux 9

echo "🦊 Deploying Firefox-powered BrowserShield..."

set -e

APP_DIR="/home/browserapp/browsershield"
BACKUP_DIR="/home/browserapp/backup-$(date +%Y%m%d-%H%M%S)"

# Create backup
sudo -u browserapp mkdir -p "$BACKUP_DIR"
sudo -u browserapp cp -r "$APP_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Created backup at: $BACKUP_DIR"

# Download latest Firefox files from GitHub
echo "📥 Downloading Firefox integration files..."
cd /tmp

curl -sSL "https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/config/firefox-puppeteer.js" -o firefox-puppeteer.js
curl -sSL "https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/services/FirefoxBrowserService.js" -o FirefoxBrowserService.js

sudo -u browserapp cp firefox-puppeteer.js "$APP_DIR/config/"
sudo -u browserapp cp FirefoxBrowserService.js "$APP_DIR/services/"

echo "✅ Firefox files installed"

# Install Firefox and dependencies
echo "🦊 Installing Firefox..."
sudo dnf install -y firefox

# Install puppeteer-firefox
echo "📦 Installing puppeteer-firefox..."
sudo -u browserapp bash -c "cd $APP_DIR && npm install puppeteer-firefox"

# Update routes to use Firefox
echo "🔄 Switching to Firefox service..."
sudo -u browserapp cp "$APP_DIR/routes/profiles.js" "$APP_DIR/routes/profiles.js.backup"

# Replace service imports and instantiation
sudo -u browserapp sed -i 's/MockBrowserService/FirefoxBrowserService/g' "$APP_DIR/routes/profiles.js"
sudo -u browserapp sed -i 's/BrowserService/FirefoxBrowserService/g' "$APP_DIR/routes/profiles.js"

# Update environment
echo "⚙️  Configuring Firefox environment..."
sudo -u browserapp tee -a "$APP_DIR/.env" > /dev/null << 'EOF'

# Firefox Configuration
FIREFOX_EXECUTABLE_PATH=/usr/bin/firefox
BROWSER_TYPE=firefox
PUPPETEER_PRODUCT=firefox
EOF

# Restart service
echo "🔄 Restarting BrowserShield with Firefox..."
sudo systemctl restart browsershield.service

sleep 5

# Verify deployment
if sudo systemctl is-active --quiet browsershield.service; then
    echo "✅ BrowserShield with Firefox deployed successfully!"
    
    FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "Firefox installed")
    echo "🦊 $FIREFOX_VERSION"
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")
    echo ""
    echo "🌐 Access: http://$SERVER_IP:5000"
    echo "🦊 Browser: Firefox (Real browser automation enabled)"
    echo ""
    
else
    echo "❌ Deployment failed. Checking logs..."
    sudo journalctl -u browsershield.service -n 20
    
    echo "🔄 Reverting to backup..."
    sudo -u browserapp cp "$APP_DIR/routes/profiles.js.backup" "$APP_DIR/routes/profiles.js"
    sudo systemctl restart browsershield.service
fi

rm -f /tmp/firefox-puppeteer.js /tmp/FirefoxBrowserService.js