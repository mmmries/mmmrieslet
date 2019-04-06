docker run -d --volume="/root/load_balancer_nginx.conf:/etc/nginx/nginx.conf" --volume="/root/secrets:/etc/ssl/nginx" --network=host --name load-balancer nginx:1.15-alpine
