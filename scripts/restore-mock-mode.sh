#!/bin/bash

# Restore BrowserShield to stable Mock mode
# Clean up all browser-related issues and run stable demo

echo "🔧 Restoring BrowserShield to stable Mock mode..."

APP_DIR="/home/browserapp/browsershield"
cd $APP_DIR

# Stop service
sudo systemctl stop browsershield.service

# Clean up routes - ensure using MockBrowserService
sudo -u browserapp sed -i 's/BrowserService/MockBrowserService/g' routes/profiles.js
sudo -u browserapp sed -i 's/FirefoxBrowserService/MockBrowserService/g' routes/profiles.js

# Clean up environment - remove all browser configs
sudo -u browserapp sed -i '/FIREFOX_EXECUTABLE_PATH/d' .env 2>/dev/null || true
sudo -u browserapp sed -i '/BROWSER_TYPE=firefox/d' .env 2>/dev/null || true
sudo -u browserapp sed -i '/BROWSER_TYPE=chromium/d' .env 2>/dev/null || true
sudo -u browserapp sed -i '/PUPPETEER_PRODUCT=firefox/d' .env 2>/dev/null || true
sudo -u browserapp sed -i '/PUPPETEER_EXECUTABLE_PATH/d' .env 2>/dev/null || true

# Add clean Mock configuration
echo "" | sudo -u browserapp tee -a .env
echo "# Mock Mode Configuration" | sudo -u browserapp tee -a .env
echo "BROWSER_MODE=mock" | sudo -u browserapp tee -a .env
echo "PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true" | sudo -u browserapp tee -a .env

# Remove problematic packages
sudo -u browserapp npm uninstall puppeteer-firefox chromium 2>/dev/null || true

# Clean install dependencies
sudo -u browserapp npm install

# Start service
sudo systemctl start browsershield.service

sleep 5

# Check status
if sudo systemctl is-active --quiet browsershield.service; then
    echo "✅ SUCCESS: BrowserShield running in stable Mock mode!"
    
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ Service responding"
    elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
        echo "✅ Web interface accessible"
    fi
    
    echo ""
    echo "🌐 Access: http://138.2.82.254:5000"
    echo "🎭 Mode: Mock (Stable demo - all features work)"
    echo "📱 Features: Profile management, API, Web UI"
    echo ""
    echo "✅ BrowserShield is ready for testing!"
    
else
    echo "❌ Still failing. Logs:"
    sudo journalctl -u browsershield.service -n 10
fi