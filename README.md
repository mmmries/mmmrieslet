# mmmrieslet

Hosting setup for personal projects.

## Generating A TLS Certificate

```
brew install certbot
sudo certbot --manual -d "riesd.com" -d "devblog.riesd.com" -d "games.riesd.com" -d "home.riesd.com" -d "showoff.riesd.com" --preferred-challenge dns-01 certonly
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

## Setting Up The Load Balancer

For now I'm just using a simple port listener and an nginx instance for a load balancer.

First we need to setup the secrets that we will put into the load balancer.
You should have already created the TLS secret above.
We will also generate some custom diff-helman params like this:

```bash
$ openssl dhparam -out secrets/dhparam.pem 4096
$ scp -r secrets root@prod:~/secrets
$ scp load_balancer_nginx.conf root@prod:~/load_balancer_nginx.conf
```

## Updating the TLS Certificate

We can update the TLS certificate by running some commands inside the load balancer docker container.

```
$ ssh riesd.com
$ docker exec -it load_balancer sh
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
certbot -n --agree-tos --email 'riesmmm@gmail.com' --webroot --webroot-path /var/www -d "riesd.com" -d "devblog.riesd.com" -d "games.riesd.com" -d "home.riesd.com" -d "showoff.riesd.com" certonly
```

Now we need to copy the certificate and key into the right place and tell nginx to update its settings.

```
cp /etc/letsencrypt/live/riesd.com/fullchain.pem /etc/ssl/nginx/riesd.com.cert.pem
cp /etc/letsencrypt/live/riesd.com/privkey.pem /etc/ssl/nginx/riesd.com.key.pem
kill -HUP 1
```

# Persistence For Showoff

The showoff application uses a DETS table to persists "published" drawings.
On the server create a directory called `showoff` and then copy the current version of the DETS file into that directory as `/root/showoff/recent.dets`.
Then you will map that file into the docker container (see `bin/start_showoff.sh`).
