#!/bin/bash

# Quick test script for BrowserShield access

echo "Testing BrowserShield access..."

# Check service
echo "1. Service status:"
sudo systemctl is-active browsershield.service

# Check port
echo "2. Port 5000 listening:"
if netstat -tulpn 2>/dev/null | grep -q ":5000" || ss -tulpn 2>/dev/null | grep -q ":5000"; then
    echo "YES - Port 5000 is listening"
else
    echo "NO - Port 5000 not listening"
fi

# Test local
echo "3. Local access test:"
if curl -s --connect-timeout 5 http://localhost:5000/ > /dev/null; then
    echo "SUCCESS - Local access works"
else
    echo "FAILED - Local access failed"
fi

# Check iptables
echo "4. Iptables rules for port 5000:"
sudo iptables -L INPUT -n | grep 5000 || echo "No iptables rules found"

# Show recent logs
echo "5. Recent service logs:"
sudo journalctl -u browsershield.service -n 3 --no-pager

echo ""
echo "If local access works but external doesn't, check Oracle Cloud Security List:"
echo "Oracle Cloud Console > Networking > VCN > Security Lists > Add Ingress Rule for port 5000"