# 🛡️ BrowserShield - Cài Đặt Tự Động

## Cài Đặt Nhanh (Khuyến Nghị)

### Oracle Linux 9 / RHEL / CentOS Stream

```bash
# Cài đặt một lệnh duy nhất
curl -sSL https://raw.githubusercontent.com/ngocdm2006/BrowserShield/main/scripts/install-browsershield.sh | bash
```

**Hoặc tải về và chạy:**

```bash
# Tải script
wget https://raw.githubusercontent.com/ngocdm2006/BrowserShield/main/scripts/install-browsershield.sh

# Cấp quyền thực thi
chmod +x install-browsershield.sh

# Chạy cài đặt
./install-browsershield.sh
```

## Yêu Cầu Hệ Thống

- **OS**: Oracle Linux 9, RHEL 9, CentOS Stream 9
- **RAM**: Tối thiểu 2GB (khuyến nghị 4GB+)
- **Storage**: 10GB trống
- **Network**: Internet connection để download dependencies
- **User**: Non-root user với sudo privileges

## Những Gì Script Sẽ Làm

### 🔧 Cài Đặt Dependencies
- Node.js 20.x
- Google Chrome Stable
- System libraries cho Puppeteer
- Development tools

### 👤 Tạo User & Security
- Tạo user `browserapp` riêng biệt
- Cấu hình file permissions
- Tạo environment variables an toàn
- Generate API token tự động

### 📦 Download & Setup Application
- Download source code từ Replit
- Cài đặt NPM dependencies
- Switch sang production mode
- Cấu hình cho VPS environment

### 🚀 Service Configuration
- Tạo SystemD service: `browsershield.service`
- Auto-start on boot
- Auto-restart on failure
- Proper logging setup

### 🔒 Security & Firewall
- Mở port 5000 cho application
- Security hardening
- File descriptor limits
- Resource constraints

### 📊 Monitoring Tools
- System monitoring script
- Update script
- Log viewing helpers

## Sau Khi Cài Đặt

### Truy Cập Application
```bash
# Local
http://localhost:5000

# External (thay YOUR_IP)
http://YOUR_VPS_IP:5000
```

### Quản Lý Service
```bash
# Xem trạng thái
sudo systemctl status browsershield.service

# Start/Stop/Restart
sudo systemctl start browsershield.service
sudo systemctl stop browsershield.service
sudo systemctl restart browsershield.service

# Xem logs
sudo journalctl -u browsershield.service -f
```

### Monitoring & Maintenance
```bash
# Monitor hệ thống
/home/browserapp/browsershield/monitor.sh

# Update application
/home/browserapp/browsershield/update.sh

# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz /home/browserapp/browsershield/data/
```

## Cấu Hình Advanced

### Environment Variables
File: `/home/browserapp/browsershield/.env`

```bash
PORT=5000
NODE_ENV=production
API_TOKEN=your-generated-token
ENABLE_RATE_LIMIT=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
```

### API Authentication
Nếu muốn bảo mật API:

```bash
# Xem token hiện tại
sudo -u browserapp cat /home/browserapp/browsershield/.env | grep API_TOKEN

# Sử dụng token trong requests
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5000/api/profiles
```

### Nginx Reverse Proxy (Optional)
```bash
# Cài đặt Nginx
sudo dnf install -y nginx

# Cấu hình
sudo tee /etc/nginx/conf.d/browsershield.conf << 'EOF'
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Mở port 80
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

## Troubleshooting

### Service Không Start
```bash
# Xem lỗi chi tiết
sudo journalctl -u browsershield.service -n 50

# Kiểm tra file permissions
ls -la /home/browserapp/browsershield/

# Test manual start
sudo -u browserapp bash -c "cd /home/browserapp/browsershield && node server.js"
```

### Chrome Issues
```bash
# Test Chrome installation
google-chrome-stable --version

# Test headless mode
google-chrome-stable --headless --no-sandbox --disable-dev-shm-usage --dump-dom https://example.com
```

### Port Issues
```bash
# Kiểm tra port đang listen
netstat -tlnp | grep :5000

# Kiểm tra firewall
sudo firewall-cmd --list-all
```

### Memory Issues
```bash
# Kiểm tra RAM
free -h

# Tạo swap file nếu cần
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Update Application

### Automatic Update
```bash
/home/browserapp/browsershield/update.sh
```

### Manual Update
```bash
cd /home/browserapp/browsershield

# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Update code (if git repo)
git pull origin main

# Update dependencies
npm install --production

# Restart service
sudo systemctl restart browsershield.service
```

## Uninstall

```bash
# Stop service
sudo systemctl stop browsershield.service
sudo systemctl disable browsershield.service

# Remove service file
sudo rm /etc/systemd/system/browsershield.service
sudo systemctl daemon-reload

# Remove application
sudo rm -rf /home/browserapp/browsershield

# Remove user (optional)
sudo userdel -r browserapp

# Close firewall port
sudo firewall-cmd --permanent --remove-port=5000/tcp
sudo firewall-cmd --reload
```

## Hỗ Trợ

- **Project URL**: https://github.com/huynd94/TheBrowserShield
- **Issues**: Báo lỗi tại GitHub repository
- **Original Demo**: https://replit.com/@ngocdm2006/BrowserShield
- **Documentation**: Xem file DEPLOYMENT.md để biết thêm chi tiết

## Changelog

- **v1.0**: Initial release với auto-installer
- **Oracle Linux 9**: Optimized cho Oracle Linux 9 VPS
- **Production Ready**: SystemD service, security hardening, monitoring tools