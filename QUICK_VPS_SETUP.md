# BrowserShield VPS Oracle Linux 9 - Quick Setup Guide

## Triển khai nhanh (One-Click)

### Script quản lý tổng hợp VPS

```bash
# Tải script quản lý tổng hợp
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager.sh -o vps-manager.sh
chmod +x vps-manager.sh

# Triển khai hoàn chỉnh
./vps-manager.sh deploy
```

### Lệnh triển khai tự động hoàn chỉnh

```bash
# Triển khai BrowserShield với Production Mode (Chrome browser)
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/deploy-oracle-linux-production.sh | bash
```

Script này sẽ tự động:
- ✅ Cài đặt Node.js 20
- ✅ Cài đặt Google Chrome cho browser automation thực
- ✅ Tải và cài đặt BrowserShield
- ✅ Cấu hình Production Mode
- ✅ Thiết lập systemd service
- ✅ Mở firewall port 5000
- ✅ Khởi động service tự động

### Sau khi triển khai

1. **Kiểm tra trạng thái**:
```bash
sudo systemctl status browsershield
```

2. **Xem logs**:
```bash
sudo journalctl -u browsershield -f
```

3. **Truy cập web interface**:
```
http://YOUR_VPS_IP:5000
```

## Cấu hình Oracle Cloud Security

### Mở port trong Oracle Cloud Console

1. **Networking** → **Virtual Cloud Networks**
2. Chọn VCN của bạn → **Security Lists**
3. **Add Ingress Rule**:
   - Source: `0.0.0.0/0`
   - Protocol: TCP
   - Port: `5000`

### Lấy IP public của VPS

```bash
curl -4 icanhazip.com
```

## Quản lý service

### Script quản lý VPS tổng hợp

```bash
# Script quản lý toàn diện
./vps-manager.sh deploy        # Triển khai mới
./vps-manager.sh update        # Cập nhật hệ thống
./vps-manager.sh configure     # Cấu hình production
./vps-manager.sh status        # Trạng thái chi tiết
./vps-manager.sh logs          # Xem logs realtime
./vps-manager.sh restart       # Khởi động lại
./vps-manager.sh backup        # Tạo backup thủ công
./vps-manager.sh monitor       # Health check
./vps-manager.sh uninstall     # Gỡ cài đặt hoàn toàn
./vps-manager.sh help          # Hướng dẫn chi tiết
```

### Script quản lý nhanh (local)

```bash
cd /home/opc/browsershield

# Các lệnh có sẵn
./manage.sh start      # Khởi động
./manage.sh stop       # Dừng
./manage.sh restart    # Khởi động lại
./manage.sh status     # Xem trạng thái
./manage.sh logs       # Xem logs
./manage.sh update     # Cập nhật từ GitHub
```

### Lệnh systemctl

```bash
sudo systemctl start browsershield     # Khởi động
sudo systemctl stop browsershield      # Dừng
sudo systemctl restart browsershield   # Khởi động lại
sudo systemctl status browsershield    # Xem trạng thái
```

## Cập nhật hệ thống

### Cập nhật tự động

```bash
# Tải và chạy script cập nhật
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-update-oracle.sh | bash
```

### Cấu hình production nâng cao

```bash
# Tối ưu cho production environment
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/configure-production-vps.sh | bash
```

## Xử lý sự cố thường gặp

### Service không khởi động

```bash
# Xem lỗi chi tiết
sudo journalctl -u browsershield -n 50

# Kiểm tra syntax
cd /home/opc/browsershield
node -c server.js
```

### Port không truy cập được

```bash
# Kiểm tra port đang chạy
sudo netstat -tlnp | grep 5000

# Kiểm tra firewall local
sudo firewall-cmd --list-all

# Test từ trong VPS
curl http://localhost:5000/health
```

### Chrome không hoạt động

```bash
# Kiểm tra Chrome
google-chrome --version

# Test Chrome headless
google-chrome --headless --disable-gpu --no-sandbox --dump-dom https://www.google.com
```

## Các URL quan trọng

- **Main Interface**: `http://YOUR_VPS_IP:5000`
- **Admin Panel**: `http://YOUR_VPS_IP:5000/admin`
- **Mode Manager**: `http://YOUR_VPS_IP:5000/mode-manager`
- **API Health**: `http://YOUR_VPS_IP:5000/health`

## Kiểm tra Production Mode

```bash
# Xem mode hiện tại
curl http://localhost:5000/api/mode

# Chuyển sang Production Mode (nếu cần)
curl -X POST http://localhost:5000/api/mode/switch \
  -H "Content-Type: application/json" \
  -d '{"mode": "production"}'
```

## Backup và monitoring

Script triển khai đã tự động cấu hình:
- ✅ Backup tự động hàng ngày (2:00 AM)
- ✅ Health check mỗi 5 phút
- ✅ Log rotation tự động
- ✅ Memory monitoring

Logs được lưu tại:
- Service logs: `sudo journalctl -u browsershield -f`
- Monitor logs: `tail -f /var/log/browsershield-monitor.log`
- Backup logs: `tail -f /var/log/browsershield-backup.log`

## Gỡ cài đặt hoàn toàn

### Test gỡ cài đặt an toàn (khuyến nghị)

```bash
# Script test hoàn toàn an toàn - chỉ xem, không xóa gì
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/test-uninstall-safe.sh | bash
```

Script này sẽ:
- ✅ Hiển thị những gì sẽ bị xóa
- ✅ Hoàn toàn an toàn - không xóa gì cả
- ✅ Giúp bạn quyết định có muốn gỡ cài đặt thực sự

### Gỡ cài đặt an toàn với preview

```bash
# Xem trước những gì sẽ bị xóa (an toàn)
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-browsershield-vps.sh | bash -s -- --dry-run

# Gỡ cài đặt với xác nhận
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-browsershield-vps.sh | bash

# Gỡ cài đặt nhanh (bỏ qua xác nhận)
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-browsershield-vps.sh | bash -s -- --force
```

### Gỡ cài đặt qua VPS Manager (khuyến nghị)

```bash
# Sử dụng script quản lý với menu tùy chọn
./vps-manager.sh uninstall
```

Menu sẽ hiển thị:
1. **Preview what would be deleted** (an toàn - chỉ xem)
2. **Complete uninstall with confirmation** (gỡ cài đặt thông thường)
3. **Force uninstall** (gỡ cài đặt nhanh)
4. **Cancel** (hủy bỏ)

### Những gì sẽ bị xóa

Script gỡ cài đặt sẽ xóa:
- ✅ Application files (`/home/opc/browsershield`)
- ✅ Systemd service (`browsershield.service`)
- ✅ Firewall rules (port 5000)
- ✅ Cron jobs (monitoring, backup)
- ✅ Log files và configurations
- ✅ Management scripts
- ✅ Tất cả processes đang chạy

### Tùy chọn bảo tồn

Script sẽ hỏi bạn có muốn xóa:
- Node.js (có thể dùng cho project khác)
- Google Chrome (có thể dùng cho mục đích khác)
- Backup files (để khôi phục sau này)

### Xác minh gỡ cài đặt

```bash
# Kiểm tra service
sudo systemctl status browsershield

# Kiểm tra files
ls -la /home/opc/browsershield

# Kiểm tra port
sudo netstat -tlnp | grep 5000

# Kiểm tra firewall
sudo firewall-cmd --list-ports
```

## Hoàn tất

Sau khi triển khai thành công, bạn có:

✅ **BrowserShield chạy Production Mode** với Chrome browser thực  
✅ **Web interface** accessible từ internet  
✅ **Auto-start** khi VPS reboot  
✅ **Monitoring và backup** tự động  
✅ **Firewall** được cấu hình đúng  

**Access URL**: `http://YOUR_VPS_IP:5000`

Sử dụng Admin Panel để tạo browser profiles và khởi động automation sessions với đầy đủ tính năng thực tế.