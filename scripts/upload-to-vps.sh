#!/bin/bash

# Upload BrowserShield từ Replit lên VPS
# Chạy script này từ máy local có quyền truy cập VPS

VPS_IP="138.2.82.254"
VPS_USER="opc"
APP_DIR="/home/opc/browsershield"

echo "Uploading BrowserShield to VPS..."

# Tạo thư mục trên VPS
ssh $VPS_USER@$VPS_IP "mkdir -p $APP_DIR"

# Upload các file chính
scp server.js $VPS_USER@$VPS_IP:$APP_DIR/
scp package.json $VPS_USER@$VPS_IP:$APP_DIR/
scp -r public $VPS_USER@$VPS_IP:$APP_DIR/

# Upload scripts và docs
scp -r scripts $VPS_USER@$VPS_IP:$APP_DIR/
scp deploy-to-vps.md $VPS_USER@$VPS_IP:$APP_DIR/

# Cài đặt và chạy
ssh $VPS_USER@$VPS_IP << 'EOF'
cd /home/opc/browsershield

# Install dependencies
npm install

# Create .env file
cat > .env << 'ENVEOF'
PORT=5000
NODE_ENV=production
API_TOKEN=4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=
BROWSER_MODE=mock
ENVEOF

# Create SystemD service
sudo tee /etc/systemd/system/browsershield.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=BrowserShield Anti-Detect Browser Manager
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

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable browsershield.service
sudo systemctl start browsershield.service

# Configure firewall
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT

echo "Upload completed! Check status:"
sudo systemctl status browsershield.service
EOF

echo "Upload và cài đặt hoàn tất!"
echo "Truy cập: http://$VPS_IP:5000"