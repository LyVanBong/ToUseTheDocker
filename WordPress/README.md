# WordPress

WordPress is the world's most popular content management system.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your secrets.

## Usage

Start the service:

```bash
make up service=wordpress
```

## Access

- **WordPress**: http://localhost:8000 (or your configured port)

## Volumes

- `db_data`: MySQL data
- `wordpress_data`: WordPress files
