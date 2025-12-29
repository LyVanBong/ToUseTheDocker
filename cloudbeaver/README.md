# CloudBeaver - Quản trị Cơ sở Dữ liệu Tập trung (Production Ready)

## 1. Giới thiệu
CloudBeaver là ứng dụng web quản trị cơ sở dữ liệu (Database Manager) mạnh mẽ, mã nguồn mở. Nó hỗ trợ PostgreSQL, MySQL, SQLite, Oracle, SQL Server và nhiều loại DB khác.
-   **An toàn**: Cấu hình kết nối DB được lưu tập trung, không cần chia sẻ password DB cho từng developer.
-   **Tiện lợi**: Truy cập mọi lúc mọi nơi qua trình duyệt.

## 2. Hướng dẫn Triển khai (Deployment)

### Yêu cầu
-   Docker & Docker Compose cài sẵn.
-   Cấu hình biến môi trường.

### Bước 1: Cấu hình Môi trường
Copy file mẫu và chỉnh sửa:
```bash
cp .env.example .env
nano .env
```
Các tham số quan trọng:
-   `CB_PORT`: Cổng truy cập (Mặc định: `8978`).
-   `CB_SERVER_NAME`: Tên hiển thị của server.

### Bước 2: Khởi động
```bash
docker-compose up -d
```
Kiểm tra log để đảm bảo hệ thống start thành công:
```bash
docker-compose logs -f
```

### Bước 3: Cấu hình Ban đầu
1.  Truy cập `http://localhost:8978` (hoặc IP server).
2.  Làm theo Wizard cài đặt:
    -   Tạo tài khoản Administrator (`cbadmin`).
    -   Cấu hình quyền truy cập (Anonymous access: **Nên TẮT** ở môi trường Production).

---

## 3. Bảo mật & Vận hành (Production Guide)

### Cấu hình HTTPS (Reverse Proxy)
Không nên mở trực tiếp port `8978`. Hãy dùng Nginx làm Reverse Proxy với SSL (Let's Encrypt).

**Ví dụ Nginx Config:**
```nginx
server {
    server_name db-manager.yourdomain.com;
    
    # ... SSL Cert configurations ...

    location / {
        proxy_pass http://localhost:8978;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Backup & Restore
Dữ liệu cấu hình (Connection, Users) nằm trong volume `cloudbeaver_data`.
-   **Backup**: Copy thư mục `var/lib/docker/volumes/...` (hoặc đường dẫn mount host nếu bạn đổi config).
-   **Khuyến nghị**: Export configuration từ giao diện nếu có thể, hoặc snapshot máy chủ định kỳ.

### Cập nhật (Update)
```bash
docker-compose pull
docker-compose up -d
```

### Giới hạn Tài nguyên
Trong `docker-compose.yml`, mình đã giới hạn:
-   **RAM**: 1GB (CloudBeaver chạy Java nên khá tốn RAM, 1GB là mức an toàn).
-   **CPU**: 1 Core.
Nếu team bạn đông người dùng đồng thời, hãy tăng `memory` lên 2GB.

## 4. Troubleshooting
-   **Lỗi "Connection refused"**: Kiểm tra lại Firewall của server xem đã mở port chưa (nếu truy cập trực tiếp).
-   **Lỗi "OOM Killed"**: Server hết RAM, container bị kill. Hãy tăng RAM cho server hoặc giới hạn lại trong docker-compose.
