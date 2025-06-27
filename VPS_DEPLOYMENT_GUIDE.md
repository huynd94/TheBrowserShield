# Hướng Dẫn Triển Khai BrowserShield Lên VPS

## Tổng Quan

Hướng dẫn này sẽ giúp bạn triển khai BrowserShield Anti-Detect Browser Manager lên VPS Ubuntu/CentOS/Oracle Linux.

## Yêu Cầu Hệ Thống

### VPS Tối Thiểu
- **RAM**: 2GB (khuyến nghị 4GB)
- **CPU**: 2 cores
- **Ổ cứng**: 20GB SSD
- **OS**: Ubuntu 20.04+, CentOS 8+, hoặc Oracle Linux 9

### Cổng Mạng
- **Port 5000**: Ứng dụng BrowserShield
- **Port 22**: SSH access
- **Port 80/443**: Nginx reverse proxy (tùy chọn)

## Bước 1: Chuẩn Bị VPS

### Kết nối SSH
```bash
ssh root@YOUR_VPS_IP
# hoặc
ssh your_username@YOUR_VPS_IP
```

### Cập nhật hệ thống
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL/Oracle Linux
sudo dnf update -y
```

## Bước 2: Cài Đặt Node.js

### Ubuntu/Debian
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### CentOS/Oracle Linux
```bash
sudo dnf install -y epel-release
sudo dnf module enable nodejs:20 -y
sudo dnf install -y nodejs npm
```

### Kiểm tra cài đặt
```bash
node --version  # Phải >= v18.0.0
npm --version
```

## Bước 3: Cài Đặt Chromium (cho Production Mode)

### Ubuntu/Debian
```bash
sudo apt install -y chromium-browser
```

### CentOS/Oracle Linux
```bash
sudo dnf install -y epel-release
sudo dnf install -y chromium
```

## Bước 4: Tạo User và Thư Mục

```bash
# Tạo user browsershield (khuyến nghị)
sudo useradd -m -s /bin/bash browsershield
sudo usermod -aG sudo browsershield

# Chuyển sang user browsershield
sudo su - browsershield

# Tạo thư mục ứng dụng
mkdir -p ~/browsershield
cd ~/browsershield
```

## Bước 5: Tải Mã Nguồn

### Từ GitHub
```bash
git clone https://github.com/huynd94/TheBrowserShield.git .
```

### Hoặc tải trực tiếp
```bash
curl -L https://github.com/huynd94/TheBrowserShield/archive/main.zip -o browsershield.zip
unzip browsershield.zip
mv TheBrowserShield-main/* .
rm -rf TheBrowserShield-main browsershield.zip
```

## Bước 6: Cài Đặt Dependencies

```bash
npm install
```

## Bước 7: Cấu Hình

### Tạo thư mục data
```bash
mkdir -p data logs
chmod 755 data logs
```

### Cấu hình mode (tùy chọn)
```bash
# Tạo file config mode
cat > data/mode-config.json << EOF
{
  "mode": "production",
  "lastChanged": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "capabilities": {
    "realBrowser": true,
    "screenshots": true,
    "websiteInteraction": true,
    "chromeAutomation": true,
    "stealthMode": true
  }
}
EOF
```

### Biến môi trường (tùy chọn)
```bash
cat > .env << EOF
NODE_ENV=production
PORT=5000
# API_TOKEN=your_secure_token_here
# ENABLE_RATE_LIMIT=true
EOF
```

## Bước 8: Tạo SystemD Service

```bash
sudo tee /etc/systemd/system/browsershield.service > /dev/null << EOF
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
After=network.target

[Service]
Type=simple
User=browsershield
WorkingDirectory=/home/browsershield/browsershield
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/browsershield/browsershield

[Install]
WantedBy=multi-user.target
EOF
```

## Bước 9: Khởi Động Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable browsershield

# Start service
sudo systemctl start browsershield

# Kiểm tra status
sudo systemctl status browsershield
```

## Bước 10: Cấu Hình Firewall

### Ubuntu (UFW)
```bash
sudo ufw allow 22/tcp
sudo ufw allow 5000/tcp
sudo ufw --force enable
```

### CentOS/Oracle Linux (firewalld)
```bash
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --reload
```

## Bước 11: Kiểm Tra Triển Khai

### Test local
```bash
curl http://localhost:5000/health
```

### Test từ máy tính của bạn
```bash
curl http://YOUR_VPS_IP:5000/health
```

### Truy cập Web UI
Mở trình duyệt và truy cập: `http://YOUR_VPS_IP:5000`

## Bước 12: Cấu Hình Nginx Reverse Proxy (Tùy chọn)

### Cài đặt Nginx
```bash
# Ubuntu/Debian
sudo apt install -y nginx

# CentOS/Oracle Linux
sudo dnf install -y nginx
```

### Cấu hình Nginx
```bash
sudo tee /etc/nginx/sites-available/browsershield > /dev/null << EOF
server {
    listen 80;
    server_name YOUR_DOMAIN_OR_IP;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site (Ubuntu/Debian)
sudo ln -s /etc/nginx/sites-available/browsershield /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test và restart Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
```

## Bước 13: SSL với Certbot (Tùy chọn)

```bash
# Cài đặt Certbot
sudo apt install -y certbot python3-certbot-nginx  # Ubuntu
# hoặc
sudo dnf install -y certbot python3-certbot-nginx  # CentOS

# Tạo SSL certificate
sudo certbot --nginx -d your-domain.com
```

## Các Lệnh Quản Lý

### Kiểm tra logs
```bash
sudo journalctl -u browsershield -f
```

### Restart service
```bash
sudo systemctl restart browsershield
```

### Stop service
```bash
sudo systemctl stop browsershield
```

### Update ứng dụng
```bash
cd ~/browsershield
git pull origin main
npm install
sudo systemctl restart browsershield
```

## Monitoring và Bảo Trì

### Script monitor tự động
```bash
chmod +x scripts/monitor.sh
./scripts/monitor.sh
```

### Backup dữ liệu
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf ~/backup_browsershield_$DATE.tar.gz ~/browsershield/data
```

### Cài đặt cron backup (tùy chọn)
```bash
crontab -e
# Thêm dòng sau để backup hàng ngày lúc 2:00 AM
0 2 * * * /bin/bash -c 'DATE=$(date +\%Y\%m\%d_\%H\%M\%S); tar -czf ~/backup_browsershield_$DATE.tar.gz ~/browsershield/data'
```

## Xử Lý Sự Cố

### Service không khởi động
```bash
sudo journalctl -u browsershield -n 50
sudo systemctl status browsershield
```

### Port bị chiếm dụng
```bash
sudo netstat -tulpn | grep :5000
sudo lsof -i :5000
```

### Chromium không hoạt động
```bash
# Kiểm tra Chromium
chromium --version
which chromium

# Cài đặt thêm dependencies
sudo apt install -y libgconf-2-4 libxss1 libgtk-3-0 libgdk-pixbuf2.0-0 libxcomposite1 libasound2
```

## Bảo Mật

### Thay đổi port mặc định
Sửa trong file `.env`:
```
PORT=8080
```

### Bật authentication
```bash
# Tạo API token mạnh
openssl rand -hex 32

# Thêm vào .env
echo "API_TOKEN=your_generated_token" >> .env
echo "ENABLE_RATE_LIMIT=true" >> .env
```

### Chặn IP không mong muốn
```bash
sudo ufw deny from SUSPICIOUS_IP
```

## Kết Luận

Sau khi hoàn thành các bước trên, BrowserShield sẽ chạy trên VPS của bạn với:

- ✅ Web interface tại `http://YOUR_VPS_IP:5000`
- ✅ API endpoints để tích hợp
- ✅ Auto-start khi reboot
- ✅ Logging hệ thống
- ✅ Production mode với Chromium

**Lưu ý**: Thay thế `YOUR_VPS_IP` và `YOUR_DOMAIN` bằng thông tin thực của bạn.

## Hỗ Trợ

- **GitHub**: https://github.com/huynd94/TheBrowserShield
- **Issues**: Báo cáo lỗi trên GitHub Issues
- **Documentation**: Xem các file .md trong dự án