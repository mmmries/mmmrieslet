# mmmrieslet

Hosting setup for personal projects.

## Generating A TLS Certificate

```
brew install certbot
sudo certbot --manual -d "riesd.com" -d "devblog.riesd.com" -d "games.riesd.com" -d "goghbots.riesd.com"  -d "home.riesd.com" -d "oprah.riesd.com" -d "showoff.riesd.com" -d "walybot.riesd.com" --preferred-challenge dns-01 certonly
```

You will be told to create a DNS record, then certbot will check that the DNS entry is there to prove that you control the domain.
Then it will tell you where your key and certificate were created.
Copy these files into `secrets`.

```
sudo cp /etc/letsencrypt/live/riesd.com/fullchain.pem secrets/riesd.com.cert.pem
sudo cp /etc/letsencrypt/live/riesd.com/privkey.pem secrets/riesd.com.key.pem
```

These secrets will be used by the load balancer a little later.

> This does not account for renewing certificates which needs to happen every 3 months with letsencrypt.
> Hopefully in the future I'll automate this process.

## Updating the TLS Certificate

If you want to add another domain name or just renew the TLS certificate you should start by running the `certbot` command above and copying the files into `./secrets` in this project.
Now update the secrets with a command like:

```
kubectl create secret generic load-balancer --from-file=dhparam.pem=secrets/dhparam.pem --from-file=nginx.crt=secrets/app.spiff.com.cert.pem --from-file=nginx.key=secrets/app.spiff.com.key.pem --dry-run -o=json | kubectl apply -f -
# run a rolling deploy to pickup the new certs
kubectl apply -f load_balancer.yaml && kubectl rolling-update load-balancer --image us.gcr.io/argon-magnet-190822/load_balancer:latest --image-pull-policy=Always
```

## Setting Up The Load Balancer

For now I'm just using a simple port listener and an nginx instance for a load balancer.

First we need to setup the secrets that we will put into the load balancer.
You should have already created the TLS secret above.
We will also generate some custom diff-helman params like this:

```bash
$ openssl dhparam -out secrets/dhparam.pem 4096
$ kubectl create secret generic load-balancer --from-file=dhparam.pem=secrets/dhparam.pem --from-file=nginx.crt=secrets/riesd.com.cert.pem --from-file=nginx.key=secrets/riesd.com.key.pem
```

Now we create a config map to hold our nginx configuration

```bash
kubectl create configmap load-balancer-config --from-file load_balancer_nginx.conf
```

And finally we create the load balancer pod that will load in the TLS secrets and the nginx config with a simple:

```bash
$ kubectl apply -f load_balancer.yaml
```

## Updating the Load Balancer

When making changes to the load balancer, you can edit the `load_balancer_nginx.conf` file, then update the configmap with

```bash
kubectl create configmap load-balancer-config --from-file load_balancer_nginx.conf --dry-run -o=json | kubectl apply -f -
```

Then you can restart the load balancer with the new config by running

```bash
kubectl rolling-update load-balancer --image nginx:1.15-alpine --image-pull-policy=Always
```

Or you can simply go into the k8s UI and destroy the existing pod and let the replication controller restart it.

## Setup Secrets

```
kubectl create secret generic home --from-literal=cookie=<YOUR_COOKIE>
```
