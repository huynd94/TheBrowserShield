# Hướng Dẫn Triển Khai VPS - BrowserShield

## Cách 1: Cài Đặt Tự Động (Khuyến nghị)

### Một lệnh duy nhất:
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/quick-deploy.sh | sudo bash
```

Chờ 5-10 phút và xong!

## Cách 2: Cài Đặt Thủ Công

### Bước 1: Chuẩn bị VPS
```bash
# Kết nối SSH
ssh root@IP_VPS_CUA_BAN

# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y  # Ubuntu
# hoặc
sudo dnf update -y  # CentOS/Oracle Linux
```

### Bước 2: Cài Node.js
```bash
# Ubuntu
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/Oracle Linux
sudo dnf install -y epel-release
sudo dnf module enable nodejs:20 -y
sudo dnf install -y nodejs npm
```

### Bước 3: Cài Chromium
```bash
# Ubuntu
sudo apt install -y chromium-browser

# CentOS/Oracle Linux
sudo dnf install -y chromium
```

### Bước 4: Tạo user và tải code
```bash
sudo useradd -m -s /bin/bash browsershield
sudo su - browsershield
mkdir ~/browsershield && cd ~/browsershield
git clone https://github.com/huynd94/TheBrowserShield.git .
npm install
```

### Bước 5: Cấu hình
```bash
mkdir -p data logs

# Tạo file config
cat > data/mode-config.json << 'EOF'
{
  "mode": "production",
  "lastChanged": "2025-06-27T00:00:00.000Z",
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

### Bước 6: Tạo service
```bash
sudo tee /etc/systemd/system/browsershield.service > /dev/null << 'EOF'
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

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable browsershield
sudo systemctl start browsershield
```

### Bước 7: Mở firewall
```bash
# Ubuntu
sudo ufw allow 5000/tcp
sudo ufw --force enable

# CentOS/Oracle Linux
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

## Kiểm Tra

### Test ứng dụng:
```bash
curl http://localhost:5000/health
```

### Truy cập web:
Mở trình duyệt: `http://IP_VPS_CUA_BAN:5000`

## Quản Lý

### Xem logs:
```bash
sudo journalctl -u browsershield -f
```

### Restart:
```bash
sudo systemctl restart browsershield
```

### Stop:
```bash
sudo systemctl stop browsershield
```

### Update code:
```bash
cd /home/browsershield/browsershield
git pull
npm install
sudo systemctl restart browsershield
```

## Lỗi Thường Gặp

### Port 5000 bị chặn:
- Kiểm tra firewall VPS
- Kiểm tra firewall provider (AWS Security Groups, etc.)

### Chromium không chạy:
```bash
# Cài thêm dependencies
sudo apt install -y libgconf-2-4 libxss1 libgtk-3-0 libgdk-pixbuf2.0-0 libxcomposite1 libasound2
```

### Service không start:
```bash
sudo journalctl -u browsershield -n 50
```

## Yêu Cầu VPS Tối Thiểu

- **RAM**: 2GB (khuyến nghị 4GB)
- **CPU**: 2 cores
- **Storage**: 20GB SSD
- **OS**: Ubuntu 20.04+, CentOS 8+, Oracle Linux 9
- **Port**: 5000 phải mở

## Hoàn Thành

Sau khi cài đặt xong, bạn có thể:

1. **Truy cập web UI**: `http://IP_VPS:5000`
2. **Admin panel**: `http://IP_VPS:5000/admin`
3. **Mode manager**: `http://IP_VPS:5000/mode-manager`

Ứng dụng sẽ tự động khởi động khi VPS reboot.