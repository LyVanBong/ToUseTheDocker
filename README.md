# ToUseTheDocker

Bộ sưu tập chuyên nghiệp các cấu hình Docker Compose cho nhiều dịch vụ khác nhau.

## Danh sách Dịch vụ

| Dịch vụ | Thư mục | Mô tả |
| :--- | :--- | :--- |
| **AppWrite** | `appwrite` | Nền tảng Backend-as-a-Service. |
| **Docker Setup** | `docker-setup` | Các script/cấu hình để cài đặt Docker. |
| **GlusterFS** | `glusterfs` | Hệ thống tệp mạng có khả năng mở rộng. |
| **Kafka** | `kafka` | Nền tảng luồng sự kiện phân tán. |
| **Mautic** | `mautic` | Tự động hóa tiếp thị mã nguồn mở. |
| **MongoDB** | `mongodb` | Cơ sở dữ liệu NoSQL. |
| **MSSQL** | `mssql` | Microsoft SQL Server. |
| **Odoo** | `odoo` | Phần mềm ERP và CRM. |
| **Oracle** | `oracle` | Cơ sở dữ liệu Oracle. |
| **Portainer** | `portainer` | Giao diện quản lý container. |
| **Swarmpit** | `swarmpit` | Quản lý Docker Swarm nhẹ nhàng. |
| **Swarmprom** | `swarmprom` | Giám sát cho Docker Swarm. |
| **Traefik** | `traefik` | Reverse proxy và load balancer hiện đại. |
| **WireGuard** | `wireguard` | VPN hiện đại. |
| **WordPress** | `wordpress` | Hệ thống quản lý nội dung (CMS). |

## Hướng dẫn Sử dụng

Bạn có thể sử dụng `Makefile` đi kèm để quản lý các dịch vụ một cách dễ dàng.

### Yêu cầu tiên quyết

- Docker
- Docker Compose
- Make (tùy chọn, để sử dụng Makefile)

### Khởi chạy một dịch vụ

```bash
make up service=wordpress
```

### Dừng một dịch vụ

```bash
make down service=wordpress
```

### Xem Logs

```bash
make logs service=wordpress
```

## Cấu trúc

Mỗi thư mục dịch vụ bao gồm:
- `docker-compose.yml`: Cấu hình dịch vụ.
- `README.md`: Hướng dẫn cụ thể cho dịch vụ đó.
- `.env.example`: Ví dụ về các biến môi trường.

## Đóng góp

Hoan nghênh các Pull request. Đối với những thay đổi lớn, vui lòng mở issue trước để thảo luận về những gì bạn muốn thay đổi.
