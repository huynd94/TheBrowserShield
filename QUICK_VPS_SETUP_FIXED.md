# Hướng Dẫn Cài Đặt BrowserShield VPS (Phiên Bản Sửa Lỗi)

## Cài Đặt Nhanh VPS Manager

### Bước 1: Tải và Cài Đặt VPS Manager
```bash
# Tải script quản lý VPS (phiên bản sửa lỗi)
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager-fixed.sh -o vps-manager.sh

# Cấp quyền thực thi
chmod +x vps-manager.sh

# Hiển thị menu
./vps-manager.sh
```

### Bước 2: Cài Đặt BrowserShield
```bash
# Cài đặt hoàn chỉnh với Production Mode
./vps-manager.sh deploy
```

## Lệnh Quản Lý Hệ Thống

### Kiểm Tra Trạng Thái
```bash
./vps-manager.sh status      # Trạng thái hệ thống
./vps-manager.sh health      # Kiểm tra sức khỏe
./vps-manager.sh logs        # Xem logs real-time
```

### Quản Lý Service
```bash
./vps-manager.sh start       # Khởi động service
./vps-manager.sh stop        # Dừng service  
./vps-manager.sh restart     # Khởi động lại
```

### Bảo Trì Hệ Thống
```bash
./vps-manager.sh update      # Cập nhật phiên bản mới
./vps-manager.sh configure   # Cấu hình production
./vps-manager.sh backup      # Tạo backup thủ công
```

### Gỡ Cài Đặt An Toàn
```bash
./vps-manager.sh uninstall   # Menu gỡ cài đặt với các tùy chọn:
                            # 1. Xem trước (an toàn)
                            # 2. Gỡ cài đặt hoàn chỉnh
                            # 3. Gỡ cài đặt force
                            # 4. Hủy bỏ
```

## Cải Tiến Trong Phiên Bản Sửa Lỗi

### ✅ Sửa Lỗi Chính
- **Xử lý lỗi tốt hơn**: Thêm kiểm tra lỗi chi tiết
- **Timeout cải tiến**: Tăng thời gian chờ cho kết nối mạng
- **Kiểm tra quyền**: Đảm bảo chạy với user đúng (opc)
- **Tương thích Oracle Linux 9**: Tối ưu cho hệ thống Oracle

### ✅ Tính Năng Mới
- **Logging cải tiến**: Messages rõ ràng hơn với timestamp
- **Kiểm tra system**: Xác thực hệ thống trước khi chạy
- **Error recovery**: Xử lý lỗi graceful và recovery
- **Better status display**: Hiển thị trạng thái chi tiết hơn

### ✅ Bảo Mật Cải Tiến
- **Input validation**: Kiểm tra đầu vào nghiêm ngặt
- **Safe defaults**: Mặc định an toàn cho tất cả operations
- **Permission checks**: Kiểm tra quyền trước khi thực hiện
- **Network timeouts**: Timeout cho tất cả network calls

## URL Truy Cập Sau Khi Cài Đặt

```
Web Interface: http://YOUR_VPS_IP:5000
Admin Panel: http://YOUR_VPS_IP:5000/admin  
Mode Manager: http://YOUR_VPS_IP:5000/mode-manager
API Health: http://YOUR_VPS_IP:5000/health
```

## Khắc Phục Sự Cố

### Lỗi Quyền
```bash
# Đảm bảo chạy với user opc (không phải root)
whoami  # Phải hiển thị 'opc'

# Nếu đang ở root, chuyển sang opc
su - opc
```

### Lỗi Network  
```bash
# Kiểm tra kết nối internet
ping -c 3 8.8.8.8

# Kiểm tra port 5000
sudo netstat -tlnp | grep :5000
```

### Lỗi Service
```bash
# Kiểm tra status service
sudo systemctl status browsershield

# Xem logs chi tiết
sudo journalctl -u browsershield -f
```

## Backup và Recovery

### Tạo Backup
```bash
./vps-manager.sh backup
# Backup sẽ được lưu tại: /home/opc/backups/
```

### Restore Backup
```bash
# List backups
ls -la /home/opc/backups/

# Restore specific backup
cd /home/opc
tar -xzf backups/browsershield_manual_YYYYMMDD_HHMMSS.tar.gz
```

## Liên Hệ Hỗ Trợ

Nếu gặp vấn đề:
1. Chạy `./vps-manager.sh status` để kiểm tra trạng thái
2. Chạy `./vps-manager.sh health` để kiểm tra sức khỏe hệ thống  
3. Xem logs: `./vps-manager.sh logs`
4. Gửi thông tin lỗi để được hỗ trợ