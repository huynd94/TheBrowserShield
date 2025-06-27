#!/bin/bash

# Anti-Detect Browser Manager - Oracle Linux 9 Installation Script
# Run with: curl -sSL https://your-repo/install-oracle-linux.sh | bash

set -e

echo "🚀 Installing Anti-Detect Browser Manager on Oracle Linux 9..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if running on Oracle Linux
if ! grep -q "Oracle Linux" /etc/os-release; then
    print_warning "This script is designed for Oracle Linux 9. Continuing anyway..."
fi

print_status "Step 1: Updating system packages..."
sudo dnf update -y

print_status "Step 2: Installing essential tools..."
sudo dnf install -y curl wget git unzip tar

# Try to install htop, but don't fail if it's not available
if ! sudo dnf install -y htop 2>/dev/null; then
    print_warning "htop not available in repository, skipping..."
fi

print_status "Step 3: Installing Node.js 20..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_status "Node.js version: $NODE_VERSION"
print_status "NPM version: $NPM_VERSION"

print_status "Step 4: Installing Chrome dependencies..."
sudo dnf install -y \
    alsa-lib \
    atk \
    cups-libs \
    gtk3 \
    ipa-gothic-fonts \
    libdrm \
    libxcomposite \
    libxdamage \
    libxrandr \
    libxss \
    libxtst \
    pango \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-cyrillic \
    xorg-x11-fonts-misc \
    xorg-x11-fonts-Type1 \
    xorg-x11-utils \
    liberation-fonts \
    nss \
    gconf-service \
    libgconf-2-4 \
    libxfont \
    cyrus-sasl-devel \
    libnsl

print_status "Step 5: Installing Google Chrome..."
sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

sudo dnf install -y google-chrome-stable

# Verify Chrome installation
CHROME_VERSION=$(google-chrome-stable --version)
print_status "Chrome version: $CHROME_VERSION"

print_status "Step 6: Creating application user..."
if id "browserapp" &>/dev/null; then
    print_warning "User 'browserapp' already exists"
else
    sudo useradd -m -s /bin/bash browserapp
    print_status "Created user 'browserapp'"
fi

print_status "Step 7: Setting up application directory..."
APP_DIR="/home/browserapp/anti-detect-browser"

# Create app directory if it doesn't exist
sudo -u browserapp mkdir -p $APP_DIR

# Download application files from Replit
print_status "Step 8: Downloading application files from Replit..."

# Create temporary directory for download
TEMP_DIR="/tmp/browsershield-download"
mkdir -p $TEMP_DIR

# Download project as zip from Replit
print_status "Downloading BrowserShield project..."
curl -L "https://replit.com/@ngocdm2006/BrowserShield.zip" -o $TEMP_DIR/browsershield.zip

# Extract files
cd $TEMP_DIR
if [ -f "browsershield.zip" ]; then
    unzip -q browsershield.zip
    
    # Find the extracted directory (it might have a different name)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*BrowserShield*" | head -1)
    
    if [ -z "$EXTRACTED_DIR" ]; then
        # Try alternative download method using git if zip fails
        print_warning "Zip extraction failed, trying git clone..."
        cd $APP_DIR
        sudo -u browserapp git clone https://github.com/huynd94/TheBrowserShield.git .
    else
        # Copy extracted files to app directory
        print_status "Copying files to application directory..."
        sudo cp -r $EXTRACTED_DIR/* $APP_DIR/
        sudo chown -R browserapp:browserapp $APP_DIR
    fi
else
    # Fallback: try direct git clone
    print_warning "Download failed, trying alternative method..."
    cd $APP_DIR
    sudo -u browserapp git clone https://github.com/huynd94/TheBrowserShield.git .
fi

# Clean up temp directory
rm -rf $TEMP_DIR

print_status "Step 9: Installing NPM dependencies..."
if [ -f "$APP_DIR/package.json" ]; then
    sudo -u browserapp bash -c "cd $APP_DIR && npm install --production"
else
    print_warning "Skipping npm install - no package.json found"
fi

print_status "Step 10: Configuring environment..."
sudo -u browserapp tee $APP_DIR/.env > /dev/null << EOF
PORT=5000
NODE_ENV=production
API_TOKEN=$(openssl rand -base64 32)
ENABLE_RATE_LIMIT=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
EOF

sudo chmod 600 $APP_DIR/.env
print_status "Created environment configuration"

print_status "Step 11: Switching to production mode..."
if [ -f "$APP_DIR/routes/profiles.js" ]; then
    # Backup and switch to production BrowserService
    sudo -u browserapp cp $APP_DIR/routes/profiles.js $APP_DIR/routes/profiles.js.backup
    sudo -u browserapp sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/BrowserService')/g" $APP_DIR/routes/profiles.js
    print_status "Switched to production BrowserService"
fi

print_status "Step 12: Creating systemd service..."
sudo tee /etc/systemd/system/anti-detect-browser.service > /dev/null << EOF
[Unit]
Description=Anti-Detect Browser Profile Manager
Documentation=https://github.com/your-repo
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
SyslogIdentifier=anti-detect-browser
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
sudo systemctl enable anti-detect-browser.service

print_status "Step 13: Configuring firewall..."
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

print_status "Step 14: Setting up performance optimizations..."
echo "browserapp soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "browserapp hard nofile 65536" | sudo tee -a /etc/security/limits.conf

print_status "Step 15: Starting the application..."
sudo systemctl start anti-detect-browser.service

# Wait a moment for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet anti-detect-browser.service; then
    print_status "✅ Service started successfully!"
else
    print_error "❌ Service failed to start. Check logs with: sudo journalctl -u anti-detect-browser.service"
    exit 1
fi

# Test the application
print_status "Step 16: Testing installation..."
if curl -s http://localhost:5000/health > /dev/null; then
    print_status "✅ Application is responding!"
else
    print_warning "⚠️  Application might still be starting up. Wait a moment and test manually."
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📊 Service Status:"
sudo systemctl status anti-detect-browser.service --no-pager -l
echo ""
echo "🌐 Access your application at:"
echo "   http://$SERVER_IP:5000"
echo ""
echo "🔧 Useful commands:"
echo "   View logs:    sudo journalctl -u anti-detect-browser.service -f"
echo "   Restart:      sudo systemctl restart anti-detect-browser.service"
echo "   Stop:         sudo systemctl stop anti-detect-browser.service"
echo "   Status:       sudo systemctl status anti-detect-browser.service"
echo ""
echo "🔑 Your API token is stored in: $APP_DIR/.env"
echo "   View it with: sudo -u browserapp cat $APP_DIR/.env | grep API_TOKEN"
echo ""
echo "📁 Application files: $APP_DIR"
echo "📝 Logs location: /var/log/journal/ (use journalctl)"
echo ""

# Show API token
API_TOKEN=$(sudo -u browserapp grep API_TOKEN $APP_DIR/.env | cut -d'=' -f2)
echo "🔐 Generated API Token: $API_TOKEN"
echo ""

print_status "Installation script completed!"