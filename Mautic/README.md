# Mautic

Mautic is the world's largest open-source marketing automation project.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your domain (`MAUTIC_HOST`) and secrets.

## Usage

Start the service:

```bash
make up service=mautic
```

## Access

- **Web UI**: `https://<MAUTIC_HOST>` (managed by Traefik)

## Volumes

- `mautic_data`: Mautic files
- `db_data`: Database data
