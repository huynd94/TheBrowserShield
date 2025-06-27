#!/bin/bash
# BrowserShield VPS Deployment Script for Oracle Linux 9
# Optimized for production environment with Chrome browser support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="browsershield"
APP_USER="opc"
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"
PORT=5000

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please run this script as opc user, not as root"
fi

log "Starting BrowserShield deployment for Oracle Linux 9 VPS"

# Update system packages
log "Updating system packages..."
sudo dnf update -y

# Install required packages for Oracle Linux 9
log "Installing system dependencies..."
sudo dnf install -y epel-release
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    curl \
    wget \
    git \
    unzip \
    tar \
    firewalld \
    systemd \
    which \
    procps-ng \
    htop \
    nano \
    vim

# Install Node.js 20
log "Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
fi

# Verify Node.js installation
NODE_VERSION=$(node --version)
log "Node.js version: $NODE_VERSION"

# Install Chrome for production mode
log "Installing Google Chrome for production browser automation..."
if ! command -v google-chrome &> /dev/null; then
    # Add Google Chrome repository
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    
    # Install Chrome
    sudo dnf install -y google-chrome-stable
    
    # Install additional dependencies for headless Chrome
    sudo dnf install -y \
        liberation-fonts \
        liberation-narrow-fonts \
        liberation-sans-fonts \
        liberation-serif-fonts \
        xorg-x11-fonts-cyrillic \
        xorg-x11-fonts-misc \
        xorg-x11-fonts-Type1 \
        xorg-x11-fonts-75dpi \
        xorg-x11-fonts-100dpi \
        alsa-lib \
        atk \
        cups-libs \
        gtk3 \
        libdrm \
        libxkbcommon \
        libxcomposite \
        libxdamage \
        libxrandr \
        mesa-libgbm \
        xorg-x11-server-Xvfb
fi

# Verify Chrome installation
CHROME_VERSION=$(google-chrome --version)
log "Chrome version: $CHROME_VERSION"

# Create application directory
log "Setting up application directory..."
if [ -d "$APP_DIR" ]; then
    warn "Application directory exists. Backing up existing installation..."
    sudo mv "$APP_DIR" "${APP_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$APP_DIR"

# Download or copy application files
log "Downloading BrowserShield application..."
if [ -f "/tmp/browsershield.zip" ]; then
    log "Using local application package..."
    unzip -q /tmp/browsershield.zip -d "$APP_DIR"
else
    log "Cloning from repository..."
    git clone https://github.com/huynd94/TheBrowserShield.git "$APP_DIR" || {
        warn "Git clone failed, downloading as ZIP..."
        wget -O /tmp/browsershield.zip https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip
        unzip -q /tmp/browsershield.zip -d /tmp/
        cp -r /tmp/TheBrowserShield-main/* "$APP_DIR/"
        rm -rf /tmp/TheBrowserShield-main /tmp/browsershield.zip
    }
fi

# Set correct ownership
sudo chown -R $APP_USER:$APP_USER "$APP_DIR"
cd "$APP_DIR"

# Install Node.js dependencies
log "Installing Node.js dependencies..."
npm install

# Create data directory with proper permissions
log "Setting up data directory..."
mkdir -p "$APP_DIR/data"
chmod 755 "$APP_DIR/data"

# Configure for production mode
log "Configuring production mode with Chrome browser..."
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

# Create environment configuration
log "Creating environment configuration..."
cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=$PORT
ENABLE_RATE_LIMIT=true
LOG_LEVEL=info
# Add API_TOKEN for security if needed
# API_TOKEN=your-secure-token-here
EOF

# Create systemd service file
log "Creating systemd service..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=5
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=$PORT
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Configure firewall
log "Configuring firewall..."
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=${PORT}/tcp
sudo firewall-cmd --reload

# Test application
log "Testing application startup..."
cd "$APP_DIR"
timeout 30s node server.js &
APP_PID=$!
sleep 10

if kill -0 $APP_PID 2>/dev/null; then
    log "Application test successful"
    kill $APP_PID
    wait $APP_PID 2>/dev/null || true
else
    error "Application failed to start during test"
fi

# Enable and start service
log "Enabling and starting BrowserShield service..."
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

# Wait for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet ${SERVICE_NAME}; then
    log "Service started successfully"
else
    error "Service failed to start. Check logs with: sudo journalctl -u ${SERVICE_NAME} -f"
fi

# Verify API endpoint
log "Verifying API endpoints..."
sleep 3
if curl -s "http://localhost:${PORT}/health" > /dev/null; then
    log "Health endpoint is responding"
else
    warn "Health endpoint is not responding yet"
fi

# Display status information
log "Deployment completed successfully!"
echo
echo -e "${BLUE}=== BrowserShield VPS Deployment Summary ===${NC}"
echo -e "${GREEN}✓ Application installed at: $APP_DIR${NC}"
echo -e "${GREEN}✓ Service name: $SERVICE_NAME${NC}"
echo -e "${GREEN}✓ Running on port: $PORT${NC}"
echo -e "${GREEN}✓ Mode: Production (Chrome browser)${NC}"
echo -e "${GREEN}✓ Chrome version: $CHROME_VERSION${NC}"
echo
echo -e "${YELLOW}Management Commands:${NC}"
echo "  sudo systemctl start $SERVICE_NAME     # Start service"
echo "  sudo systemctl stop $SERVICE_NAME      # Stop service" 
echo "  sudo systemctl restart $SERVICE_NAME   # Restart service"
echo "  sudo systemctl status $SERVICE_NAME    # Check status"
echo "  sudo journalctl -u $SERVICE_NAME -f   # View logs"
echo
echo -e "${YELLOW}Access URLs:${NC}"
echo "  Web Interface: http://YOUR_VPS_IP:$PORT"
echo "  Admin Panel: http://YOUR_VPS_IP:$PORT/admin"
echo "  Mode Manager: http://YOUR_VPS_IP:$PORT/mode-manager"
echo "  API Health: http://YOUR_VPS_IP:$PORT/health"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure your firewall/security groups to allow port $PORT"
echo "2. Access the web interface to create browser profiles"
echo "3. Use Production Mode for real browser automation"
echo "4. Monitor logs with: sudo journalctl -u $SERVICE_NAME -f"
echo
echo -e "${GREEN}Deployment completed successfully!${NC}"

# Create quick management script
cat > "$APP_DIR/manage.sh" << 'EOF'
#!/bin/bash
# BrowserShield Management Script

case "$1" in
    start)
        sudo systemctl start browsershield
        echo "BrowserShield started"
        ;;
    stop)
        sudo systemctl stop browsershield
        echo "BrowserShield stopped"
        ;;
    restart)
        sudo systemctl restart browsershield
        echo "BrowserShield restarted"
        ;;
    status)
        sudo systemctl status browsershield
        ;;
    logs)
        sudo journalctl -u browsershield -f
        ;;
    update)
        echo "Updating BrowserShield..."
        cd /home/opc/browsershield
        git pull origin main
        npm install
        sudo systemctl restart browsershield
        echo "Update completed"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

chmod +x "$APP_DIR/manage.sh"

log "Management script created at $APP_DIR/manage.sh"