#!/bin/bash

# BrowserShield VPS Final Fix Script
# Completely removes puppeteer-firefox and fixes all VPS issues
# Version: 3.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/home/$(whoami)/browsershield"
SERVICE_NAME="browsershield"
GITHUB_REPO="https://github.com/huynd94/TheBrowserShield"

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_header "BrowserShield VPS Final Fix v3.0"
print_status "Removing deprecated puppeteer-firefox and fixing all issues"

# Check if we're in the right directory
if [ ! -d "$APP_DIR" ]; then
    print_error "BrowserShield directory not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

# Step 1: Stop everything
print_header "Step 1: Stop All Services"
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
sudo pkill -f "node server.js" 2>/dev/null || true
sudo pkill -f "browsershield" 2>/dev/null || true
sleep 5
print_status "All services stopped"

# Step 2: Backup and download latest code
print_header "Step 2: Download Latest Code (No puppeteer-firefox)"
print_status "Creating backup..."
cp -r "$APP_DIR" "${APP_DIR}-backup-$(date +%Y%m%d-%H%M%S)" || true

print_status "Downloading latest code..."
cd /tmp
rm -rf TheBrowserShield
git clone $GITHUB_REPO.git
cd TheBrowserShield

# Copy updated files
cp -f server.js "$APP_DIR/"
cp -rf config/ "$APP_DIR/"
cp -rf services/ "$APP_DIR/"
cp -rf middleware/ "$APP_DIR/"
cp -rf routes/ "$APP_DIR/"
cp -rf utils/ "$APP_DIR/"
cp -rf public/ "$APP_DIR/"

print_status "Latest code installed"

# Step 3: Fix Node.js and dependencies
print_header "Step 3: Fix Node.js Environment"
cd "$APP_DIR"

# Install Node.js 20 if needed
NODE_VERSION=$(node --version 2>/dev/null || echo "none")
if [[ "$NODE_VERSION" == "none" ]] || [[ ! "$NODE_VERSION" =~ ^v2[0-9] ]]; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
fi

# Complete dependency cleanup
print_status "Cleaning all dependencies..."
rm -rf node_modules package-lock.json .npm
npm cache clean --force

# Remove puppeteer-firefox completely if exists
npm uninstall puppeteer-firefox 2>/dev/null || true

# Install clean dependencies (without puppeteer-firefox)
print_status "Installing clean dependencies..."
cat > package.json << 'EOF'
{
  "name": "browsershield",
  "version": "1.3.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "echo \"No tests specified\" && exit 0"
  },
  "keywords": ["browser", "automation", "anti-detect"],
  "author": "BrowserShield Team",
  "license": "ISC",
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^5.1.0",
    "puppeteer": "^24.10.2",
    "puppeteer-extra": "^3.3.6",
    "puppeteer-extra-plugin-stealth": "^2.11.2",
    "uuid": "^11.1.0"
  }
}
EOF

npm install

print_status "Dependencies installed without puppeteer-firefox"

# Step 4: Install Chrome for production browser automation
print_header "Step 4: Install Chrome Browser"
if ! command -v google-chrome &> /dev/null && ! command -v chromium-browser &> /dev/null; then
    print_status "Installing Chrome/Chromium..."
    
    # Try Google Chrome first
    sudo dnf install -y wget
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo rpm --import -
    sudo dnf config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo
    sudo dnf install -y google-chrome-stable 2>/dev/null || {
        # Fallback to Chromium
        print_status "Google Chrome failed, installing Chromium..."
        sudo dnf install -y epel-release
        sudo dnf install -y chromium
    }
    
    print_status "Browser installed"
else
    print_status "Browser already available"
fi

# Step 5: Setup data structure
print_header "Step 5: Setup Data Structure"
mkdir -p data logs public config services routes middleware utils

# Create data files
echo "[]" > data/profiles.json
echo '{"currentMode": "production"}' > data/mode-config.json
echo "[]" > data/proxy-pool.json

print_status "Data structure created"

# Step 6: Fix permissions
print_header "Step 6: Fix Permissions"
sudo chown -R $(whoami):$(whoami) "$APP_DIR"
chmod +x server.js
find "$APP_DIR" -type f -name "*.js" -exec chmod 644 {} \;
find "$APP_DIR" -type d -exec chmod 755 {} \;

print_status "Permissions fixed"

# Step 7: Validate server
print_header "Step 7: Validate Server"
if node -c server.js; then
    print_status "✓ Server syntax validation passed"
else
    print_error "✗ Server syntax validation failed"
    exit 1
fi

# Step 8: Update SystemD service
print_header "Step 8: Update SystemD Service"
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=NODE_OPTIONS=--max-old-space-size=2048
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
print_status "SystemD service updated"

# Step 9: Start service
print_header "Step 9: Start BrowserShield Service"
print_status "Starting service..."
sudo systemctl start $SERVICE_NAME

# Monitor startup
for i in {1..20}; do
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        print_status "✓ Service started successfully (attempt $i/20)"
        break
    fi
    print_status "Waiting for service... ($i/20)"
    sleep 3
done

# Final verification
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_status "✓ BrowserShield service is running"
    
    sleep 5
    if curl -s http://localhost:5000/health > /dev/null; then
        print_status "✓ HTTP endpoint responding"
    else
        print_warning "Service running but HTTP not ready yet"
    fi
else
    print_error "✗ Service failed to start"
    print_status "Recent logs:"
    sudo journalctl -u $SERVICE_NAME --no-pager -n 20
    exit 1
fi

# Final status
print_header "Final Status"
sudo systemctl status $SERVICE_NAME --no-pager -l

print_header "🎉 Fix Complete!"
print_status "✅ Removed deprecated puppeteer-firefox"
print_status "✅ Installed clean dependencies"
print_status "✅ Chrome/Chromium browser available"
print_status "✅ Service running in Production Mode"
print_status "🌐 Access: http://$(curl -s ifconfig.me):5000"
print_status "🔧 Admin: http://$(curl -s ifconfig.me):5000/admin"
print_status "📊 Logs: sudo journalctl -u $SERVICE_NAME -f"