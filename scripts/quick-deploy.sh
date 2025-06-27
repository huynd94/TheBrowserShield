#!/bin/bash

# BrowserShield Quick Deploy - One-line VPS deployment
# Usage: curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/quick-deploy.sh | sudo bash

set -e

echo "🛡️ BrowserShield Quick Deploy Starting..."
echo "📥 Downloading full deployment script..."

# Download and execute main deployment script
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/deploy-vps.sh -o /tmp/deploy-vps.sh
chmod +x /tmp/deploy-vps.sh

echo "🚀 Starting automated deployment..."
/tmp/deploy-vps.sh

# Cleanup
rm -f /tmp/deploy-vps.sh

echo "✅ Quick deployment completed!"