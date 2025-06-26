#!/bin/bash

# Quick fix for BrowserShield - restore working state
# Use Chromium instead of problematic Firefox

echo "🔧 Quick fix for BrowserShield..."

APP_DIR="/home/browserapp/browsershield"

# Stop service
sudo systemctl stop browsershield.service

# Restore working routes
if [ -f "$APP_DIR/routes/profiles.js.backup" ]; then
    sudo -u browserapp cp "$APP_DIR/routes/profiles.js.backup" "$APP_DIR/routes/profiles.js"
    echo "✅ Restored routes"
fi

# Remove Firefox packages
sudo -u browserapp bash -c "cd $APP_DIR && npm uninstall puppeteer-firefox" 2>/dev/null || true

# Install Chromium (easier than Chrome on Oracle Linux)
sudo dnf install -y epel-release chromium

# Check Chromium
if command -v chromium &> /dev/null; then
    CHROMIUM_PATH="/usr/bin/chromium"
    echo "✅ Chromium found: $CHROMIUM_PATH"
    
    # Switch to real browser with Chromium
    sudo -u browserapp sed -i 's/MockBrowserService/BrowserService/g' "$APP_DIR/routes/profiles.js"
    
    # Update environment
    sudo -u browserapp sed -i '/FIREFOX_EXECUTABLE_PATH/d' "$APP_DIR/.env" 2>/dev/null || true
    sudo -u browserapp sed -i '/BROWSER_TYPE=firefox/d' "$APP_DIR/.env" 2>/dev/null || true  
    sudo -u browserapp sed -i '/PUPPETEER_PRODUCT=firefox/d' "$APP_DIR/.env" 2>/dev/null || true
    sudo -u browserapp sed -i '/PUPPETEER_EXECUTABLE_PATH/d' "$APP_DIR/.env" 2>/dev/null || true
    
    echo "" | sudo -u browserapp tee -a "$APP_DIR/.env"
    echo "PUPPETEER_EXECUTABLE_PATH=$CHROMIUM_PATH" | sudo -u browserapp tee -a "$APP_DIR/.env"
    echo "BROWSER_TYPE=chromium" | sudo -u browserapp tee -a "$APP_DIR/.env"
    
    echo "✅ Switched to Chromium production mode"
else
    echo "⚠️ Chromium not found, keeping Mock mode"
fi

# Start service
sudo systemctl start browsershield.service

sleep 3

if sudo systemctl is-active --quiet browsershield.service; then
    echo "✅ BrowserShield fixed and running!"
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "138.2.82.254")
    echo "🌐 Access: http://$SERVER_IP:5000"
    
    if command -v chromium &> /dev/null; then
        echo "🌐 Mode: Production with Chromium"
    else
        echo "🌐 Mode: Mock (demo)"
    fi
else
    echo "❌ Still failing. Check logs:"
    sudo journalctl -u browsershield.service -n 10
fi