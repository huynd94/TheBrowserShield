#!/bin/bash

# BrowserShield Simple Installation for Oracle Linux 9
# Minimal approach focusing on core functionality

set -e

echo "🛡️  BrowserShield Simple Installer for Oracle Linux 9"
echo "================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
if [[ $EUID -eq 0 ]]; then
   print_error "Don't run as root. Use a user with sudo privileges."
   exit 1
fi

print_status "Step 1: System update..."
sudo dnf update -y

print_status "Step 2: Install basic tools..."
sudo dnf install -y curl wget git unzip tar

print_status "Step 3: Install Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
fi

print_status "Node.js: $(node --version), NPM: $(npm --version)"

print_status "Step 4: Skip Chrome for now (install manually later)..."
print_warning "Chrome installation skipped due to Oracle Linux 9 compatibility issues"

print_status "Step 5: Create application user..."
if ! id "browserapp" &>/dev/null; then
    sudo useradd -m -s /bin/bash browserapp
fi

print_status "Step 6: Download BrowserShield..."
APP_DIR="/home/browserapp/browsershield"
sudo -u browserapp mkdir -p $APP_DIR

TEMP_DIR="/tmp/browsershield-simple"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

if git clone https://github.com/huynd94/TheBrowserShield.git repo; then
    sudo cp -r repo/* $APP_DIR/
    sudo chown -R browserapp:browserapp $APP_DIR
    print_status "✅ Downloaded from GitHub"
else
    print_error "Failed to download from GitHub"
    exit 1
fi

print_status "Step 7: Install NPM dependencies..."
sudo -u browserapp bash -c "cd $APP_DIR && npm install"

print_status "Step 8: Configure environment..."
API_TOKEN=$(openssl rand -base64 32)
sudo -u browserapp tee $APP_DIR/.env > /dev/null << EOF
PORT=5000
NODE_ENV=production
API_TOKEN=$API_TOKEN
ENABLE_RATE_LIMIT=false
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
EOF

sudo chmod 600 $APP_DIR/.env

print_status "Step 9: Use Mock Browser Service (since Chrome has issues)..."
# Keep MockBrowserService for now until Chrome is fixed
print_warning "Using MockBrowserService due to Chrome installation issues"

print_status "Step 10: Create systemd service..."
sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager (Mock Mode)
After=network.target

[Service]
Type=simple
User=browserapp
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable browsershield.service

print_status "Step 11: Configure firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
fi

print_status "Step 12: Start BrowserShield..."
sudo systemctl start browsershield.service

sleep 3

if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ BrowserShield started successfully!"
else
    print_error "Service failed to start. Checking logs..."
    sudo journalctl -u browsershield.service -n 10
fi

# Test application
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    print_status "✅ Application responding!"
elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
    print_status "✅ Web interface accessible!"
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")

echo ""
echo "🎉 BrowserShield installation completed!"
echo ""
echo "🌐 Access: http://$SERVER_IP:5000"
echo "🔑 API Token: $API_TOKEN"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Running in MOCK MODE (demo only)"
echo "   - To use real browsers, install Chrome manually:"
echo "     sudo ./scripts/fix-oracle-chrome.sh"
echo "   - Then switch to production mode"
echo ""
echo "🔧 Commands:"
echo "   Status: sudo systemctl status browsershield.service"
echo "   Logs:   sudo journalctl -u browsershield.service -f"
echo ""

rm -rf $TEMP_DIR