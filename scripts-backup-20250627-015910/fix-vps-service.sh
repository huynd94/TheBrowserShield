#!/bin/bash

# BrowserShield VPS Service Fix Script
# Fixes Node.js module errors and service startup issues
# Version: 1.0

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

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_header "BrowserShield VPS Service Fix"

# Check if we're in the right directory
if [ ! -d "$APP_DIR" ]; then
    print_error "BrowserShield directory not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

# Step 1: Stop the service
print_header "Step 1: Stop BrowserShield Service"
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
print_status "Service stopped"

# Step 2: Fix Node.js version and modules
print_header "Step 2: Fix Node.js Environment"

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "none")
print_status "Current Node.js version: $NODE_VERSION"

if [[ "$NODE_VERSION" == "none" ]] || [[ ! "$NODE_VERSION" =~ ^v2[0-9] ]]; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
    print_status "Node.js 20 installed"
fi

# Step 3: Clean and reinstall node_modules
print_header "Step 3: Clean and Reinstall Dependencies"
rm -rf node_modules package-lock.json
print_status "Cleaned node_modules and package-lock.json"

npm cache clean --force
print_status "Cleared npm cache"

npm install
print_status "Dependencies reinstalled"

# Step 4: Create data directories
print_header "Step 4: Create Required Directories"
mkdir -p data logs
touch data/profiles.json
echo "[]" > data/profiles.json
echo '{"currentMode": "mock"}' > data/mode-config.json
print_status "Data directories and files created"

# Step 5: Fix permissions
print_header "Step 5: Fix File Permissions"
sudo chown -R $(whoami):$(whoami) "$APP_DIR"
chmod +x server.js
print_status "Permissions fixed"

# Step 6: Test server syntax
print_header "Step 6: Validate Server Syntax"
node -c server.js
if [ $? -eq 0 ]; then
    print_status "Server syntax validation passed"
else
    print_error "Server syntax validation failed"
    exit 1
fi

# Step 7: Update systemd service
print_header "Step 7: Update SystemD Service"
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
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
print_status "SystemD service updated"

# Step 8: Start and enable service
print_header "Step 8: Start BrowserShield Service"
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Wait a moment for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_status "✓ BrowserShield service is running"
    
    # Test HTTP endpoint
    if curl -s http://localhost:5000/health > /dev/null; then
        print_status "✓ HTTP endpoint is responding"
    else
        print_warning "Service running but HTTP endpoint not responding"
    fi
else
    print_error "✗ Service failed to start"
    print_status "Checking service logs..."
    sudo journalctl -u $SERVICE_NAME --no-pager -n 20
    exit 1
fi

# Step 9: Show status
print_header "Step 9: Service Status"
sudo systemctl status $SERVICE_NAME --no-pager -l

print_header "Fix Complete!"
print_status "BrowserShield service has been fixed and is running"
print_status "Access your application at: http://$(curl -s ifconfig.me):5000"
print_status "To view logs: sudo journalctl -u $SERVICE_NAME -f"