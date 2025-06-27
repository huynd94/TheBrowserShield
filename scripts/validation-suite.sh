#!/bin/bash
# Validation Suite for VPS Uninstallation Scripts
# Tests all scripts for syntax, functionality, and safety

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

test_passed() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "  ✓ ${GREEN}PASS${NC}: $1"
}

test_failed() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "  ✗ ${RED}FAIL${NC}: $1"
}

show_banner() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  VPS Uninstall Validation Suite${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Test script syntax
test_syntax() {
    log "Testing script syntax..."
    
    local scripts=(
        "scripts/vps-uninstall-suite.sh"
        "scripts/uninstall-browsershield-vps.sh"
        "scripts/vps-manager-fixed.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_passed "Syntax check: $script"
            else
                test_failed "Syntax check: $script"
            fi
        else
            test_failed "Script not found: $script"
        fi
    done
}

# Test help functionality
test_help_options() {
    log "Testing help options..."
    
    # Test vps-uninstall-suite.sh help
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        chmod +x scripts/vps-uninstall-suite.sh
        if ./scripts/vps-uninstall-suite.sh --help >/dev/null 2>&1; then
            test_passed "Help option: vps-uninstall-suite.sh"
        else
            test_failed "Help option: vps-uninstall-suite.sh"
        fi
    fi
    
    # Test uninstall-browsershield-vps.sh help
    if [ -f "scripts/uninstall-browsershield-vps.sh" ]; then
        chmod +x scripts/uninstall-browsershield-vps.sh
        if ./scripts/uninstall-browsershield-vps.sh --help >/dev/null 2>&1; then
            test_passed "Help option: uninstall-browsershield-vps.sh"
        else
            test_failed "Help option: uninstall-browsershield-vps.sh"
        fi
    fi
}

# Test dry-run functionality
test_dry_run() {
    log "Testing dry-run functionality..."
    
    # Test vps-uninstall-suite.sh dry-run
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        if ./scripts/vps-uninstall-suite.sh --dry-run validate >/dev/null 2>&1; then
            test_passed "Dry-run mode: vps-uninstall-suite.sh"
        else
            test_failed "Dry-run mode: vps-uninstall-suite.sh"
        fi
    fi
    
    # Test uninstall-browsershield-vps.sh dry-run
    if [ -f "scripts/uninstall-browsershield-vps.sh" ]; then
        if ./scripts/uninstall-browsershield-vps.sh --dry-run >/dev/null 2>&1; then
            test_passed "Dry-run mode: uninstall-browsershield-vps.sh"
        else
            test_failed "Dry-run mode: uninstall-browsershield-vps.sh"
        fi
    fi
}

# Test error handling
test_error_handling() {
    log "Testing error handling..."
    
    # Test invalid options
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        if ! ./scripts/vps-uninstall-suite.sh --invalid-option >/dev/null 2>&1; then
            test_passed "Error handling: invalid option"
        else
            test_failed "Error handling: invalid option"
        fi
    fi
    
    # Test invalid commands
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        if ! ./scripts/vps-uninstall-suite.sh invalid-command >/dev/null 2>&1; then
            test_passed "Error handling: invalid command"
        else
            test_failed "Error handling: invalid command"
        fi
    fi
}

# Test required components
test_components() {
    log "Testing script components..."
    
    local required_functions=(
        "show_help"
        "validate_system"
        "create_backup"
        "clean_services"
        "clean_packages"
        "clean_files"
        "clean_logs"
    )
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        for func in "${required_functions[@]}"; do
            if grep -q "^$func()" scripts/vps-uninstall-suite.sh; then
                test_passed "Function exists: $func"
            else
                test_failed "Function missing: $func"
            fi
        done
    fi
    
    # Test for safety features
    local safety_features=(
        "--dry-run"
        "--force"
        "DRY_RUN"
        "FORCE_DELETE"
        "INTERACTIVE"
    )
    
    for feature in "${safety_features[@]}"; do
        if grep -q "$feature" scripts/vps-uninstall-suite.sh 2>/dev/null; then
            test_passed "Safety feature: $feature"
        else
            test_failed "Safety feature missing: $feature"
        fi
    done
}

# Test logging functionality
test_logging() {
    log "Testing logging functionality..."
    
    # Test if scripts create log files
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        if grep -q "LOG_FILE" scripts/vps-uninstall-suite.sh; then
            test_passed "Logging capability: LOG_FILE variable"
        else
            test_failed "Logging capability: LOG_FILE variable"
        fi
        
        if grep -q "log()" scripts/vps-uninstall-suite.sh; then
            test_passed "Logging capability: log function"
        else
            test_failed "Logging capability: log function"
        fi
    fi
}

# Test backup functionality
test_backup() {
    log "Testing backup functionality..."
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        # Test backup command exists
        if ./scripts/vps-uninstall-suite.sh --dry-run backup >/dev/null 2>&1; then
            test_passed "Backup command functionality"
        else
            test_failed "Backup command functionality"
        fi
        
        # Test backup creates appropriate structure
        if grep -q "tar -czf" scripts/vps-uninstall-suite.sh; then
            test_passed "Backup compression capability"
        else
            test_failed "Backup compression capability"
        fi
    fi
}

# Test validation functionality
test_validation() {
    log "Testing validation functionality..."
    
    if [ -f "scripts/vps-uninstall-suite.sh" ]; then
        # Test validation command
        if ./scripts/vps-uninstall-suite.sh validate >/dev/null 2>&1; then
            test_passed "System validation command"
        else
            test_failed "System validation command"
        fi
        
        # Test OS detection
        if grep -q "Oracle Linux" scripts/vps-uninstall-suite.sh; then
            test_passed "Oracle Linux detection"
        else
            test_failed "Oracle Linux detection"
        fi
    fi
}

# Test VPS Manager functionality
test_vps_manager() {
    log "Testing VPS Manager functionality..."
    
    if [ -f "scripts/vps-manager-fixed.sh" ]; then
        chmod +x scripts/vps-manager-fixed.sh
        
        # Test menu display
        if ./scripts/vps-manager-fixed.sh >/dev/null 2>&1; then
            test_passed "VPS Manager menu display"
        else
            test_failed "VPS Manager menu display"
        fi
        
        # Test help command
        if ./scripts/vps-manager-fixed.sh help >/dev/null 2>&1; then
            test_passed "VPS Manager help command"
        else
            test_failed "VPS Manager help command"
        fi
    fi
}

# Generate test report
generate_report() {
    echo
    log "Test Suite Results"
    echo "================================"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "Overall Status: ${GREEN}ALL TESTS PASSED${NC}"
        echo
        log "All validation tests completed successfully!"
        log "Scripts are ready for production use."
    else
        echo -e "Overall Status: ${RED}SOME TESTS FAILED${NC}"
        echo
        warn "Some validation tests failed. Please review and fix issues."
        return 1
    fi
    
    echo
    echo "Available Scripts:"
    echo "  - scripts/vps-uninstall-suite.sh (Complete uninstall suite)"
    echo "  - scripts/uninstall-browsershield-vps.sh (BrowserShield specific)"
    echo "  - scripts/vps-manager-fixed.sh (VPS management tool)"
    echo
    echo "Usage Examples:"
    echo "  ./scripts/vps-uninstall-suite.sh --dry-run uninstall"
    echo "  ./scripts/vps-uninstall-suite.sh --force clean-services"
    echo "  ./scripts/vps-manager-fixed.sh deploy"
}

# Main execution
main() {
    show_banner
    
    # Run all tests
    test_syntax
    test_help_options
    test_dry_run
    test_error_handling
    test_components
    test_logging
    test_backup
    test_validation
    test_vps_manager
    
    # Generate final report
    generate_report
}

# Execute main function
main "$@"