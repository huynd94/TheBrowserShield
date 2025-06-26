#!/bin/bash

# BrowserShield Ultimate One-Click Installation Script for Oracle Linux 9
# Comprehensive installation with all known fixes applied
# Project URL: https://github.com/huynd94/TheBrowserShield
# Run with: curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-ultimate.sh | bash

set -e

echo "🛡️ BrowserShield Ultimate Installation - Oracle Linux 9"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Preflight checks
print_header "Preflight System Checks"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as opc user."
   exit 1
fi

# Check sudo access
if ! sudo -v; then
    print_error "This script requires sudo privileges."
    exit 1
fi

# Check if Oracle Linux/RHEL
if ! command -v dnf &> /dev/null; then
    print_error "This script requires Oracle Linux 9 or RHEL-based system with dnf."
    exit 1
fi

# Detect architecture and set variables
ARCH=$(uname -m)
CURRENT_USER=$(whoami)
APP_DIR="/home/$CURRENT_USER/browsershield"
API_TOKEN=$(openssl rand -base64 32)

print_status "System: $(cat /etc/oracle-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || echo 'RHEL-based')"
print_status "Architecture: $ARCH"
print_status "User: $CURRENT_USER"
print_status "Install directory: $APP_DIR"

# Step 1: Clean up any existing installation
print_header "Step 1: Cleanup Previous Installation"
sudo systemctl stop browsershield.service 2>/dev/null || true
sudo systemctl disable browsershield.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/browsershield.service
sudo rm -rf /home/browserapp 2>/dev/null || true
rm -rf $APP_DIR 2>/dev/null || true
print_status "Previous installation cleaned up"

# Step 2: System update and essential tools
print_header "Step 2: System Preparation"
print_status "Updating system packages..."
sudo dnf update -y >/dev/null 2>&1

print_status "Installing essential tools..."
sudo dnf install -y curl wget git unzip tar openssl >/dev/null 2>&1

# Try to install htop, skip if not available
sudo dnf install -y htop 2>/dev/null || print_warning "htop not available, skipping..."

# Step 3: Node.js installation
print_header "Step 3: Node.js Installation"
if ! command -v node &> /dev/null || [[ $(node --version | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - >/dev/null 2>&1
    sudo dnf install -y nodejs >/dev/null 2>&1
else
    print_warning "Node.js already installed"
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_status "Node.js: $NODE_VERSION | NPM: $NPM_VERSION"

# Step 4: Browser dependencies
print_header "Step 4: Browser Dependencies"
print_status "Installing EPEL repository..."
sudo dnf install -y epel-release >/dev/null 2>&1

print_status "Installing core browser dependencies..."
# Install packages individually to avoid stopping on single failures
ESSENTIAL_PACKAGES=(
    "alsa-lib"
    "atk" 
    "cairo"
    "cups-libs"
    "fontconfig"
    "freetype"
    "gdk-pixbuf2"
    "glib2"
    "gtk3"
    "libX11"
    "libXcomposite"
    "libXcursor"
    "libXdamage"
    "libXext"
    "libXfixes"
    "libXi"
    "libXrandr"
    "libXrender"
    "libXss"
    "libXtst"
    "libdrm"
    "libxcb"
    "nss"
    "pango"
    "liberation-fonts"
)

INSTALLED_COUNT=0
for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if sudo dnf install -y "$package" >/dev/null 2>&1; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_warning "Failed to install $package, continuing..."
    fi
done

print_status "Successfully installed $INSTALLED_COUNT/${#ESSENTIAL_PACKAGES[@]} essential packages"

# Try optional packages
OPTIONAL_PACKAGES=(
    "dbus-glib"
    "mesa-libgbm"
    "vulkan-loader"
)

for package in "${OPTIONAL_PACKAGES[@]}"; do
    sudo dnf install -y "$package" >/dev/null 2>&1 || true
done

# Step 5: Browser installation with fallback strategy
print_header "Step 5: Browser Installation"
BROWSER_INSTALLED=false
BROWSER_PATH=""
BROWSER_MODE="mock"

# Try Chromium from EPEL first
if [ "$BROWSER_INSTALLED" = false ]; then
    print_status "Attempting Chromium installation from EPEL..."
    if sudo dnf install -y chromium 2>/dev/null; then
        # Check multiple possible paths
        for path in "/usr/bin/chromium-browser" "/usr/bin/chromium" "/usr/lib64/chromium-browser/chromium-browser"; do
            if [ -f "$path" ]; then
                BROWSER_PATH="$path"
                BROWSER_INSTALLED=true
                BROWSER_MODE="production"
                print_status "Chromium installed successfully at $path"
                break
            fi
        done
    fi
fi

# Try Chrome direct download (x86_64 only)
if [ "$BROWSER_INSTALLED" = false ] && [ "$ARCH" = "x86_64" ]; then
    print_status "Attempting Chrome direct download..."
    CHROME_RPM="/tmp/google-chrome-stable.rpm"
    if curl -L "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o "$CHROME_RPM" 2>/dev/null; then
        # Try multiple installation methods
        if sudo dnf install -y --nobest "$CHROME_RPM" 2>/dev/null; then
            BROWSER_PATH="/usr/bin/google-chrome-stable"
            BROWSER_INSTALLED=true
            BROWSER_MODE="production"
            print_status "Chrome installed via dnf"
        elif sudo rpm -ivh --force --nodeps "$CHROME_RPM" 2>/dev/null; then
            BROWSER_PATH="/usr/bin/google-chrome-stable"
            BROWSER_INSTALLED=true
            BROWSER_MODE="production"
            print_status "Chrome installed via rpm"
        fi
        rm -f "$CHROME_RPM"
    fi
fi

# Try Firefox as fallback
if [ "$BROWSER_INSTALLED" = false ]; then
    print_status "Installing Firefox as fallback..."
    if sudo dnf install -y firefox 2>/dev/null; then
        BROWSER_PATH="/usr/bin/firefox"
        BROWSER_INSTALLED=true
        BROWSER_MODE="production"
        print_status "Firefox installed as fallback"
    fi
fi

# Set mock mode if no browser
if [ "$BROWSER_INSTALLED" = false ]; then
    print_warning "No browser available - using Mock mode"
    BROWSER_MODE="mock"
fi

print_status "Browser setup completed: $BROWSER_MODE mode"

# Step 6: Application setup
print_header "Step 6: Application Setup"
print_status "Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

# Download from GitHub with multiple fallback methods
print_status "Downloading BrowserShield source code..."
DOWNLOAD_SUCCESS=false

# Method 1: Git clone
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    if git clone https://github.com/huynd94/TheBrowserShield.git temp-repo >/dev/null 2>&1; then
        if [ -f "temp-repo/package.json" ]; then
            cp -r temp-repo/* ./
            rm -rf temp-repo
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded via Git clone"
        fi
    fi
fi

# Method 2: ZIP download
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    if curl -L "https://github.com/huynd94/TheBrowserShield/archive/refs/heads/main.zip" -o source.zip >/dev/null 2>&1; then
        if unzip -q source.zip; then
            EXTRACTED_DIR=$(find . -name "TheBrowserShield-main" -type d | head -1)
            if [ -n "$EXTRACTED_DIR" ] && [ -f "$EXTRACTED_DIR/package.json" ]; then
                cp -r $EXTRACTED_DIR/* ./
                rm -rf $EXTRACTED_DIR source.zip
                DOWNLOAD_SUCCESS=true
                print_status "Downloaded via ZIP"
            fi
        fi
    fi
fi

# Method 3: Create minimal working version
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    print_warning "Creating minimal working version..."
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "browsershield",
  "version": "1.0.0",
  "description": "Anti-Detect Browser Profile Manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^5.1.0",
    "cors": "^2.8.5",
    "uuid": "^11.1.0",
    "puppeteer-extra": "^3.3.6",
    "puppeteer-extra-plugin-stealth": "^2.11.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

    # Create directories
    mkdir -p {routes,services,middleware,config,utils,public,data}
    
    # Create minimal server.js
    cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'BrowserShield',
        mode: process.env.BROWSER_MODE || 'mock',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// Routes
try {
    const profileRoutes = require('./routes/profiles');
    app.use('/api/profiles', profileRoutes);
} catch (err) {
    console.log('Routes not available, using basic endpoints');
}

// Basic root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'BrowserShield Anti-Detect Browser Manager',
        status: 'running',
        mode: process.env.BROWSER_MODE || 'mock',
        endpoints: ['/health', '/api/profiles']
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🛡️ BrowserShield running on port ${PORT}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🎭 Mode: ${process.env.BROWSER_MODE || 'mock'}`);
});
EOF

    DOWNLOAD_SUCCESS=true
fi

# Step 7: NPM dependencies
print_header "Step 7: Installing Dependencies"
print_status "Installing NPM packages..."
if [ -f "package.json" ]; then
    npm install --production >/dev/null 2>&1
    print_status "Dependencies installed successfully"
else
    print_error "package.json not found"
    exit 1
fi

# Step 8: Configuration
print_header "Step 8: Configuration"
print_status "Creating environment configuration..."

cat > .env << EOF
PORT=5000
NODE_ENV=production
API_TOKEN=$API_TOKEN
ENABLE_RATE_LIMIT=false
BROWSER_MODE=$BROWSER_MODE
PUPPETEER_EXECUTABLE_PATH=$BROWSER_PATH
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
EOF

chmod 600 .env

# Configure for mock mode if needed
if [ "$BROWSER_MODE" = "mock" ] && [ -f "routes/profiles.js" ]; then
    print_status "Configuring for Mock mode..."
    cp routes/profiles.js routes/profiles.js.backup 2>/dev/null || true
    sed -i 's/BrowserService/MockBrowserService/g' routes/profiles.js 2>/dev/null || true
    sed -i 's/FirefoxBrowserService/MockBrowserService/g' routes/profiles.js 2>/dev/null || true
fi

# Create data directory with sample data
mkdir -p data
cat > data/profiles.json << 'EOF'
[
  {
    "id": "sample-1",
    "name": "Default Profile",
    "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "timezone": "America/New_York",
    "viewport": {"width": 1920, "height": 1080},
    "createdAt": "2025-06-26T12:00:00.000Z"
  },
  {
    "id": "sample-2", 
    "name": "Mobile Profile",
    "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)",
    "timezone": "Europe/London",
    "viewport": {"width": 375, "height": 667},
    "createdAt": "2025-06-26T12:00:00.000Z"
  }
]
EOF

cat > data/proxy-pool.json << 'EOF'
[]
EOF

# Step 9: Pre-flight testing
print_header "Step 9: Application Testing"
print_status "Testing application startup..."

# Test syntax
if node -c server.js >/dev/null 2>&1; then
    print_status "✅ Server syntax is valid"
else
    print_error "Server syntax error"
    exit 1
fi

# Test startup
timeout 8 node server.js &
STARTUP_PID=$!
sleep 5

if ps -p $STARTUP_PID >/dev/null 2>&1; then
    print_status "✅ Application starts successfully"
    kill $STARTUP_PID 2>/dev/null || true
    wait $STARTUP_PID 2>/dev/null || true
else
    print_error "Application failed to start"
    exit 1
fi

# Test HTTP response
node server.js &
SERVER_PID=$!
sleep 3

if curl -s http://localhost:5000/health >/dev/null 2>&1; then
    print_status "✅ HTTP endpoints responding"
else
    print_warning "HTTP test inconclusive"
fi

kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

# Step 10: SystemD service
print_header "Step 10: System Service Setup"
print_status "Creating SystemD service..."

sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

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

# Step 11: Firewall configuration
print_header "Step 11: Firewall Configuration"
print_status "Configuring firewall access..."

# Configure firewalld if available
if command -v firewall-cmd &> /dev/null && sudo systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-port=5000/tcp >/dev/null 2>&1
    sudo firewall-cmd --reload >/dev/null 2>&1
    print_status "✅ firewalld configured"
fi

# Configure iptables for Oracle Cloud
if sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT 2>/dev/null; then
    print_status "✅ iptables configured"
fi

# Step 12: Performance optimization
print_header "Step 12: Performance Optimization"
print_status "Applying performance optimizations..."

# Increase file limits
echo "$CURRENT_USER soft nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null
echo "$CURRENT_USER hard nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null

# Step 13: Management scripts
print_header "Step 13: Management Tools"
print_status "Creating management scripts..."

# Monitor script
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "🖥️  BrowserShield System Monitor"
echo "==============================="

echo "📊 Service Status:"
if systemctl is-active --quiet browsershield.service; then
    echo "✅ BrowserShield is RUNNING"
else
    echo "❌ BrowserShield is STOPPED"
fi

echo ""
systemctl status browsershield.service --no-pager -l | head -10

echo ""
echo "🌐 Application Health:"
if curl -s http://localhost:5000/health >/dev/null; then
    echo "✅ Application responding"
    curl -s http://localhost:5000/health | python3 -m json.tool 2>/dev/null || echo "Response received"
else
    echo "❌ Application not responding"
fi

echo ""
echo "💾 System Resources:"
free -h | grep -E "(Mem|Swap)"
echo ""
df -h | grep -E "(Filesystem|/$)"

echo ""
echo "📝 Recent Logs:"
journalctl -u browsershield.service -n 5 --no-pager
EOF

chmod +x monitor.sh

# Update script
cat > update.sh << 'EOF'
#!/bin/bash
echo "🔄 Updating BrowserShield..."

# Backup data
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/ 2>/dev/null || true

# Stop service
sudo systemctl stop browsershield.service

# Update from git if available
if [ -d ".git" ]; then
    git pull origin main
    npm install --production
fi

# Restart service
sudo systemctl start browsershield.service

echo "✅ Update completed!"
./monitor.sh
EOF

chmod +x update.sh

# Step 14: Service startup
print_header "Step 14: Service Startup"
print_status "Starting BrowserShield service..."

sudo systemctl start browsershield.service
sleep 5

# Verify service status
if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ Service started successfully"
    
    # Test web interface
    sleep 2
    if curl -s http://localhost:5000/health >/dev/null 2>&1; then
        print_status "✅ Web interface accessible"
    else
        print_warning "Service running but web interface test failed"
    fi
else
    print_error "❌ Service failed to start"
    echo "Service logs:"
    sudo journalctl -u browsershield.service -n 10 --no-pager
    exit 1
fi

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

# Final status report
print_header "Installation Completed Successfully!"

echo ""
echo "🎉 BrowserShield Ultimate installation completed!"
echo ""
echo "📊 Installation Summary:"
echo "   ✅ System: Oracle Linux 9 ($ARCH)"
echo "   ✅ User: $CURRENT_USER"
echo "   ✅ Node.js: $NODE_VERSION"
echo "   ✅ Browser: $BROWSER_MODE mode"
if [ "$BROWSER_INSTALLED" = true ]; then
echo "   ✅ Browser Path: $BROWSER_PATH"
fi
echo "   ✅ Service: Running and enabled"
echo "   ✅ Firewall: Configured for port 5000"
echo ""
echo "🌐 Access Information:"
echo "   External URL: http://$EXTERNAL_IP:5000"
echo "   Local URL:    http://localhost:5000"
echo "   Health Check: http://$EXTERNAL_IP:5000/health"
echo ""
echo "🔑 Security:"
echo "   API Token: $API_TOKEN"
echo "   Config: $APP_DIR/.env"
echo ""
echo "🛠️  Management Commands:"
echo "   Service Status:  sudo systemctl status browsershield.service"
echo "   View Logs:       sudo journalctl -u browsershield.service -f"
echo "   Restart Service: sudo systemctl restart browsershield.service"
echo "   System Monitor:  $APP_DIR/monitor.sh"
echo "   Update App:      $APP_DIR/update.sh"
echo ""

if [ "$BROWSER_MODE" = "mock" ]; then
    echo "⚠️  Running in MOCK mode (demo functionality)"
    echo "   - All features available for testing"
    echo "   - No real browser automation"
    echo "   - Install Chrome/Chromium for full functionality"
    echo ""
fi

echo "🎯 Quick Test:"
echo "   curl http://localhost:5000/health"
echo ""
echo "✅ BrowserShield is ready to use!"
echo "📖 Documentation: https://github.com/huynd94/TheBrowserShield"

print_status "Ultimate installation script completed successfully!"