#!/bin/bash

# Complete fresh installation of BrowserShield on Oracle Linux 9
# Install under opc user to avoid permission issues

echo "🛡️ Complete Fresh BrowserShield Installation"
echo "============================================"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Stop and remove any existing installation
print_status "Cleaning up existing installation..."
sudo systemctl stop browsershield.service 2>/dev/null || true
sudo systemctl disable browsershield.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/browsershield.service
sudo rm -rf /home/browserapp
sudo rm -rf /home/opc/browsershield

print_status "Step 1: System preparation..."
sudo dnf update -y
sudo dnf install -y curl wget git unzip

print_status "Step 2: Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
fi

NODE_VERSION=$(node --version)
print_status "Node.js installed: $NODE_VERSION"

print_status "Step 3: Creating application directory..."
APP_DIR="/home/opc/browsershield"
mkdir -p $APP_DIR
cd $APP_DIR

print_status "Step 4: Creating BrowserShield application..."

# Create package.json
cat > package.json << 'EOF'
{
  "name": "browsershield",
  "version": "1.0.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

print_status "Installing Node.js dependencies..."
npm install

# Create main server file
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`${timestamp} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// In-memory storage for demo
let profiles = [
    {
        id: uuidv4(),
        name: "Default Profile",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        timezone: "America/New_York",
        viewport: { width: 1920, height: 1080 },
        status: "mock",
        createdAt: new Date().toISOString()
    },
    {
        id: uuidv4(),
        name: "Mobile Profile", 
        userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)",
        timezone: "Europe/London",
        viewport: { width: 375, height: 667 },
        status: "mock",
        createdAt: new Date().toISOString()
    }
];

let activeSessions = [];

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'BrowserShield Anti-Detect Browser Manager',
        mode: 'Mock Mode',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '1.0.0'
    });
});

// Root endpoint with web interface
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>BrowserShield - Anti-Detect Browser Manager</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; margin-bottom: 30px; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .api-info { background: #f0f8ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .profiles { margin: 30px 0; }
        .profile { background: #fafafa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007bff; }
        .endpoints { background: #fff8dc; padding: 15px; border-radius: 5px; margin: 20px 0; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 8px 0; border-bottom: 1px solid #eee; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .footer { text-align: center; margin-top: 40px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ BrowserShield Anti-Detect Browser Manager</h1>
        
        <div class="status">
            <h3>✅ Service Status</h3>
            <p><strong>Status:</strong> Running in Mock Mode</p>
            <p><strong>Port:</strong> 5000</p>
            <p><strong>API Token:</strong> 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=</p>
            <p><strong>Started:</strong> ${new Date().toISOString()}</p>
        </div>

        <div class="api-info">
            <h3>📡 API Information</h3>
            <p>All API endpoints are functional and return mock data for testing purposes.</p>
            <p>Use the API token above for authenticated requests (if enabled).</p>
        </div>

        <div class="endpoints">
            <h3>🔗 Available Endpoints</h3>
            <ul>
                <li><a href="/health">GET /health</a> - Service health check</li>
                <li><a href="/api/profiles">GET /api/profiles</a> - List all profiles</li>
                <li><a href="/api/profiles/sessions/active">GET /api/profiles/sessions/active</a> - Active sessions</li>
                <li>POST /api/profiles - Create new profile</li>
                <li>POST /api/profiles/:id/start - Start browser session</li>
                <li>POST /api/profiles/:id/stop - Stop browser session</li>
            </ul>
        </div>

        <div class="profiles">
            <h3>👤 Sample Profiles</h3>
            ${profiles.map(profile => `
                <div class="profile">
                    <strong>${profile.name}</strong><br>
                    <small>ID: ${profile.id}</small><br>
                    User Agent: ${profile.userAgent.substring(0, 60)}...<br>
                    Timezone: ${profile.timezone} | Viewport: ${profile.viewport.width}x${profile.viewport.height}
                </div>
            `).join('')}
        </div>

        <div class="footer">
            <p>BrowserShield v1.0.0 - Anti-Detect Browser Profile Manager</p>
            <p>Running on Oracle Linux 9 | Node.js ${process.version}</p>
        </div>
    </div>
</body>
</html>
    `);
});

// API Routes
app.get('/api/profiles', (req, res) => {
    res.json({
        success: true,
        count: profiles.length,
        profiles: profiles
    });
});

app.post('/api/profiles', (req, res) => {
    const { name, userAgent, timezone, viewport, proxy } = req.body;
    
    if (!name) {
        return res.status(400).json({
            success: false,
            error: 'Profile name is required'
        });
    }

    const profile = {
        id: uuidv4(),
        name,
        userAgent: userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        timezone: timezone || "America/New_York",
        viewport: viewport || { width: 1920, height: 1080 },
        proxy: proxy || null,
        status: "mock",
        createdAt: new Date().toISOString()
    };

    profiles.push(profile);
    
    res.json({
        success: true,
        profile: profile
    });
});

app.get('/api/profiles/:id', (req, res) => {
    const profile = profiles.find(p => p.id === req.params.id);
    if (!profile) {
        return res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }
    
    res.json({
        success: true,
        profile: profile
    });
});

app.post('/api/profiles/:id/start', (req, res) => {
    const profile = profiles.find(p => p.id === req.params.id);
    if (!profile) {
        return res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }

    // Mock browser session
    const session = {
        profileId: req.params.id,
        sessionId: uuidv4(),
        status: 'mock_active',
        startTime: Date.now(),
        browserType: 'mock',
        currentUrl: 'about:blank'
    };

    activeSessions.push(session);

    res.json({
        success: true,
        message: 'Mock browser session started',
        session: session
    });
});

app.post('/api/profiles/:id/stop', (req, res) => {
    const sessionIndex = activeSessions.findIndex(s => s.profileId === req.params.id);
    if (sessionIndex === -1) {
        return res.status(404).json({
            success: false,
            error: 'No active session found'
        });
    }

    activeSessions.splice(sessionIndex, 1);

    res.json({
        success: true,
        message: 'Mock browser session stopped'
    });
});

app.get('/api/profiles/sessions/active', (req, res) => {
    const sessionsWithUptime = activeSessions.map(session => ({
        ...session,
        uptime: Math.floor((Date.now() - session.startTime) / 1000)
    }));

    res.json({
        success: true,
        count: sessionsWithUptime.length,
        sessions: sessionsWithUptime
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🛡️ BrowserShield Anti-Detect Browser Manager running on port ${PORT}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Access: http://localhost:${PORT}`);
    console.log(`🎭 Mode: Mock (Demo)`);
});

module.exports = app;
EOF

print_status "Step 5: Testing application startup..."
timeout 5 node server.js &
sleep 3
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    print_status "✅ Application test successful"
    pkill -f "node server.js" 2>/dev/null || true
else
    print_error "Application test failed"
    pkill -f "node server.js" 2>/dev/null || true
    exit 1
fi

print_status "Step 6: Creating SystemD service..."
sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=opc
Group=opc
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable browsershield.service

print_status "Step 7: Configuring firewall..."
if command -v firewall-cmd &> /dev/null && sudo systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
    print_status "Firewall configured"
fi

# Configure iptables for Oracle Cloud
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT 2>/dev/null || true

print_status "Step 8: Starting BrowserShield service..."
sudo systemctl start browsershield.service

sleep 5

if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ BrowserShield service is running!"
    
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_status "✅ Web interface is accessible!"
    fi
    
    EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "138.2.82.254")
    
    echo ""
    echo "🎉 BrowserShield installation completed successfully!"
    echo ""
    echo "🌐 Access URLs:"
    echo "   External: http://$EXTERNAL_IP:5000"
    echo "   Local:    http://localhost:5000"
    echo ""
    echo "🔑 API Token: 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k="
    echo ""
    echo "🎭 Mode: Mock (Full-featured demo)"
    echo "   - Complete web interface"
    echo "   - All API endpoints functional"
    echo "   - Profile management"
    echo "   - Session simulation"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Status:  sudo systemctl status browsershield.service"
    echo "   Restart: sudo systemctl restart browsershield.service"
    echo "   Logs:    sudo journalctl -u browsershield.service -f"
    echo "   Test:    curl http://localhost:5000/health"
    echo ""
    print_status "Installation completed successfully!"
    
else
    print_error "❌ Service failed to start. Checking logs..."
    sudo journalctl -u browsershield.service -n 10 --no-pager
    exit 1
fi