# Quick VPS Setup Guide - Oracle Linux 9 (FIXED)

## Lỗi Thường Gặp và Giải Pháp

### Lỗi "Unable to find a match: htop"
**Nguyên nhân**: Oracle Linux 9 không có htop package trong repository mặc định

**Giải pháp**: Script đã được sửa để bỏ qua htop hoặc cài từ EPEL repository

## Cài Đặt Nhanh (Đã Sửa Lỗi)

### Bước 1: Tải Script Cài Đặt Mới
```bash
# Đăng nhập VPS Oracle Linux 9
ssh opc@YOUR_VPS_IP

# Tải script đã sửa lỗi
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-oracle-fixed.sh -o install-fixed.sh

# Phân quyền thực thi
chmod +x install-fixed.sh
```

### Bước 2: Chạy Script Sửa Lỗi Packages
```bash
# Sửa lỗi packages trước (chạy với sudo)
sudo curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-oracle-linux-packages.sh | bash

# Hoặc tải về và chạy
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-oracle-linux-packages.sh -o fix-packages.sh
chmod +x fix-packages.sh
sudo ./fix-packages.sh
```

### Bước 3: Cài Đặt BrowserShield
```bash
# Chạy script cài đặt đã sửa lỗi
sudo ./install-fixed.sh
```

## Lệnh Cài Đặt 1 Dòng (Đã Sửa Lỗi)

```bash
# Cài đặt hoàn toàn tự động
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-oracle-fixed.sh | sudo bash
```

## Khắc Phục Lỗi Cụ Thể

### 1. Sửa Lỗi EPEL Repository
```bash
# Kích hoạt EPEL repository
sudo dnf install -y epel-release
sudo dnf clean all
sudo dnf makecache
```

### 2. Cài Đặt htop Thủ Công
```bash
# Cài htop từ EPEL
sudo dnf install -y htop

# Nếu vẫn lỗi, bỏ qua htop
echo "htop not critical for BrowserShield operation"
```

### 3. Cài Đặt Chrome/Chromium
```bash
# Thêm Google Chrome repository
sudo tee /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Cài đặt Chrome
sudo dnf install -y google-chrome-stable

# Hoặc cài Chromium thay thế
sudo dnf install -y chromium
```

### 4. Cài Đặt Node.js
```bash
# Cài Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs
```

## Kiểm Tra Cài Đặt

### Xác Minh Packages
```bash
# Kiểm tra các package chính
node --version
npm --version
google-chrome --version || chromium-browser --version
```

### Kiểm Tra Service
```bash
# Trạng thái service
sudo systemctl status browsershield

# Xem logs
sudo journalctl -u browsershield -f

# Kiểm tra port
sudo netstat -tlnp | grep 5000
```

## Troubleshooting

### Nếu Vẫn Gặp Lỗi Packages
```bash
# Update hệ thống
sudo dnf update -y

# Xóa cache và rebuild
sudo dnf clean all
sudo dnf makecache

# Kiểm tra repositories
sudo dnf repolist
```

### Nếu Service Không Khởi Động
```bash
# Kiểm tra lỗi chi tiết
sudo journalctl -u browsershield --no-pager

# Khởi động thủ công
cd /home/opc/browsershield
node server.js

# Kiểm tra firewall
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

## VPS Manager Đã Sửa Lỗi

### Sử Dụng VPS Manager
```bash
# Tải VPS Manager đã sửa lỗi
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager-fixed.sh -o vps-manager.sh
chmod +x vps-manager.sh

# Chạy các lệnh
sudo ./vps-manager.sh deploy    # Cài đặt
sudo ./vps-manager.sh status    # Kiểm tra trạng thái
sudo ./vps-manager.sh logs      # Xem logs
sudo ./vps-manager.sh restart   # Khởi động lại
```

## Các Tính Năng Đã Sửa

### ✅ Package Installation
- Bỏ qua htop nếu không có
- Tự động cài EPEL repository
- Fallback từ Chrome sang Chromium

### ✅ Error Handling
- Graceful handling của missing packages
- Timeout tăng cho VPS chậm
- Retry logic cho network operations

### ✅ Oracle Linux 9 Specific
- Optimized cho Oracle Linux 9
- Xử lý permission issues
- Repository configuration fixes

## Liên Hệ Support

Nếu vẫn gặp vấn đề:
1. Kiểm tra logs: `sudo journalctl -u browsershield`
2. Chạy script validation: `./scripts/validation-suite.sh`
3. Sử dụng dry-run mode: `./scripts/vps-uninstall-suite.sh --dry-run validate`

---

**Script Version**: Fixed for Oracle Linux 9  
**Last Updated**: June 27, 2025  
**Compatibility**: Oracle Linux 9, RHEL 8+