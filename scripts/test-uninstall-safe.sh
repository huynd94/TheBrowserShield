#!/bin/bash
# BrowserShield Safe Uninstall Test Script
# Test script to preview uninstall process safely

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  BrowserShield Safe Uninstall Test${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo -e "${YELLOW}This script will show you what would be removed WITHOUT actually removing anything.${NC}"
echo -e "${YELLOW}It's completely safe to run.${NC}"
echo
echo "Testing uninstall script with --dry-run option..."
echo

# Download and run uninstall script in dry-run mode
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-browsershield-vps.sh | bash -s -- --dry-run

echo
echo -e "${GREEN}Safe test completed!${NC}"
echo
echo -e "${YELLOW}What's next?${NC}"
echo "If you want to actually uninstall:"
echo "  1. Run: curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-browsershield-vps.sh | bash"
echo "  2. Or use VPS Manager: ./vps-manager.sh uninstall"
echo
echo "If you want to keep BrowserShield, no action needed."