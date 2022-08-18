export USE_HOSTNAME=dog.bbytegroup.com

# Set up the server hostname
echo $USE_HOSTNAME > /etc/hostname
hostname -F /etc/hostname

# Install the latest updates
apt-get update
apt-get upgrade -y

# Download Docker
curl -fsSL get.docker.com -o get-docker.sh CHANNEL=stable
# Install Docker using the stable channel (instead of the default "edge")
CHANNEL=stable sh get-docker.sh
# Remove Docker install script
rm get-docker.sh

docker swarm init --advertise-addr 0.0.0.0

------------------------------------
Traefik Proxy with HTTPS

docker network create --driver=overlay traefik-public

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add traefik-public.traefik-public-certificates=true $NODE_ID

export EMAIL=bonglv@bbytesolutions.com

export DOMAIN=traefik.sys.bbytegroup.com

export USERNAME=bonglv

export PASSWORD=bonglv@traefik.sys.bbytegroup.com

export HASHED_PASSWORD=$(openssl passwd -apr1 $PASSWORD)

echo $HASHED_PASSWORD

curl -L dockerswarm.rocks/traefik.yml -o traefik.yml

docker stack deploy -c traefik.yml traefik

docker stack ps traefik

docker service logs traefik_traefik

curl -L dockerswarm.rocks/traefik-host.yml -o traefik-host.yml

docker stack deploy -c traefik-host.yml traefik

-----------------------
Swarmpit web user interface for your Docker Swarm cluster

export DOMAIN=swarmpit.sys.bbytegroup.com

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add swarmpit.db-data=true $NODE_ID

docker node update --label-add swarmpit.influx-data=true $NODE_ID

curl -L dockerswarm.rocks/swarmpit.yml -o swarmpit.yml

docker stack deploy -c swarmpit.yml swarmpit

docker stack ps swarmpit

user: bonglv
passwd: bonglv@swarmpit.sys.bbytegroup.com

-----------------------
Swarmprom for real-time monitoring and alerts

grafana.bbytegroup.com
alertmanager.bbytegroup.com
unsee.bbytegroup.com
prometheus.bbytegroup.com

$ git clone https://github.com/stefanprodan/swarmprom.git
$ cd swarmprom

export ADMIN_USER=bonglv

export ADMIN_PASSWORD=bonglv@bbytegroup.com

export HASHED_PASSWORD=$(openssl passwd -apr1 $ADMIN_PASSWORD)

echo $HASHED_PASSWORD

export DOMAIN=bbytegroup.com

<!-- curl -L dockerswarm.rocks/swarmprom.yml -o swarmprom.yml

docker stack deploy -c swarmprom.yml swarmprom -->

docker stack deploy -c docker-compose.traefik.yml swarmprom

--------------------------
Portainer web user interface for your Docker Swarm cluster

export DOMAIN=portainer.sys.bbytegroup.com

docker node update --label-add portainer.portainer-data=true $NODE_ID

curl -L dockerswarm.rocks/portainer.yml -o portainer.yml

docker stack deploy -c portainer.yml portainer

docker service logs portainer_portainer

user: bonglv
passwd: bonglv@portainer.sys.bbytegroup.com

----------------------------
The Lounge - self-hosted web IRC client

export DOMAIN=thelounge.bbytegroup.com

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add thelounge.thelounge-data=true $NODE_ID

curl -L dockerswarm.rocks/thelounge.yml -o thelounge.yml

docker stack deploy -c thelounge.yml thelounge

docker exec -it thelounge_app.1.kxdsp9f1nuilj0vclhhfuc4ho bash

user: bonglv
passwd: bonglv@thelounge.bbytegroup.com


------------------
https://dockerswarm.rocks/
https://github.com/tiangolo/dockerswarm.rocks