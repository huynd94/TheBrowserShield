# VPS Service Fix Guide - BrowserShield

## Lỗi hiện tại
Service BrowserShield bị crash do lỗi Node.js module không tìm thấy.

## Giải pháp nhanh

### Bước 1: Tải script sửa lỗi
```bash
cd /home/opc/browsershield
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-vps-service.sh -o fix-vps-service.sh
chmod +x fix-vps-service.sh
```

### Bước 2: Chạy script sửa lỗi
```bash
./fix-vps-service.sh
```

### Bước 3: Kiểm tra trạng thái
```bash
sudo systemctl status browsershield
curl http://localhost:5000/health
```

## Script tự động thực hiện:

1. **Dừng service** để tránh xung đột
2. **Cài đặt Node.js 20** nếu cần thiết
3. **Xóa và cài lại node_modules** để sửa lỗi dependency
4. **Tạo thư mục data** và file cấu hình cần thiết
5. **Sửa quyền file** cho user opc
6. **Kiểm tra syntax** server.js
7. **Cập nhật SystemD service** với cấu hình đúng
8. **Khởi động lại service** và kiểm tra trạng thái

## Nếu vẫn lỗi:

### Kiểm tra logs chi tiết:
```bash
sudo journalctl -u browsershield -f
```

### Kiểm tra port 5000:
```bash
sudo netstat -tlnp | grep 5000
```

### Test chạy manual:
```bash
cd /home/opc/browsershield
node server.js
```

## URL Script Update:
- **Script sửa lỗi**: `https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-vps-service.sh`
- **Script update tổng thể**: `https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh`

## Sau khi sửa xong:
- Truy cập: `http://[VPS-IP]:5000`
- Admin panel: `http://[VPS-IP]:5000/admin`
- Mode manager: `http://[VPS-IP]:5000/mode-manager`