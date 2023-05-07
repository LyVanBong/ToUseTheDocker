# Portainer web user interface for your Docker Swarm cluster

Portainer web user interface for your Docker Swarm cluster
Portainer is a web UI (user interface) that allows you to see the state of your Docker services in a Docker Swarm mode cluster and manage it.

Follow this guide to integrate it in your Docker Swarm mode cluster deployed as described in DockerSwarm.rocks with a global Traefik HTTPS proxy.

Here's one of the screens:



Preparation
Connect via SSH to a Docker Swarm manager node.

Create an environment variable with the domain where you want to access your Portainer instance, e.g.:


export DOMAIN=portainer.sys.example.com
Make sure that your DNS records point that domain (e.g. portainer.sys.example.com) to one of the IPs of the Docker Swarm mode cluster.

Get the Swarm node ID of this (manager) node and store it in an environment variable:


export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
Create a tag in this node, so that Portainer is always deployed to the same node and uses the existing volume:

docker node update --label-add portainer.portainer-data=true $NODE_ID
Create the Docker Compose file
Download the file portainer.yml:

curl -L dockerswarm.rocks/portainer.yml -o portainer.yml
...or create it manually, for example, using nano:

nano portainer.yml
And copy the contents inside:

version: '3.3'

services:
  agent:
    image: portainer/agent
    environment:
      AGENT_CLUSTER_ADDR: tasks.agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - agent-network
    deploy:
      mode: global
      placement:
        constraints:
          - node.platform.os == linux

  portainer:
    image: portainer/portainer
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer-data:/data
    networks:
      - agent-network
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.role == manager
          - node.labels.portainer.portainer-data == true
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.portainer-http.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.portainer-http.entrypoints=http
        - traefik.http.routers.portainer-http.middlewares=https-redirect
        - traefik.http.routers.portainer-https.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.portainer-https.entrypoints=https
        - traefik.http.routers.portainer-https.tls=true
        - traefik.http.routers.portainer-https.tls.certresolver=le
        - traefik.http.services.portainer.loadbalancer.server.port=9000

networks:
  agent-network:
    attachable: true
  traefik-public:
    external: true

volumes:
  portainer-data:
Info

This is just a standard Docker Compose file.

It's common to name the file docker-compose.yml or something like docker-compose.portainer.yml.

Here it's named just portainer.yml for brevity.

Deploy it
Deploy the stack with:


docker stack deploy -c portainer.yml portainer
It will use the environment variables you created above.

Check it
Check if the stack was deployed with:

docker stack ps portainer
It will output something like:


ID             NAME                       IMAGE                        NODE              DESIRED STATE   CURRENT STATE          ERROR   PORT
xvyasdfh56hg   portainer_agent.b282rzs5   portainer/agent:latest       dog.example.com   Running         Running 1 minute ago
j3ahasdfe0mr   portainer_portainer.1      portainer/portainer:latest   cat.example.com   Running         Running 1 minute ago
You can check the Portainer logs with:

docker service logs portainer_portainer
Check the user interface
After some seconds/minutes, Traefik will acquire the HTTPS certificates for the web user interface.

You will be able to securely access the web UI at https://<your portainer domain> where you can create your username and password.

Timing Note
Make sure you login and create your credentials soon after Portainer is ready, or it will automatically shut down itself for security.

If you didn't create the credentials on time and it shut down itself automatically, you can force it to restart with:


docker service update portainer_portainer --force
References
This guide on Portainer is adapted from the official Portainer documentation for Docker Swarm mode clusters, adding deployment restrictions to make sure the same volume and database is always used and to enable HTTPS via Traefik, using the same ideas from DockerSwarm.rocks.