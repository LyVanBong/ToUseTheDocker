# Matomo Analytics (Secure Production Ready)

Đây là tài liệu triển khai Matomo Analytics chuẩn **Secure Production**, sử dụng Docker Compose với các cấu hình bảo mật nâng cao.

## 1. Cấu hình Môi trường

Trước khi chạy, bạn **CẦN** thiết lập các biến môi trường để bảo mật mật khẩu.

1.  Copy file mẫu `.env.example` thành `.env`:
    ```bash
    cp .env.example .env
    ```

2.  Mở file `.env` và thay đổi các giá trị mặc định, đặc biệt là mật khẩu:
    ```ini
    MYSQL_ROOT_PASSWORD=Thay_Mat_Khau_Nay_Rat_Manh_123!
    MYSQL_PASSWORD=Thay_Mat_Khau_Nay_Khac_123!
    MATOMO_PORT=8080
    ```

## 2. Tính năng Bảo mật Đã Kích hoạt

File `docker-compose.yml` này đã được cấu hình sẵn các tính năng bảo mật sau:

*   **Network Isolation**: Sử dụng mạng riêng `matomo-net`.
*   **No New Privileges**: Ngăn chặn leo thang đặc quyền (Root Escalation) bên trong container.
*   **Resource Limits**:
    *   **CPU**: Tối đa 1.0 core.
    *   **Memory**: Tối đa 1GB RAM.
    *   *Lưu ý*: Nếu website của bạn có lượng traffic rất lớn (>100.000 hits/ngày), bạn có thể cần tăng giới hạn này trong `docker-compose.yml`.

## 3. Khởi động Service

```bash
docker-compose up -d
```

Service `app` sẽ đợi database `db` khởi động hoàn tất (Healthy) trước khi chạy.

## 4. Hướng dẫn Production (Quan trọng)

Để chạy thực tế (Production), bạn cần lưu ý thêm:

### HTTPS / SSL
Không bao giờ public cổng 8080 trực tiếp ra Internet. Hãy sử dụng một Reverse Proxy (như Nginx, Apache, Traefik, Caddy) phía trước để:
-   Terminated SSL (HTTPS).
-   Chuyển hướng traffic vào `http://localhost:8080`.

Ví dụ cấu hình Nginx đơn giản:
```nginx
server {
    server_name analytics.yourdomain.com;
    # ... SSL config ...

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Backup Dữ liệu
Dữ liệu quan trọng nằm trong 2 Volumes:
1.  `matomo_db`: Chứa toàn bộ log analytics và cấu hình user.
2.  `matomo_matomo`: Chứa file config `config/config.ini.php` và các plugin cài thêm.

Hãy thiết lập quy trình backup định kỳ cho 2 volume này hoặc dump database MariaDB thường xuyên.

### Cập nhật (Update)
Kéo image mới về và restart:
```bash
docker-compose pull
docker-compose up -d
```
Do chúng ta đã ghim version `5-apache` trong `.env` (hoặc docker-compose), bạn sẽ luôn nhận được các bản vá lỗi (patch) mới nhất của dòng version 5 mà không sợ bị nhảy vọt lên version 6 gây lỗi (breaking changes).
