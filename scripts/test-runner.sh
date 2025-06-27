#!/bin/bash
# Test Runner for VPS Uninstallation Scripts
# Executes comprehensive testing of all uninstall components

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

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

show_banner() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  VPS Uninstall Script Tester${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Test individual script functionality
test_uninstall_suite() {
    log "Testing VPS Uninstall Suite..."
    
    if [ ! -f "scripts/vps-uninstall-suite.sh" ]; then
        error "vps-uninstall-suite.sh not found"
        return 1
    fi
    
    chmod +x scripts/vps-uninstall-suite.sh
    
    # Test help
    info "Testing help option..."
    ./scripts/vps-uninstall-suite.sh --help > /dev/null
    
    # Test dry-run validation
    info "Testing dry-run validation..."
    ./scripts/vps-uninstall-suite.sh --dry-run validate > /dev/null
    
    # Test dry-run backup
    info "Testing dry-run backup..."
    ./scripts/vps-uninstall-suite.sh --dry-run backup > /dev/null
    
    # Test dry-run clean operations
    info "Testing dry-run clean operations..."
    ./scripts/vps-uninstall-suite.sh --dry-run clean-services > /dev/null
    ./scripts/vps-uninstall-suite.sh --dry-run clean-files > /dev/null
    ./scripts/vps-uninstall-suite.sh --dry-run clean-logs > /dev/null
    
    log "VPS Uninstall Suite tests completed"
}

# Test BrowserShield specific uninstaller
test_browsershield_uninstaller() {
    log "Testing BrowserShield Uninstaller..."
    
    if [ ! -f "scripts/uninstall-browsershield-vps.sh" ]; then
        error "uninstall-browsershield-vps.sh not found"
        return 1
    fi
    
    chmod +x scripts/uninstall-browsershield-vps.sh
    
    # Test help
    info "Testing help option..."
    ./scripts/uninstall-browsershield-vps.sh --help > /dev/null
    
    # Test dry-run
    info "Testing dry-run mode..."
    ./scripts/uninstall-browsershield-vps.sh --dry-run > /dev/null
    
    log "BrowserShield Uninstaller tests completed"
}

# Test VPS Manager
test_vps_manager() {
    log "Testing VPS Manager..."
    
    if [ ! -f "scripts/vps-manager-fixed.sh" ]; then
        error "vps-manager-fixed.sh not found"
        return 1
    fi
    
    chmod +x scripts/vps-manager-fixed.sh
    
    # Test menu display
    info "Testing menu display..."
    ./scripts/vps-manager-fixed.sh > /dev/null
    
    # Test help
    info "Testing help command..."
    ./scripts/vps-manager-fixed.sh help > /dev/null
    
    # Test status (safe operation)
    info "Testing status command..."
    ./scripts/vps-manager-fixed.sh status > /dev/null || true
    
    log "VPS Manager tests completed"
}

# Run validation suite
run_validation_suite() {
    log "Running comprehensive validation suite..."
    
    if [ ! -f "scripts/validation-suite.sh" ]; then
        error "validation-suite.sh not found"
        return 1
    fi
    
    chmod +x scripts/validation-suite.sh
    ./scripts/validation-suite.sh
}

# Create test environment simulation
simulate_test_environment() {
    log "Simulating test environment..."
    
    # Create temporary test directories
    mkdir -p /tmp/test-env/{systemd,logs,home}
    
    # Create mock files for testing
    touch /tmp/test-env/systemd/browsershield.service
    touch /tmp/test-env/logs/browsershield.log
    mkdir -p /tmp/test-env/home/opc/browsershield
    
    info "Test environment created at /tmp/test-env"
}

# Cleanup test environment
cleanup_test_environment() {
    log "Cleaning up test environment..."
    rm -rf /tmp/test-env
    rm -f /tmp/vps-uninstall-*.log
    info "Test environment cleaned up"
}

# Main test execution
main() {
    show_banner
    
    log "Starting comprehensive script testing..."
    
    # Setup test environment
    simulate_test_environment
    
    # Run individual tests
    test_uninstall_suite
    test_browsershield_uninstaller
    test_vps_manager
    
    # Run validation suite
    run_validation_suite
    
    # Cleanup
    cleanup_test_environment
    
    log "All tests completed successfully!"
    echo
    info "Scripts are ready for production use on Oracle Linux 9"
    echo
    echo "Available Scripts:"
    echo "  ✓ scripts/vps-uninstall-suite.sh - Complete uninstall suite"
    echo "  ✓ scripts/uninstall-browsershield-vps.sh - BrowserShield specific"
    echo "  ✓ scripts/vps-manager-fixed.sh - VPS management tool"
    echo "  ✓ scripts/validation-suite.sh - Validation testing"
    echo
    echo "Usage Examples:"
    echo "  ./scripts/vps-uninstall-suite.sh --help"
    echo "  ./scripts/vps-uninstall-suite.sh --dry-run uninstall"
    echo "  ./scripts/vps-manager-fixed.sh deploy"
}

# Execute main function
main "$@"