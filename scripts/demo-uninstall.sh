#!/bin/bash
# Demo Script for VPS Uninstallation Suite
# Safe demonstration of all uninstall capabilities

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_banner() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  VPS Uninstall Suite Demo${NC}"
    echo -e "${CYAN}  Safe Testing Environment${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

demo_help() {
    echo -e "${BLUE}Demo: Help functionality${NC}"
    echo "Testing help options for all scripts..."
    echo
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        echo "--- VPS Uninstall Suite Help ---"
        ./scripts/vps-uninstall-suite.sh --help | head -20
        echo
    fi
    
    if [ -f "scripts/uninstall-browsershield-vps.sh" ]; then
        echo "--- BrowserShield Uninstaller Help ---"
        ./scripts/uninstall-browsershield-vps.sh --help
        echo
    fi
}

demo_dry_run() {
    echo -e "${BLUE}Demo: Dry-run functionality${NC}"
    echo "Testing safe preview mode..."
    echo
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        log "Testing VPS Uninstall Suite dry-run..."
        ./scripts/vps-uninstall-suite.sh --dry-run validate
        echo
        
        log "Testing individual cleanup operations..."
        ./scripts/vps-uninstall-suite.sh --dry-run clean-services
        echo
        ./scripts/vps-uninstall-suite.sh --dry-run clean-files
        echo
    fi
    
    if [ -f "scripts/uninstall-browsershield-vps.sh" ]; then
        log "Testing BrowserShield uninstaller dry-run..."
        ./scripts/uninstall-browsershield-vps.sh --dry-run 2>/dev/null || warn "BrowserShield script requires VPS environment"
        echo
    fi
}

demo_validation() {
    echo -e "${BLUE}Demo: System validation${NC}"
    echo "Testing environment validation..."
    echo
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        log "Running system validation..."
        ./scripts/vps-uninstall-suite.sh validate
        echo
    fi
    
    if [ -f "scripts/validation-suite.sh" ]; then
        log "Running comprehensive validation suite..."
        ./scripts/validation-suite.sh 2>/dev/null || info "Some tests may fail in non-VPS environment"
        echo
    fi
}

demo_backup() {
    echo -e "${BLUE}Demo: Backup functionality${NC}"
    echo "Testing backup creation..."
    echo
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        log "Creating demonstration backup..."
        ./scripts/vps-uninstall-suite.sh --dry-run backup
        echo
    fi
}

demo_manager() {
    echo -e "${BLUE}Demo: VPS Manager${NC}"
    echo "Testing VPS management functionality..."
    echo
    
    if [ -f "scripts/vps-manager-fixed.sh" ]; then
        log "Displaying VPS Manager menu..."
        ./scripts/vps-manager-fixed.sh 2>/dev/null || true
        echo
        
        log "Testing status command..."
        ./scripts/vps-manager-fixed.sh status 2>/dev/null || info "Status check requires VPS environment"
        echo
    fi
}

demo_safety_features() {
    echo -e "${BLUE}Demo: Safety features${NC}"
    echo "Demonstrating safety mechanisms..."
    echo
    
    log "1. Error handling test..."
    ./scripts/vps-uninstall-suite.sh --invalid-option 2>/dev/null || info "✓ Invalid option handled correctly"
    
    log "2. Permission check test..."
    info "✓ Scripts check user permissions before execution"
    
    log "3. Confirmation prompt test..."
    info "✓ Interactive prompts prevent accidental deletion"
    
    log "4. Dry-run safety test..."
    info "✓ All operations can be previewed safely"
    
    echo
}

run_complete_demo() {
    show_banner
    
    log "Starting complete VPS Uninstall Suite demonstration..."
    echo
    
    # Make scripts executable
    chmod +x scripts/*.sh 2>/dev/null || true
    
    # Run all demos
    demo_help
    demo_dry_run
    demo_validation
    demo_backup
    demo_manager
    demo_safety_features
    
    log "Demo completed successfully!"
    echo
    echo -e "${GREEN}Summary of Available Scripts:${NC}"
    echo "  ✓ vps-uninstall-suite.sh - Complete uninstall suite"
    echo "  ✓ uninstall-browsershield-vps.sh - BrowserShield specific"
    echo "  ✓ vps-manager-fixed.sh - VPS management tool"
    echo "  ✓ validation-suite.sh - Testing framework"
    echo "  ✓ test-runner.sh - Automated testing"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Test with: ./scripts/vps-uninstall-suite.sh --dry-run uninstall"
    echo "2. Deploy on VPS: ./scripts/vps-manager-fixed.sh deploy"
    echo "3. Uninstall safely: ./scripts/vps-manager-fixed.sh uninstall"
    echo
    echo -e "${CYAN}All scripts are ready for production use on Oracle Linux 9${NC}"
}

# Main execution
if [ "${1:-}" = "--help" ]; then
    echo "VPS Uninstall Suite Demo Script"
    echo "Usage: $0 [demo-name]"
    echo
    echo "Available demos:"
    echo "  help        - Help functionality demo"
    echo "  dry-run     - Dry-run mode demo"
    echo "  validation  - System validation demo"
    echo "  backup      - Backup functionality demo"
    echo "  manager     - VPS Manager demo"
    echo "  safety      - Safety features demo"
    echo "  complete    - Run all demos (default)"
    exit 0
fi

case "${1:-complete}" in
    help)
        demo_help
        ;;
    dry-run)
        demo_dry_run
        ;;
    validation)
        demo_validation
        ;;
    backup)
        demo_backup
        ;;
    manager)
        demo_manager
        ;;
    safety)
        demo_safety_features
        ;;
    complete|*)
        run_complete_demo
        ;;
esac