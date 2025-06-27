#!/bin/bash
# BrowserShield VPS Update Script for Oracle Linux 9
# Updates existing installation with latest code and fixes

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"
BACKUP_DIR="/home/opc/browsershield_backups"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as correct user
if [ "$USER" != "opc" ]; then
    error "Please run this script as opc user"
fi

log "Starting BrowserShield VPS update for Oracle Linux 9"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current installation
log "Creating backup of current installation..."
BACKUP_NAME="browsershield_backup_$(date +%Y%m%d_%H%M%S)"
sudo systemctl stop $SERVICE_NAME || true
cp -r "$APP_DIR" "$BACKUP_DIR/$BACKUP_NAME"
log "Backup created at: $BACKUP_DIR/$BACKUP_NAME"

# Backup important data
log "Backing up configuration and data..."
cp -r "$APP_DIR/data" /tmp/browsershield_data_backup || true
cp "$APP_DIR/.env" /tmp/browsershield_env_backup || true

# Download latest code
log "Downloading latest BrowserShield code..."
cd /tmp
wget -O browsershield-latest.zip https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip
unzip -q browsershield-latest.zip
cd TheBrowserShield-main

# Update application files
log "Updating application files..."
rsync -av --exclude='data' --exclude='node_modules' --exclude='.env' ./ "$APP_DIR/"

# Restore data and configuration
log "Restoring configuration and data..."
if [ -d "/tmp/browsershield_data_backup" ]; then
    cp -r /tmp/browsershield_data_backup/* "$APP_DIR/data/" || true
fi
if [ -f "/tmp/browsershield_env_backup" ]; then
    cp /tmp/browsershield_env_backup "$APP_DIR/.env" || true
fi

# Set ownership
sudo chown -R opc:opc "$APP_DIR"

# Update dependencies
log "Updating Node.js dependencies..."
cd "$APP_DIR"
npm install

# Ensure production mode configuration
log "Configuring production mode..."
cat > "$APP_DIR/data/mode-config.json" << EOF
{
  "mode": "production",
  "lastChanged": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "capabilities": {
    "realBrowser": true,
    "screenshots": true,
    "websiteInteraction": true,
    "chromeAutomation": true,
    "stealth": true
  }
}
EOF

# Test syntax
log "Testing application syntax..."
node -c server.js || error "Application has syntax errors"

# Start service
log "Starting BrowserShield service..."
sudo systemctl start $SERVICE_NAME

# Wait and verify
sleep 5
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "Service started successfully"
else
    error "Service failed to start. Restoring backup..."
    sudo systemctl stop $SERVICE_NAME || true
    rm -rf "$APP_DIR"
    cp -r "$BACKUP_DIR/$BACKUP_NAME" "$APP_DIR"
    sudo systemctl start $SERVICE_NAME
    error "Update failed, backup restored"
fi

# Verify API
log "Verifying API endpoints..."
sleep 3
if curl -s "http://localhost:5000/health" > /dev/null; then
    log "API is responding correctly"
else
    warn "API health check failed, but service is running"
fi

# Cleanup
log "Cleaning up temporary files..."
rm -rf /tmp/TheBrowserShield-main /tmp/browsershield-latest.zip
rm -rf /tmp/browsershield_data_backup /tmp/browsershield_env_backup

log "Update completed successfully!"
echo
echo -e "${GREEN}✓ BrowserShield updated to latest version${NC}"
echo -e "${GREEN}✓ Configuration and data preserved${NC}"
echo -e "${GREEN}✓ Production mode maintained${NC}"
echo -e "${GREEN}✓ Service restarted successfully${NC}"
echo
echo "Check status with: sudo systemctl status $SERVICE_NAME"
echo "View logs with: sudo journalctl -u $SERVICE_NAME -f"