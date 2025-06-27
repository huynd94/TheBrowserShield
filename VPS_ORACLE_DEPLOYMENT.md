# BrowserShield VPS Deployment Guide - Oracle Linux 9

## Tổng quan

Hướng dẫn triển khai BrowserShield trên Oracle Linux 9 VPS với Production Mode (Chrome browser) để có đầy đủ tính năng automation thực tế.

## Yêu cầu hệ thống

- **OS**: Oracle Linux 9
- **RAM**: Tối thiểu 2GB (khuyến nghị 4GB+)
- **CPU**: Tối thiểu 2 cores
- **Storage**: Tối thiểu 20GB
- **Network**: Port 5000 mở ra ngoài internet
- **User**: opc (Oracle Cloud default user)

## Triển khai tự động

### Bước 1: Tải script triển khai

```bash
# Tải script triển khai
wget https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/deploy-oracle-linux-production.sh

# Cấp quyền thực thi
chmod +x deploy-oracle-linux-production.sh
```

### Bước 2: Chạy triển khai tự động

```bash
# Chạy script triển khai (đừng dùng sudo)
./deploy-oracle-linux-production.sh
```

Script sẽ tự động:
- Cập nhật hệ thống Oracle Linux 9
- Cài đặt Node.js 20
- Cài đặt Google Chrome cho Production Mode
- Tải và cài đặt BrowserShield
- Cấu hình systemd service
- Thiết lập firewall
- Khởi động dịch vụ

### Bước 3: Xác minh triển khai

```bash
# Kiểm tra trạng thái service
sudo systemctl status browsershield

# Kiểm tra logs
sudo journalctl -u browsershield -f

# Test API endpoint
curl http://localhost:5000/health
```

## Cấu hình Oracle Cloud

### Firewall và Security Groups

1. **Oracle Cloud Console**:
   - Networking → Virtual Cloud Networks
   - Chọn VCN của bạn → Security Lists
   - Thêm Ingress Rule:
     - Source: 0.0.0.0/0
     - Protocol: TCP
     - Port: 5000

2. **VPS Firewall**:
```bash
# Mở port (script đã tự động làm)
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

## Quản lý dịch vụ

### Các lệnh cơ bản

```bash
# Khởi động
sudo systemctl start browsershield

# Dừng
sudo systemctl stop browsershield

# Khởi động lại
sudo systemctl restart browsershield

# Xem trạng thái
sudo systemctl status browsershield

# Xem logs realtime
sudo journalctl -u browsershield -f
```

### Script quản lý nhanh

```bash
# Sử dụng script manage.sh
cd /home/opc/browsershield

# Các lệnh có sẵn
./manage.sh start      # Khởi động
./manage.sh stop       # Dừng
./manage.sh restart    # Khởi động lại
./manage.sh status     # Xem trạng thái
./manage.sh logs       # Xem logs
./manage.sh update     # Cập nhật từ GitHub
```

## Cập nhật hệ thống

### Cập nhật tự động

```bash
# Tải script cập nhật
wget https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-update-oracle.sh
chmod +x vps-update-oracle.sh

# Chạy cập nhật
./vps-update-oracle.sh
```

### Cập nhật thủ công

```bash
cd /home/opc/browsershield

# Backup trước khi cập nhật
sudo systemctl stop browsershield
cp -r data data_backup
cp .env env_backup

# Tải code mới
git pull origin main
npm install

# Khởi động lại
sudo systemctl start browsershield
```

## Production Mode Configuration

### Kiểm tra mode hiện tại

```bash
curl http://localhost:5000/api/mode
```

### Chuyển sang Production Mode

1. **Qua API**:
```bash
curl -X POST http://localhost:5000/api/mode/switch \
  -H "Content-Type: application/json" \
  -d '{"mode": "production"}'
```

2. **Qua Web Interface**:
   - Truy cập: `http://YOUR_VPS_IP:5000/mode-manager`
   - Click "Switch to Production Mode"

3. **Thủ công**:
```bash
cd /home/opc/browsershield
cat > data/mode-config.json << EOF
{
  "mode": "production",
  "lastChanged": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "capabilities": {
    "realBrowser": true,
    "screenshots": true,
    "websiteInteraction": true,
    "chromeAutomation": true,
    "stealth": true
  }
}
EOF

sudo systemctl restart browsershield
```

## Truy cập Web Interface

### URLs chính

- **Web Interface**: `http://YOUR_VPS_IP:5000`
- **Admin Panel**: `http://YOUR_VPS_IP:5000/admin`
- **Mode Manager**: `http://YOUR_VPS_IP:5000/mode-manager`
- **API Health**: `http://YOUR_VPS_IP:5000/health`
- **API Documentation**: `http://YOUR_VPS_IP:5000/docs/README.md`

### Lấy Public IP

```bash
# Xem IP public của VPS
curl -4 icanhazip.com
```

## Troubleshooting

### Service không khởi động

```bash
# Xem chi tiết lỗi
sudo journalctl -u browsershield -n 50

# Kiểm tra cú pháp
cd /home/opc/browsershield
node -c server.js

# Kiểm tra port đã được sử dụng
sudo netstat -tlnp | grep 5000
```

### Chrome không hoạt động

```bash
# Kiểm tra Chrome
google-chrome --version

# Test Chrome headless
google-chrome --headless --disable-gpu --no-sandbox --dump-dom https://www.google.com
```

### Port không accessible

```bash
# Kiểm tra firewall
sudo firewall-cmd --list-all

# Kiểm tra iptables
sudo iptables -L -n

# Test port từ bên trong
curl http://localhost:5000/health

# Test port từ bên ngoài
curl http://YOUR_VPS_IP:5000/health
```

### Memory issues

```bash
# Kiểm tra memory usage
free -h
ps aux | grep node

# Khởi động lại để giải phóng memory
sudo systemctl restart browsershield
```

## Performance Optimization

### Cấu hình Node.js

```bash
# Thêm vào /etc/systemd/system/browsershield.service
[Service]
Environment=NODE_OPTIONS="--max-old-space-size=2048"
ExecStart=/usr/bin/node --max-old-space-size=2048 server.js
```

### Cấu hình Chrome

```bash
# Tối ưu Chrome cho VPS (thêm vào config)
Environment=CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu"
```

### Monitoring

```bash
# Xem resource usage
htop

# Monitor logs
tail -f /var/log/messages | grep browsershield

# Check disk space
df -h
```

## Security

### API Token (khuyến nghị)

```bash
# Tạo API token
echo "API_TOKEN=$(openssl rand -hex 32)" >> /home/opc/browsershield/.env

# Restart service
sudo systemctl restart browsershield
```

### Firewall bổ sung

```bash
# Chỉ cho phép IP cụ thể (thay YOUR_IP)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="YOUR_IP" port protocol="tcp" port="5000" accept'
sudo firewall-cmd --permanent --remove-port=5000/tcp
sudo firewall-cmd --reload
```

## Backup và Restore

### Backup tự động

```bash
# Tạo script backup
cat > /home/opc/backup-browsershield.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/opc/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/browsershield_$DATE.tar.gz -C /home/opc browsershield/data browsershield/.env
find $BACKUP_DIR -name "browsershield_*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/opc/backup-browsershield.sh

# Thêm vào crontab (backup hàng ngày)
echo "0 2 * * * /home/opc/backup-browsershield.sh" | crontab -
```

### Restore

```bash
# Restore từ backup
sudo systemctl stop browsershield
cd /home/opc
tar -xzf backups/browsershield_YYYYMMDD_HHMMSS.tar.gz
sudo systemctl start browsershield
```

## Monitoring và Alerting

### Kiểm tra health định kỳ

```bash
# Tạo health check script
cat > /home/opc/health-check.sh << 'EOF'
#!/bin/bash
if ! curl -s http://localhost:5000/health > /dev/null; then
    echo "BrowserShield is down, restarting..."
    sudo systemctl restart browsershield
    echo "BrowserShield restarted at $(date)" >> /var/log/browsershield-health.log
fi
EOF

chmod +x /home/opc/health-check.sh

# Chạy mỗi 5 phút
echo "*/5 * * * * /home/opc/health-check.sh" | crontab -
```

## Kết luận

Sau khi triển khai thành công:

1. ✅ BrowserShield chạy trong Production Mode với Chrome browser
2. ✅ Systemd service tự động khởi động khi reboot
3. ✅ Firewall được cấu hình đúng
4. ✅ API endpoints hoạt động bình thường
5. ✅ Web interface accessible từ internet

**Access URL**: `http://YOUR_VPS_IP:5000`

Sử dụng Admin Panel để tạo profiles và khởi động browser sessions với đầy đủ tính năng automation thực tế.