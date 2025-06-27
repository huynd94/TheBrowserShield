# Giải Pháp Lỗi Oracle Linux 9 - BrowserShield

## 🚨 Lỗi Bạn Đang Gặp

Từ ảnh chụp màn hình, lỗi chính là:
```
Error: Unable to find a match: htop
```

## ✅ Giải Pháp Hoàn Chỉnh

### Bước 1: Sửa Lỗi Packages Ngay Lập Tức
```bash
# Trên VPS Oracle Linux 9 của bạn
ssh opc@YOUR_VPS_IP

# Chạy script sửa lỗi packages
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-oracle-linux-packages.sh | sudo bash
```

### Bước 2: Cài Đặt BrowserShield Với Script Đã Sửa
```bash
# Cài đặt với script đã khắc phục lỗi Oracle Linux 9
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-oracle-fixed.sh | sudo bash
```

### Bước 3: Kiểm Tra Kết Quả
```bash
# Kiểm tra service
sudo systemctl status browsershield

# Kiểm tra port
sudo netstat -tlnp | grep 5000

# Truy cập web interface
# http://VPS_IP_CUA_BAN:5000
```

## 🔧 Scripts Đã Tạo Để Sửa Lỗi

### 1. `fix-oracle-linux-packages.sh`
- Tự động kích hoạt EPEL repository
- Bỏ qua htop nếu không có sẵn
- Cài Chrome/Chromium, Node.js
- Xử lý tất cả vấn đề packages

### 2. `install-browsershield-oracle-fixed.sh`
- Script cài đặt chuyên biệt cho Oracle Linux 9
- Graceful handling của missing packages
- Tự động fallback Chrome → Chromium
- Timeout tăng cho VPS chậm

### 3. `uninstall-oracle-linux-fixed.sh`
- Gỡ cài đặt an toàn với dry-run mode
- Xử lý packages không tồn tại
- Backup tự động trước khi xóa

## 🎯 Cách Sử Dụng Trên VPS

### Nếu Muốn Test Trước (An Toàn)
```bash
# Preview những gì sẽ được cài/gỡ
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-oracle-linux-fixed.sh | bash -s -- --dry-run
```

### Nếu Muốn Gỡ Cài Đặt Cũ
```bash
# Gỡ cài đặt có vấn đề
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/uninstall-oracle-linux-fixed.sh | bash
```

### Cài Đặt Mới Với Script Đã Sửa
```bash
# Cài đặt phiên bản đã sửa lỗi
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-oracle-fixed.sh | sudo bash
```

## 🔍 Các Lỗi Đã Được Sửa

### ✅ Package Issues
- **htop không có**: Bỏ qua hoặc cài từ EPEL
- **Repository missing**: Tự động thêm EPEL
- **Chrome install fail**: Fallback sang Chromium

### ✅ Permission Issues  
- **User validation**: Kiểm tra opc vs root
- **File permissions**: Tự động chmod/chown
- **Service permissions**: Systemd configuration

### ✅ Network Issues
- **Timeout tăng**: 300s cho VPS chậm  
- **Retry logic**: Tự động thử lại khi fail
- **Fallback options**: Multiple download sources

## 🎉 Kết Quả Mong Đợi

Sau khi chạy script sửa lỗi:
```
✓ Node.js: v20.x.x
✓ Chrome/Chromium: Installed
✓ BrowserShield Service: Running
✓ Port 5000: Open
✓ Web Interface: http://YOUR_VPS_IP:5000
```

## 📞 Nếu Vẫn Gặp Lỗi

1. **Kiểm tra logs**:
   ```bash
   sudo journalctl -u browsershield -f
   ```

2. **Chạy validation**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/validation-suite.sh | bash
   ```

3. **Dry-run test**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-uninstall-suite.sh | bash -s -- --dry-run validate
   ```

---

**Tóm tắt**: Scripts đã được sửa chuyên biệt cho Oracle Linux 9, khắc phục hoàn toàn lỗi htop và các vấn đề packages. Chạy lệnh trên để cài đặt thành công.