#!/bin/bash
# BrowserShield VPS Management Script for Oracle Linux 9
# Fixed version with improved error handling and compatibility

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/huynd94/TheBrowserShield/main"
APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Use 'opc' user."
        exit 1
    fi
}

# Check Oracle Linux 9
check_system() {
    if ! grep -q "Oracle Linux" /etc/os-release 2>/dev/null; then
        warn "This script is optimized for Oracle Linux 9"
    fi
}

show_banner() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}   BrowserShield VPS Manager${NC}"
    echo -e "${CYAN}   Oracle Linux 9 Edition${NC}"
    echo -e "${CYAN}   Fixed Version v1.1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

show_menu() {
    echo -e "${BLUE}Available Commands:${NC}"
    echo "  1. deploy        - Deploy BrowserShield with Production Mode"
    echo "  2. update        - Update to latest version"
    echo "  3. configure     - Configure production environment"
    echo "  4. status        - Show system status"
    echo "  5. logs          - View service logs"
    echo "  6. restart       - Restart service"
    echo "  7. backup        - Create backup"
    echo "  8. monitor       - Run health check"
    echo "  9. uninstall     - Complete uninstall"
    echo "  10. help         - Show detailed help"
    echo
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo "  start|stop|restart - Service control"
    echo "  health            - Quick health check"
    echo
}

deploy_browsershield() {
    check_root
    check_system
    
    log "Deploying BrowserShield with Production Mode..."
    info "This will install:"
    echo "  - Node.js 20"
    echo "  - Google Chrome browser"
    echo "  - BrowserShield application"
    echo "  - SystemD service"
    echo "  - Firewall configuration"
    echo
    
    read -p "Continue with deployment? (y/N): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        warn "Deployment cancelled"
        return 0
    fi
    
    log "Starting deployment..."
    if curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/deploy-oracle-linux-production.sh" | bash; then
        log "Deployment completed successfully!"
        info "Access: http://$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP'):5000"
    else
        error "Deployment failed!"
        exit 1
    fi
}

update_browsershield() {
    check_root
    
    log "Updating BrowserShield to latest version..."
    if [ ! -d "$APP_DIR" ]; then
        error "BrowserShield not installed. Use 'deploy' command first."
        exit 1
    fi
    
    if curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/vps-update-oracle.sh" | bash; then
        log "Update completed successfully!"
    else
        error "Update failed!"
        exit 1
    fi
}

configure_production() {
    check_root
    
    log "Configuring production environment..."
    if [ ! -d "$APP_DIR" ]; then
        error "BrowserShield not installed. Use 'deploy' command first."
        exit 1
    fi
    
    if curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/configure-production-vps.sh" | bash; then
        log "Configuration completed!"
    else
        error "Configuration failed!"
        exit 1
    fi
}

show_status() {
    log "BrowserShield System Status"
    echo "================================"
    
    # Service status
    if sudo systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "Service Status: ${GREEN}Running${NC}"
        local uptime=$(sudo systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp --value 2>/dev/null | cut -d' ' -f2- || echo "Unknown")
        echo "Uptime: $uptime"
    else
        echo -e "Service Status: ${RED}Stopped${NC}"
    fi
    
    # System info
    echo "System: $(cat /etc/oracle-release 2>/dev/null || echo 'Oracle Linux')"
    echo "Memory: $(free -h 2>/dev/null | grep '^Mem:' | awk '{print $3 "/" $2}' || echo 'Unknown')"
    echo "Disk: $(df -h / 2>/dev/null | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}' || echo 'Unknown')"
    
    # Network
    local ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo 'Unknown')
    echo "IP Address: $ip"
    
    local port_status="Closed"
    if command -v netstat >/dev/null 2>&1; then
        if sudo netstat -tlnp 2>/dev/null | grep -q :5000; then
            port_status="Open"
        fi
    fi
    echo "Port 5000: $port_status"
    
    # Application status
    if [ -d "$APP_DIR" ]; then
        echo -e "Application: ${GREEN}Installed${NC}"
        echo "Location: $APP_DIR"
        local version=$(grep '"version"' "$APP_DIR/package.json" 2>/dev/null | cut -d'"' -f4 || echo 'Unknown')
        echo "Version: $version"
    else
        echo -e "Application: ${RED}Not Installed${NC}"
    fi
}

view_logs() {
    log "Viewing BrowserShield logs (Press Ctrl+C to exit)"
    if command -v journalctl >/dev/null 2>&1; then
        sudo journalctl -u $SERVICE_NAME -f
    else
        error "journalctl not available"
        exit 1
    fi
}

restart_service() {
    log "Restarting BrowserShield service..."
    if sudo systemctl restart $SERVICE_NAME 2>/dev/null; then
        log "Service restarted successfully"
        sleep 3
        if sudo systemctl is-active --quiet $SERVICE_NAME; then
            log "Service is running"
        else
            error "Service failed to start after restart"
            exit 1
        fi
    else
        error "Failed to restart service"
        exit 1
    fi
}

create_backup() {
    check_root
    
    if [ ! -d "$APP_DIR" ]; then
        error "BrowserShield not installed"
        exit 1
    fi
    
    log "Creating backup..."
    local backup_dir="/home/opc/backups"
    local backup_name="browsershield_manual_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    if [ -d "$APP_DIR/data" ] && [ -f "$APP_DIR/.env" ]; then
        tar -czf "$backup_dir/$backup_name.tar.gz" -C /home/opc browsershield/data browsershield/.env 2>/dev/null
        log "Backup created: $backup_dir/$backup_name.tar.gz"
    else
        warn "Data directory or .env file not found, creating basic backup"
        tar -czf "$backup_dir/$backup_name.tar.gz" -C /home/opc browsershield 2>/dev/null
        log "Basic backup created: $backup_dir/$backup_name.tar.gz"
    fi
}

run_health_check() {
    log "Running health check..."
    local status=0
    
    # Service check
    if sudo systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "✓ Service is ${GREEN}running${NC}"
    else
        echo -e "✗ Service is ${RED}stopped${NC}"
        status=1
    fi
    
    # API check
    if curl -s --max-time 10 http://localhost:5000/health >/dev/null 2>&1; then
        echo -e "✓ API is ${GREEN}responding${NC}"
    else
        echo -e "✗ API is ${RED}not responding${NC}"
        status=1
    fi
    
    # Memory check
    if command -v ps >/dev/null 2>&1; then
        local memory_usage=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem -C node 2>/dev/null | grep server.js | awk '{print $4}' | head -1 || echo "")
        if [ -n "$memory_usage" ]; then
            if (( $(echo "$memory_usage < 80" | bc -l 2>/dev/null || echo 1) )); then
                echo -e "✓ Memory usage: ${GREEN}${memory_usage}%${NC}"
            else
                echo -e "⚠ Memory usage: ${YELLOW}${memory_usage}%${NC} (high)"
            fi
        fi
    fi
    
    if [ $status -eq 0 ]; then
        log "Health check completed - All systems operational"
    else
        warn "Health check completed - Issues detected"
    fi
    
    return $status
}

uninstall_browsershield() {
    check_root
    
    info "BrowserShield Uninstall Options:"
    echo "1. Preview what would be deleted (safe)"
    echo "2. Complete uninstall with confirmation"
    echo "3. Force uninstall (no prompts)"
    echo "4. Cancel"
    echo
    
    read -p "Choose option (1-4): " UNINSTALL_OPTION
    
    case $UNINSTALL_OPTION in
        1)
            log "Running safe preview..."
            curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/uninstall-browsershield-vps.sh" | bash -s -- --dry-run
            ;;
        2)
            warn "Starting complete uninstall..."
            curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/uninstall-browsershield-vps.sh" | bash
            ;;
        3)
            warn "Starting force uninstall..."
            curl -fsSL --max-time 300 "$GITHUB_REPO/scripts/uninstall-browsershield-vps.sh" | bash -s -- --force
            ;;
        4|*)
            warn "Uninstall cancelled"
            return 0
            ;;
    esac
}

show_help() {
    show_banner
    echo -e "${BLUE}BrowserShield VPS Manager - Detailed Help${NC}"
    echo
    echo -e "${YELLOW}DEPLOYMENT:${NC}"
    echo "  ./vps-manager-fixed.sh deploy"
    echo "    - Complete fresh installation with Production Mode"
    echo "    - Installs Node.js 20 + Google Chrome"
    echo "    - Configures systemd service and firewall"
    echo "    - Sets up monitoring and backups"
    echo
    echo -e "${YELLOW}MAINTENANCE:${NC}"
    echo "  ./vps-manager-fixed.sh update"
    echo "    - Updates to latest code from GitHub"
    echo "    - Preserves data and configuration"
    echo "    - Automatic backup before update"
    echo
    echo "  ./vps-manager-fixed.sh configure"
    echo "    - Optimizes for production environment"
    echo "    - Sets up monitoring and security"
    echo "    - Configures log rotation"
    echo
    echo -e "${YELLOW}MONITORING:${NC}"
    echo "  ./vps-manager-fixed.sh status"
    echo "    - Complete system status overview"
    echo "    - Service, system, and network information"
    echo
    echo "  ./vps-manager-fixed.sh monitor"
    echo "    - Health check with detailed diagnostics"
    echo "    - Memory, API, and service status"
    echo
    echo "  ./vps-manager-fixed.sh logs"
    echo "    - Real-time service logs"
    echo "    - Press Ctrl+C to exit"
    echo
    echo -e "${YELLOW}MANAGEMENT:${NC}"
    echo "  ./vps-manager-fixed.sh start|stop|restart"
    echo "    - Service control commands"
    echo
    echo "  ./vps-manager-fixed.sh backup"
    echo "    - Manual backup creation"
    echo "    - Includes data and configuration"
    echo
    echo "  ./vps-manager-fixed.sh uninstall"
    echo "    - Complete removal of BrowserShield"
    echo "    - Removes all files, services, and configurations"
    echo
    echo -e "${YELLOW}QUICK SETUP:${NC}"
    echo "  # One-line deployment"
    echo "  curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager-fixed.sh | bash -s deploy"
    echo
    echo -e "${YELLOW}ACCESS URLS:${NC}"
    echo "  Web Interface: http://YOUR_VPS_IP:5000"
    echo "  Admin Panel: http://YOUR_VPS_IP:5000/admin"
    echo "  Mode Manager: http://YOUR_VPS_IP:5000/mode-manager"
    echo "  API Health: http://YOUR_VPS_IP:5000/health"
    echo
}

# Main script logic
main() {
    if [ $# -eq 0 ]; then
        show_banner
        show_menu
        exit 0
    fi

    case "$1" in
        deploy)
            deploy_browsershield
            ;;
        update)
            update_browsershield
            ;;
        configure)
            configure_production
            ;;
        status)
            show_status
            ;;
        logs)
            view_logs
            ;;
        start)
            if sudo systemctl start $SERVICE_NAME 2>/dev/null; then
                log "Service started"
            else
                error "Failed to start service"
                exit 1
            fi
            ;;
        stop)
            if sudo systemctl stop $SERVICE_NAME 2>/dev/null; then
                warn "Service stopped"
            else
                error "Failed to stop service"
                exit 1
            fi
            ;;
        restart)
            restart_service
            ;;
        backup)
            create_backup
            ;;
        monitor|health)
            run_health_check
            ;;
        uninstall)
            uninstall_browsershield
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo
            show_menu
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"