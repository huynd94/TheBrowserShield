# VPS Emergency Fix - BrowserShield

## Lỗi: "BrowserServiceClass is not a constructor"

### Giải pháp cuối cùng - Script hoàn chỉnh:

```bash
# Tải script sửa lỗi hoàn chỉnh v2.0
cd /home/opc/browsershield
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-vps-complete.sh -o fix-vps-complete.sh
chmod +x fix-vps-complete.sh

# Chạy script (tự động tải code mới từ GitHub)
./fix-vps-complete.sh
```

### Script v2.0 sẽ thực hiện:

1. **Dừng toàn bộ service** và kill process cũ
2. **Backup** installation hiện tại 
3. **Tải code mới** từ GitHub với fix "BrowserServiceClass" 
4. **Cài đặt Node.js 20** chính xác
5. **Xóa và cài lại dependencies** với version cụ thể
6. **Tạo data structure** đầy đủ
7. **Sửa permissions** cho Oracle Linux
8. **Test syntax** server.js
9. **Cập nhật SystemD** với config tối ưu
10. **Start service** với monitoring

### Nếu vẫn lỗi, kiểm tra:

```bash
# Xem logs chi tiết
sudo journalctl -u browsershield -f

# Test chạy manual
cd /home/opc/browsershield
node server.js

# Kiểm tra port
sudo netstat -tlnp | grep 5000
```

### URL Scripts:
- **Fix hoàn chỉnh v2.0**: `https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/fix-vps-complete.sh`
- **Update system**: `https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh`

Script v2.0 này đã sửa lỗi "BrowserServiceClass is not a constructor" và tương thích hoàn toàn với Oracle Linux 9 VPS.