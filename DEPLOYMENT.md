# Hướng Dẫn Deploy & Update BrowserShield trên Oracle Linux 9 VPS

## Yêu Cầu Hệ Thống

- Oracle Linux 9 VPS với ít nhất 2GB RAM và 20GB storage
- Root access hoặc sudo privileges
- Port 5000 mở cho external access
- Internet connection để download dependencies

## Bước 1: Cập Nhật Hệ Thống

```bash
# Update system packages
sudo dnf update -y

# Install essential tools
sudo dnf install -y curl wget git unzip
```

## Bước 2: Cài Đặt Node.js 20

```bash
# Install Node.js repository
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -

# Install Node.js and npm
sudo dnf install -y nodejs

# Verify installation
node --version
npm --version
```

## Bước 3: Cài Đặt Dependencies cho Puppeteer

```bash
# Install Chrome dependencies
sudo dnf install -y \
    alsa-lib \
    atk \
    cups-libs \
    gtk3 \
    ipa-gothic-fonts \
    libdrm \
    libxcomposite \
    libxdamage \
    libxrandr \
    libxss \
    libxtst \
    pango \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-cyrillic \
    xorg-x11-fonts-misc \
    xorg-x11-fonts-Type1 \
    xorg-x11-utils

# Install additional dependencies
sudo dnf install -y \
    liberation-fonts \
    nss \
    gconf-service \
    libgconf-2-4 \
    libxfont \
    cyrus-sasl-devel \
    libnsl
```

## Bước 4: Tạo User cho Application

```bash
# Create dedicated user for the application
sudo useradd -m -s /bin/bash browserapp

# Switch to the new user
sudo su - browserapp
```

## Bước 5: Clone và Setup Application

```bash
# Clone repository
cd /home/browserapp
git clone https://github.com/huynd94/TheBrowserShield.git anti-detect-browser
# Hoặc upload files bằng scp/rsync

cd anti-detect-browser

# Install npm dependencies
npm install

# Set proper permissions
chmod +x server.js
```

## Bước 6: Cấu Hình Environment Variables

```bash
# Create environment file
cat > .env << 'EOF'
PORT=5000
NODE_ENV=production
API_TOKEN=your-secure-api-token-here
ENABLE_RATE_LIMIT=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
EOF

# Set secure permissions for env file
chmod 600 .env
```

## Bước 7: Cài Đặt Google Chrome

```bash
# Add Google Chrome repository
sudo tee /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Install Google Chrome
sudo dnf install -y google-chrome-stable

# Verify Chrome installation
google-chrome-stable --version
```

## Bước 8: Switch sang Production Mode

```bash
# Edit server.js để sử dụng BrowserService thay vì MockBrowserService
cd /home/browserapp/anti-detect-browser

# Backup current routes file
cp routes/profiles.js routes/profiles.js.backup

# Update to use real BrowserService
sed -i "s/require('..\/services\/MockBrowserService')/require('..\/services\/BrowserService')/g" routes/profiles.js

echo "Switched to production BrowserService"
```

## Bước 9: Tạo SystemD Service

```bash
# Exit from browserapp user back to root
exit

# Create systemd service file
sudo tee /etc/systemd/system/anti-detect-browser.service << 'EOF'
[Unit]
Description=Anti-Detect Browser Profile Manager
Documentation=https://github.com/your-repo
After=network.target

[Service]
Type=simple
User=browserapp
WorkingDirectory=/home/browserapp/anti-detect-browser
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
SyslogIdentifier=anti-detect-browser
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/home/browserapp/anti-detect-browser

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable anti-detect-browser.service
```

## Bước 10: Cấu Hình Firewall

```bash
# Open port 5000 for the application
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-all
```

## Bước 11: Start Application

```bash
# Start the service
sudo systemctl start anti-detect-browser.service

# Check service status
sudo systemctl status anti-detect-browser.service

# View logs
sudo journalctl -u anti-detect-browser.service -f
```

## Bước 12: Setup Nginx Reverse Proxy (Optional)

```bash
# Install Nginx
sudo dnf install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/conf.d/anti-detect-browser.conf << 'EOF'
server {
    listen 80;
    server_name your-domain.com;  # Thay bằng domain của bạn

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Open HTTP port
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

## Bước 13: Test Deployment

```bash
# Test local connection
curl http://localhost:5000/health

# Test external connection (thay YOUR_VPS_IP bằng IP thực)
curl http://YOUR_VPS_IP:5000/health

# Test web interface
curl -s http://YOUR_VPS_IP:5000/ | grep "Anti-Detect"
```

## Bước 14: Monitoring và Logs

```bash
# Monitor service status
sudo systemctl status anti-detect-browser.service

# View real-time logs
sudo journalctl -u anti-detect-browser.service -f

# View recent logs
sudo journalctl -u anti-detect-browser.service --since "1 hour ago"

# Check resource usage
htop
```

## 🔄 System Updates

### Quick Update (Recommended)
```bash
# Automated update with backup and validation
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh | bash
```

### Manual Update Process
```bash
# Stop service
sudo systemctl stop browsershield.service

# Backup current installation
cp -r /home/opc/browsershield /home/opc/browsershield-backup-$(date +%Y%m%d)

# Download latest code
cd /tmp
git clone https://github.com/huynd94/TheBrowserShield.git browsershield-new

# Preserve user data
cp /home/opc/browsershield/data/* /tmp/browsershield-new/data/
cp /home/opc/browsershield/.env /tmp/browsershield-new/

# Replace installation
rm -rf /home/opc/browsershield
mv /tmp/browsershield-new /home/opc/browsershield
cd /home/opc/browsershield

# Update dependencies
npm install --production

# Start service
sudo systemctl start browsershield.service
```

### Update Features
- Automatic backup before updates
- Data preservation (profiles, proxy pool, mode config)
- Syntax validation before restart
- Rollback capability on failures
- Health check verification

### Cleanup Unused Scripts
```bash
cd /home/opc/browsershield/scripts
./cleanup-unused-scripts.sh
```

## Maintenance Commands

```bash
# Restart service
sudo systemctl restart browsershield.service

# Stop service
sudo systemctl stop browsershield.service

# Monitor system health
cd /home/opc/browsershield/scripts
./monitor.sh

# Check service status
sudo systemctl status browsershield.service

# View logs
sudo journalctl -u browsershield.service -f

# Backup data manually
tar -czf /home/opc/backup-$(date +%Y%m%d).tar.gz /home/opc/browsershield/data/
```

## Troubleshooting

### Chrome không khởi chạy được:
```bash
# Check Chrome installation
google-chrome-stable --version

# Test Chrome with debug info
google-chrome-stable --headless --no-sandbox --disable-dev-shm-usage --dump-dom https://example.com
```

### Service không start:
```bash
# Check detailed error logs
sudo journalctl -u anti-detect-browser.service -n 50

# Check file permissions
ls -la /home/browserapp/anti-detect-browser/
```

### Port không accessible:
```bash
# Check if port is listening
netstat -tlnp | grep :5000

# Check firewall status
sudo firewall-cmd --list-all
```

### Memory issues:
```bash
# Check system resources
free -h
df -h

# Adjust Chrome arguments trong config/puppeteer.js:
# Thêm: '--memory-pressure-off', '--max_old_space_size=512'
```

## Security Recommendations

1. **Change default API token:**
   ```bash
   # Generate secure token
   openssl rand -base64 32
   # Update .env file với token mới
   ```

2. **Setup SSL với Let's Encrypt:**
   ```bash
   sudo dnf install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

3. **Regular updates:**
   ```bash
   # Create update script
   cat > /home/browserapp/update.sh << 'EOF'
   #!/bin/bash
   cd /home/browserapp/anti-detect-browser
   git pull origin main
   npm install
   sudo systemctl restart anti-detect-browser.service
   EOF
   chmod +x /home/browserapp/update.sh
   ```

4. **Backup automation:**
   ```bash
   # Add to crontab
   echo "0 2 * * * tar -czf /home/browserapp/backup-\$(date +\%Y\%m\%d).tar.gz /home/browserapp/anti-detect-browser/data/" | crontab -
   ```

## Performance Optimization

1. **Tăng file descriptor limits:**
   ```bash
   echo "browserapp soft nofile 65536" | sudo tee -a /etc/security/limits.conf
   echo "browserapp hard nofile 65536" | sudo tee -a /etc/security/limits.conf
   ```

2. **Configure swap nếu RAM thấp:**
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

Sau khi hoàn thành các bước trên, ứng dụng sẽ chạy tại `http://YOUR_VPS_IP:5000` với đầy đủ chức năng anti-detect browser management.