# Triển khai BrowserShield lên VPS Oracle Linux 9

## Cách 1: Cài đặt tự động bằng một lệnh

Chạy lệnh này trên VPS để cài đặt hoàn toàn tự động:

```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-vps-auto.sh | bash
```

## Cách 2: Cài đặt thủ công từng bước

### Bước 1: Kết nối VPS
```bash
ssh opc@138.2.82.254
```

### Bước 2: Cài đặt dependencies
```bash
# Update system
sudo dnf update -y

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs git unzip curl wget

# Verify installation
node --version
npm --version
```

### Bước 3: Tải và cài đặt BrowserShield
```bash
# Create app directory
mkdir -p /home/opc/browsershield
cd /home/opc/browsershield

# Download project files
git clone https://github.com/huynd94/TheBrowserShield.git .

# Install dependencies
npm install

# Create environment file
cat > .env << 'EOF'
PORT=5000
NODE_ENV=production
API_TOKEN=4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=
BROWSER_MODE=mock
EOF
```

### Bước 4: Tạo SystemD service
```bash
# Create service file
sudo tee /etc/systemd/system/browsershield.service > /dev/null << 'EOF'
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
Documentation=https://github.com/huynd94/TheBrowserShield
After=network.target

[Service]
Type=simple
User=opc
Group=opc
WorkingDirectory=/home/opc/browsershield
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=browsershield

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable browsershield.service
sudo systemctl start browsershield.service
```

### Bước 5: Cấu hình firewall
```bash
# Configure Oracle Cloud firewall
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Configure system firewall (if enabled)
if sudo systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
fi
```

### Bước 6: Kiểm tra hoạt động
```bash
# Check service status
sudo systemctl status browsershield.service

# Check logs
sudo journalctl -u browsershield.service -f

# Test local access
curl http://localhost:5000/health

# Test external access (từ máy khác)
curl http://138.2.82.254:5000/health
```

## Cách 3: Upload code từ Replit

### Upload qua GitHub
```bash
# Trên VPS
cd /home/opc
git clone https://github.com/huynd94/TheBrowserShield.git browsershield
cd browsershield
npm install
```

### Upload qua SCP
```bash
# Từ máy local
scp -r ./project-files opc@138.2.82.254:/home/opc/browsershield
```

## Các lệnh quản lý service

```bash
# Start service
sudo systemctl start browsershield.service

# Stop service
sudo systemctl stop browsershield.service

# Restart service
sudo systemctl restart browsershield.service

# Check status
sudo systemctl status browsershield.service

# View logs
sudo journalctl -u browsershield.service -f

# Enable auto-start on boot
sudo systemctl enable browsershield.service
```

## Truy cập giao diện

Sau khi cài đặt thành công:

- **Trang chủ**: http://138.2.82.254:5000
- **Admin Panel**: http://138.2.82.254:5000/admin
- **API Health**: http://138.2.82.254:5000/health

## Troubleshooting

### Lỗi permission denied
```bash
sudo chown -R opc:opc /home/opc/browsershield
sudo chmod -R 755 /home/opc/browsershield
```

### Lỗi port đã được sử dụng
```bash
# Kill process sử dụng port 5000
sudo fuser -k 5000/tcp
sudo systemctl restart browsershield.service
```

### Lỗi Node.js module not found
```bash
cd /home/opc/browsershield
rm -rf node_modules package-lock.json
npm install
sudo systemctl restart browsershield.service
```

### Check Oracle Cloud Security List
1. Vào Oracle Cloud Console
2. Virtual Cloud Networks > Security Lists
3. Thêm Ingress Rule: TCP, Port 5000, Source 0.0.0.0/0

## Backup và Restore

### Backup
```bash
# Backup profiles data
tar -czf browsershield-backup-$(date +%Y%m%d).tar.gz /home/opc/browsershield

# Backup service file
sudo cp /etc/systemd/system/browsershield.service ~/browsershield.service.backup
```

### Restore
```bash
# Restore files
tar -xzf browsershield-backup-*.tar.gz -C /

# Restore service
sudo cp ~/browsershield.service.backup /etc/systemd/system/browsershield.service
sudo systemctl daemon-reload
```