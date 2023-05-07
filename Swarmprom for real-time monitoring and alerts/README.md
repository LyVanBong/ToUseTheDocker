# Swarmprom for real-time monitoring and alerts

Swarmprom for real-time monitoring and alerts
This article lives in:

Medium
GitHub
DockerSwarm.rocks
Intro
Let's say you already set up a Docker Swarm mode cluster, with a Traefik HTTPS proxy.

Here's how you can set up Swarmprom to monitor your cluster.

It will allow you to:

Monitor CPU, disk, memory usage, etc.
Monitor it all per node, per service, per container, etc.
Have a nice, interactive, real-time dashboard with all the data nicely plotted.
Trigger alerts (for example, in Slack, Rocket.chat, etc) when your services/nodes pass certain thresholds.
And more...
Swarmprom is actually just a set of tools pre-configured in a smart way for a Docker Swarm cluster.

It includes:

Prometheus
Grafana
cAdvisor
Node Exporter
Alert Manager
Unsee
Here's how it looks like:



Instructions
Clone Swarmprom repository and enter into the directory:

$ git clone https://github.com/stefanprodan/swarmprom.git
$ cd swarmprom
Set and export an ADMIN_USER environment variable:

export ADMIN_USER=admin
Set and export an ADMIN_PASSWORD environment variable:

export ADMIN_PASSWORD=changethis
Set and export a hashed version of the ADMIN_PASSWORD using openssl, it will be used by Traefik's HTTP Basic Auth for most of the services:

export HASHED_PASSWORD=$(openssl passwd -apr1 $ADMIN_PASSWORD)
(Optional): Alternatively, if you don't want to put the password in an environment variable, you could type it interactively, e.g.:


$ export HASHED_PASSWORD=$(openssl passwd -apr1)
Password: $ enter your password here
Verifying - Password: $ re enter your password here
You can check the contents with:

echo $HASHED_PASSWORD
it will look like:


$apr1$89eqM5Ro$CxaFELthUKV21DpI3UTQO.
Create and export an environment variable DOMAIN, e.g.:

export DOMAIN=example.com
and make sure that the following sub-domains point to your Docker Swarm cluster IPs:

grafana.example.com
alertmanager.example.com
unsee.example.com
prometheus.example.com
(and replace example.com with your actual domain).

Note: You can also use a subdomain, like swarmprom.example.com. Just make sure that the subdomains point to (at least one of) your cluster IPs. Or set up a wildcard subdomain (*).

If you are using Slack and want to integrate it, set the following environment variables:

export SLACK_URL=https://hooks.slack.com/services/TOKEN
export SLACK_CHANNEL=devops-alerts
export SLACK_USER=alertmanager
Note: by using export when declaring all the environment variables above, the next command will be able to use them.

Create the Docker Compose file
Download the file swarmprom.yml:

curl -L dockerswarm.rocks/swarmprom.yml -o swarmprom.yml
...or create it manually, for example, using nano:

nano swarmprom.yml
And copy the contents inside:

version: "3.3"

networks:
  net:
    driver: overlay
    attachable: true
  traefik-public:
    external: true

volumes:
    prometheus: {}
    grafana: {}
    alertmanager: {}

configs:
  dockerd_config:
    file: ./dockerd-exporter/Caddyfile
  node_rules:
    file: ./prometheus/rules/swarm_node.rules.yml
  task_rules:
    file: ./prometheus/rules/swarm_task.rules.yml

services:
  dockerd-exporter:
    image: stefanprodan/caddy
    networks:
      - net
    environment:
      - DOCKER_GWBRIDGE_IP=172.18.0.1
    configs:
      - source: dockerd_config
        target: /etc/caddy/Caddyfile
    deploy:
      mode: global
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  cadvisor:
    image: google/cadvisor
    networks:
      - net
    command: -logtostderr -docker_only
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /:/rootfs:ro
      - /var/run:/var/run
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    deploy:
      mode: global
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  grafana:
    image: stefanprodan/swarmprom-grafana:5.3.4
    networks:
      - default
      - net
      - traefik-public
    environment:
      - GF_SECURITY_ADMIN_USER=${ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
      #- GF_SERVER_ROOT_URL=${GF_SERVER_ROOT_URL:-localhost}
      #- GF_SMTP_ENABLED=${GF_SMTP_ENABLED:-false}
      #- GF_SMTP_FROM_ADDRESS=${GF_SMTP_FROM_ADDRESS:-grafana@test.com}
      #- GF_SMTP_FROM_NAME=${GF_SMTP_FROM_NAME:-Grafana}
      #- GF_SMTP_HOST=${GF_SMTP_HOST:-smtp:25}
      #- GF_SMTP_USER=${GF_SMTP_USER}
      #- GF_SMTP_PASSWORD=${GF_SMTP_PASSWORD}
    volumes:
      - grafana:/var/lib/grafana
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmprom-grafana-http.rule=Host(`grafana.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-grafana-http.entrypoints=http
        - traefik.http.routers.swarmprom-grafana-http.middlewares=https-redirect
        - traefik.http.routers.swarmprom-grafana-https.rule=Host(`grafana.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-grafana-https.entrypoints=https
        - traefik.http.routers.swarmprom-grafana-https.tls=true
        - traefik.http.routers.swarmprom-grafana-https.tls.certresolver=le
        - traefik.http.services.swarmprom-grafana.loadbalancer.server.port=3000

  alertmanager:
    image: stefanprodan/swarmprom-alertmanager:v0.14.0
    networks:
      - default
      - net
      - traefik-public
    environment:
      - SLACK_URL=${SLACK_URL:-https://hooks.slack.com/services/TOKEN}
      - SLACK_CHANNEL=${SLACK_CHANNEL:-general}
      - SLACK_USER=${SLACK_USER:-alertmanager}
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    volumes:
      - alertmanager:/alertmanager
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmprom-alertmanager-http.rule=Host(`alertmanager.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-alertmanager-http.entrypoints=http
        - traefik.http.routers.swarmprom-alertmanager-http.middlewares=https-redirect
        - traefik.http.routers.swarmprom-alertmanager-https.rule=Host(`alertmanager.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-alertmanager-https.entrypoints=https
        - traefik.http.routers.swarmprom-alertmanager-https.tls=true
        - traefik.http.routers.swarmprom-alertmanager-https.tls.certresolver=le
        - traefik.http.services.swarmprom-alertmanager.loadbalancer.server.port=9093
        - traefik.http.middlewares.swarmprom-alertmanager-auth.basicauth.users=${ADMIN_USER?Variable not set}:${HASHED_PASSWORD?Variable not set}
        - traefik.http.routers.swarmprom-alertmanager-https.middlewares=swarmprom-alertmanager-auth

  unsee:
    image: cloudflare/unsee:v0.8.0
    networks:
      - default
      - net
      - traefik-public
    environment:
      - "ALERTMANAGER_URIS=default:http://alertmanager:9093"
    deploy:
      mode: replicated
      replicas: 1
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmprom-unsee-http.rule=Host(`unsee.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-unsee-http.entrypoints=http
        - traefik.http.routers.swarmprom-unsee-http.middlewares=https-redirect
        - traefik.http.routers.swarmprom-unsee-https.rule=Host(`unsee.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-unsee-https.entrypoints=https
        - traefik.http.routers.swarmprom-unsee-https.tls=true
        - traefik.http.routers.swarmprom-unsee-https.tls.certresolver=le
        - traefik.http.services.swarmprom-unsee.loadbalancer.server.port=8080
        - traefik.http.middlewares.swarmprom-unsee-auth.basicauth.users=${ADMIN_USER?Variable not set}:${HASHED_PASSWORD?Variable not set}
        - traefik.http.routers.swarmprom-unsee-https.middlewares=swarmprom-unsee-auth

  node-exporter:
    image: stefanprodan/swarmprom-node-exporter:v0.16.0
    networks:
      - net
    environment:
      - NODE_ID={{.Node.ID}}
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - /etc/hostname:/etc/nodename
    command:
      - '--path.sysfs=/host/sys'
      - '--path.procfs=/host/proc'
      - '--collector.textfile.directory=/etc/node-exporter/'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
      - '--no-collector.ipvs'
    deploy:
      mode: global
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  prometheus:
    image: stefanprodan/swarmprom-prometheus:v2.5.0
    networks:
      - default
      - net
      - traefik-public
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=${PROMETHEUS_RETENTION:-24h}'
    volumes:
      - prometheus:/prometheus
    configs:
      - source: node_rules
        target: /etc/prometheus/swarm_node.rules.yml
      - source: task_rules
        target: /etc/prometheus/swarm_task.rules.yml
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          memory: 2048M
        reservations:
          memory: 128M
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmprom-prometheus-http.rule=Host(`prometheus.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-prometheus-http.entrypoints=http
        - traefik.http.routers.swarmprom-prometheus-http.middlewares=https-redirect
        - traefik.http.routers.swarmprom-prometheus-https.rule=Host(`prometheus.${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmprom-prometheus-https.entrypoints=https
        - traefik.http.routers.swarmprom-prometheus-https.tls=true
        - traefik.http.routers.swarmprom-prometheus-https.tls.certresolver=le
        - traefik.http.services.swarmprom-prometheus.loadbalancer.server.port=9090
        - traefik.http.middlewares.swarmprom-prometheus-auth.basicauth.users=${ADMIN_USER?Variable not set}:${HASHED_PASSWORD?Variable not set}
        - traefik.http.routers.swarmprom-prometheus-https.middlewares=swarmprom-prometheus-auth
Info

This is just a standard Docker Compose file.

It's common to name the file docker-compose.yml or something like docker-compose.swarmprom.yml.

Here it's named just swarmprom.yml for brevity.

Deploy the Traefik version of the stack:

docker stack deploy -c swarmprom.yml swarmprom
To test it, go to each URL:

https://grafana.example.com
https://alertmanager.example.com
https://unsee.example.com
https://prometheus.example.com