#!/bin/bash
# BrowserShield Complete Uninstall Script for Oracle Linux 9 VPS
# Removes all components, data, and configurations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="browsershield"
APP_USER="opc"
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"
BACKUP_DIR="/home/opc/browsershield_backups"
PORT=5000

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as correct user
if [ "$USER" != "opc" ]; then
    error "Please run this script as opc user, not as root"
    exit 1
fi

# Parse command line arguments
DRY_RUN=false
FORCE_DELETE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_DELETE=true
            shift
            ;;
        --help)
            echo "BrowserShield Uninstall Script"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be deleted without actually deleting"
            echo "  --force      Skip confirmation prompts"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${RED}================================${NC}"
echo -e "${RED}  BrowserShield Uninstall Script${NC}"
echo -e "${RED}================================${NC}"
echo

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}"
    echo
fi

warn "This script will COMPLETELY REMOVE BrowserShield and all its data!"
warn "The following will be deleted:"
echo "  - Application files: $APP_DIR"
echo "  - System service: $SERVICE_NAME"
if [ -d "$BACKUP_DIR" ]; then
    echo "  - Backup files: $BACKUP_DIR"
fi
echo "  - Log files and configurations"
echo "  - Firewall rules"
echo "  - Cron jobs"
echo

# Show current installation status
if [ -d "$APP_DIR" ]; then
    echo -e "${BLUE}Current Installation Status:${NC}"
    echo "  ✓ Application directory exists"
    if sudo systemctl list-unit-files | grep -q $SERVICE_NAME; then
        echo "  ✓ System service exists"
    fi
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo "  ✓ Service is running"
    fi
    if crontab -l 2>/dev/null | grep -q "browsershield"; then
        echo "  ✓ Cron jobs exist"
    fi
    echo
fi

if [ "$FORCE_DELETE" != true ] && [ "$DRY_RUN" != true ]; then
    echo -e "${YELLOW}Safety options:${NC}"
    echo "  --dry-run    See what would be deleted (safe preview)"
    echo "  --force      Skip this confirmation"
    echo
    read -p "Are you sure you want to continue? Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        info "Uninstall cancelled by user"
        info "Use '--dry-run' to see what would be deleted safely"
        exit 0
    fi
elif [ "$DRY_RUN" = true ]; then
    info "DRY RUN - Showing what would be deleted..."
fi

if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would perform the following actions:"
else
    log "Starting BrowserShield complete uninstall process..."
fi

# Stop and disable service
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would stop BrowserShield service..."
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        info "Would stop running service"
    else
        info "Service is not running"
    fi
    
    if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
        info "Would disable service"
    else
        info "Service is not enabled"
    fi
else
    log "Stopping BrowserShield service..."
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        sudo systemctl stop $SERVICE_NAME
        log "Service stopped"
    else
        info "Service was not running"
    fi

    if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
        sudo systemctl disable $SERVICE_NAME
        log "Service disabled"
    else
        info "Service was not enabled"
    fi
fi

# Remove systemd service file
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove systemd service file..."
    if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        info "Would remove systemd service file"
    else
        info "Systemd service file not found"
    fi
else
    log "Removing systemd service file..."
    if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        sudo rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
        sudo systemctl daemon-reload
        log "Systemd service file removed"
    else
        info "Systemd service file not found"
    fi
fi

# Remove firewall rules
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove firewall rules..."
    if sudo firewall-cmd --list-ports | grep -q "${PORT}/tcp"; then
        info "Would remove firewall rule for port $PORT"
    else
        info "Firewall rule for port $PORT not found"
    fi
else
    log "Removing firewall rules..."
    if sudo firewall-cmd --list-ports | grep -q "${PORT}/tcp"; then
        sudo firewall-cmd --permanent --remove-port=${PORT}/tcp
        sudo firewall-cmd --reload
        log "Firewall rule for port $PORT removed"
    else
        info "Firewall rule for port $PORT not found"
    fi
fi

# Remove cron jobs
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove cron jobs..."
    if crontab -l 2>/dev/null | grep -q "monitor-browsershield\|backup-browsershield"; then
        info "Would remove BrowserShield cron jobs"
    else
        info "No BrowserShield cron jobs found"
    fi
else
    log "Removing cron jobs..."
    if crontab -l 2>/dev/null | grep -q "monitor-browsershield\|backup-browsershield"; then
        crontab -l 2>/dev/null | grep -v "monitor-browsershield\|backup-browsershield" | crontab -
        log "Cron jobs removed"
    else
        info "No BrowserShield cron jobs found"
    fi
fi

# Remove application directory
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove application directory..."
    if [ -d "$APP_DIR" ]; then
        info "Would remove application directory: $APP_DIR"
    else
        info "Application directory not found: $APP_DIR"
    fi
else
    log "Removing application directory..."
    if [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
        log "Application directory removed: $APP_DIR"
    else
        info "Application directory not found: $APP_DIR"
    fi
fi

# Remove backup directory
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would ask about backup directory..."
    if [ -d "$BACKUP_DIR" ]; then
        info "Would ask to remove backup directory: $BACKUP_DIR"
    else
        info "Backup directory not found: $BACKUP_DIR"
    fi
else
    log "Removing backup directory..."
    if [ -d "$BACKUP_DIR" ]; then
        if [ "$FORCE_DELETE" = true ]; then
            rm -rf "$BACKUP_DIR"
            log "Backup directory removed: $BACKUP_DIR"
        else
            read -p "Remove all backups in $BACKUP_DIR? (y/N): " REMOVE_BACKUPS
            if [[ $REMOVE_BACKUPS =~ ^[Yy]$ ]]; then
                rm -rf "$BACKUP_DIR"
                log "Backup directory removed: $BACKUP_DIR"
            else
                warn "Backup directory preserved: $BACKUP_DIR"
            fi
        fi
    else
        info "Backup directory not found: $BACKUP_DIR"
    fi
fi

# Remove management scripts
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove management scripts..."
    SCRIPTS_TO_REMOVE=(
        "/home/opc/monitor-browsershield.sh"
        "/home/opc/backup-browsershield.sh"
        "/home/opc/deploy-oracle-linux-production.sh"
        "/home/opc/vps-update-oracle.sh"
        "/home/opc/configure-production-vps.sh"
    )

    for script in "${SCRIPTS_TO_REMOVE[@]}"; do
        if [ -f "$script" ]; then
            info "Would remove script: $script"
        fi
    done
else
    log "Removing management scripts..."
    SCRIPTS_TO_REMOVE=(
        "/home/opc/monitor-browsershield.sh"
        "/home/opc/backup-browsershield.sh"
        "/home/opc/deploy-oracle-linux-production.sh"
        "/home/opc/vps-update-oracle.sh"
        "/home/opc/configure-production-vps.sh"
    )

    for script in "${SCRIPTS_TO_REMOVE[@]}"; do
        if [ -f "$script" ]; then
            rm -f "$script"
            log "Removed script: $script"
        fi
    done
fi

# Remove log rotation configuration
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove log rotation configuration..."
    if [ -f "/etc/logrotate.d/browsershield" ]; then
        info "Would remove log rotation configuration"
    else
        info "Log rotation configuration not found"
    fi
else
    log "Removing log rotation configuration..."
    if [ -f "/etc/logrotate.d/browsershield" ]; then
        sudo rm -f "/etc/logrotate.d/browsershield"
        log "Log rotation configuration removed"
    else
        info "Log rotation configuration not found"
    fi
fi

# Remove log files
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would remove log files..."
    LOG_FILES=(
        "/var/log/browsershield.log"
        "/var/log/browsershield-monitor.log"
        "/var/log/browsershield-backup.log"
    )

    for logfile in "${LOG_FILES[@]}"; do
        if [ -f "$logfile" ]; then
            info "Would remove log file: $logfile"
        fi
    done
else
    log "Removing log files..."
    LOG_FILES=(
        "/var/log/browsershield.log"
        "/var/log/browsershield-monitor.log"
        "/var/log/browsershield-backup.log"
    )

    for logfile in "${LOG_FILES[@]}"; do
        if [ -f "$logfile" ]; then
            sudo rm -f "$logfile"
            log "Removed log file: $logfile"
        fi
    done
fi

# Clean systemd journal logs for the service
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would clean systemd journal logs..."
    info "Would clean journal logs for service: $SERVICE_NAME"
else
    log "Cleaning systemd journal logs..."
    sudo journalctl --vacuum-time=1s --identifier=$SERVICE_NAME 2>/dev/null || true
fi

# Optional: Remove Node.js and Chrome (ask user)
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would ask about removing Node.js and Chrome..."
    if command -v node &> /dev/null; then
        info "Would ask to remove Node.js"
    fi
    if command -v google-chrome &> /dev/null; then
        info "Would ask to remove Google Chrome"
    fi
else
    echo
    if [ "$FORCE_DELETE" != true ]; then
        read -p "Remove Node.js? (y/N): " REMOVE_NODEJS
        if [[ $REMOVE_NODEJS =~ ^[Yy]$ ]]; then
            log "Removing Node.js..."
            sudo dnf remove -y nodejs npm
            log "Node.js removed"
        fi

        read -p "Remove Google Chrome? (y/N): " REMOVE_CHROME
        if [[ $REMOVE_CHROME =~ ^[Yy]$ ]]; then
            log "Removing Google Chrome..."
            sudo dnf remove -y google-chrome-stable
            if [ -f "/etc/yum.repos.d/google-chrome.repo" ]; then
                sudo rm -f "/etc/yum.repos.d/google-chrome.repo"
            fi
            log "Google Chrome removed"
        fi
    else
        info "Force mode: Skipping optional Node.js and Chrome removal"
    fi
fi

# Remove any remaining processes
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would check for remaining processes..."
    BROWSER_PROCESSES=$(ps aux | grep -E "(browsershield|chrome.*--user-data-dir.*browsershield)" | grep -v grep | wc -l)
    if [ "$BROWSER_PROCESSES" -gt 0 ]; then
        info "Would terminate $BROWSER_PROCESSES remaining processes"
    else
        info "No remaining processes found"
    fi
else
    log "Checking for remaining BrowserShield processes..."
    BROWSER_PROCESSES=$(ps aux | grep -E "(browsershield|chrome.*--user-data-dir.*browsershield)" | grep -v grep | wc -l)
    if [ "$BROWSER_PROCESSES" -gt 0 ]; then
        warn "Found $BROWSER_PROCESSES remaining processes, terminating..."
        pkill -f "browsershield" 2>/dev/null || true
        pkill -f "chrome.*--user-data-dir.*browsershield" 2>/dev/null || true
        sleep 2
        pkill -9 -f "browsershield" 2>/dev/null || true
        pkill -9 -f "chrome.*--user-data-dir.*browsershield" 2>/dev/null || true
        log "Remaining processes terminated"
    else
        info "No remaining processes found"
    fi
fi

# Clean up temporary files
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would clean up temporary files..."
    info "Would remove /tmp/browsershield* and /tmp/TheBrowserShield*"
else
    log "Cleaning up temporary files..."
    rm -rf /tmp/browsershield* 2>/dev/null || true
    rm -rf /tmp/TheBrowserShield* 2>/dev/null || true
fi

# Verify uninstall
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN - Would verify uninstall completion..."
    info "Would check if all components were removed successfully"
else
    log "Verifying uninstall..."
    VERIFICATION_PASSED=true

    if [ -d "$APP_DIR" ]; then
        error "Application directory still exists: $APP_DIR"
        VERIFICATION_PASSED=false
    fi

    if sudo systemctl list-unit-files | grep -q $SERVICE_NAME; then
        error "Systemd service still exists: $SERVICE_NAME"
        VERIFICATION_PASSED=false
    fi

    if sudo firewall-cmd --list-ports | grep -q "${PORT}/tcp"; then
        error "Firewall rule still exists for port: $PORT"
        VERIFICATION_PASSED=false
    fi

    if crontab -l 2>/dev/null | grep -q "browsershield"; then
        error "Cron jobs still exist"
        VERIFICATION_PASSED=false
    fi
fi

# Final status
echo
echo -e "${BLUE}================================${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}  Dry Run Summary${NC}"
else
    echo -e "${BLUE}  Uninstall Summary${NC}"
fi
echo -e "${BLUE}================================${NC}"

if [ "$DRY_RUN" = true ]; then
    log "DRY RUN completed - No files were actually deleted"
    echo -e "${YELLOW}The following would be removed:${NC}"
    echo -e "${YELLOW}✓ Application files${NC}"
    echo -e "${YELLOW}✓ System service${NC}"
    echo -e "${YELLOW}✓ Firewall rules${NC}"
    echo -e "${YELLOW}✓ Cron jobs${NC}"
    echo -e "${YELLOW}✓ Log files${NC}"
    echo -e "${YELLOW}✓ Configuration files${NC}"
    echo -e "${YELLOW}✓ All processes${NC}"
    echo
    info "To actually uninstall, run: $0 (without --dry-run)"
    info "To force uninstall without prompts, run: $0 --force"
elif [ "$VERIFICATION_PASSED" = true ]; then
    log "BrowserShield has been completely uninstalled!"
    echo -e "${GREEN}✓ Application files removed${NC}"
    echo -e "${GREEN}✓ System service removed${NC}"
    echo -e "${GREEN}✓ Firewall rules removed${NC}"
    echo -e "${GREEN}✓ Cron jobs removed${NC}"
    echo -e "${GREEN}✓ Log files removed${NC}"
    echo -e "${GREEN}✓ Configuration files removed${NC}"
    echo -e "${GREEN}✓ All processes terminated${NC}"
    echo
    log "System is now clean of BrowserShield components"
else
    error "Uninstall completed with warnings - some components may remain"
    warn "Please check the errors above and remove manually if needed"
fi

# Show what's preserved (if any)
echo
info "Preserved items (if any):"
if [ -d "$BACKUP_DIR" ]; then
    echo "  - Backup directory: $BACKUP_DIR"
fi

if command -v node &> /dev/null; then
    echo "  - Node.js: $(node --version)"
fi

if command -v google-chrome &> /dev/null; then
    echo "  - Google Chrome: $(google-chrome --version 2>/dev/null | head -1)"
fi

echo
log "Uninstall process completed"
echo -e "${YELLOW}Note: You may want to restart the system to ensure all changes take effect${NC}"