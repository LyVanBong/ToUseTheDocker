# WireGuard (wg-easy)

The easiest way to run WireGuard VPN + Web-based Admin UI.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your `WG_HOST` (public IP/domain) and `PASSWORD`.

## Usage

Start the service:

```bash
make up service=wireguard
```

## Access

- **Admin UI**: `https://<WG_HOST>` (managed by Traefik)
- **VPN Port**: 51820/udp
