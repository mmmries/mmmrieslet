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

# Persistence For Showoff

The showoff application uses a DETS table to persists "published" drawings.
On the server create a directory called `showoff` and then copy the current version of the DETS file into that directory as `/root/showoff/recent.dets`.
Then you will map that file into the docker container (see `bin/start_showoff.sh`).