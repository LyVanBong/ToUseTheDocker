# Dozzle - Giám sát Log Realtime (Production Ready)

## 1. Giới thiệu
Dozzle là công cụ xem log Docker container theo thời gian thực (Real-time) cực nhẹ, không lưu trữ log vào database nên không tốn dung lượng ổ cứng.
-   **An toàn**: Chỉ đọc (`read-only`), không thể can thiệp hệ thống.
-   **Nhanh**: Giao diện React mượt mà, hỗ trợ search/filter log.

## 2. Hướng dẫn Triển khai

### Bước 1: Cấu hình Bảo mật
Việc xem log có thể lộ thông tin nhạy cảm. **Bắt buộc** phải đặt mật khẩu.
```bash
cp .env.example .env
nano .env
```
Điền thông tin:
```ini
DOZZLE_USERNAME=admin
DOZZLE_PASSWORD=Mat_Khau_Sieu_Kho_Nhe_123!
```

### Bước 2: Khởi động
```bash
docker-compose up -d
```

---

## 3. Bảo mật & Vận hành (Production Guide)

### Cơ chế An toàn (Hardening)
File `docker-compose.yml` đã được cấu hình tối ưu:
1.  **Read-Only Socket**: `- /var/run/docker.sock:/var/run/docker.sock:ro`. Kể cả Dozzle bị hack, kẻ tấn công cũng không thể ra lệnh cho Docker (tạo/xóa container).
2.  **No New Privileges**: Ngăn chặn leo thang quyền root.
3.  **Low Resource**: Giới hạn chỉ 128MB RAM (Dozzle viết bằng Go nên rất nhẹ).

### HTTPS Proxy (Khuyên dùng)
Dozzle hỗ trợ Basic Auth nội bộ, nhưng tốt nhất vẫn nên đi qua Nginx SSL.

**Ví dụ Nginx Config:**
```nginx
server {
    server_name logs.yourdomain.com;
    
    # ... SSL Cert configurations ...

    location / {
        proxy_pass http://localhost:8888;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
    }
}
```

### Khắc phục sự cố
-   **Không thấy container nào?**: Kiểm tra xem user chạy Docker có quyền truy cập `docker.sock` không (thường là root hoặc user trong group `docker`).
-   **Log bị trôi quá nhanh?**: Dozzle chỉ hiển thị log realtime và một phần log cũ (tail). Nó không thay thế được các hệ thống logging tập trung (như ELK stack) nếu bạn cần lưu log 30 ngày. Dozzle dùng để debug nóng (hot debug).
