#!/bin/bash

# Auto install script for BrowserShield on Oracle Linux 9 VPS
# Usage: curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-vps-auto.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "    BrowserShield VPS Auto-Installer"
    echo "    Oracle Linux 9 - Production Ready"
    echo "=================================================="
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as normal user (opc)."
        exit 1
    fi
}

detect_system() {
    if [ -f /etc/oracle-release ]; then
        DISTRO="oracle"
        print_status "Detected Oracle Linux"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        print_status "Detected Red Hat/CentOS"
    else
        print_warning "Unknown distribution, proceeding with Oracle Linux assumptions"
        DISTRO="oracle"
    fi
}

install_nodejs() {
    print_status "Installing Node.js 20..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_status "Node.js $NODE_VERSION is already installed"
            return
        fi
    fi
    
    # Install Node.js 20
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
    
    # Verify installation
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_status "Node.js installed: $NODE_VERSION"
    print_status "NPM installed: $NPM_VERSION"
}

install_dependencies() {
    print_status "Installing system dependencies..."
    sudo dnf update -y
    sudo dnf install -y git curl wget unzip tar
}

setup_application() {
    print_status "Setting up BrowserShield application..."
    
    APP_DIR="/home/opc/browsershield"
    
    # Remove existing installation
    if [ -d "$APP_DIR" ]; then
        print_warning "Removing existing installation..."
        rm -rf "$APP_DIR"
    fi
    
    # Create app directory
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"
    
    # Download from GitHub or create files directly
    if git clone https://github.com/huynd94/TheBrowserShield.git . 2>/dev/null; then
        print_status "Downloaded from GitHub successfully"
    else
        print_warning "GitHub download failed, creating minimal installation..."
        create_minimal_app
    fi
    
    # Install npm dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Create environment file
    cat > .env << 'EOF'
PORT=5000
NODE_ENV=production
API_TOKEN=4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=
BROWSER_MODE=mock
LOG_LEVEL=info
EOF
    
    # Set proper permissions
    chmod -R 755 "$APP_DIR"
    print_status "Application setup completed"
}

create_minimal_app() {
    print_status "Creating minimal BrowserShield application..."
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "browsershield",
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
    "uuid": "^9.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

    # Create server.js with full functionality
    curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/server.js -o server.js || {
        print_warning "Failed to download server.js, creating basic version..."
        cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'BrowserShield', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
    res.json({ 
        service: 'BrowserShield Anti-Detect Browser Manager',
        status: 'Running',
        version: '1.0.0'
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`BrowserShield running on port ${PORT}`);
});
EOF
    }
    
    # Create public directory and download admin files
    mkdir -p public
    curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/public/admin.html -o public/admin.html 2>/dev/null || true
    curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/public/admin.js -o public/admin.js 2>/dev/null || true
}

setup_systemd_service() {
    print_status "Setting up SystemD service..."
    
    # Stop existing service if running
    sudo systemctl stop browsershield.service 2>/dev/null || true
    
    # Create service file
    sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=opc
Group=opc
WorkingDirectory=/home/opc/browsershield
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/opc/browsershield

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable browsershield.service
    
    print_status "SystemD service configured"
}

configure_firewall() {
    print_status "Configuring firewall..."
    
    # Oracle Cloud iptables rule
    if sudo iptables -C INPUT -m state --state NEW -p tcp --dport 5000 -j ACCEPT 2>/dev/null; then
        print_status "iptables rule already exists"
    else
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT
        # Save iptables rules
        sudo mkdir -p /etc/iptables
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        print_status "iptables rule added for port 5000"
    fi
    
    # System firewall (if running)
    if sudo systemctl is-active --quiet firewalld; then
        sudo firewall-cmd --permanent --add-port=5000/tcp 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        print_status "firewalld configured"
    fi
}

test_installation() {
    print_status "Testing installation..."
    
    # Start service
    sudo systemctl start browsershield.service
    
    # Wait for service to start
    sleep 5
    
    # Check service status
    if sudo systemctl is-active --quiet browsershield.service; then
        print_status "✅ BrowserShield service is running"
    else
        print_error "❌ Service failed to start"
        sudo journalctl -u browsershield.service -n 5 --no-pager
        return 1
    fi
    
    # Test local connectivity
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_status "✅ Local connectivity test passed"
    else
        print_error "❌ Local connectivity test failed"
        return 1
    fi
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")
    
    print_status "✅ Installation completed successfully!"
    echo ""
    echo -e "${GREEN}🌐 Access URLs:${NC}"
    echo "   Homepage: http://$EXTERNAL_IP:5000"
    echo "   Admin Panel: http://$EXTERNAL_IP:5000/admin"
    echo "   Health Check: http://$EXTERNAL_IP:5000/health"
    echo ""
    echo -e "${GREEN}🔧 Management Commands:${NC}"
    echo "   Status:  sudo systemctl status browsershield.service"
    echo "   Restart: sudo systemctl restart browsershield.service"
    echo "   Logs:    sudo journalctl -u browsershield.service -f"
    echo "   Stop:    sudo systemctl stop browsershield.service"
    echo ""
    echo -e "${YELLOW}📝 Notes:${NC}"
    echo "   - Service runs automatically on boot"
    echo "   - API Token: 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k="
    echo "   - Running in Mock Mode (demo)"
    echo "   - Files located at: /home/opc/browsershield"
}

cleanup() {
    if [ $? -ne 0 ]; then
        print_error "Installation failed. Check the logs above for details."
        print_status "You can retry the installation or install manually."
    fi
}

# Main installation flow
main() {
    print_header
    
    trap cleanup EXIT
    
    print_status "Starting BrowserShield installation on Oracle Linux 9..."
    
    check_root
    detect_system
    install_dependencies
    install_nodejs
    setup_application
    setup_systemd_service
    configure_firewall
    test_installation
    
    print_status "🎉 BrowserShield installation completed successfully!"
}

# Run main function
main "$@"