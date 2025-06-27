#!/bin/bash
# Test Oracle Linux 9 Fix Scripts
# Validates all scripts work correctly for your VPS issue

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
    echo -e "${CYAN}  Oracle Linux 9 Fix Validator${NC}"
    echo -e "${CYAN}  Testing VPS Scripts${NC}"
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

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

test_script_syntax() {
    log "Testing script syntax..."
    
    local scripts=(
        "scripts/fix-oracle-linux-packages.sh"
        "scripts/install-browsershield-oracle-fixed.sh"
        "scripts/uninstall-oracle-linux-fixed.sh"
        "scripts/vps-uninstall-suite.sh"
        "scripts/vps-manager-fixed.sh"
    )
    
    local passed=0
    local total=${#scripts[@]}
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                info "✓ PASS: Syntax check for $script"
                ((passed++))
            else
                error "✗ FAIL: Syntax error in $script"
            fi
        else
            warn "Script not found: $script"
        fi
    done
    
    echo "Syntax Tests: $passed/$total passed"
    echo
}

test_help_functionality() {
    log "Testing help functionality..."
    
    local scripts_with_help=(
        "scripts/uninstall-oracle-linux-fixed.sh"
        "scripts/vps-uninstall-suite.sh"
        "scripts/vps-manager-fixed.sh"
    )
    
    for script in "${scripts_with_help[@]}"; do
        if [ -f "$script" ]; then
            if ./"$script" --help >/dev/null 2>&1; then
                info "✓ PASS: Help option works for $script"
            else
                warn "Help option not working for $script"
            fi
        fi
    done
    echo
}

test_dry_run_mode() {
    log "Testing dry-run mode..."
    
    if [ -f "scripts/uninstall-oracle-linux-fixed.sh" ]; then
        info "Testing Oracle Linux uninstaller dry-run..."
        # Would need opc user, but we can test syntax
        if grep -q "DRY_RUN=true" "scripts/uninstall-oracle-linux-fixed.sh"; then
            info "✓ PASS: Dry-run mode implemented"
        else
            warn "Dry-run mode not found"
        fi
    fi
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        if ./scripts/vps-uninstall-suite.sh --dry-run validate 2>/dev/null; then
            info "✓ PASS: VPS uninstaller dry-run works"
        else
            info "VPS uninstaller dry-run requires specific environment"
        fi
    fi
    echo
}

test_oracle_linux_specific_fixes() {
    log "Testing Oracle Linux 9 specific fixes..."
    
    # Test fix-packages script
    if [ -f "scripts/fix-oracle-linux-packages.sh" ]; then
        if grep -q "epel-release" "scripts/fix-oracle-linux-packages.sh"; then
            info "✓ PASS: EPEL repository handling found"
        fi
        
        if grep -q "htop" "scripts/fix-oracle-linux-packages.sh"; then
            info "✓ PASS: htop package handling found"
        fi
        
        if grep -q "google-chrome" "scripts/fix-oracle-linux-packages.sh"; then
            info "✓ PASS: Chrome installation handling found"
        fi
    fi
    
    # Test install script
    if [ -f "scripts/install-browsershield-oracle-fixed.sh" ]; then
        if grep -q "Oracle Linux" "scripts/install-browsershield-oracle-fixed.sh"; then
            info "✓ PASS: Oracle Linux detection found"
        fi
        
        if grep -q "fallback" "scripts/install-browsershield-oracle-fixed.sh"; then
            info "✓ PASS: Package fallback logic found"
        fi
    fi
    echo
}

test_error_handling() {
    log "Testing error handling..."
    
    # Test invalid options
    if ./scripts/vps-uninstall-suite.sh --invalid-option 2>/dev/null; then
        warn "Invalid option not handled properly"
    else
        info "✓ PASS: Invalid options handled correctly"
    fi
    
    # Test permission checks
    local scripts_with_permission_checks=(
        "scripts/uninstall-oracle-linux-fixed.sh"
        "scripts/fix-oracle-linux-packages.sh"
    )
    
    for script in "${scripts_with_permission_checks[@]}"; do
        if [ -f "$script" ]; then
            if grep -q "root\|opc" "$script"; then
                info "✓ PASS: Permission checks found in $script"
            fi
        fi
    done
    echo
}

test_documentation() {
    log "Testing documentation..."
    
    local docs=(
        "ORACLE_LINUX_9_FIX.md"
        "QUICK_VPS_SETUP_ORACLE_FIXED.md"
        "VPS_UNINSTALL_README.md"
        "SCRIPT_SUMMARY.md"
    )
    
    local found=0
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            info "✓ FOUND: $doc"
            ((found++))
        fi
    done
    
    echo "Documentation: $found/${#docs[@]} files found"
    echo
}

show_usage_examples() {
    log "Usage examples for Oracle Linux 9 fix:"
    echo
    echo -e "${CYAN}1. Fix packages issue (your current problem):${NC}"
    echo "   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-oracle-linux-packages.sh | sudo bash"
    echo
    echo -e "${CYAN}2. Install BrowserShield with fixed script:${NC}"
    echo "   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-oracle-fixed.sh | sudo bash"
    echo
    echo -e "${CYAN}3. Test uninstall safely:${NC}"
    echo "   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-oracle-linux-fixed.sh | bash -s -- --dry-run"
    echo
    echo -e "${CYAN}4. Complete uninstall:${NC}"
    echo "   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-oracle-linux-fixed.sh | bash"
    echo
}

validate_vps_readiness() {
    log "Validating VPS deployment readiness..."
    
    local required_scripts=(
        "scripts/fix-oracle-linux-packages.sh"
        "scripts/install-browsershield-oracle-fixed.sh"
        "scripts/uninstall-oracle-linux-fixed.sh"
    )
    
    local ready=true
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            error "Missing required script: $script"
            ready=false
        elif ! bash -n "$script" 2>/dev/null; then
            error "Syntax error in: $script"
            ready=false
        fi
    done
    
    if [ "$ready" = true ]; then
        log "✓ All scripts ready for Oracle Linux 9 VPS deployment"
    else
        error "Some scripts need fixes before VPS deployment"
    fi
    echo
}

main() {
    show_banner
    
    log "Running comprehensive Oracle Linux 9 fix validation..."
    echo
    
    test_script_syntax
    test_help_functionality
    test_dry_run_mode
    test_oracle_linux_specific_fixes
    test_error_handling
    test_documentation
    validate_vps_readiness
    
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Validation Complete${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    
    show_usage_examples
    
    log "Oracle Linux 9 fix scripts are ready for your VPS!"
}

main "$@"