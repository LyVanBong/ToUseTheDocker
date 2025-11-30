# Swarmpit

Swarmpit provides a nice and clean way to manage your Docker Swarm cluster.

## Prerequisites

- Docker Swarm
- Traefik (configured as `traefik-public`)

## Configuration

1. Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
2. Edit `.env` and set your `DOMAIN`.

## Setup Labels

You need to label your nodes to pin the database and influxdb:

```bash
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add swarmpit.db-data=true $NODE_ID
docker node update --label-add swarmpit.influx-data=true $NODE_ID
```

## Usage

Deploy the stack:

```bash
make up service=swarmpit
```
(Note: `make up` uses `docker compose up`, for Swarm you might want `docker stack deploy -c docker-compose.yml swarmpit`)

## Access

- **Web UI**: `https://<DOMAIN>`