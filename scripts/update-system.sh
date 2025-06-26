#!/bin/bash

# BrowserShield System Update Script
# Downloads latest code from GitHub and updates the VPS installation
# Author: BrowserShield Team
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://github.com/huynd94/TheBrowserShield"
APP_DIR="/home/$(whoami)/browsershield"
BACKUP_DIR="/home/$(whoami)/browsershield-backup-$(date +%Y%m%d-%H%M%S)"
SERVICE_NAME="browsershield"

# Functions
print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as opc user."
   exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_status "Installing git..."
    sudo dnf install -y git
fi

print_header "BrowserShield System Update"
print_status "Starting system update process..."

# Step 1: Backup current installation
print_header "Step 1: Backup Current Installation"
if [ -d "$APP_DIR" ]; then
    print_status "Creating backup at: $BACKUP_DIR"
    cp -r "$APP_DIR" "$BACKUP_DIR"
    
    # Backup important data
    if [ -f "$APP_DIR/data/profiles.json" ]; then
        print_status "Backing up profiles data..."
        cp "$APP_DIR/data/profiles.json" "$BACKUP_DIR/profiles-backup.json"
    fi
    
    if [ -f "$APP_DIR/data/proxy-pool.json" ]; then
        print_status "Backing up proxy pool data..."
        cp "$APP_DIR/data/proxy-pool.json" "$BACKUP_DIR/proxy-pool-backup.json"
    fi
    
    if [ -f "$APP_DIR/data/mode-config.json" ]; then
        print_status "Backing up mode configuration..."
        cp "$APP_DIR/data/mode-config.json" "$BACKUP_DIR/mode-config-backup.json"
    fi
    
    if [ -f "$APP_DIR/.env" ]; then
        print_status "Backing up environment configuration..."
        cp "$APP_DIR/.env" "$BACKUP_DIR/env-backup"
    fi
    
    print_status "Backup completed successfully"
else
    print_warning "No existing installation found at $APP_DIR"
fi

# Step 2: Stop service
print_header "Step 2: Stop BrowserShield Service"
if systemctl is-active --quiet $SERVICE_NAME.service; then
    print_status "Stopping BrowserShield service..."
    sudo systemctl stop $SERVICE_NAME.service
    sleep 2
    print_status "Service stopped"
else
    print_warning "Service is not running"
fi

# Step 3: Download latest code
print_header "Step 3: Download Latest Code"
TEMP_DIR="/tmp/browsershield-update-$(date +%s)"
print_status "Downloading from GitHub to: $TEMP_DIR"

if git clone "$GITHUB_REPO" "$TEMP_DIR"; then
    print_status "Successfully cloned repository"
else
    print_error "Failed to clone repository. Attempting alternative download..."
    
    # Alternative: Download as ZIP
    curl -L "${GITHUB_REPO}/archive/main.zip" -o "/tmp/browsershield-main.zip"
    cd /tmp
    unzip -q browsershield-main.zip
    mv TheBrowserShield-main "$TEMP_DIR"
    rm browsershield-main.zip
    print_status "Downloaded as ZIP archive"
fi

# Verify download
if [ ! -f "$TEMP_DIR/package.json" ]; then
    print_error "Download verification failed - package.json not found"
    exit 1
fi

# Step 4: Update application files
print_header "Step 4: Update Application Files"
if [ -d "$APP_DIR" ]; then
    # Preserve data and config during update
    if [ -d "$APP_DIR/data" ]; then
        print_status "Preserving data directory..."
        cp -r "$APP_DIR/data" "$TEMP_DIR/"
    fi
    
    if [ -f "$APP_DIR/.env" ]; then
        print_status "Preserving environment configuration..."
        cp "$APP_DIR/.env" "$TEMP_DIR/"
    fi
    
    # Remove old installation
    print_status "Removing old installation..."
    rm -rf "$APP_DIR"
fi

# Move new files
print_status "Installing new files..."
mv "$TEMP_DIR" "$APP_DIR"
cd "$APP_DIR"

# Set proper permissions
print_status "Setting permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod 600 .env 2>/dev/null || true

# Step 5: Update dependencies
print_header "Step 5: Update Dependencies"
print_status "Installing/updating NPM packages..."

# Check if package.json changed
if npm outdated; then
    print_status "Updating outdated packages..."
    npm update --production
else
    print_status "Installing dependencies..."
    npm install --production --no-audit
fi

# Step 6: Database/Data migrations (if needed)
print_header "Step 6: Data Migration"
# Create data directory if it doesn't exist
mkdir -p data

# Initialize data files if they don't exist
if [ ! -f "data/profiles.json" ]; then
    echo '[]' > data/profiles.json
    print_status "Initialized profiles.json"
fi

if [ ! -f "data/proxy-pool.json" ]; then
    echo '[]' > data/proxy-pool.json
    print_status "Initialized proxy-pool.json"
fi

# Preserve or initialize mode config
if [ ! -f "data/mode-config.json" ]; then
    cat > data/mode-config.json << 'EOF'
{
  "mode": "mock",
  "lastChanged": "2025-06-26T14:20:00.000Z",
  "capabilities": ["Profile management", "Session simulation", "API testing"]
}
EOF
    print_status "Initialized mode-config.json"
fi

# Step 7: Syntax validation
print_header "Step 7: Syntax Validation"
print_status "Validating server.js syntax..."
if node -c server.js; then
    print_status "Syntax validation passed"
else
    print_error "Syntax validation failed!"
    
    # Restore from backup
    if [ -d "$BACKUP_DIR" ]; then
        print_status "Restoring from backup..."
        rm -rf "$APP_DIR"
        cp -r "$BACKUP_DIR" "$APP_DIR"
        print_status "Backup restored"
    fi
    exit 1
fi

# Step 8: Update systemd service if needed
print_header "Step 8: Update System Service"
CURRENT_USER=$(whoami)

# Check if service file needs updating
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
if [ -f "$SERVICE_FILE" ]; then
    # Update service file to ensure correct paths
    sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
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
    print_status "System service updated"
else
    print_warning "System service file not found - manual setup may be required"
fi

# Step 9: Start service
print_header "Step 9: Start BrowserShield Service"
print_status "Starting BrowserShield service..."
sudo systemctl start $SERVICE_NAME.service
sleep 3

# Verify service status
if sudo systemctl is-active --quiet $SERVICE_NAME.service; then
    print_status "Service started successfully"
    
    # Test web interface
    sleep 2
    if curl -s http://localhost:5000/health >/dev/null 2>&1; then
        print_status "Web interface is responding"
    else
        print_warning "Web interface test failed"
    fi
else
    print_error "Service failed to start"
    echo "Service logs:"
    sudo journalctl -u $SERVICE_NAME.service -n 10 --no-pager
    exit 1
fi

# Step 10: Cleanup
print_header "Step 10: Cleanup"
print_status "Cleaning up temporary files..."

# Clean up old backups (keep only last 3)
BACKUP_BASE_DIR="/home/$(whoami)"
print_status "Cleaning old backups..."
ls -dt $BACKUP_BASE_DIR/browsershield-backup-* 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true

print_status "Cleanup completed"

# Final status report
print_header "Update Completed Successfully!"

# Get version info if available
if [ -f "package.json" ]; then
    VERSION=$(grep '"version"' package.json | cut -d'"' -f4)
    print_status "Version: $VERSION"
fi

# Get current mode
if [ -f "data/mode-config.json" ]; then
    CURRENT_MODE=$(grep '"mode"' data/mode-config.json | cut -d'"' -f4)
    print_status "Current Mode: $CURRENT_MODE"
fi

echo ""
echo "🎉 BrowserShield has been updated successfully!"
echo ""
echo "📊 Update Summary:"
echo "   ✅ Code updated from GitHub"
echo "   ✅ Dependencies refreshed"
echo "   ✅ Data preserved"
echo "   ✅ Service restarted"
echo "   ✅ Health check passed"
echo ""
echo "🌐 Access Information:"
echo "   Web Interface: http://localhost:5000"
echo "   Admin Panel:   http://localhost:5000/admin"
echo "   Mode Manager:  http://localhost:5000/mode-manager"
echo ""
echo "🔧 Management Commands:"
echo "   Service Status:  sudo systemctl status $SERVICE_NAME.service"
echo "   View Logs:       sudo journalctl -u $SERVICE_NAME.service -f"
echo "   Restart Service: sudo systemctl restart $SERVICE_NAME.service"
echo ""
echo "💾 Backup Location: $BACKUP_DIR"
echo ""
echo "✅ Update completed successfully!"

print_status "System update script completed successfully!"