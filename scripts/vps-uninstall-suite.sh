#!/bin/bash
# VPS Uninstallation Suite for Oracle Linux 9
# Comprehensive system cleanup and management tool

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_NAME="VPS Uninstall Suite"
VERSION="1.0.0"
LOG_FILE="/tmp/vps-uninstall-$(date +%Y%m%d_%H%M%S).log"

# Global flags
DRY_RUN=false
FORCE_DELETE=false
VERBOSE=false
INTERACTIVE=true

# Logging functions
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$timestamp] $message${NC}"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp] ERROR: $message${NC}" >&2
    echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
}

warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] WARNING: $message${NC}"
    echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
}

info() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${BLUE}[$timestamp] INFO: $message${NC}"
        echo "[$timestamp] INFO: $message" >> "$LOG_FILE"
    fi
}

show_banner() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}   $SCRIPT_NAME v$VERSION${NC}"
    echo -e "${CYAN}   Oracle Linux 9 Edition${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

show_help() {
    show_banner
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo
    echo "OPTIONS:"
    echo "  --dry-run         Preview actions without executing"
    echo "  --force           Skip confirmation prompts"
    echo "  --verbose         Enable verbose logging"
    echo "  --non-interactive Disable interactive prompts"
    echo "  --help           Show this help message"
    echo
    echo "COMMANDS:"
    echo "  uninstall        Complete system uninstallation"
    echo "  clean-services   Remove systemd services only"
    echo "  clean-packages   Remove installed packages only"
    echo "  clean-files      Remove application files only"
    echo "  clean-logs       Remove log files only"
    echo "  validate         Validate system state"
    echo "  backup           Create backup before cleanup"
    echo
    echo "EXAMPLES:"
    echo "  $0 --dry-run uninstall      # Preview uninstallation"
    echo "  $0 --force clean-services   # Force remove services"
    echo "  $0 backup                   # Create system backup"
    echo
}

# System validation
validate_system() {
    log "Validating system environment..."
    
    # Check OS
    if ! grep -q "Oracle Linux" /etc/os-release 2>/dev/null; then
        warn "Not running on Oracle Linux - some operations may fail"
    fi
    
    # Check user
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root - consider using sudo with regular user"
    fi
    
    # Check required commands (with fallbacks for different environments)
    local critical_commands=("tar" "find")
    local optional_commands=("systemctl" "dnf")
    
    for cmd in "${critical_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Critical command not found: $cmd"
            return 1
        fi
    done
    
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            warn "Optional command not found: $cmd (some features may be limited)"
        fi
    done
    
    log "System validation completed"
    return 0
}

# Create system backup
create_backup() {
    log "Creating system backup..."
    
    local backup_dir="/tmp/vps-backup-$(date +%Y%m%d_%H%M%S)"
    local backup_items=(
        "/etc/systemd/system/*.service"
        "/home/*/browsershield"
        "/var/log/*.log"
        "/etc/logrotate.d/*"
    )
    
    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN - Would create backup at: $backup_dir"
        for item in "${backup_items[@]}"; do
            if ls $item 1> /dev/null 2>&1; then
                info "Would backup: $item"
            fi
        done
        return 0
    fi
    
    mkdir -p "$backup_dir"
    
    for item in "${backup_items[@]}"; do
        if ls $item 1> /dev/null 2>&1; then
            cp -r $item "$backup_dir/" 2>/dev/null || warn "Failed to backup: $item"
            info "Backed up: $item"
        fi
    done
    
    tar -czf "${backup_dir}.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    log "Backup created: ${backup_dir}.tar.gz"
}

# Clean systemd services
clean_services() {
    log "Cleaning systemd services..."
    
    local services=(
        "browsershield"
        "browsershield.service"
    )
    
    # Check if systemctl is available
    if ! command -v systemctl &> /dev/null; then
        warn "systemctl not available - skipping service management"
        return 0
    fi
    
    for service in "${services[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if systemctl is-enabled "$service" &>/dev/null; then
                info "DRY RUN - Would stop and disable service: $service"
            fi
            if [ -f "/etc/systemd/system/$service" ] || [ -f "/etc/systemd/system/${service}.service" ]; then
                info "DRY RUN - Would remove service file: $service"
            fi
        else
            # Stop and disable service
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                sudo systemctl stop "$service" 2>/dev/null || warn "Failed to stop service: $service"
                log "Stopped service: $service"
            fi
            
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                sudo systemctl disable "$service" 2>/dev/null || warn "Failed to disable service: $service"
                log "Disabled service: $service"
            fi
            
            # Remove service files
            for service_file in "/etc/systemd/system/$service" "/etc/systemd/system/${service}.service"; do
                if [ -f "$service_file" ]; then
                    sudo rm -f "$service_file" 2>/dev/null || warn "Failed to remove: $service_file"
                    log "Removed service file: $service_file"
                fi
            done
        fi
    done
    
    if [ "$DRY_RUN" = false ] && command -v systemctl &> /dev/null; then
        sudo systemctl daemon-reload 2>/dev/null || warn "Failed to reload systemd daemon"
        log "Reloaded systemd daemon"
    fi
}

# Clean installed packages
clean_packages() {
    log "Cleaning installed packages..."
    
    local packages=(
        "nodejs"
        "npm"
        "google-chrome-stable"
        "chromium"
    )
    
    # Check if package manager is available
    local pkg_manager=""
    if command -v dnf &> /dev/null; then
        pkg_manager="dnf"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
    elif command -v apt &> /dev/null; then
        pkg_manager="apt"
    else
        warn "No supported package manager found - skipping package removal"
        return 0
    fi
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        warn "This will remove the following packages:"
        for pkg in "${packages[@]}"; do
            case $pkg_manager in
                dnf|yum)
                    if $pkg_manager list installed "$pkg" &>/dev/null; then
                        echo "  - $pkg"
                    fi
                    ;;
                apt)
                    if dpkg -l | grep -q "^ii.*$pkg"; then
                        echo "  - $pkg"
                    fi
                    ;;
            esac
        done
        echo
        read -p "Continue? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            warn "Package removal cancelled"
            return 0
        fi
    fi
    
    for pkg in "${packages[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            case $pkg_manager in
                dnf|yum)
                    if $pkg_manager list installed "$pkg" &>/dev/null; then
                        info "DRY RUN - Would remove package: $pkg"
                    fi
                    ;;
                apt)
                    if dpkg -l | grep -q "^ii.*$pkg"; then
                        info "DRY RUN - Would remove package: $pkg"
                    fi
                    ;;
            esac
        else
            case $pkg_manager in
                dnf|yum)
                    if $pkg_manager list installed "$pkg" &>/dev/null; then
                        sudo $pkg_manager remove -y "$pkg" 2>/dev/null || warn "Failed to remove package: $pkg"
                        log "Removed package: $pkg"
                    fi
                    ;;
                apt)
                    if dpkg -l | grep -q "^ii.*$pkg"; then
                        sudo apt remove -y "$pkg" 2>/dev/null || warn "Failed to remove package: $pkg"
                        log "Removed package: $pkg"
                    fi
                    ;;
            esac
        fi
    done
    
    # Clean package cache
    if [ "$DRY_RUN" = false ]; then
        case $pkg_manager in
            dnf|yum)
                sudo $pkg_manager clean all 2>/dev/null || true
                ;;
            apt)
                sudo apt autoremove -y 2>/dev/null || true
                sudo apt autoclean 2>/dev/null || true
                ;;
        esac
        log "Cleaned package cache"
    fi
}

# Clean application files
clean_files() {
    log "Cleaning application files..."
    
    local file_patterns=(
        "/home/*/browsershield"
        "/opt/browsershield"
        "/var/lib/browsershield"
        "/etc/browsershield"
        "/tmp/browsershield*"
        "/tmp/TheBrowserShield*"
    )
    
    for pattern in "${file_patterns[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if ls $pattern 1> /dev/null 2>&1; then
                info "DRY RUN - Would remove: $pattern"
            fi
        else
            if ls $pattern 1> /dev/null 2>&1; then
                sudo rm -rf $pattern
                log "Removed files: $pattern"
            fi
        fi
    done
    
    # Clean user home directories
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            local user=$(basename "$user_home")
            local app_dirs=(
                "$user_home/.config/browsershield"
                "$user_home/.local/share/browsershield"
                "$user_home/.cache/browsershield"
            )
            
            for dir in "${app_dirs[@]}"; do
                if [ "$DRY_RUN" = true ]; then
                    if [ -d "$dir" ]; then
                        info "DRY RUN - Would remove user directory: $dir"
                    fi
                else
                    if [ -d "$dir" ]; then
                        sudo rm -rf "$dir"
                        log "Removed user directory: $dir"
                    fi
                fi
            done
        fi
    done
}

# Clean log files
clean_logs() {
    log "Cleaning log files..."
    
    local log_patterns=(
        "/var/log/browsershield*"
        "/var/log/*browsershield*"
        "/home/*/browsershield*.log"
        "/tmp/*browsershield*.log"
    )
    
    # Clean logrotate configuration
    local logrotate_configs=(
        "/etc/logrotate.d/browsershield"
    )
    
    for config in "${logrotate_configs[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if [ -f "$config" ]; then
                info "DRY RUN - Would remove logrotate config: $config"
            fi
        else
            if [ -f "$config" ]; then
                sudo rm -f "$config"
                log "Removed logrotate config: $config"
            fi
        fi
    done
    
    # Clean log files
    for pattern in "${log_patterns[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            if ls $pattern 1> /dev/null 2>&1; then
                info "DRY RUN - Would remove logs: $pattern"
            fi
        else
            if ls $pattern 1> /dev/null 2>&1; then
                sudo rm -f $pattern
                log "Removed logs: $pattern"
            fi
        fi
    done
    
    # Clean systemd journal
    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN - Would clean systemd journal for browsershield"
    else
        if command -v journalctl &> /dev/null; then
            sudo journalctl --vacuum-time=1s --identifier=browsershield 2>/dev/null || true
            log "Cleaned systemd journal"
        else
            warn "journalctl not available - skipping journal cleanup"
        fi
    fi
}

# Complete uninstallation
complete_uninstall() {
    log "Starting complete system uninstallation..."
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        warn "This will completely remove all traces of the application from your system."
        warn "This action cannot be undone without a backup."
        echo
        read -p "Are you absolutely sure? (yes/no): " confirm
        if [[ ! $confirm =~ ^[Yy][Ee][Ss]$ ]]; then
            warn "Uninstallation cancelled"
            return 0
        fi
    fi
    
    # Execute cleanup steps
    clean_services
    clean_files
    clean_logs
    clean_packages
    
    log "Complete uninstallation finished"
}

# Parse command line arguments
parse_arguments() {
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
            --help|-h)
                show_help
                exit 0
                ;;
            uninstall)
                COMMAND="uninstall"
                shift
                ;;
            clean-services)
                COMMAND="clean-services"
                shift
                ;;
            clean-packages)
                COMMAND="clean-packages"
                shift
                ;;
            clean-files)
                COMMAND="clean-files"
                shift
                ;;
            clean-logs)
                COMMAND="clean-logs"
                shift
                ;;
            validate)
                COMMAND="validate"
                shift
                ;;
            backup)
                COMMAND="backup"
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    show_banner
    
    # Default command if none specified
    if [ -z "${COMMAND:-}" ]; then
        COMMAND="uninstall"
    fi
    
    # Initialize logging
    log "Starting $SCRIPT_NAME v$VERSION"
    log "Command: $COMMAND"
    log "Options: DRY_RUN=$DRY_RUN, FORCE=$FORCE_DELETE, VERBOSE=$VERBOSE"
    
    # Validate system
    if ! validate_system; then
        error "System validation failed"
        exit 1
    fi
    
    # Execute command
    case $COMMAND in
        uninstall)
            complete_uninstall
            ;;
        clean-services)
            clean_services
            ;;
        clean-packages)
            clean_packages
            ;;
        clean-files)
            clean_files
            ;;
        clean-logs)
            clean_logs
            ;;
        validate)
            validate_system
            ;;
        backup)
            create_backup
            ;;
        *)
            error "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
    
    log "Operation completed successfully"
    log "Log file saved: $LOG_FILE"
    
    if [ "$DRY_RUN" = true ]; then
        echo
        warn "This was a dry run. No changes were made to your system."
        warn "Remove --dry-run flag to execute the actual operation."
    fi
}

# Parse arguments and execute
COMMAND=""
parse_arguments "$@"
main