#!/bin/bash

# Fix Oracle Cloud access for BrowserShield port 5000
# Configure firewall and iptables for external access

echo "Fixing Oracle Cloud access for port 5000..."

# Step 1: Configure iptables for Oracle Cloud
echo "Configuring iptables..."
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT
sudo netfilter-persistent save 2>/dev/null || sudo service iptables save 2>/dev/null

# Step 2: Configure firewalld if available
if command -v firewall-cmd &> /dev/null; then
    echo "Configuring firewalld..."
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
fi

# Step 3: Check service status
echo "Checking BrowserShield service..."
sudo systemctl status browsershield.service --no-pager -l

# Step 4: Restart service to ensure proper binding
echo "Restarting service..."
sudo systemctl restart browsershield.service
sleep 3

# Step 5: Verify port is listening
echo "Checking port 5000..."
netstat -tulpn | grep :5000 || ss -tulpn | grep :5000

# Step 6: Test local access
echo "Testing local access..."
if curl -s http://localhost:5000/health > /dev/null; then
    echo "SUCCESS: Local access working"
else
    echo "WARNING: Local access failed"
fi

# Step 7: Display network info
echo ""
echo "Network configuration:"
echo "External IP: $(curl -s ifconfig.me 2>/dev/null || echo "Unknown")"
echo "Listening ports:"
netstat -tulpn | grep LISTEN | grep -E ":(5000|80|443)"

echo ""
echo "Oracle Cloud Security List Configuration Required:"
echo "1. Go to Oracle Cloud Console"
echo "2. Navigate to: Networking > Virtual Cloud Networks"
echo "3. Select your VCN > Security Lists > Default Security List"
echo "4. Add Ingress Rule:"
echo "   - Source CIDR: 0.0.0.0/0"
echo "   - IP Protocol: TCP"
echo "   - Destination Port Range: 5000"
echo ""
echo "After adding the security list rule, try accessing:"
echo "http://138.2.82.254:5000"