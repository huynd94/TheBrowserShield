#!/bin/bash
# Oracle Linux 9 Specialized Uninstaller - Fixed Version
# Handles htop and package availability issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
APP_NAME="browsershield"
APP_USER="opc"
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"
BACKUP_DIR="/tmp/browsershield_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/oracle-uninstall-$(date +%Y%m%d_%H%M%S).log"

# Parse command line arguments
DRY_RUN=false
FORCE_DELETE=false
VERBOSE=false
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_DELETE=true
            INTERACTIVE=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --help)
            echo "Oracle Linux 9 BrowserShield Uninstaller"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run         Preview actions without executing"
            echo "  --force           Skip confirmation prompts"
            echo "  --verbose         Enable detailed logging"
            echo "  --non-interactive Disable interactive prompts"
            echo "  --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --dry-run      # Preview what would be removed"
            echo "  $0 --force        # Remove without confirmation"
            echo "  $0               # Interactive removal"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

warn() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo -e "${YELLOW}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

info() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1"
    echo -e "${BLUE}$message${NC}"
    if [ "$VERBOSE" = true ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Check if running as correct user
check_user() {
    if [ "$USER" != "opc" ] && [ "$USER" != "root" ]; then
        error "Please run this script as opc user or root"
        exit 1
    fi
}

# Detect Oracle Linux version
detect_system() {
    if [ -f /etc/oracle-release ]; then
        local version=$(grep -o 'release [0-9]*' /etc/oracle-release | cut -d' ' -f2)
        info "Detected Oracle Linux version: $version"
        if [ "$version" != "9" ]; then
            warn "This script is optimized for Oracle Linux 9, detected version $version"
        fi
    else
        warn "Oracle Linux release file not found, proceeding anyway"
    fi
}

# Execute command with dry-run support
execute_cmd() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY-RUN] Would execute: $description${NC}"
        echo -e "${CYAN}[DRY-RUN] Command: $cmd${NC}"
        return 0
    fi
    
    info "$description"
    if [ "$VERBOSE" = true ]; then
        echo "Executing: $cmd"
    fi
    
    eval "$cmd"
}

# Stop and remove systemd service
remove_service() {
    log "Removing BrowserShield service..."
    
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        execute_cmd "systemctl stop $SERVICE_NAME" "Stopping $SERVICE_NAME service"
    else
        info "Service $SERVICE_NAME is not running"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        execute_cmd "systemctl disable $SERVICE_NAME" "Disabling $SERVICE_NAME service"
    else
        info "Service $SERVICE_NAME is not enabled"
    fi
    
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        execute_cmd "rm -f /etc/systemd/system/$SERVICE_NAME.service" "Removing service file"
        execute_cmd "systemctl daemon-reload" "Reloading systemd"
    else
        info "Service file not found"
    fi
}

# Remove installed packages (with Oracle Linux 9 compatibility)
remove_packages() {
    log "Removing installed packages..."
    
    # List of packages to remove (skip htop if not installed)
    local packages_to_check=(
        "google-chrome-stable"
        "chromium"
        "nodejs"
        "npm"
        "htop"
    )
    
    local packages_to_remove=()
    
    for package in "${packages_to_check[@]}"; do
        if dnf list installed "$package" >/dev/null 2>&1; then
            packages_to_remove+=("$package")
            info "Package $package is installed and will be removed"
        else
            info "Package $package is not installed, skipping"
        fi
    done
    
    if [ ${#packages_to_remove[@]} -gt 0 ]; then
        if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
            echo -e "${YELLOW}The following packages will be removed:${NC}"
            printf '%s\n' "${packages_to_remove[@]}"
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                warn "Package removal cancelled by user"
                return 0
            fi
        fi
        
        execute_cmd "dnf remove -y ${packages_to_remove[*]}" "Removing packages: ${packages_to_remove[*]}"
    else
        info "No packages to remove"
    fi
}

# Remove application files
remove_files() {
    log "Removing application files..."
    
    local directories_to_remove=(
        "$APP_DIR"
        "/home/opc/.config/browsershield"
        "/home/opc/.local/share/browsershield"
        "/home/opc/.cache/browsershield"
        "/var/lib/browsershield"
        "/etc/browsershield"
    )
    
    for dir in "${directories_to_remove[@]}"; do
        if [ -d "$dir" ]; then
            execute_cmd "rm -rf '$dir'" "Removing directory: $dir"
        else
            info "Directory not found: $dir"
        fi
    done
    
    # Remove temporary files
    execute_cmd "rm -f /tmp/*browsershield*" "Removing temporary files"
}

# Remove log files
remove_logs() {
    log "Removing log files..."
    
    local log_locations=(
        "/var/log/browsershield*"
        "/var/log/*browsershield*"
        "/etc/logrotate.d/browsershield"
    )
    
    for pattern in "${log_locations[@]}"; do
        if ls $pattern 1> /dev/null 2>&1; then
            execute_cmd "rm -f $pattern" "Removing logs: $pattern"
        else
            info "No logs found: $pattern"
        fi
    done
}

# Clean up repositories
clean_repositories() {
    log "Cleaning up repositories..."
    
    if [ -f "/etc/yum.repos.d/google-chrome.repo" ]; then
        execute_cmd "rm -f /etc/yum.repos.d/google-chrome.repo" "Removing Google Chrome repository"
    fi
    
    if [ -f "/etc/yum.repos.d/nodesource-el9.repo" ]; then
        execute_cmd "rm -f /etc/yum.repos.d/nodesource-el9.repo" "Removing Node.js repository"
    fi
    
    execute_cmd "dnf clean all" "Cleaning package cache"
}

# Close firewall ports
close_firewall() {
    log "Closing firewall ports..."
    
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        if firewall-cmd --list-ports | grep -q "5000/tcp"; then
            execute_cmd "firewall-cmd --permanent --remove-port=5000/tcp" "Removing port 5000 from firewall"
            execute_cmd "firewall-cmd --reload" "Reloading firewall"
        else
            info "Port 5000 not found in firewall rules"
        fi
    else
        info "Firewalld is not running"
    fi
}

# Create backup before uninstall
create_backup() {
    if [ "$DRY_RUN" = true ]; then
        info "Would create backup at: $BACKUP_DIR"
        return 0
    fi
    
    log "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup application files
    if [ -d "$APP_DIR" ]; then
        cp -r "$APP_DIR" "$BACKUP_DIR/app_files" 2>/dev/null || true
    fi
    
    # Backup service file
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        cp "/etc/systemd/system/$SERVICE_NAME.service" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Create backup info
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup created: $(date)
Original application directory: $APP_DIR
Service name: $SERVICE_NAME
System: $(cat /etc/oracle-release 2>/dev/null || echo 'Unknown')
EOF
    
    log "Backup created at: $BACKUP_DIR"
}

# Validate uninstall
validate_uninstall() {
    log "Validating uninstall..."
    
    local issues=()
    
    # Check service
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        issues+=("Service $SERVICE_NAME is still running")
    fi
    
    # Check files
    if [ -d "$APP_DIR" ]; then
        issues+=("Application directory still exists: $APP_DIR")
    fi
    
    # Check service file
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        issues+=("Service file still exists")
    fi
    
    if [ ${#issues[@]} -eq 0 ]; then
        log "Uninstall validation passed - all components removed"
    else
        warn "Uninstall validation found issues:"
        printf '%s\n' "${issues[@]}"
    fi
}

# Main uninstall process
main() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  Oracle Linux 9 Uninstaller${NC}"
    echo -e "${CYAN}  BrowserShield Removal Tool${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    
    # Pre-flight checks
    check_user
    detect_system
    
    # Create log file
    touch "$LOG_FILE"
    log "Starting uninstall process..."
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}DRY-RUN MODE: No actual changes will be made${NC}"
        echo
    fi
    
    # Show what will be removed
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo -e "${YELLOW}This will remove:${NC}"
        echo "  - BrowserShield service and application files"
        echo "  - Installed packages (Chrome, Node.js, etc.)"
        echo "  - Configuration and log files"
        echo "  - Firewall rules"
        echo "  - Repository configurations"
        echo
        
        if [ "$FORCE_DELETE" = false ]; then
            read -p "Continue with uninstall? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "Uninstall cancelled by user"
                exit 0
            fi
        fi
    fi
    
    # Create backup
    create_backup
    
    # Uninstall steps
    if [ "$USER" = "root" ]; then
        remove_service
        remove_packages
        clean_repositories
        close_firewall
    fi
    
    remove_files
    remove_logs
    
    # Validation
    validate_uninstall
    
    # Final message
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Uninstall Complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "Log file: ${CYAN}$LOG_FILE${NC}"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "Backup location: ${CYAN}$BACKUP_DIR${NC}"
    fi
    
    log "Oracle Linux 9 uninstall completed successfully"
}

# Execute main function
main "$@"