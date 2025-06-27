#!/bin/bash

# BrowserShield VPS Deployment Script
# Automated deployment for Ubuntu/CentOS/Oracle Linux
# Version: 2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="browsershield"
APP_USER="browsershield"
APP_DIR="/home/$APP_USER/$APP_NAME"
SERVICE_NAME="browsershield"
GITHUB_REPO="https://github.com/huynd94/TheBrowserShield"
NODE_VERSION="20"

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    print_status "Detected OS: $OS $VER"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root"
        print_status "Usage: sudo bash deploy-vps.sh"
        exit 1
    fi
}

# Install Node.js
install_nodejs() {
    print_header "Installing Node.js $NODE_VERSION"
    
    case $OS in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
            apt-get install -y nodejs
            ;;
        centos|rhel|ol|almalinux|rocky)
            dnf install -y epel-release
            dnf module enable nodejs:$NODE_VERSION -y
            dnf install -y nodejs npm
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_status "Node.js installed: $node_version"
    print_status "NPM installed: $npm_version"
}

# Install Chromium
install_chromium() {
    print_header "Installing Chromium"
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y chromium-browser
            ;;
        centos|rhel|ol|almalinux|rocky)
            dnf install -y epel-release
            dnf install -y chromium
            ;;
    esac
    
    print_status "Chromium installed successfully"
}

# Install system dependencies
install_dependencies() {
    print_header "Installing System Dependencies"
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y curl wget git unzip nginx firewalld
            # Dependencies for Chromium
            apt install -y libgconf-2-4 libxss1 libgtk-3-0 libgdk-pixbuf2.0-0 libxcomposite1 libasound2
            ;;
        centos|rhel|ol|almalinux|rocky)
            dnf install -y curl wget git unzip nginx firewalld
            # Dependencies for Chromium
            dnf install -y gtk3 libXScrnSaver alsa-lib
            ;;
    esac
    
    print_status "System dependencies installed"
}

# Create application user
create_user() {
    print_header "Creating Application User"
    
    if id "$APP_USER" &>/dev/null; then
        print_warning "User $APP_USER already exists"
    else
        useradd -m -s /bin/bash $APP_USER
        usermod -aG sudo $APP_USER
        print_status "User $APP_USER created"
    fi
}

# Download and setup application
setup_application() {
    print_header "Setting Up BrowserShield Application"
    
    # Create directory
    sudo -u $APP_USER mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Download source code
    print_status "Downloading source code..."
    sudo -u $APP_USER git clone $GITHUB_REPO.git .
    
    # Install NPM dependencies
    print_status "Installing NPM dependencies..."
    sudo -u $APP_USER npm install
    
    # Create necessary directories
    sudo -u $APP_USER mkdir -p data logs
    sudo -u $APP_USER chmod 755 data logs
    
    # Create production mode config
    sudo -u $APP_USER tee data/mode-config.json > /dev/null << EOF
{
  "mode": "production",
  "lastChanged": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "capabilities": {
    "realBrowser": true,
    "screenshots": true,
    "websiteInteraction": true,
    "chromeAutomation": true,
    "stealthMode": true
  }
}
EOF
    
    # Create environment file
    sudo -u $APP_USER tee .env > /dev/null << EOF
NODE_ENV=production
PORT=5000
EOF
    
    print_status "Application setup completed"
}

# Create systemd service
create_service() {
    print_header "Creating SystemD Service"
    
    tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload and enable service
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    
    print_status "SystemD service created and enabled"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    case $OS in
        ubuntu|debian)
            ufw allow 22/tcp
            ufw allow 5000/tcp
            ufw --force enable
            ;;
        centos|rhel|ol|almalinux|rocky)
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-port=5000/tcp
            firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --reload
            ;;
    esac
    
    print_status "Firewall configured"
}

# Setup Nginx reverse proxy
setup_nginx() {
    print_header "Setting Up Nginx Reverse Proxy"
    
    # Create Nginx config
    tee /etc/nginx/sites-available/$APP_NAME > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    # Enable site (Ubuntu/Debian style)
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
    else
        # CentOS/RHEL style
        cp /etc/nginx/sites-available/$APP_NAME /etc/nginx/conf.d/$APP_NAME.conf
    fi
    
    # Test and start Nginx
    nginx -t
    systemctl enable nginx
    systemctl restart nginx
    
    print_status "Nginx reverse proxy configured"
}

# Start application
start_application() {
    print_header "Starting BrowserShield"
    
    systemctl start $SERVICE_NAME
    sleep 3
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "BrowserShield started successfully"
    else
        print_error "Failed to start BrowserShield"
        systemctl status $SERVICE_NAME
        exit 1
    fi
}

# Test deployment
test_deployment() {
    print_header "Testing Deployment"
    
    # Test local connection
    print_status "Testing local connection..."
    if curl -s http://localhost:5000/health >/dev/null 2>&1; then
        print_status "✅ Local connection test passed"
    else
        print_warning "❌ Local connection test failed"
    fi
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "UNKNOWN")
    
    print_status "Deployment completed successfully!"
    echo ""
    echo "🎉 BrowserShield is now running on your VPS!"
    echo ""
    echo "📋 Access Information:"
    echo "   🌐 Direct Access: http://$SERVER_IP:5000"
    echo "   🔧 Admin Panel: http://$SERVER_IP:5000/admin"
    echo "   ⚙️  Mode Manager: http://$SERVER_IP:5000/mode-manager"
    echo ""
    echo "🔧 Management Commands:"
    echo "   📊 Check Status: systemctl status $SERVICE_NAME"
    echo "   📋 View Logs: journalctl -u $SERVICE_NAME -f"
    echo "   🔄 Restart: systemctl restart $SERVICE_NAME"
    echo "   🛑 Stop: systemctl stop $SERVICE_NAME"
    echo ""
    echo "📁 Application Directory: $APP_DIR"
    echo "👤 Application User: $APP_USER"
}

# Main deployment function
main() {
    print_header "BrowserShield VPS Deployment Script v2.0"
    
    # Pre-checks
    check_root
    detect_os
    
    # Installation steps
    install_dependencies
    install_nodejs
    install_chromium
    create_user
    setup_application
    create_service
    configure_firewall
    setup_nginx
    start_application
    test_deployment
    
    print_status "Deployment completed! 🎉"
}

# Run main function
main "$@"