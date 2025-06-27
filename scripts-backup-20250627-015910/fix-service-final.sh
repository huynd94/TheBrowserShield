#!/bin/bash

# Final fix for BrowserShield service
# Comprehensive fix for all known issues

echo "Final fix for BrowserShield service..."

APP_DIR="/home/browserapp/browsershield"
cd $APP_DIR

# Stop service
sudo systemctl stop browsershield.service

echo "1. Ensuring clean Mock configuration..."

# Restore from original if backup exists
if [ -f "routes/profiles.js.backup" ]; then
    sudo -u browserapp cp routes/profiles.js.backup routes/profiles.js
fi

# Ensure MockBrowserService is used
sudo -u browserapp sed -i 's/BrowserService/MockBrowserService/g' routes/profiles.js
sudo -u browserapp sed -i 's/FirefoxBrowserService/MockBrowserService/g' routes/profiles.js

# Check routes file
echo "Routes file using:"
grep -n "require.*Service" routes/profiles.js

echo ""
echo "2. Cleaning environment configuration..."

# Create clean .env
sudo -u browserapp tee .env > /dev/null << 'EOF'
PORT=5000
NODE_ENV=production
API_TOKEN=4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=
ENABLE_RATE_LIMIT=false
BROWSER_MODE=mock
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
EOF

echo "Environment file:"
cat .env

echo ""
echo "3. Cleaning dependencies..."

# Remove problematic packages
sudo -u browserapp npm uninstall puppeteer-firefox 2>/dev/null || true

# Clean install
sudo -u browserapp npm install

echo ""
echo "4. Testing manual startup..."
if sudo -u browserapp timeout 5 node server.js 2>&1 | grep -q "running on port"; then
    echo "SUCCESS: Manual startup works"
else
    echo "ERROR: Manual startup failed"
    sudo -u browserapp node server.js 2>&1 | head -5
fi

echo ""
echo "5. Updating SystemD service..."

sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager (Mock Mode)
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=browserapp
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

echo ""
echo "6. Starting service..."
sudo systemctl start browsershield.service

sleep 5

if sudo systemctl is-active --quiet browsershield.service; then
    echo "SUCCESS: Service is running!"
    
    # Test local access
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "SUCCESS: Local access works"
        echo "Web interface: http://138.2.82.254:5000"
    else
        echo "Service running but not responding"
    fi
    
else
    echo "ERROR: Service failed to start"
    echo "Logs:"
    sudo journalctl -u browsershield.service -n 5 --no-pager
fi

echo ""
echo "7. Final status:"
sudo systemctl status browsershield.service --no-pager -l