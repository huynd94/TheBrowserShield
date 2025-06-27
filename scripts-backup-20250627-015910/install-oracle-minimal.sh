#!/bin/bash

# BrowserShield - Oracle Linux 9 Minimal Installation Script
# Optimized for Oracle Linux 9 with minimal dependencies
# Repository: https://github.com/huynd94/TheBrowserShield

set -e

echo "🛡️  BrowserShield - Oracle Linux 9 Minimal Installer"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_status "Step 1: Updating system packages..."
sudo dnf update -y

print_status "Step 2: Installing essential tools..."
sudo dnf install -y curl wget git unzip tar

print_status "Step 3: Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
else
    print_warning "Node.js already installed"
fi

NODE_VERSION=$(node --version 2>/dev/null || echo "Not installed")
NPM_VERSION=$(npm --version 2>/dev/null || echo "Not installed")
print_status "Node.js: $NODE_VERSION, NPM: $NPM_VERSION"

print_status "Step 4: Installing minimal Chrome dependencies..."
# Only install packages that definitely exist in Oracle Linux 9
sudo dnf install -y \
    alsa-lib \
    nss \
    liberation-fonts \
    liberation-sans-fonts \
    liberation-serif-fonts \
    liberation-mono-fonts

print_status "Step 5: Installing Google Chrome..."
if ! command -v google-chrome-stable &> /dev/null; then
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    sudo dnf install -y google-chrome-stable
else
    print_warning "Google Chrome already installed"
fi

CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null || echo "Installation failed")
print_status "Chrome: $CHROME_VERSION"

print_status "Step 6: Creating application user..."
if id "browserapp" &>/dev/null; then
    print_warning "User 'browserapp' already exists"
else
    sudo useradd -m -s /bin/bash browserapp
    print_status "Created user 'browserapp'"
fi

print_status "Step 7: Setting up application directory..."
APP_DIR="/home/browserapp/browsershield"
sudo -u browserapp mkdir -p $APP_DIR

print_status "Step 8: Downloading BrowserShield from GitHub..."
TEMP_DIR="/tmp/browsershield-install"
sudo rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# Download from GitHub
if git clone https://github.com/huynd94/TheBrowserShield.git browsershield-repo 2>/dev/null; then
    if [ -f "browsershield-repo/package.json" ]; then
        sudo cp -r browsershield-repo/* $APP_DIR/
        print_status "Downloaded via Git clone"
    fi
elif curl -L --fail "https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip" -o browsershield.zip 2>/dev/null; then
    if unzip -q browsershield.zip 2>/dev/null; then
        EXTRACTED_DIR=$(find . -name "package.json" | head -1 | xargs dirname 2>/dev/null || echo "")
        if [ -n "$EXTRACTED_DIR" ] && [ -f "$EXTRACTED_DIR/package.json" ]; then
            sudo cp -r $EXTRACTED_DIR/* $APP_DIR/
            print_status "Downloaded via GitHub ZIP"
        fi
    fi
else
    print_error "Failed to download BrowserShield. Please check your internet connection."
    exit 1
fi

sudo chown -R browserapp:browserapp $APP_DIR
rm -rf $TEMP_DIR

print_status "Step 9: Installing NPM dependencies..."
if [ -f "$APP_DIR/package.json" ]; then
    sudo -u browserapp bash -c "cd $APP_DIR && npm install --production"
else
    print_error "package.json not found"
    exit 1
fi

print_status "Step 10: Configuring environment..."
API_TOKEN=$(openssl rand -base64 32)
sudo -u browserapp tee $APP_DIR/.env > /dev/null << EOF
PORT=5000
NODE_ENV=production
API_TOKEN=$API_TOKEN
ENABLE_RATE_LIMIT=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
EOF

sudo chmod 600 $APP_DIR/.env

print_status "Step 11: Switching to production mode..."
if [ -f "$APP_DIR/routes/profiles.js" ]; then
    sudo -u browserapp cp $APP_DIR/routes/profiles.js $APP_DIR/routes/profiles.js.backup 2>/dev/null || true
    sudo -u browserapp sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/BrowserService')/g" $APP_DIR/routes/profiles.js 2>/dev/null || true
    print_status "Switched to production BrowserService"
fi

print_status "Step 12: Creating systemd service..."
sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=browserapp
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
SyslogIdentifier=browsershield
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable browsershield.service

print_status "Step 13: Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
    print_status "Firewall configured"
fi

print_status "Step 14: Starting BrowserShield..."
sudo systemctl start browsershield.service

sleep 3

if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ BrowserShield started successfully!"
else
    print_error "❌ Service failed to start. Checking logs..."
    sudo journalctl -u browsershield.service -n 10
    exit 1
fi

# Test the application
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
else
    print_warning "⚠️  Application test inconclusive"
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

echo ""
echo "🎉 BrowserShield installation completed successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   Local:    http://localhost:5000"
echo "   External: http://$SERVER_IP:5000"
echo ""
echo "🔑 API Token: $API_TOKEN"
echo ""
echo "🔧 Management Commands:"
echo "   Status:   sudo systemctl status browsershield.service"
echo "   Restart:  sudo systemctl restart browsershield.service"
echo "   Logs:     sudo journalctl -u browsershield.service -f"
echo ""
print_status "Installation completed successfully!"