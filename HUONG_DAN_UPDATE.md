# 🔄 Hướng Dẫn Cập Nhật BrowserShield

## Cập Nhật Nhanh

### Cách 1: Cập nhật tự động (Khuyến nghị)
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh | bash
```

### Cách 2: Cập nhật từ file local
```bash
cd /home/opc/browsershield/scripts
./update-system.sh
```

## Tính Năng Cập Nhật

✅ **Tự động backup** trước khi cập nhật
✅ **Bảo toàn dữ liệu** (profiles, proxy pool, cấu hình mode)
✅ **Kiểm tra syntax** trước khi khởi động lại
✅ **Khôi phục tự động** khi có lỗi
✅ **Kiểm tra sức khỏe** hệ thống sau cập nhật
✅ **Quản lý service** tự động

## Những Gì Được Cập Nhật

- 📄 Mã nguồn mới nhất từ GitHub
- 📦 Dependencies và packages
- ⚙️ Cấu hình system service
- 📚 Documentation và scripts

## Quy Trình Cập Nhật Chi Tiết

### Bước 1: Backup Tự Động
- Tạo backup với timestamp: `/home/opc/browsershield-backup-YYYYMMDD-HHMMSS`
- Lưu trữ dữ liệu profiles, proxy pool, cấu hình mode
- Backup file môi trường (.env)

### Bước 2: Tải Mã Nguồn Mới
- Clone từ GitHub repository
- Kiểm tra tính toàn vẹn dữ liệu
- Fallback download ZIP nếu Git thất bại

### Bước 3: Cập Nhật Thông Minh
- Dừng service BrowserShield an toàn
- Cập nhật file ứng dụng
- Bảo toàn dữ liệu người dùng và cấu hình
- Cập nhật dependencies
- Kiểm tra syntax trước khi khởi động

### Bước 4: Quản Lý Service
- Cập nhật cấu hình systemd service
- Khởi động lại service tự động
- Thực hiện health checks
- Rollback nếu có lỗi

### Bước 5: Dọn Dẹp & Xác Minh
- Xóa file tạm thời
- Giữ lại 3 backup gần nhất
- Test web interface
- Báo cáo trạng thái cập nhật

## Cập Nhật Thủ Công (Khi Tự Động Thất Bại)

### 1. Dừng service
```bash
sudo systemctl stop browsershield.service
```

### 2. Tạo backup thủ công
```bash
cp -r /home/opc/browsershield /home/opc/browsershield-backup-manual-$(date +%Y%m%d)
```

### 3. Tải mã nguồn mới
```bash
cd /tmp
git clone https://github.com/huynd94/TheBrowserShield.git browsershield-new
```

### 4. Bảo toàn dữ liệu
```bash
cp /home/opc/browsershield/data/* /tmp/browsershield-new/data/
cp /home/opc/browsershield/.env /tmp/browsershield-new/
```

### 5. Thay thế cài đặt
```bash
rm -rf /home/opc/browsershield
mv /tmp/browsershield-new /home/opc/browsershield
cd /home/opc/browsershield
npm install --production
```

### 6. Khởi động service
```bash
sudo systemctl start browsershield.service
```

## Khôi Phục Khi Có Lỗi

### 1. Dừng service hiện tại
```bash
sudo systemctl stop browsershield.service
```

### 2. Khôi phục từ backup
```bash
cd /home/opc
rm -rf browsershield
cp -r browsershield-backup-YYYYMMDD-HHMMSS browsershield
```

### 3. Khởi động lại service
```bash
sudo systemctl start browsershield.service
```

## Kiểm Tra Sau Cập Nhật

### 1. Kiểm tra trạng thái service
```bash
sudo systemctl status browsershield.service
```

### 2. Test web interface
```bash
curl http://localhost:5000/health
```

### 3. Xác minh các tính năng
- Truy cập: http://your-server:5000
- Admin: http://your-server:5000/admin
- Mode Manager: http://your-server:5000/mode-manager

### 4. Xem logs
```bash
sudo journalctl -u browsershield.service -n 20
```

## Cập Nhật Định Kỳ (Tùy Chọn)

### Thiết lập cập nhật tự động hàng tuần
```bash
(crontab -l 2>/dev/null; echo "0 2 * * 1 /home/opc/browsershield/scripts/update-system.sh >> /home/opc/update.log 2>&1") | crontab -
```

### Kiểm tra cập nhật thủ công
```bash
cd /home/opc/browsershield
git fetch origin
git log HEAD..origin/main --oneline
```

## Dọn Dẹp Scripts Cũ

### Xóa các script không sử dụng
```bash
cd /home/opc/browsershield/scripts
./cleanup-unused-scripts.sh
```

### Scripts được giữ lại:
- `update-system.sh` - Script cập nhật hệ thống
- `install-browsershield-fixed-robust.sh` - Script cài đặt chính
- `monitor.sh` - Giám sát hệ thống
- `cleanup-unused-scripts.sh` - Dọn dẹp scripts

## Giám Sát Hệ Thống

### Kiểm tra sức khỏe hệ thống
```bash
cd /home/opc/browsershield/scripts
./monitor.sh
```

### Thông tin hiển thị:
- 📊 Trạng thái service
- 🌐 Sức khỏe ứng dụng
- 💾 Tài nguyên hệ thống
- 📄 Process information
- 📝 Logs gần đây
- 🔗 Quick links

## Xử Lý Sự Cố Thường Gặp

### 1. Git Clone Thất Bại
**Giải pháp**: Kiểm tra kết nối internet và truy cập GitHub
```bash
ping github.com
curl -I https://github.com/huynd94/TheBrowserShield
```

### 2. Permission Denied
**Giải pháp**: Đảm bảo chạy với user opc, không phải root
```bash
whoami  # Phải trả về 'opc'
```

### 3. Port Đã Được Sử Dụng
**Giải pháp**: Kill process cũ
```bash
sudo pkill -f "node server.js"
sudo systemctl restart browsershield.service
```

### 4. NPM Install Thất Bại
**Giải pháp**: Xóa cache và cài đặt lại
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install --production
```

### 5. Service Không Khởi Động
**Giải pháp**: Kiểm tra syntax và logs
```bash
cd /home/opc/browsershield
node -c server.js
sudo journalctl -u browsershield.service -n 50
```

## Khôi Phục Hoàn Toàn

### Khi mọi thứ đều thất bại:
```bash
sudo systemctl stop browsershield.service
cd /home/opc
rm -rf browsershield
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh | bash
```

## Thông Tin Hỗ Trợ

### Khi cần trợ giúp, cung cấp:
- Phiên bản hiện tại
- Thông báo lỗi
- System logs
- Các bước tái tạo lỗi
- Thông tin hệ thống

### Kiểm tra phiên bản hiện tại:
```bash
cd /home/opc/browsershield
grep '"version"' package.json
```

### Lấy logs hệ thống:
```bash
sudo journalctl -u browsershield.service -f
```

---

## 📞 Liên Hệ

- GitHub Repository: https://github.com/huynd94/TheBrowserShield
- Issues: https://github.com/huynd94/TheBrowserShield/issues

## 📅 Lịch Bảo Trì Khuyến Nghị

### Hàng Tuần
- Chạy script cập nhật
- Kiểm tra sức khỏe hệ thống
- Xem logs hoạt động
- Dọn dẹp backup cũ

### Hàng Tháng
- Backup toàn bộ hệ thống
- Đánh giá hiệu suất
- Kiểm tra bảo mật
- Cập nhật documentation