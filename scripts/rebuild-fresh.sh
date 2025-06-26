#!/bin/bash

# Rebuild BrowserShield completely from scratch
# Fix all permission and path issues

echo "Rebuilding BrowserShield from scratch..."

# Stop any existing service
sudo systemctl stop browsershield.service 2>/dev/null || true
sudo systemctl disable browsershield.service 2>/dev/null || true

# Remove old installation
sudo rm -rf /home/browserapp/browsershield
sudo rm -f /etc/systemd/system/browsershield.service

echo "1. Creating fresh application directory..."
sudo mkdir -p /home/browserapp/browsershield
sudo chown browserapp:browserapp /home/browserapp/browsershield
cd /home/browserapp/browsershield

echo "2. Downloading fresh code from GitHub..."
if curl -L "https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip" -o browsershield.zip; then
    unzip -q browsershield.zip
    sudo -u browserapp cp -r TheBrowserShield-main/* .
    rm -rf TheBrowserShield-main browsershield.zip
    echo "Downloaded fresh code"
else
    echo "GitHub download failed, creating minimal working version..."
    
    # Create minimal working server.js
    sudo -u browserapp tee server.js > /dev/null << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Simple logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        service: 'BrowserShield Mock Mode'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.send(`
        <html>
        <head><title>BrowserShield</title></head>
        <body>
            <h1>BrowserShield Anti-Detect Browser Manager</h1>
            <p>Service is running in Mock Mode</p>
            <p>API Token: 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=</p>
            <h2>Available Endpoints:</h2>
            <ul>
                <li><a href="/health">Health Check</a></li>
                <li><a href="/api/profiles">API Profiles</a></li>
            </ul>
        </body>
        </html>
    `);
});

// Mock API endpoints
app.get('/api/profiles', (req, res) => {
    res.json({
        success: true,
        profiles: [
            { id: '1', name: 'Sample Profile 1', status: 'mock' },
            { id: '2', name: 'Sample Profile 2', status: 'mock' }
        ]
    });
});

app.get('/api/profiles/sessions/active', (req, res) => {
    res.json({
        success: true,
        sessions: []
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`BrowserShield running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
EOF

    # Create package.json
    sudo -u browserapp tee package.json > /dev/null << 'EOF'
{
  "name": "browsershield",
  "version": "1.0.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5"
  }
}
EOF
fi

echo "3. Setting proper permissions..."
sudo chown -R browserapp:browserapp /home/browserapp/browsershield
sudo chmod -R 755 /home/browserapp/browsershield
sudo chmod 644 /home/browserapp/browsershield/package.json
sudo chmod 644 /home/browserapp/browsershield/server.js

echo "4. Creating environment file..."
sudo -u browserapp tee .env > /dev/null << 'EOF'
PORT=5000
NODE_ENV=production
API_TOKEN=4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=
BROWSER_MODE=mock
EOF

echo "5. Installing dependencies..."
sudo -u browserapp npm install

echo "6. Testing manual startup..."
cd /home/browserapp/browsershield
if sudo -u browserapp timeout 10 node server.js &
then
    sleep 3
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "SUCCESS: Manual startup works!"
        pkill -f "node server.js" 2>/dev/null || true
    else
        echo "Server started but not responding"
        pkill -f "node server.js" 2>/dev/null || true
    fi
else
    echo "Manual startup failed"
fi

echo "7. Creating SystemD service..."
sudo tee /etc/systemd/system/browsershield.service > /dev/null << 'EOF'
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=browserapp
Group=browserapp
WorkingDirectory=/home/browserapp/browsershield
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable browsershield.service
sudo systemctl start browsershield.service

echo "8. Waiting for service to start..."
sleep 5

if sudo systemctl is-active --quiet browsershield.service; then
    echo "SUCCESS: BrowserShield service is running!"
    
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "SUCCESS: Web interface is accessible!"
        echo ""
        echo "🌐 Access BrowserShield at: http://138.2.82.254:5000"
        echo "🔑 API Token: 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k="
        echo ""
        echo "✅ Installation completed successfully!"
    else
        echo "Service running but web interface not responding"
    fi
else
    echo "❌ Service failed to start. Logs:"
    sudo journalctl -u browsershield.service -n 5 --no-pager
fi

echo ""
echo "Commands:"
echo "  Status: sudo systemctl status browsershield.service"
echo "  Logs:   sudo journalctl -u browsershield.service -f"
echo "  Test:   curl http://localhost:5000/health"