#!/bin/bash
# Quick fix script to restore BrowserShield functionality

echo "Fixing BrowserShield service..."

# Step 1: Stop service
echo "Stopping service..."
sudo systemctl stop browsershield.service

# Step 2: Go to app directory
cd /home/browserapp/browsershield

# Step 3: Restore working routes from backup
if [ -f "routes/profiles.js.backup" ]; then
    sudo -u browserapp cp routes/profiles.js.backup routes/profiles.js
    echo "Routes restored from backup"
fi

# Step 4: Remove problematic Firefox packages
echo "Removing puppeteer-firefox..."
sudo -u browserapp npm uninstall puppeteer-firefox 2>/dev/null || true

# Step 5: Install Chromium (easier than Chrome)
echo "Installing Chromium..."
sudo dnf install -y epel-release
sudo dnf install -y chromium

# Step 6: Check if Chromium installed
if command -v chromium &> /dev/null; then
    echo "Chromium found, switching to production mode..."
    
    # Update routes to use real BrowserService
    sudo -u browserapp sed -i 's/MockBrowserService/BrowserService/g' routes/profiles.js
    
    # Clean up old Firefox config
    sudo -u browserapp sed -i '/FIREFOX_EXECUTABLE_PATH/d' .env 2>/dev/null || true
    sudo -u browserapp sed -i '/BROWSER_TYPE=firefox/d' .env 2>/dev/null || true
    sudo -u browserapp sed -i '/PUPPETEER_PRODUCT=firefox/d' .env 2>/dev/null || true
    sudo -u browserapp sed -i '/PUPPETEER_EXECUTABLE_PATH/d' .env 2>/dev/null || true
    
    # Add Chromium config
    echo "" | sudo -u browserapp tee -a .env
    echo "PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium" | sudo -u browserapp tee -a .env
    echo "BROWSER_TYPE=chromium" | sudo -u browserapp tee -a .env
    
    echo "Configured for Chromium production mode"
else
    echo "Chromium not available, keeping Mock mode"
fi

# Step 7: Start service
echo "Starting service..."
sudo systemctl start browsershield.service

# Step 8: Check status
sleep 3
if sudo systemctl is-active --quiet browsershield.service; then
    echo "SUCCESS: BrowserShield is running!"
    
    # Test endpoint
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "Service responding on http://localhost:5000"
    fi
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_IP")
    echo "Access: http://$SERVER_IP:5000"
    
    if command -v chromium &> /dev/null; then
        echo "Mode: Production (Real browsers with Chromium)"
    else
        echo "Mode: Mock (Demo mode)"
    fi
else
    echo "FAILED: Service not running. Logs:"
    sudo journalctl -u browsershield.service -n 5
fi