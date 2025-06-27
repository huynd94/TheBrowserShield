#!/bin/bash
# BrowserShield VPS Management Script for Oracle Linux 9
# Comprehensive management tool for deployment, maintenance, and removal

set -e

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

show_banner() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}   BrowserShield VPS Manager${NC}"
    echo -e "${CYAN}   Oracle Linux 9 Edition${NC}"
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
    echo -e "${GREEN}Deploying BrowserShield with Production Mode...${NC}"
    curl -fsSL $GITHUB_REPO/scripts/deploy-oracle-linux-production.sh | bash
}

update_browsershield() {
    echo -e "${GREEN}Updating BrowserShield...${NC}"
    curl -fsSL $GITHUB_REPO/scripts/vps-update-oracle.sh | bash
}

configure_production() {
    echo -e "${GREEN}Configuring production environment...${NC}"
    curl -fsSL $GITHUB_REPO/scripts/configure-production-vps.sh | bash
}

show_status() {
    echo -e "${BLUE}=== BrowserShield System Status ===${NC}"
    echo
    
    # Service status
    echo -e "${YELLOW}Service Status:${NC}"
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "  Status: ${GREEN}Running${NC}"
    else
        echo -e "  Status: ${RED}Stopped${NC}"
    fi
    
    if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "  Auto-start: ${GREEN}Enabled${NC}"
    else
        echo -e "  Auto-start: ${RED}Disabled${NC}"
    fi
    
    # System info
    echo -e "\n${YELLOW}System Information:${NC}"
    echo "  Uptime: $(uptime -p)"
    echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "  Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "  Disk: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5" used)"}')"
    
    # Application info
    if [ -d "$APP_DIR" ]; then
        echo -e "\n${YELLOW}Application Information:${NC}"
        echo "  Installation: ${GREEN}Found${NC} at $APP_DIR"
        
        if command -v node &> /dev/null; then
            echo "  Node.js: $(node --version)"
        fi
        
        if command -v google-chrome &> /dev/null; then
            echo "  Chrome: $(google-chrome --version 2>/dev/null | head -1)"
        fi
        
        # API health check
        if curl -s --max-time 5 http://localhost:5000/health > /dev/null 2>&1; then
            echo -e "  API Health: ${GREEN}OK${NC}"
            
            # Get current mode
            MODE=$(curl -s http://localhost:5000/api/mode 2>/dev/null | grep -o '"currentMode":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "unknown")
            echo "  Current Mode: $MODE"
        else
            echo -e "  API Health: ${RED}Failed${NC}"
        fi
    else
        echo -e "\n${YELLOW}Application Information:${NC}"
        echo -e "  Installation: ${RED}Not Found${NC}"
    fi
    
    # Network
    echo -e "\n${YELLOW}Network Information:${NC}"
    PUBLIC_IP=$(curl -s --max-time 5 -4 icanhazip.com 2>/dev/null || echo "Unable to detect")
    echo "  Public IP: $PUBLIC_IP"
    echo "  Web Interface: http://$PUBLIC_IP:5000"
    
    # Check if port is open
    if sudo netstat -tlnp 2>/dev/null | grep -q ":5000 "; then
        echo -e "  Port 5000: ${GREEN}Open${NC}"
    else
        echo -e "  Port 5000: ${RED}Closed${NC}"
    fi
}

view_logs() {
    echo -e "${GREEN}Viewing service logs (press Ctrl+C to exit)...${NC}"
    sudo journalctl -u $SERVICE_NAME -f
}

restart_service() {
    echo -e "${GREEN}Restarting BrowserShield service...${NC}"
    sudo systemctl restart $SERVICE_NAME
    sleep 3
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}Service restarted successfully${NC}"
    else
        echo -e "${RED}Failed to restart service${NC}"
        exit 1
    fi
}

create_backup() {
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${RED}BrowserShield not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Creating backup...${NC}"
    BACKUP_DIR="/home/opc/backups"
    BACKUP_NAME="browsershield_manual_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C /home/opc browsershield/data browsershield/.env
    
    echo -e "${GREEN}Backup created: $BACKUP_DIR/$BACKUP_NAME.tar.gz${NC}"
}

run_health_check() {
    echo -e "${GREEN}Running health check...${NC}"
    
    # Service check
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "✓ Service is ${GREEN}running${NC}"
    else
        echo -e "✗ Service is ${RED}stopped${NC}"
        return 1
    fi
    
    # API check
    if curl -s --max-time 10 http://localhost:5000/health > /dev/null; then
        echo -e "✓ API is ${GREEN}responding${NC}"
    else
        echo -e "✗ API is ${RED}not responding${NC}"
        return 1
    fi
    
    # Memory check
    MEMORY_USAGE=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem -C node | grep server.js | awk '{print $4}' | head -1)
    if [ ! -z "$MEMORY_USAGE" ]; then
        if (( $(echo "$MEMORY_USAGE < 80" | bc -l) )); then
            echo -e "✓ Memory usage: ${GREEN}${MEMORY_USAGE}%${NC}"
        else
            echo -e "⚠ Memory usage: ${YELLOW}${MEMORY_USAGE}%${NC} (high)"
        fi
    fi
    
    echo -e "${GREEN}Health check completed${NC}"
}

uninstall_browsershield() {
    echo -e "${RED}Starting complete uninstall...${NC}"
    curl -fsSL $GITHUB_REPO/scripts/uninstall-browsershield-vps.sh | bash
}

show_help() {
    show_banner
    echo -e "${BLUE}BrowserShield VPS Manager - Detailed Help${NC}"
    echo
    echo -e "${YELLOW}DEPLOYMENT:${NC}"
    echo "  ./vps-manager.sh deploy"
    echo "    - Complete fresh installation with Production Mode"
    echo "    - Installs Node.js 20 + Google Chrome"
    echo "    - Configures systemd service and firewall"
    echo "    - Sets up monitoring and backups"
    echo
    echo -e "${YELLOW}MAINTENANCE:${NC}"
    echo "  ./vps-manager.sh update"
    echo "    - Updates to latest code from GitHub"
    echo "    - Preserves data and configuration"
    echo "    - Automatic backup before update"
    echo
    echo "  ./vps-manager.sh configure"
    echo "    - Optimizes for production environment"
    echo "    - Sets up monitoring and security"
    echo "    - Configures log rotation"
    echo
    echo -e "${YELLOW}MONITORING:${NC}"
    echo "  ./vps-manager.sh status"
    echo "    - Complete system status overview"
    echo "    - Service, system, and network information"
    echo
    echo "  ./vps-manager.sh monitor"
    echo "    - Health check with detailed diagnostics"
    echo "    - Memory, API, and service status"
    echo
    echo "  ./vps-manager.sh logs"
    echo "    - Real-time service logs"
    echo "    - Press Ctrl+C to exit"
    echo
    echo -e "${YELLOW}MANAGEMENT:${NC}"
    echo "  ./vps-manager.sh start|stop|restart"
    echo "    - Service control commands"
    echo
    echo "  ./vps-manager.sh backup"
    echo "    - Manual backup creation"
    echo "    - Includes data and configuration"
    echo
    echo "  ./vps-manager.sh uninstall"
    echo "    - Complete removal of BrowserShield"
    echo "    - Removes all files, services, and configurations"
    echo
    echo -e "${YELLOW}QUICK SETUP:${NC}"
    echo "  # One-line deployment"
    echo "  curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager.sh | bash -s deploy"
    echo
    echo -e "${YELLOW}ACCESS URLS:${NC}"
    echo "  Web Interface: http://YOUR_VPS_IP:5000"
    echo "  Admin Panel: http://YOUR_VPS_IP:5000/admin"
    echo "  Mode Manager: http://YOUR_VPS_IP:5000/mode-manager"
    echo "  API Health: http://YOUR_VPS_IP:5000/health"
    echo
}

# Main script logic
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
        sudo systemctl start $SERVICE_NAME
        echo -e "${GREEN}Service started${NC}"
        ;;
    stop)
        sudo systemctl stop $SERVICE_NAME
        echo -e "${YELLOW}Service stopped${NC}"
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
        echo -e "${RED}Unknown command: $1${NC}"
        echo
        show_menu
        exit 1
        ;;
esac