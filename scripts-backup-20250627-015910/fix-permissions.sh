#!/bin/bash

# Fix permissions and dependencies for BrowserShield

echo "Fixing permissions and dependencies..."

APP_DIR="/home/browserapp/browsershield"

# Stop service
sudo systemctl stop browsershield.service

echo "1. Fixing file permissions..."
sudo chown -R browserapp:browserapp $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chmod 644 $APP_DIR/.env
sudo chmod 644 $APP_DIR/routes/*.js
sudo chmod 644 $APP_DIR/services/*.js
sudo chmod 644 $APP_DIR/package.json

echo "2. Checking current permissions..."
ls -la $APP_DIR/
ls -la $APP_DIR/routes/
ls -la $APP_DIR/.env

echo "3. Recreating clean package.json..."
cd $APP_DIR
sudo -u browserapp tee package.json > /dev/null << 'EOF'
{
  "name": "browsershield",
  "version": "1.0.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^5.1.0",
    "cors": "^2.8.5",
    "uuid": "^11.1.0",
    "puppeteer-extra": "^3.3.6",
    "puppeteer-extra-plugin-stealth": "^2.11.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

echo "4. Clean npm install..."
sudo -u browserapp rm -rf node_modules package-lock.json
sudo -u browserapp npm install

echo "5. Testing Node.js basics..."
sudo -u browserapp node -e "console.log('Node.js working')"
sudo -u browserapp node -e "console.log('Express:', require('express').version || 'loaded')"

echo "6. Testing server.js syntax..."
sudo -u browserapp node -c server.js && echo "Syntax OK" || echo "Syntax ERROR"

echo "7. Testing manual startup with verbose output..."
cd $APP_DIR
sudo -u browserapp node server.js &
STARTUP_PID=$!
sleep 3

if ps -p $STARTUP_PID > /dev/null; then
    echo "SUCCESS: Server started manually"
    kill $STARTUP_PID
else
    echo "FAILED: Manual startup failed"
fi

echo "8. Creating simplified SystemD service..."
sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield
After=network.target

[Service]
Type=simple
User=browserapp
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start browsershield.service

sleep 3

if sudo systemctl is-active --quiet browsershield.service; then
    echo "SUCCESS: SystemD service running!"
    
    if curl -s http://localhost:5000/ > /dev/null 2>&1; then
        echo "SUCCESS: Web interface accessible!"
        echo "Access: http://138.2.82.254:5000"
    fi
else
    echo "Service logs:"
    sudo journalctl -u browsershield.service -n 5 --no-pager
fi