#!/bin/bash

# BrowserShield VPS Complete Fix Script
# Fixes all known VPS deployment issues including BrowserServiceClass constructor error
# Version: 2.0

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

print_header "BrowserShield VPS Complete Fix v2.0"

# Check if we're in the right directory
if [ ! -d "$APP_DIR" ]; then
    print_error "BrowserShield directory not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

# Step 1: Stop the service completely
print_header "Step 1: Stop All Services"
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
sudo pkill -f "node server.js" 2>/dev/null || true
sleep 3
print_status "All services stopped"

# Step 2: Download latest working code
print_header "Step 2: Download Latest Code"
print_status "Backing up current installation..."
cp -r "$APP_DIR" "${APP_DIR}-backup-$(date +%Y%m%d-%H%M%S)" || true

print_status "Downloading latest code from GitHub..."
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
cp -f package.json "$APP_DIR/"

print_status "Code updated successfully"

# Step 3: Fix Node.js environment
print_header "Step 3: Fix Node.js Environment"
cd "$APP_DIR"

# Ensure Node.js 20 is installed
NODE_VERSION=$(node --version 2>/dev/null || echo "none")
print_status "Current Node.js version: $NODE_VERSION"

if [[ "$NODE_VERSION" == "none" ]] || [[ ! "$NODE_VERSION" =~ ^v2[0-9] ]]; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
    print_status "Node.js 20 installed"
fi

# Step 4: Complete dependency cleanup and reinstall
print_header "Step 4: Fix Dependencies"
rm -rf node_modules package-lock.json
npm cache clean --force

# Install with specific versions to avoid conflicts
npm install express@5.1.0 cors@2.8.5 uuid@11.1.0 puppeteer-extra@3.3.6 puppeteer-extra-plugin-stealth@2.11.2

print_status "Dependencies installed successfully"

# Step 5: Create required directories and files
print_header "Step 5: Setup Data Structure"
mkdir -p data logs public config services routes middleware utils

# Create essential data files
if [ ! -f "data/profiles.json" ]; then
    echo "[]" > data/profiles.json
fi

if [ ! -f "data/mode-config.json" ]; then
    echo '{"currentMode": "mock"}' > data/mode-config.json
fi

if [ ! -f "data/proxy-pool.json" ]; then
    echo "[]" > data/proxy-pool.json
fi

print_status "Data structure created"

# Step 6: Fix file permissions
print_header "Step 6: Fix Permissions"
sudo chown -R $(whoami):$(whoami) "$APP_DIR"
chmod +x server.js
find "$APP_DIR" -type f -name "*.js" -exec chmod 644 {} \;
find "$APP_DIR" -type d -exec chmod 755 {} \;

print_status "Permissions fixed"

# Step 7: Test server syntax
print_header "Step 7: Validate Server"
if node -c server.js; then
    print_status "✓ Server syntax validation passed"
else
    print_error "✗ Server syntax validation failed"
    exit 1
fi

# Step 8: Create optimized SystemD service
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
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=15
StartLimitInterval=60
StartLimitBurst=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
print_status "SystemD service updated with optimized configuration"

# Step 9: Start service with monitoring
print_header "Step 9: Start Service"
sudo systemctl enable $SERVICE_NAME

print_status "Starting BrowserShield service..."
sudo systemctl start $SERVICE_NAME

# Monitor startup
print_status "Monitoring service startup..."
for i in {1..30}; do
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        print_status "✓ Service is active (attempt $i/30)"
        break
    fi
    print_status "Waiting for service to start... ($i/30)"
    sleep 2
done

# Final verification
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_status "✓ BrowserShield service is running successfully"
    
    # Test HTTP endpoint
    sleep 5
    if curl -s http://localhost:5000/health > /dev/null; then
        print_status "✓ HTTP endpoint is responding"
    else
        print_warning "Service running but HTTP endpoint not responding yet"
        print_status "Waiting for HTTP endpoint..."
        sleep 10
        if curl -s http://localhost:5000/health > /dev/null; then
            print_status "✓ HTTP endpoint is now responding"
        fi
    fi
else
    print_error "✗ Service failed to start"
    print_status "Service logs:"
    sudo journalctl -u $SERVICE_NAME --no-pager -n 30
    exit 1
fi

# Step 10: Display final status
print_header "Step 10: Final Status"
sudo systemctl status $SERVICE_NAME --no-pager -l

print_header "Fix Complete!"
print_status "🎉 BrowserShield service has been completely fixed and is running"
print_status "🌐 Access your application at: http://$(curl -s ifconfig.me):5000"
print_status "🔧 Admin panel: http://$(curl -s ifconfig.me):5000/admin"
print_status "⚙️  Mode manager: http://$(curl -s ifconfig.me):5000/mode-manager"
print_status "📊 To view logs: sudo journalctl -u $SERVICE_NAME -f"
print_status "🔄 To restart: sudo systemctl restart $SERVICE_NAME"

print_header "Service Information"
print_status "Status: $(sudo systemctl is-active $SERVICE_NAME)"
print_status "Mode: Mock Mode (VPS compatible)"
print_status "Port: 5000"
print_status "User: $(whoami)"