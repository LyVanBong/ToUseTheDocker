# Kafka

Apache Kafka is an open-source distributed event streaming platform used by thousands of companies for high-performance data pipelines, streaming analytics, data integration, and mission-critical applications.

## Prerequisites

- Docker
- Docker Compose

## Configuration

1. Copy `.env.example` to `.env` (optional, defaults are usually fine for dev).
2. Ensure `config.yaml` exists for Kowl (Kafka UI).

## Usage

Start the service:

```bash
make up service=kafka
```

## Access

- **Kafka Broker**: `localhost:9092`
- **Kowl (UI)**: http://localhost:8888
