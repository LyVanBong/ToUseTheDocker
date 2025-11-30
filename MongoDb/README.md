# MongoDB

MongoDB is a general purpose, document-based, distributed database built for modern application developers and for the cloud era.

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
make up service=mongodb
```

## Access

- **MongoDB**: `localhost:27017`
- **Mongo Express**: http://localhost:8081

## Volumes

- `mongo_data`: Database data
