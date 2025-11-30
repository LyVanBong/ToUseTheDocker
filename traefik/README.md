# Traefik Proxy with HTTPS

Intro
So, you have a Docker Swarm mode cluster set up as described in DockerSwarm.rocks.

Now you can add a main Traefik load balancer/proxy to:

Handle connections.
Expose specific services and applications based on their domain names.
Handle multiple domains (if you need to). Similar to "virtual hosts".
Handle HTTPS.
Acquire (generate) HTTPS certificates automatically (including renewals) with Let's Encrypt.
Add HTTP Basic Auth for any service that you need to protect and doesn't have its own security, etc.
Get all its configurations automatically from Docker labels set in your stacks (you don't need to update configuration files).
These ideas, techniques, and tools would also apply to other cluster orchestrators, like Kubernetes or Mesos, to add a main load balancer with HTTPS support, certificate generation, etc. But this article is focused on Docker Swarm mode.

User Interface
The guide includes how to expose the internal Traefik web UI dashboard through the same Traefik load balancer, using a secure HTTPS certificate and HTTP Basic Auth.



How it works
The idea is to have a main load balancer/proxy that covers all the Docker Swarm cluster and handles HTTPS certificates and requests for each domain.

But doing it in a way that allows you to have other Traefik services inside each stack without interfering with each other, to redirect based on path in the same stack (e.g. one container handles / for a web frontend and another handles /api for an API under the same domain), or to redirect from HTTP to HTTPS selectively.

Preparation
Connect via SSH to a manager node in your cluster (you might have only one node) that will have the Traefik service.
Create a network that will be shared with Traefik and the containers that should be accessible from the outside, with:

docker network create --driver=overlay traefik-public
Get the Swarm node ID of this node and store it in an environment variable:

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
Create a tag in this node, so that Traefik is always deployed to the same node and uses the same volume:

docker node update --label-add traefik-public.traefik-public-certificates=true $NODE_ID
Create an environment variable with your email, to be used for the generation of Let's Encrypt certificates, e.g.:

export EMAIL=admin@example.com
Create an environment variable with the domain you want to use for the Traefik UI (user interface), e.g.:

export DOMAIN=traefik.sys.example.com
You will access the Traefik dashboard at this domain, e.g. traefik.sys.example.com. So, make sure that your DNS records point the domain to one of the IPs of the cluster. Better if it is the IP where the Traefik service runs (the manager node you are currently connected to).

Create an environment variable with a username (you will use it for the HTTP Basic Auth for Traefik and Consul UIs), for example:


export USERNAME=admin
Create an environment variable with the password, e.g.:

export PASSWORD=changethis
Use openssl to generate the "hashed" version of the password and store it in an environment variable:

export HASHED_PASSWORD=$(openssl passwd -apr1 $PASSWORD)
(Optional): Alternatively, if you don't want to put the password in an environment variable, you could type it interactively, e.g.:


$ export HASHED_PASSWORD=$(openssl passwd -apr1)
Password: $ enter your password here
Verifying - Password: $ re enter your password here
You can check the contents with:

echo $HASHED_PASSWORD
It will look like:


$apr1$89eqM5Ro$CxaFELthUKV21DpI3UTQO.
Create the Docker Compose file
Download the file traefik.yml:

curl -L dockerswarm.rocks/traefik.yml -o traefik.yml
...or create it manually, for example, using nano:

nano traefik.yml
And copy the contents inside:

version: '3.3'

services:

  traefik:
    # Use the latest v2.2.x Traefik image available
    image: traefik:v2.2
    ports:
      # Listen on port 80, default for HTTP, necessary to redirect to HTTPS
      - 80:80
      # Listen on port 443, default for HTTPS
      - 443:443
    deploy:
      placement:
        constraints:
          # Make the traefik service run only on the node with this label
          # as the node with it has the volume for the certificates
          - node.labels.traefik-public.traefik-public-certificates == true
      labels:
        # Enable Traefik for this service, to make it available in the public network
        - traefik.enable=true
        # Use the traefik-public network (declared below)
        - traefik.docker.network=traefik-public
        # Use the custom label "traefik.constraint-label=traefik-public"
        # This public Traefik will only use services with this label
        # That way you can add other internal Traefik instances per stack if needed
        - traefik.constraint-label=traefik-public
        # admin-auth middleware with HTTP Basic auth
        # Using the environment variables USERNAME and HASHED_PASSWORD
        - traefik.http.middlewares.admin-auth.basicauth.users=${USERNAME?Variable not set}:${HASHED_PASSWORD?Variable not set}
        # https-redirect middleware to redirect HTTP to HTTPS
        # It can be re-used by other stacks in other Docker Compose files
        - traefik.http.middlewares.https-redirect.redirectscheme.scheme=https
        - traefik.http.middlewares.https-redirect.redirectscheme.permanent=true
        # traefik-http set up only to use the middleware to redirect to https
        # Uses the environment variable DOMAIN
        - traefik.http.routers.traefik-public-http.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.traefik-public-http.entrypoints=http
        - traefik.http.routers.traefik-public-http.middlewares=https-redirect
        # traefik-https the actual router using HTTPS
        # Uses the environment variable DOMAIN
        - traefik.http.routers.traefik-public-https.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.traefik-public-https.entrypoints=https
        - traefik.http.routers.traefik-public-https.tls=true
        # Use the special Traefik service api@internal with the web UI/Dashboard
        - traefik.http.routers.traefik-public-https.service=api@internal
        # Use the "le" (Let's Encrypt) resolver created below
        - traefik.http.routers.traefik-public-https.tls.certresolver=le
        # Enable HTTP Basic auth, using the middleware created above
        - traefik.http.routers.traefik-public-https.middlewares=admin-auth
        # Define the port inside of the Docker service to use
        - traefik.http.services.traefik-public.loadbalancer.server.port=8080
    volumes:
      # Add Docker as a mounted volume, so that Traefik can read the labels of other services
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Mount the volume to store the certificates
      - traefik-public-certificates:/certificates
    command:
      # Enable Docker in Traefik, so that it reads labels from Docker services
      - --providers.docker
      # Add a constraint to only use services with the label "traefik.constraint-label=traefik-public"
      - --providers.docker.constraints=Label(`traefik.constraint-label`, `traefik-public`)
      # Do not expose all Docker services, only the ones explicitly exposed
      - --providers.docker.exposedbydefault=false
      # Enable Docker Swarm mode
      - --providers.docker.swarmmode
      # Create an entrypoint "http" listening on port 80
      - --entrypoints.http.address=:80
      # Create an entrypoint "https" listening on port 443
      - --entrypoints.https.address=:443
      # Create the certificate resolver "le" for Let's Encrypt, uses the environment variable EMAIL
      - --certificatesresolvers.le.acme.email=${EMAIL?Variable not set}
      # Store the Let's Encrypt certificates in the mounted volume
      - --certificatesresolvers.le.acme.storage=/certificates/acme.json
      # Use the TLS Challenge for Let's Encrypt
      - --certificatesresolvers.le.acme.tlschallenge=true
      # Enable the access log, with HTTP requests
      - --accesslog
      # Enable the Traefik log, for configurations and errors
      - --log
      # Enable the Dashboard and API
      - --api
    networks:
      # Use the public network created to be shared between Traefik and
      # any other service that needs to be publicly available with HTTPS
      - traefik-public

volumes:
  # Create a volume to store the certificates, there is a constraint to make sure
  # Traefik is always deployed to the same Docker node with the same volume containing
  # the HTTPS certificates
  traefik-public-certificates:

networks:
  # Use the previously created public network "traefik-public", shared with other
  # services that need to be publicly available via this Traefik
  traefik-public:
    external: true
Tip

Read the internal comments to learn what each configuration is for.

The file without comments is actually quite smaller, but the comments should give you an idea of what everything is doing.

Info

This is just a standard Docker Compose file.

It's common to name the file docker-compose.yml or something like docker-compose.traefik.yml.

Here it's named just traefik.yml for brevity.

Deploy it
Deploy the stack with:


docker stack deploy -c traefik.yml traefik
It will use the environment variables you created above.

Check it
Check if the stack was deployed with:

docker stack ps traefik
It will output something like:


ID             NAME                IMAGE          NODE              DESIRED STATE   CURRENT STATE          ERROR   PORTS
w5o6fmmln8ni   traefik_traefik.1   traefik:v2.2   dog.example.com   Running         Running 1 minute ago
You can check the Traefik logs with:

docker service logs traefik_traefik
Check the user interface
After some seconds/minutes, Traefik will acquire the HTTPS certificates for the web user interface (UI).

You will be able to securely access the web UI at https://traefik.<your domain> using the created username and password.

Once you deploy a stack, you will be able to see it there and see how the different hosts and paths map to different Docker services / containers.

Getting the client IP
If you need to read the client IP in your applications/stacks using the X-Forwarded-For or X-Real-IP headers provided by Traefik, you need to make Traefik listen directly, not through Docker Swarm mode, even while being deployed with Docker Swarm mode.

For that, you need to publish the ports using "host" mode.

So, the Docker Compose lines:


    ports:
      - 80:80
      - 443:443
need to be:


    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
You can use all the same instructions above, downloading the host-mode file:


curl -L dockerswarm.rocks/traefik-host.yml -o traefik-host.yml
Or alternatively, copying it directly:


version: '3.3'

services:

  traefik:
    # Use the latest Traefik image
    image: traefik:v2.2
    ports:
      # Listen on port 80, default for HTTP, necessary to redirect to HTTPS
      - target: 80
        published: 80
        mode: host
      # Listen on port 443, default for HTTPS
      - target: 443
        published: 443
        mode: host
    deploy:
      placement:
        constraints:
          # Make the traefik service run only on the node with this label
          # as the node with it has the volume for the certificates
          - node.labels.traefik-public.traefik-public-certificates == true
      labels:
        # Enable Traefik for this service, to make it available in the public network
        - traefik.enable=true
        # Use the traefik-public network (declared below)
        - traefik.docker.network=traefik-public
        # Use the custom label "traefik.constraint-label=traefik-public"
        # This public Traefik will only use services with this label
        # That way you can add other internal Traefik instances per stack if needed
        - traefik.constraint-label=traefik-public
        # admin-auth middleware with HTTP Basic auth
        # Using the environment variables USERNAME and HASHED_PASSWORD
        - traefik.http.middlewares.admin-auth.basicauth.users=${USERNAME?Variable not set}:${HASHED_PASSWORD?Variable not set}
        # https-redirect middleware to redirect HTTP to HTTPS
        # It can be re-used by other stacks in other Docker Compose files
        - traefik.http.middlewares.https-redirect.redirectscheme.scheme=https
        - traefik.http.middlewares.https-redirect.redirectscheme.permanent=true
        # traefik-http set up only to use the middleware to redirect to https
        # Uses the environment variable DOMAIN
        - traefik.http.routers.traefik-public-http.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.traefik-public-http.entrypoints=http
        - traefik.http.routers.traefik-public-http.middlewares=https-redirect
        # traefik-https the actual router using HTTPS
        # Uses the environment variable DOMAIN
        - traefik.http.routers.traefik-public-https.rule=Host(`${DOMAIN?Variable not set}`)
        - traefik.http.routers.traefik-public-https.entrypoints=https
        - traefik.http.routers.traefik-public-https.tls=true
        # Use the special Traefik service api@internal with the web UI/Dashboard
        - traefik.http.routers.traefik-public-https.service=api@internal
        # Use the "le" (Let's Encrypt) resolver created below
        - traefik.http.routers.traefik-public-https.tls.certresolver=le
        # Enable HTTP Basic auth, using the middleware created above
        - traefik.http.routers.traefik-public-https.middlewares=admin-auth
        # Define the port inside of the Docker service to use
        - traefik.http.services.traefik-public.loadbalancer.server.port=8080
    volumes:
      # Add Docker as a mounted volume, so that Traefik can read the labels of other services
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Mount the volume to store the certificates
      - traefik-public-certificates:/certificates
    command:
      # Enable Docker in Traefik, so that it reads labels from Docker services
      - --providers.docker
      # Add a constraint to only use services with the label "traefik.constraint-label=traefik-public"
      - --providers.docker.constraints=Label(`traefik.constraint-label`, `traefik-public`)
      # Do not expose all Docker services, only the ones explicitly exposed
      - --providers.docker.exposedbydefault=false
      # Enable Docker Swarm mode
      - --providers.docker.swarmmode
      # Create an entrypoint "http" listening on address 80
      - --entrypoints.http.address=:80
      # Create an entrypoint "https" listening on address 443
      - --entrypoints.https.address=:443
      # Create the certificate resolver "le" for Let's Encrypt, uses the environment variable EMAIL
      - --certificatesresolvers.le.acme.email=${EMAIL?Variable not set}
      # Store the Let's Encrypt certificates in the mounted volume
      - --certificatesresolvers.le.acme.storage=/certificates/acme.json
      # Use the TLS Challenge for Let's Encrypt
      - --certificatesresolvers.le.acme.tlschallenge=true
      # Enable the access log, with HTTP requests
      - --accesslog
      # Enable the Traefik log, for configurations and errors
      - --log
      # Enable the Dashboard and API
      - --api
    networks:
      # Use the public network created to be shared between Traefik and
      # any other service that needs to be publicly available with HTTPS
      - traefik-public

volumes:
  # Create a volume to store the certificates, there is a constraint to make sure
  # Traefik is always deployed to the same Docker node with the same volume containing
  # the HTTPS certificates
  traefik-public-certificates:

networks:
  # Use the previously created public network "traefik-public", shared with other
  # services that need to be publicly available via this Traefik
  traefik-public:
    external: true
And then deploying with:


docker stack deploy -c traefik-host.yml traefik
Distributed Let's Encrypt
There was a guide in DockerSwarm.rocks for setting up Traefik with Consul to store the Let's Encrypt certificates in a distributed way.

Nevertheless, that technique was fragile and error prone. Because of that, the Traefik team disabled that functionality in Traefik version 2.

In many cases the technique described here should be enough. But if you have a big and complex system that requires a distributed Let's Encrypt store for Traefik, you should check Traefik Enterprise Edition that supports it.

What's next
The next thing would be to deploy a stack (a complete web application, with backend, frontend, database, etc) using this Docker Swarm mode cluster.

It's actually very simple, as you can use Docker Compose for local development and then use the same files for deployment in the Docker Swarm mode cluster.

If you want to try it right now, you can check this project generator with a FastAPI backend and a frontend using Vue.js https://github.com/tiangolo/full-stack-fastapi-postgresql.