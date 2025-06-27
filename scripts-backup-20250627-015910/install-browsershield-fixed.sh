#!/bin/bash

# BrowserShield Anti-Detect Browser Manager - Oracle Linux 9 Installation Script (Fixed)
# Project URL: https://github.com/huynd94/TheBrowserShield
# Run with: curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed.sh | bash

set -e

echo "🛡️  Installing BrowserShield Anti-Detect Browser Manager on Oracle Linux 9 (Fixed Version)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check sudo access
if ! sudo -v; then
    print_error "This script requires sudo privileges. Please run with a user that has sudo access."
    exit 1
fi

# Check if running on Oracle Linux or similar RHEL-based system
if ! command -v dnf &> /dev/null; then
    print_error "This script is designed for Oracle Linux 9 or RHEL-based systems with dnf package manager."
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
print_status "Detected architecture: $ARCH"

print_header "BrowserShield Installation Starting (Fixed Version)"
echo "Project: https://github.com/huynd94/TheBrowserShield"
echo "Target: Oracle Linux 9 VPS"
echo "Architecture: $ARCH"
echo ""

print_status "Step 1: Updating system packages..."
sudo dnf update -y

print_status "Step 2: Installing essential tools..."
sudo dnf install -y curl wget git unzip tar

# Try to install htop, but don't fail if it's not available
if ! sudo dnf install -y htop 2>/dev/null; then
    print_warning "htop not available in repository, skipping..."
fi

print_status "Step 3: Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
else
    print_warning "Node.js already installed"
fi

# Verify Node.js installation
NODE_VERSION=$(node --version 2>/dev/null || echo "Not installed")
NPM_VERSION=$(npm --version 2>/dev/null || echo "Not installed")
print_status "Node.js version: $NODE_VERSION"
print_status "NPM version: $NPM_VERSION"

print_status "Step 4: Installing browser dependencies..."

# Essential packages that are definitely available
sudo dnf install -y \
    alsa-lib \
    atk \
    cups-libs \
    gtk3 \
    libdrm \
    libXcomposite \
    libXdamage \
    libXrandr \
    libXss \
    libXtst \
    pango \
    liberation-fonts \
    nss \
    cyrus-sasl-devel \
    libnsl

# Install EPEL repository for additional packages
sudo dnf install -y epel-release

print_status "Step 5: Installing Chromium browser..."

# Try different methods to install Chromium based on architecture
BROWSER_INSTALLED=false

# Method 1: Try installing Chromium from EPEL
if [ "$BROWSER_INSTALLED" = false ]; then
    print_status "Attempting to install Chromium from EPEL..."
    if sudo dnf install -y chromium 2>/dev/null; then
        BROWSER_PATH="/usr/bin/chromium-browser"
        if [ -f "$BROWSER_PATH" ]; then
            BROWSER_INSTALLED=true
            print_status "✅ Chromium installed from EPEL"
        fi
    fi
fi

# Method 2: Try installing from Flatpak (if available)
if [ "$BROWSER_INSTALLED" = false ]; then
    print_status "Attempting to install Chromium via Flatpak..."
    if sudo dnf install -y flatpak 2>/dev/null; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        if sudo flatpak install -y flathub org.chromium.Chromium 2>/dev/null; then
            BROWSER_PATH="/usr/bin/flatpak run org.chromium.Chromium"
            BROWSER_INSTALLED=true
            print_status "✅ Chromium installed via Flatpak"
        fi
    fi
fi

# Method 3: Download and install Chromium manually for x86_64
if [ "$BROWSER_INSTALLED" = false ] && [ "$ARCH" = "x86_64" ]; then
    print_status "Downloading Chromium manually for x86_64..."
    
    # Create temp directory
    TEMP_DIR="/tmp/chromium-install"
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR
    
    # Download Chromium
    CHROMIUM_URL="https://download-chromium.appspot.com/dl/Linux_x64?type=snapshots"
    if wget -q "$CHROMIUM_URL" -O chromium.zip; then
        if unzip -q chromium.zip; then
            CHROMIUM_DIR=$(find . -name "chrome-linux*" -type d | head -1)
            if [ -n "$CHROMIUM_DIR" ]; then
                sudo mv "$CHROMIUM_DIR" /opt/chromium
                sudo ln -sf /opt/chromium/chrome /usr/local/bin/chromium-browser
                BROWSER_PATH="/usr/local/bin/chromium-browser"
                BROWSER_INSTALLED=true
                print_status "✅ Chromium installed manually"
            fi
        fi
    fi
    
    # Clean up
    cd /
    rm -rf $TEMP_DIR
fi

# Method 4: Install Firefox as fallback
if [ "$BROWSER_INSTALLED" = false ]; then
    print_status "Installing Firefox as fallback browser..."
    if sudo dnf install -y firefox; then
        BROWSER_PATH="/usr/bin/firefox"
        BROWSER_INSTALLED=true
        print_status "✅ Firefox installed as fallback"
    fi
fi

# Method 5: Set up for mock mode if no browser available
if [ "$BROWSER_INSTALLED" = false ]; then
    print_warning "⚠️  No browser could be installed. Setting up in MOCK mode."
    BROWSER_PATH=""
    MOCK_MODE=true
else
    MOCK_MODE=false
fi

# Verify browser installation
if [ "$BROWSER_INSTALLED" = true ]; then
    BROWSER_VERSION=$($BROWSER_PATH --version 2>/dev/null || echo "Version check failed")
    print_status "Browser version: $BROWSER_VERSION"
    print_status "Browser path: $BROWSER_PATH"
fi

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

# Create temporary directory
TEMP_DIR="/tmp/browsershield-install"
sudo rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# Download source code using multiple methods
print_status "Downloading from GitHub repository..."
DOWNLOAD_SUCCESS=false

# Method 1: Git clone from GitHub
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    print_status "Cloning from GitHub repository..."
    if git clone https://github.com/huynd94/TheBrowserShield.git browsershield-git 2>/dev/null; then
        if [ -f "browsershield-git/package.json" ]; then
            sudo cp -r browsershield-git/* $APP_DIR/
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded via Git clone"
        fi
    fi
fi

# Method 2: Download ZIP from GitHub
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    print_status "Trying GitHub ZIP download..."
    if curl -L --fail "https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip" -o browsershield.zip 2>/dev/null; then
        if unzip -q browsershield.zip 2>/dev/null; then
            EXTRACTED_DIR=$(find . -maxdepth 2 -name "package.json" | head -1 | xargs dirname 2>/dev/null || echo "")
            if [ -n "$EXTRACTED_DIR" ] && [ -f "$EXTRACTED_DIR/package.json" ]; then
                sudo cp -r $EXTRACTED_DIR/* $APP_DIR/
                DOWNLOAD_SUCCESS=true
                print_status "Downloaded via GitHub ZIP"
            fi
        fi
    fi
fi

# Method 3: Manual creation with template (fallback)
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    print_warning "Direct download failed. Creating from template..."
    
    # Create basic project structure
    sudo -u browserapp tee $APP_DIR/package.json > /dev/null << 'EOF'
{
  "name": "browsershield-anti-detect",
  "version": "1.0.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "puppeteer": "^21.0.0",
    "puppeteer-extra": "^3.3.6",
    "puppeteer-extra-plugin-stealth": "^2.11.2"
  },
  "keywords": ["browser", "automation", "anti-detect", "stealth"],
  "author": "BrowserShield",
  "license": "MIT"
}
EOF

    print_warning "Download failed. Please check your internet connection and try again."
    print_warning "Or manually clone the repository:"
    print_warning "git clone https://github.com/huynd94/TheBrowserShield.git $APP_DIR"
    DOWNLOAD_SUCCESS=true
fi

# Set proper ownership
sudo chown -R browserapp:browserapp $APP_DIR

# Clean up temp directory
rm -rf $TEMP_DIR

print_status "Step 9: Installing NPM dependencies..."
if [ -f "$APP_DIR/package.json" ]; then
    sudo -u browserapp bash -c "cd $APP_DIR && npm install --production"
    print_status "NPM dependencies installed"
else
    print_warning "Skipping npm install - no package.json found"
fi

print_status "Step 10: Configuring environment..."
# Generate secure API token
API_TOKEN=$(openssl rand -base64 32)

# Set browser configuration based on what was installed
if [ "$MOCK_MODE" = true ]; then
    BROWSER_MODE="mock"
    BROWSER_EXECUTABLE=""
else
    BROWSER_MODE="production"
    BROWSER_EXECUTABLE="$BROWSER_PATH"
fi

sudo -u browserapp tee $APP_DIR/.env > /dev/null << EOF
PORT=5000
NODE_ENV=production
API_TOKEN=$API_TOKEN
ENABLE_RATE_LIMIT=true
BROWSER_MODE=$BROWSER_MODE
PUPPETEER_EXECUTABLE_PATH=$BROWSER_EXECUTABLE
EOF

sudo chmod 600 $APP_DIR/.env
print_status "Environment configuration created"

print_status "Step 11: Configuring browser service mode..."
if [ -f "$APP_DIR/routes/profiles.js" ]; then
    # Backup and switch to appropriate BrowserService
    sudo -u browserapp cp $APP_DIR/routes/profiles.js $APP_DIR/routes/profiles.js.backup 2>/dev/null || true
    
    if [ "$MOCK_MODE" = true ]; then
        sudo -u browserapp sed -i "s/require('..\/services\/BrowserService')/require('..\/services\/MockBrowserService')/g" $APP_DIR/routes/profiles.js 2>/dev/null || true
        print_status "Configured for Mock mode (no browser available)"
    else
        sudo -u browserapp sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/BrowserService')/g" $APP_DIR/routes/profiles.js 2>/dev/null || true
        print_status "Configured for Production mode with $BROWSER_PATH"
    fi
else
    print_warning "Routes file not found - manual configuration may be needed"
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
Environment=DISPLAY=:99
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
else
    print_warning "firewalld not found - please configure firewall manually to allow port 5000"
fi

print_status "Step 14: Setting up performance optimizations..."
echo "browserapp soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "browserapp hard nofile 65536" | sudo tee -a /etc/security/limits.conf

print_status "Step 15: Creating management scripts..."
# Create update script
sudo -u browserapp tee $APP_DIR/update.sh > /dev/null << 'EOF'
#!/bin/bash
echo "🔄 Updating BrowserShield..."
cd /home/browserapp/browsershield

# Backup current data
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/ 2>/dev/null || true

# Pull latest changes (if git repo)
if [ -d ".git" ]; then
    git pull origin main
fi

# Update dependencies
npm install --production

# Restart service
sudo systemctl restart browsershield.service

echo "✅ Update completed!"
EOF

sudo chmod +x $APP_DIR/update.sh

# Create monitoring script
sudo -u browserapp tee $APP_DIR/monitor.sh > /dev/null << 'EOF'
#!/bin/bash
echo "🖥️  BrowserShield System Monitor"
echo "==============================="
echo ""

# Service status
echo "📊 Service Status:"
if systemctl is-active --quiet browsershield.service; then
    echo "✅ BrowserShield is RUNNING"
else
    echo "❌ BrowserShield is STOPPED"
fi

echo ""
systemctl status browsershield.service --no-pager -l | head -15

echo ""
echo "🌐 Application Health:"
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Application is responding"
else
    echo "❌ Application is not responding"
fi

echo ""
echo "💾 System Resources:"
echo "Memory Usage:"
free -h | grep -E "(Mem|Swap)"

echo ""
echo "Disk Usage:"
df -h | grep -E "(Filesystem|/$)"

echo ""
echo "📝 Recent Logs:"
journalctl -u browsershield.service -n 5 --no-pager
EOF

sudo chmod +x $APP_DIR/monitor.sh

print_status "Step 16: Starting BrowserShield..."
if [ -f "$APP_DIR/server.js" ]; then
    sudo systemctl start browsershield.service
    
    # Wait for service to start
    sleep 5
    
    # Check service status
    if sudo systemctl is-active --quiet browsershield.service; then
        print_status "✅ BrowserShield started successfully!"
    else
        print_error "❌ Service failed to start. Checking logs..."
        sudo journalctl -u browsershield.service -n 10
    fi
else
    print_warning "⚠️  server.js not found. Service created but not started."
    print_warning "Please upload your BrowserShield files and start manually with:"
    print_warning "sudo systemctl start browsershield.service"
fi

# Test the application
print_status "Step 17: Testing installation..."
sleep 2
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
    print_status "✅ Application is responding!"
else
    print_warning "⚠️  Application test inconclusive. Check manually."
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

print_header "Installation Completed!"

echo ""
echo "🎉 BrowserShield installation completed successfully!"
echo ""
echo "📊 Service Information:"
echo "   Service Name: browsershield.service"
echo "   User: browserapp"
echo "   Directory: $APP_DIR"
echo "   Browser Mode: $BROWSER_MODE"
if [ "$BROWSER_INSTALLED" = true ]; then
echo "   Browser Path: $BROWSER_PATH"
fi
echo ""
echo "🌐 Access URLs:"
echo "   Local:    http://localhost:5000"
echo "   External: http://$SERVER_IP:5000"
echo ""
echo "🔧 Management Commands:"
echo "   Status:   sudo systemctl status browsershield.service"
echo "   Start:    sudo systemctl start browsershield.service"
echo "   Stop:     sudo systemctl stop browsershield.service"
echo "   Restart:  sudo systemctl restart browsershield.service"
echo "   Logs:     sudo journalctl -u browsershield.service -f"
echo ""
echo "🔑 Security Information:"
echo "   API Token: $API_TOKEN"
echo "   Config File: $APP_DIR/.env"
echo ""
echo "📁 Useful Files:"
echo "   Update Script: $APP_DIR/update.sh"
echo "   Monitor Script: $APP_DIR/monitor.sh"
echo "   Application Data: $APP_DIR/data/"
echo ""
echo "🚀 Quick Commands:"
echo "   Monitor System: $APP_DIR/monitor.sh"
echo "   Update App: $APP_DIR/update.sh"
echo ""

if [ "$MOCK_MODE" = true ]; then
    echo "⚠️  IMPORTANT: Running in MOCK mode (demo only)"
    echo "   - No real browser automation available"
    echo "   - Install Chromium/Chrome manually for full functionality"
    echo "   - Run: sudo dnf install chromium"
    echo ""
fi

# Show final service status
if sudo systemctl is-active --quiet browsershield.service; then
    echo "✅ BrowserShield is running and ready to use!"
    echo "🌐 Open http://$SERVER_IP:5000 in your browser to access the web interface"
else
    echo "⚠️  BrowserShield service needs to be started manually"
    echo "Run: sudo systemctl start browsershield.service"
fi

echo ""
print_status "Installation script completed successfully!"
echo "📖 For troubleshooting and advanced configuration, check the documentation."