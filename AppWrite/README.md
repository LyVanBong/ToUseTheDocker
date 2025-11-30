# AppWrite

Appwrite is a secure end-to-end backend server for Web, Mobile, and Flutter developers that is packaged as a set of Docker containers for easy deployment.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your secrets (especially `_APP_OPENSSL_KEY_V1`, `_APP_EXECUTOR_SECRET`, and DB passwords).

## Usage

Start the service:

```bash
docker compose up -d
```

Or using the root Makefile:

```bash
make up service=appwrite
```

## Access

- **Appwrite Console**: http://localhost (or your configured domain)
- **API**: http://localhost/v1

## Volumes

Persistent data is stored in the following volumes:
- `appwrite-mariadb`
- `appwrite-redis`
- `appwrite-cache`
- `appwrite-uploads`
- `appwrite-certificates`
- `appwrite-functions`
- `appwrite-builds`
- `appwrite-influxdb`
- `appwrite-config`
- `appwrite-executor`
