# Netdata - Giám sát Hạ tầng Toàn diện (Production Ready)

## 1. Giới thiệu
Netdata là hệ thống giám sát sức khỏe máy chủ (Health Monitoring) thời gian thực với độ chi tiết cao (per-second).
-   **Zero configs**: Tự động phát hiện dịch vụ (MySQL, Nginx, Docker...) để giám sát.
-   **Cảnh báo**: Tích hợp gửi cảnh báo qua Telegram, Slack, Email.

## 2. Hướng dẫn Triển khai

### Lưu ý quan trọng về Mạng
Netdata cần chạy ở chế độ `network_mode: host` để có thể đọc được chính xác thông số Network Interface của máy chủ vật lý.
-   Điều này có nghĩa là port `19999` sẽ mở trực tiếp trên máy chủ.
-   Cần dùng Firewall (UFW/IPTables) hoặc Security Group (AWS/GCP) để chặn truy cập port 19999 từ bên ngoài nếu không qua VPN/Proxy.

### Bước 1: Cấu hình
```bash
cp .env.example .env
```
Nếu bạn muốn dùng **Netdata Cloud** (xem dashboard tập trung nhiều server miễn phí):
1.  Đăng ký tài khoản tại [netdata.cloud](https://app.netdata.cloud/).
2.  Lấy `Connect Node` command (có chứa token).
3.  Dán Token vào biến `NETDATA_CLAIM_TOKEN` trong file `.env`.

### Bước 2: Khởi động
```bash
docker-compose up -d
```

---

## 3. Bảo mật & Vận hành (Production Guide)

### Bảo vệ Dashboard
Netdata bản Open Source Community mặc định **không có mật khẩu**. Bất kỳ ai biết IP:19999 đều xem được thông tin hệ thống.

**Giải pháp 1: Dùng Netdata Cloud (Khuyên dùng)**
-   Kết nối server với Netdata Cloud qua Claim Token.
-   Chặn port 19999 từ Internet (chỉ cho phép localhost).
-   Xem dashboard thông qua app.netdata.cloud (đã có bảo mật account).

**Giải pháp 2: Nginx Basic Auth**
Nếu tự host, hãy dùng Nginx để thêm mật khẩu:

```nginx
server {
    server_name monitor.yourdomain.com;
    
    # ... SSL Cert ...

    location / {
        proxy_pass http://localhost:19999;
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

### Resource Usage
Netdata thu thập hàng nghìn metrics mỗi giây nên có thể tốn tài nguyên.
-   Trong `docker-compose.yml`, tôi đã giới hạn **2GB RAM** để tránh trường hợp Netdata lưu history quá dài gây tràn RAM server.
-   Nếu server yếu, hãy giảm `history` trong cấu hình Netdata (`netdata.conf`).

### Cập nhật
Netdata ra version mới rất thường xuyên.
```bash
docker-compose pull
docker-compose up -d
```
Service sẽ tự động update các collector mới nhất mà không mất dữ liệu lịch sử (do đã mount volume `netdatalib`).
