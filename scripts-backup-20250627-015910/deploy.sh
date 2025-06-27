#!/bin/bash

# Quick deployment script for updates
# Usage: ./scripts/deploy.sh

set -e

APP_DIR="/home/browserapp/anti-detect-browser"
BACKUP_DIR="/home/browserapp/backups"

echo "🚀 Deploying Anti-Detect Browser Manager updates..."

# Create backup directory
sudo -u browserapp mkdir -p $BACKUP_DIR

# Create backup
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
echo "📦 Creating backup: $BACKUP_NAME"
sudo -u browserapp tar -czf $BACKUP_DIR/$BACKUP_NAME -C /home/browserapp anti-detect-browser/data

# Stop service
echo "🛑 Stopping service..."
sudo systemctl stop anti-detect-browser.service

# Update application files
echo "📥 Updating application files..."
if [ -d ".git" ]; then
    # If in a git repository
    sudo -u browserapp git pull origin main
else
    # Copy current directory files
    sudo cp -r . $APP_DIR/
    sudo chown -R browserapp:browserapp $APP_DIR
fi

# Install/update dependencies
echo "📦 Updating dependencies..."
sudo -u browserapp bash -c "cd $APP_DIR && npm install --production"

# Switch to production mode
echo "🔧 Configuring production mode..."
if [ -f "$APP_DIR/routes/profiles.js" ]; then
    sudo -u browserapp sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/BrowserService')/g" $APP_DIR/routes/profiles.js
fi

# Start service
echo "▶️  Starting service..."
sudo systemctl start anti-detect-browser.service

# Wait for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet anti-detect-browser.service; then
    echo "✅ Deployment successful!"
    echo "📊 Service status:"
    sudo systemctl status anti-detect-browser.service --no-pager -l
else
    echo "❌ Deployment failed! Checking logs..."
    sudo journalctl -u anti-detect-browser.service -n 20
    exit 1
fi

# Test the application
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Application is responding!"
else
    echo "⚠️  Application test failed"
fi

echo ""
echo "🎉 Deployment completed!"
echo "📁 Backup saved to: $BACKUP_DIR/$BACKUP_NAME"
echo "🌐 Application URL: http://$(curl -s ifconfig.me):5000"