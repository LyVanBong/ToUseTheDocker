# Swarmprom

Swarmprom is a starter kit for Docker Swarm monitoring with Prometheus, Grafana, cAdvisor, Node Exporter, Alert Manager and Unsee.

## Installation

Since Swarmprom requires specific configuration files for Prometheus and Caddy, it is recommended to clone the official repository or the specific fork you are using.

```bash
git clone https://github.com/stefanprodan/swarmprom.git
cd swarmprom
```

## Configuration

1. Create an `.env` file with the following variables:
    ```bash
    ADMIN_USER=admin
    ADMIN_PASSWORD=admin
    SLACK_URL=https://hooks.slack.com/services/TOKEN
    SLACK_CHANNEL=devops-alerts
    SLACK_USER=alertmanager
    ```

## Usage

Deploy the stack:

```bash
docker stack deploy -c docker-compose.yml mon
```