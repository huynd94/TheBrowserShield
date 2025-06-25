#!/bin/bash

# BrowserShield Quick Install Script
# Repository: https://github.com/huynd94/TheBrowserShield

echo "🛡️  BrowserShield Quick Installer"
echo "================================="
echo ""

# Check if running on supported OS
if command -v dnf &> /dev/null; then
    echo "✅ Oracle Linux/RHEL detected"
    curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield.sh | bash
elif command -v apt &> /dev/null; then
    echo "❌ Ubuntu/Debian not yet supported. Please use Oracle Linux 9 or RHEL."
    echo "   You can still install manually by cloning the repository."
else
    echo "❌ Unsupported operating system."
    echo "   Supported: Oracle Linux 9, RHEL 9, CentOS Stream 9"
fi