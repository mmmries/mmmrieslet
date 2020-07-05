# mmmrieslet

Hosting setup for personal projects.

## Create a Kubernetes Cluster

These projects don't need much in terms of resources, so you probably want to create a minimally sized cluster.

## Setting up the Load Balancer

First you'll need some initial load balancer configuration files.
Then load those files into a secret:

```
kubectl create secret generic load-balancer --from-file=dhparam.pem=secrets/dhparam.pem --from-file=riesd.com.cert.pem=secrets/riesd.com.cert.pem --from-file=riesd.com.key.pem=secrets/riesd.com.key.pem --from-file=mime.types=mime.types --from-file=nginx.conf=load_balancer_nginx.conf --dry-run -o=json | kubectl apply -f -
```

We also need to create a persistent disk for showoff to store its DETS database.

```
gcloud compute disks create --size=1GB showoff-dets
```

Now start up the various services and finish off with starting the load balancer

```
kubectl apply -f blog.yaml
kubectl apply -f ref.yaml
kubectl apply -f showoff.yaml
kubectl apply -f load_balancer.yaml
```

## Updating the TLS Certificate

We can update the TLS certificate by running some commands inside the load balancer docker container.

```
kubectl exec -it load-balancer-97b9784cd-gz6ll -- sh
```

Now that you are inside the load balancer container, you'll need to start by making a web root directory.

```
mkdir /var/www
chmod 755 /var/www
chown nginx:nginx /var/www
```

Now we need to install certbot and run the command to have it do the secure handshake to generate new TLS credentials

```
apk add --no-cache certbot
certbot -n --agree-tos --email 'riesmmm@gmail.com' --webroot --webroot-path /var/www -d "riesd.com" -d "blog.riesd.com" -d "devblog.riesd.com" -d "games.riesd.com" -d "home.riesd.com" -d "ref.riesd.com" -d "showoff.riesd.com" certonly
```

Now we need to copy the certificate and key into the right place and tell nginx to update its settings.

```
cat /etc/letsencrypt/live/riesd.com/fullchain.pem
# copy-paste into secrets/riesd.com.cert.pem
cat /etc/letsencrypt/live/riesd.com/privkey.pem
# copy-paste into secrets/riesd.com.key.pem
```

Now re-create the kubernetes secret that holds those files as shows in the "setting up the load balancer" above and kill the existing pod so it starts with the new secret.
