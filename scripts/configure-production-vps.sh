#!/bin/bash
# Production Configuration Script for Oracle Linux 9 VPS
# Optimizes BrowserShield for production environment

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_DIR="/home/opc/browsershield"
SERVICE_NAME="browsershield"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

if [ "$USER" != "opc" ]; then
    error "Please run this script as opc user"
fi

log "Configuring BrowserShield for production VPS environment"

# Stop service for configuration
sudo systemctl stop $SERVICE_NAME || true

# Configure production environment
log "Setting up production environment variables..."
cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=5000
ENABLE_RATE_LIMIT=true
LOG_LEVEL=info
CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-extensions --disable-plugins --disable-images --disable-javascript --headless"
NODE_OPTIONS="--max-old-space-size=2048"
EOF

# Configure production mode
log "Configuring production mode with Chrome browser..."
cat > "$APP_DIR/data/mode-config.json" << EOF
{
  "mode": "production",
  "lastChanged": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "capabilities": {
    "realBrowser": true,
    "screenshots": true,
    "websiteInteraction": true,
    "chromeAutomation": true,
    "stealth": true,
    "antiDetection": true
  }
}
EOF

# Update systemd service with production optimizations
log "Updating systemd service for production..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=5
User=opc
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=NODE_OPTIONS="--max-old-space-size=2048"
Environment=CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu"
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=10
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# Resource limits for production
LimitNOFILE=65536
LimitNPROC=4096
LimitMEMLOCK=64000

# OOM Score (prefer to kill this service over system services)
OOMScoreAdjust=500

[Install]
WantedBy=multi-user.target
EOF

# Create production-ready sample profiles
log "Creating production sample profiles..."
mkdir -p "$APP_DIR/data/profiles"

cat > "$APP_DIR/data/profiles/production-chrome.json" << EOF
{
  "id": "prod-chrome-001",
  "name": "Production Chrome Profile",
  "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "timezone": "America/New_York",
  "viewport": {
    "width": 1920,
    "height": 1080
  },
  "proxy": null,
  "stealthConfig": {
    "canvasNoise": true,
    "webrtcProtection": true,
    "timezoneSpoof": true,
    "languageSpoof": true
  },
  "autoNavigateUrl": "https://httpbin.org/headers",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
}
EOF

# Configure log rotation
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/browsershield > /dev/null << EOF
/var/log/browsershield.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 opc opc
    postrotate
        /bin/systemctl reload browsershield > /dev/null 2>&1 || true
    endscript
}
EOF

# Setup system monitoring
log "Setting up system monitoring..."
cat > /home/opc/monitor-browsershield.sh << 'EOF'
#!/bin/bash
# BrowserShield monitoring script

LOGFILE="/var/log/browsershield-monitor.log"
SERVICE="browsershield"

check_service() {
    if ! systemctl is-active --quiet $SERVICE; then
        echo "$(date): Service $SERVICE is down, restarting..." >> $LOGFILE
        sudo systemctl restart $SERVICE
        return 1
    fi
    return 0
}

check_api() {
    if ! curl -s --max-time 10 http://localhost:5000/health > /dev/null; then
        echo "$(date): API health check failed" >> $LOGFILE
        return 1
    fi
    return 0
}

check_memory() {
    MEMORY_USAGE=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem -C node | grep server.js | awk '{print $4}' | head -1)
    if [ ! -z "$MEMORY_USAGE" ] && (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
        echo "$(date): High memory usage detected: ${MEMORY_USAGE}%" >> $LOGFILE
        sudo systemctl restart $SERVICE
        return 1
    fi
    return 0
}

# Main monitoring
check_service
check_api
check_memory

# Log system stats every hour
HOUR=$(date +%H)
if [ "$HOUR" == "00" ]; then
    echo "$(date): Daily stats - Memory: $(free -h | grep Mem | awk '{print $3"/"$2}'), Load: $(uptime | awk -F'load average:' '{print $2}')" >> $LOGFILE
fi
EOF

chmod +x /home/opc/monitor-browsershield.sh

# Setup cron jobs
log "Setting up monitoring cron jobs..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/opc/monitor-browsershield.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /home/opc/backup-browsershield.sh") | crontab -

# Create backup script
cat > /home/opc/backup-browsershield.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/opc/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup data and configuration
tar -czf $BACKUP_DIR/browsershield_$DATE.tar.gz -C /home/opc browsershield/data browsershield/.env

# Keep only last 7 days of backups
find $BACKUP_DIR -name "browsershield_*.tar.gz" -mtime +7 -delete

echo "$(date): Backup completed - browsershield_$DATE.tar.gz" >> /var/log/browsershield-backup.log
EOF

chmod +x /home/opc/backup-browsershield.sh

# Security hardening
log "Applying security hardening..."
# Disable root login over SSH (if not already done)
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Configure fail2ban for additional security (optional)
if command -v fail2ban-client &> /dev/null; then
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
fi

# Set proper file permissions
chmod 750 "$APP_DIR"
chmod 640 "$APP_DIR/.env"
chmod -R 750 "$APP_DIR/data"

# Reload systemd and start service
log "Reloading systemd and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Wait for service to start
sleep 10

# Verify everything is working
log "Verifying production configuration..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "Service is running successfully"
else
    error "Service failed to start"
fi

if curl -s http://localhost:5000/health > /dev/null; then
    log "API health check passed"
else
    warn "API health check failed"
fi

# Check current mode
MODE_CHECK=$(curl -s http://localhost:5000/api/mode | grep -o '"currentMode":"[^"]*"' | cut -d'"' -f4)
if [ "$MODE_CHECK" == "production" ]; then
    log "Production mode confirmed"
else
    warn "Mode is not set to production: $MODE_CHECK"
fi

log "Production configuration completed successfully!"
echo
echo -e "${GREEN}✓ Production environment configured${NC}"
echo -e "${GREEN}✓ Chrome browser optimization enabled${NC}"
echo -e "${GREEN}✓ System monitoring setup${NC}"
echo -e "${GREEN}✓ Automatic backups configured${NC}"
echo -e "${GREEN}✓ Security hardening applied${NC}"
echo -e "${GREEN}✓ Log rotation configured${NC}"
echo
echo "Service status: $(sudo systemctl is-active $SERVICE_NAME)"
echo "Current mode: $MODE_CHECK"
echo
echo "Management commands:"
echo "  ./manage.sh {start|stop|restart|status|logs|update}"
echo "  /home/opc/monitor-browsershield.sh  # Manual health check"
echo "  /home/opc/backup-browsershield.sh   # Manual backup"
echo
echo "Log files:"
echo "  sudo journalctl -u $SERVICE_NAME -f  # Service logs"
echo "  tail -f /var/log/browsershield-monitor.log  # Monitor logs"
echo "  tail -f /var/log/browsershield-backup.log   # Backup logs"