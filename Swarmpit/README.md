# Swarmpit web user interface for your Docker Swarm cluster

Swarmpit web user interface for your Docker Swarm cluster
Swarmpit provides a nice and clean way to manage your Docker Swarm cluster.

Follow this guide to integrate it in your Docker Swarm mode cluster deployed as described in DockerSwarm.rocks with a global Traefik HTTPS proxy.

Here's one of the screens:

Swarmpit UI

Preparation
Connect via SSH to a Docker Swarm manager node.

Create an environment variable with the domain where you want to access your Swarmpit instance, e.g.:


export DOMAIN=swarmpit.sys.example.com
Make sure that your DNS records point that domain (e.g. swarmpit.sys.example.com) to one of the IPs of the Docker Swarm mode cluster.

Get the Swarm node ID of this (manager) node and store it in an environment variable:


export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
Create a label in this node, so that the CouchDB database used by Swarmpit is always deployed to the same node and uses the existing volume:

docker node update --label-add swarmpit.db-data=true $NODE_ID
Create another label in this node, so that the Influx database used by Swarmpit is always deployed to the same node and uses the existing volume:

docker node update --label-add swarmpit.influx-data=true $NODE_ID
Create the Docker Compose file
Download the file swarmpit.yml:

curl -L dockerswarm.rocks/swarmpit.yml -o swarmpit.yml
...or create it manually, for example, using nano:

nano swarmpit.yml
And copy the contents inside:

version: '3.3'

services:
  app:
    image: swarmpit/swarmpit:latest
    environment:
      - SWARMPIT_DB=http://db:5984
      - SWARMPIT_INFLUXDB=http://influxdb:8086
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - net
      - traefik-public
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 1024M
        reservations:
          cpus: '0.25'
          memory: 512M
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmpit-http.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmpit-http.entrypoints=http
        - traefik.http.routers.swarmpit-http.middlewares=https-redirect
        - traefik.http.routers.swarmpit-https.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.swarmpit-https.entrypoints=https
        - traefik.http.routers.swarmpit-https.tls=true
        - traefik.http.routers.swarmpit-https.tls.certresolver=le
        - traefik.http.services.swarmpit.loadbalancer.server.port=8080

  db:
    image: couchdb:2.3.0
    volumes:
      - db-data:/opt/couchdb/data
    networks:
      - net
    deploy:
      resources:
        limits:
          cpus: '0.30'
          memory: 512M
        reservations:
          cpus: '0.15'
          memory: 256M
      placement:
        constraints:
          - node.labels.swarmpit.db-data == true
  influxdb:
    image: influxdb:1.7
    volumes:
      - influx-data:/var/lib/influxdb
    networks:
      - net
    deploy:
      resources:
        reservations:
          cpus: '0.3'
          memory: 128M
        limits:
          cpus: '0.6'
          memory: 512M
      placement:
        constraints:
          - node.labels.swarmpit.influx-data == true
  agent:
    image: swarmpit/agent:latest
    environment:
      - DOCKER_API_VERSION=1.35
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - net
    deploy:
      mode: global
      resources:
        limits:
          cpus: '0.10'
          memory: 64M
        reservations:
          cpus: '0.05'
          memory: 32M

networks:
  net:
    driver: overlay
    attachable: true
  traefik-public:
    external: true

volumes:
  db-data:
    driver: local
  influx-data:
    driver: local
Info

This is just a standard Docker Compose file.

It's common to name the file docker-compose.yml or something like docker-compose.swarmpit.yml.

Here it's named just swarmpit.yml for brevity.

Deploy it
Deploy the stack with:


docker stack deploy -c swarmpit.yml swarmpit
It will use the environment variables you created above.

Check it
Check if the stack was deployed with:

docker stack ps swarmpit
It will output something like:


ID             NAME                       IMAGE                      NODE                DESIRED STATE   CURRENT STATE          ERROR   PORT
kkhasdfvce30   swarmpit_agent.ndasdfav5   swarmpit/agent:latest      dog.example.com     Running         Running 3 minutes ago
k8oasdfg70jm   swarmpit_agent.i9asdfjps   swarmpit/agent:latest      cat.example.com     Running         Running 3 minutes ago
kcvasdft0yzj   swarmpit_agent.3jasdfd3k   swarmpit/agent:latest      snake.example.com   Running         Running 3 minutes ago
9onasdfzopve   swarmpit_agent.r6asdfb20   swarmpit/agent:latest      snake.example.com   Running         Running 3 minutes ago
fxoasdfwjrbj   swarmpit_db.1              couchdb:2.3.0              dog.example.com     Running         Running 3 minutes ago
m4jasdf3369c   swarmpit_app.1             swarmpit/swarmpit:latest   cat.example.com     Running         Running 3 minutes ago
You can check the Swarmpit logs with:

docker service logs swarmpit_app
Check the user interfaces
After some seconds/minutes, Traefik will acquire the HTTPS certificates for the web user interface.

You will be able to securely access the web UI at https://<your swarmpit domain> where you can create your username and password.