#!/bin/bash

# Fix BrowserShield port 5000 access issues on Oracle Linux 9
# Check firewall, service binding, and network configuration

echo "🔧 Fixing port 5000 access for BrowserShield..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

APP_DIR="/home/browserapp/browsershield"

print_status "Step 1: Checking current service status..."
sudo systemctl status browsershield.service --no-pager -l

print_status "Step 2: Checking if service is listening on port 5000..."
netstat -tulpn | grep :5000 || ss -tulpn | grep :5000

print_status "Step 3: Checking server.js binding configuration..."
if [ -f "$APP_DIR/server.js" ]; then
    grep -n "listen\|bind\|host" "$APP_DIR/server.js" | head -5
fi

print_status "Step 4: Ensuring service binds to 0.0.0.0..."
if [ -f "$APP_DIR/server.js" ]; then
    # Check if server is binding to localhost only
    if grep -q "localhost\|127.0.0.1" "$APP_DIR/server.js"; then
        print_warning "Server might be binding to localhost only"
        
        # Create backup
        sudo -u browserapp cp "$APP_DIR/server.js" "$APP_DIR/server.js.backup"
        
        # Replace localhost with 0.0.0.0
        sudo -u browserapp sed -i 's/localhost/0.0.0.0/g' "$APP_DIR/server.js"
        sudo -u browserapp sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_DIR/server.js"
        
        print_status "Updated server binding to 0.0.0.0"
    fi
fi

print_status "Step 5: Configuring firewall for port 5000..."

# Oracle Linux uses firewalld
if command -v firewall-cmd &> /dev/null; then
    print_status "Configuring firewalld..."
    
    # Check if firewalld is running
    if sudo systemctl is-active --quiet firewalld; then
        # Add port 5000
        sudo firewall-cmd --permanent --add-port=5000/tcp
        sudo firewall-cmd --reload
        
        # Verify rule
        sudo firewall-cmd --list-ports | grep 5000
        
        print_status "✅ Firewall configured for port 5000"
    else
        print_warning "Firewalld not running"
    fi
fi

# Also check iptables as backup
if command -v iptables &> /dev/null; then
    print_status "Checking iptables rules..."
    sudo iptables -C INPUT -p tcp --dport 5000 -j ACCEPT 2>/dev/null || {
        sudo iptables -I INPUT -p tcp --dport 5000 -j ACCEPT
        print_status "Added iptables rule for port 5000"
    }
fi

print_status "Step 6: Updating environment configuration..."
if [ -f "$APP_DIR/.env" ]; then
    # Ensure HOST is set to 0.0.0.0
    if ! grep -q "HOST=" "$APP_DIR/.env"; then
        echo "HOST=0.0.0.0" | sudo -u browserapp tee -a "$APP_DIR/.env"
    else
        sudo -u browserapp sed -i 's/HOST=.*/HOST=0.0.0.0/' "$APP_DIR/.env"
    fi
    
    print_status "Environment configured for external access"
fi

print_status "Step 7: Restarting BrowserShield service..."
sudo systemctl restart browsershield.service

sleep 5

print_status "Step 8: Verifying service is running and accessible..."

# Check service status
if sudo systemctl is-active --quiet browsershield.service; then
    print_status "✅ Service is running"
    
    # Check if port is listening
    if netstat -tulpn 2>/dev/null | grep -q ":5000" || ss -tulpn 2>/dev/null | grep -q ":5000"; then
        print_status "✅ Port 5000 is listening"
        
        # Test local access
        if curl -s http://localhost:5000/health > /dev/null 2>&1; then
            print_status "✅ Local access working"
        elif curl -s http://localhost:5000/ > /dev/null 2>&1; then
            print_status "✅ Local web interface accessible"
        fi
        
        # Get external IP
        EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "138.2.82.254")
        
        print_status "Testing external access..."
        if curl -s --connect-timeout 10 http://$EXTERNAL_IP:5000/ > /dev/null 2>&1; then
            print_status "✅ External access working!"
        else
            print_warning "External access test failed (might be normal due to network/firewall)"
        fi
        
        echo ""
        echo "🌐 BrowserShield should be accessible at:"
        echo "   External: http://$EXTERNAL_IP:5000"
        echo "   Local:    http://localhost:5000"
        echo ""
        
    else
        print_error "Port 5000 is not listening"
        print_status "Service logs:"
        sudo journalctl -u browsershield.service -n 10 --no-pager
    fi
    
else
    print_error "Service is not running"
    print_status "Service logs:"
    sudo journalctl -u browsershield.service -n 10 --no-pager
fi

print_status "Step 9: Network diagnostics..."
echo "Active network listeners:"
netstat -tulpn 2>/dev/null | grep LISTEN | grep -E ":(80|443|5000|8000)" || ss -tulpn 2>/dev/null | grep LISTEN | grep -E ":(80|443|5000|8000)"

echo ""
echo "Firewall status:"
if command -v firewall-cmd &> /dev/null && sudo systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --list-ports
else
    echo "Firewalld not active"
fi

echo ""
echo "🔧 Port access configuration completed!"