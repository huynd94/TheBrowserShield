#!/bin/bash

# Debug BrowserShield service issues
# Find and fix the root cause of service crashes

echo "Debugging BrowserShield service..."

APP_DIR="/home/browserapp/browsershield"

echo "1. Checking service logs..."
sudo journalctl -u browsershield.service -n 20 --no-pager

echo ""
echo "2. Checking app directory and permissions..."
ls -la $APP_DIR/
ls -la $APP_DIR/.env

echo ""
echo "3. Testing Node.js app manually..."
cd $APP_DIR
sudo -u browserapp node --version
sudo -u browserapp npm --version

echo ""
echo "4. Testing app startup..."
sudo -u browserapp timeout 10 node server.js 2>&1 | head -10

echo ""
echo "5. Checking dependencies..."
sudo -u browserapp npm list --depth=0 2>&1 | head -10

echo ""
echo "6. Checking environment file..."
sudo -u browserapp cat .env

echo ""
echo "7. Checking routes file..."
head -5 routes/profiles.js

echo ""
echo "8. Process information..."
ps aux | grep -E "(node|browsershield)" | grep -v grep

echo ""
echo "Debug completed. Check output above for errors."