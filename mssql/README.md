# Microsoft SQL Server

Microsoft SQL Server is a relational database management system developed by Microsoft.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your secrets (especially `SA_PASSWORD`).

## Usage

Start the service:

```bash
make up service=mssql
```

## Access

- **Port**: 1433

## Volumes

- `mssql_data`: Database data
