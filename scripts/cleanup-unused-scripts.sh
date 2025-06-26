#!/bin/bash

# BrowserShield Cleanup Script
# Removes unused and obsolete installation scripts
# Keeps only essential scripts for production use

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_header "BrowserShield Script Cleanup"

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_status "Project root: $PROJECT_ROOT"
print_status "Scripts directory: $SCRIPT_DIR"

# List of scripts to keep (essential for production)
KEEP_SCRIPTS=(
    "update-system.sh"
    "cleanup-unused-scripts.sh"
    "install-browsershield-fixed-robust.sh"
    "monitor.sh"
)

# List of obsolete scripts to remove
OBSOLETE_SCRIPTS=(
    "install-browsershield-ultimate.sh"
    "install-oracle-linux.sh"
    "install-browsershield.sh"
    "install-browsershield-v2.sh"
    "install-browsershield-fixed.sh"
    "deploy.sh"
    "setup-oracle-linux.sh"
    "quick-setup.sh"
)

print_header "Step 1: Analyzing Current Scripts"

cd "$SCRIPT_DIR"

# List all .sh files
ALL_SCRIPTS=($(ls -1 *.sh 2>/dev/null || true))

if [ ${#ALL_SCRIPTS[@]} -eq 0 ]; then
    print_warning "No shell scripts found in scripts directory"
    exit 0
fi

print_status "Found ${#ALL_SCRIPTS[@]} script(s):"
for script in "${ALL_SCRIPTS[@]}"; do
    echo "  - $script"
done

print_header "Step 2: Backup Scripts Before Cleanup"

# Create backup directory
BACKUP_DIR="$PROJECT_ROOT/scripts-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_status "Creating backup at: $BACKUP_DIR"
cp *.sh "$BACKUP_DIR/" 2>/dev/null || true
print_status "Backup created successfully"

print_header "Step 3: Remove Obsolete Scripts"

REMOVED_COUNT=0

for script in "${OBSOLETE_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        print_status "Removing obsolete script: $script"
        rm "$script"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

print_header "Step 4: Verify Essential Scripts"

MISSING_ESSENTIAL=()

for script in "${KEEP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        print_status "Essential script present: $script"
    else
        print_warning "Essential script missing: $script"
        MISSING_ESSENTIAL+=("$script")
    fi
done

# Create missing essential scripts if needed
if [ ${#MISSING_ESSENTIAL[@]} -gt 0 ]; then
    print_header "Step 5: Create Missing Essential Scripts"
    
    for script in "${MISSING_ESSENTIAL[@]}"; do
        case "$script" in
            "monitor.sh")
                print_status "Creating monitor.sh..."
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
    curl -s http://localhost:5000/health | jq '.' 2>/dev/null || echo "Health check response received"
else
    echo "❌ Application not responding"
fi

echo ""
echo "💾 System Resources:"
echo "Memory Usage:"
free -h | grep -E "Mem:|Swap:"

echo ""
echo "📊 Process Information:"
ps aux | grep -E "(node|browsershield)" | grep -v grep

echo ""
echo "📝 Recent Logs:"
journalctl -u browsershield.service -n 10 --no-pager

echo ""
echo "🔗 Quick Links:"
echo "  Home:         http://localhost:5000"
echo "  Admin:        http://localhost:5000/admin"
echo "  Mode Manager: http://localhost:5000/mode-manager"
echo "  Health:       http://localhost:5000/health"
EOF
                chmod +x monitor.sh
                ;;
        esac
    done
fi

print_header "Step 6: Cleanup Other Unnecessary Files"

# Remove temporary files
print_status "Cleaning temporary files..."
find "$PROJECT_ROOT" -name "*.tmp" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "*.log" -not -path "*/node_modules/*" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name ".DS_Store" -delete 2>/dev/null || true

# Clean npm cache if needed
if [ -d "$PROJECT_ROOT/node_modules" ]; then
    print_status "Cleaning npm cache..."
    cd "$PROJECT_ROOT"
    npm cache clean --force 2>/dev/null || true
fi

print_header "Step 7: Update Script Permissions"

cd "$SCRIPT_DIR"
print_status "Setting execute permissions on remaining scripts..."
chmod +x *.sh 2>/dev/null || true

print_header "Step 8: Generate Script Documentation"

# Create README for scripts directory
cat > README.md << EOF
# BrowserShield Scripts Directory

This directory contains essential scripts for BrowserShield system management.

## Available Scripts

### Production Scripts
- \`update-system.sh\` - Updates BrowserShield from GitHub repository
- \`install-browsershield-fixed-robust.sh\` - Robust installation script for Oracle Linux 9
- \`monitor.sh\` - System monitoring and health checks
- \`cleanup-unused-scripts.sh\` - Removes obsolete scripts (this script)

## Usage

### Update System
\`\`\`bash
./update-system.sh
\`\`\`

### Monitor System
\`\`\`bash
./monitor.sh
\`\`\`

### Fresh Installation
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh | bash
\`\`\`

## Maintenance

- Scripts are automatically maintained via the update system
- Obsolete scripts are cleaned up periodically
- Backups are created before any cleanup operations

## Last Cleanup
$(date)
EOF

print_status "Documentation updated"

print_header "Cleanup Summary"

# Count remaining scripts
REMAINING_SCRIPTS=($(ls -1 *.sh 2>/dev/null || true))

echo ""
echo "🧹 Cleanup completed successfully!"
echo ""
echo "📊 Summary:"
echo "   🗑️  Scripts removed: $REMOVED_COUNT"
echo "   📁 Scripts remaining: ${#REMAINING_SCRIPTS[@]}"
echo "   💾 Backup location: $BACKUP_DIR"
echo ""
echo "📋 Remaining Scripts:"
for script in "${REMAINING_SCRIPTS[@]}"; do
    is_essential=false
    for keep_script in "${KEEP_SCRIPTS[@]}"; do
        if [[ "$script" == "$keep_script" ]]; then
            is_essential=true
            break
        fi
    done
    
    if $is_essential; then
        echo "   ✅ $script (essential)"
    else
        echo "   📄 $script"
    fi
done
echo ""
echo "🔧 Next Steps:"
echo "   1. Review remaining scripts if needed"
echo "   2. Test system functionality: ./monitor.sh"
echo "   3. Remove backup if no issues: rm -rf $BACKUP_DIR"
echo ""
echo "✅ Script cleanup completed!"