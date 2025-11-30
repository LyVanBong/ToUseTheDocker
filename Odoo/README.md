# Odoo

Odoo is a suite of open source business apps that cover all your company needs: CRM, eCommerce, accounting, inventory, point of sale, project management, etc.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your domain (`ODOO_HOST`) and secrets.

## Usage

Start the service:

```bash
make up service=odoo
```

## Access

- **Web UI**: `https://<ODOO_HOST>` (managed by Traefik)

## Volumes

- `db_data`: Database data
