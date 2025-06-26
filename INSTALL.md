# 🚀 BrowserShield - Hướng Dẫn Cài Đặt & Cập Nhật

## Cài Đặt Mới (Oracle Linux 9)

### Cách 1: Cài đặt tự động (Khuyến nghị)
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh | bash
```

### Cách 2: Cài đặt thủ công
```bash
wget https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh
chmod +x install-browsershield-fixed-robust.sh
./install-browsershield-fixed-robust.sh
```

## 🔄 Cập Nhật Hệ Thống

### Cập nhật nhanh
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh | bash
```

### Dọn dẹp scripts cũ
```bash
cd /home/opc/browsershield/scripts
./cleanup-unused-scripts.sh
```

### Giám sát hệ thống
```bash
cd /home/opc/browsershield/scripts
./monitor.sh
```

## 📋 Sau Khi Cài Đặt

### Truy cập ứng dụng:
- **Trang chủ**: http://your-server:5000
- **Admin Panel**: http://your-server:5000/admin
- **Mode Manager**: http://your-server:5000/mode-manager

### Kiểm tra service:
```bash
sudo systemctl status browsershield.service
```

### Xem logs:
```bash
sudo journalctl -u browsershield.service -f
```

## 🛠️ Quản Lý Service

```bash
# Khởi động
sudo systemctl start browsershield.service

# Dừng
sudo systemctl stop browsershield.service

# Khởi động lại
sudo systemctl restart browsershield.service

# Kiểm tra trạng thái
sudo systemctl status browsershield.service
```

## ⚙️ Chế Độ Hoạt Động

### Mock Mode (Mặc định)
- Dùng cho demo và testing
- Không cần cài đặt trình duyệt thật
- An toàn và nhanh chóng

### Production Mode (Chrome)
- Trình duyệt automation thật
- Cần cài đặt Chromium:
```bash
sudo dnf install -y epel-release chromium
```

### Firefox Mode
- Automation với Firefox
- Cần cài đặt Firefox:
```bash
sudo dnf install -y firefox
```

## 🔧 Xử Lý Sự Cố

### Service không khởi động:
```bash
# Kiểm tra logs
sudo journalctl -u browsershield.service -n 20

# Kiểm tra syntax
cd /home/opc/browsershield
node -c server.js
```

### Port bị chiếm:
```bash
# Kill process cũ
sudo pkill -f "node server.js"
sudo systemctl restart browsershield.service
```

### Khôi phục từ backup:
```bash
cd /home/opc
sudo systemctl stop browsershield.service
rm -rf browsershield
cp -r browsershield-backup-YYYYMMDD-HHMMSS browsershield
sudo systemctl start browsershield.service
```

## 📞 Hỗ Trợ

- **GitHub**: https://github.com/huynd94/TheBrowserShield
- **Issues**: https://github.com/huynd94/TheBrowserShield/issues
- **Documentation**: Xem các file MD trong project

## 📅 Bảo Trì Định Kỳ

### Hàng tuần:
- Chạy script cập nhật
- Kiểm tra logs hệ thống
- Dọn dẹp backup cũ

### Hàng tháng:
- Backup toàn bộ hệ thống
- Đánh giá hiệu suất
- Cập nhật documentation