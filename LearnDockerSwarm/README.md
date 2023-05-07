# Khởi tạo docker swarm
- docker swarm init
- Khởi tạo service: docker service create image_name comand
- Liệt kê các service đang hoạt động: docker service ls
- Liệt kê các container đang hoạt động: docker container ls
- Update service: docker service update service_id --replicas 3
- Xoá container: docker container rm -f name_container
- Xoá service: docker service rm service_name
- Tạo mạng: docker network create --driver overlay mydrupal
- Tạo 1 service và kết nối vào 1 network đã tạo: docker service create --name psql --network mydrupal -e POSTGRES_PASSWORD=mypass postgres
- docker service create --name drupal --network mydrupal -p 8080:80 drupal
# Stacks: Production Grade Compose
- docker stack deploy -c file_name.yml
- The Swarm Visualizer: docker service create --name=viz --publish=8082:8080/tcp --constraint=node.role==manager --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock bretfisher/visualizer 
# Secrets Storage
- docker secret create psql_user psql_user.txt
- echo "myDBpassWORD" | docker secret create psql_pass
- docker secret ls
- docker secret inspect psql_user
- docker service create --name psql --secret psql_user --secret psql_pass -e POSTGRES_PASSWORD_FILE=/run/secrets/psql_pass -e POSTGRES_USER_FILE=/run/secrets/psql_user postgres

docker exec -it CONTAINER NAME bash

# Docker Healthchecks
