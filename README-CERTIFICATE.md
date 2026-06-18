# UPDATE

Update from ownoudoors server shell. This requires root access to the server.

```bash
export DOMAIN=ownoutdoors.com
certbot certonly --manual -d *.$DOMAIN -d $DOMAIN --agree-tos --manual-public-ip-logging-ok --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory --register-unsafely-without-email --rsa-key-size 4096
```
Do not press ENTER!

Add multiple acme-challenge TXT records to DNS provider. Verify DNS TXT entries.
Run this script from your workstation

```bash
nslookup -q=txt _acme-challenge.ownoutdoors.com.
```

Verify DNS TXT entries

```bash
https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.ownoutdoors.com.
```
If the token appears, then you can press ENTER for the certbot command that was
previously run on the ownoutdoors server.
If certbot does not find the token, then you have to start all over again.
