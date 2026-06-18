# Thinking sphinx

## Index

```
bundle exec rake ts:index
```

```
bundle exec rake ts:rebuild
```

if it does not work

```
bundle exec rails c
irb(main):001:0> Listing.find_each do |listing| listing.save end
```

## Force reindex

Please set listing's shipping_price_additional_cents with random number
This will trigger the sphinx update

```
bundle exec rails c
> Listing.all.find_each do |x| x.shipping_price_additional_cents = 1; x.save end
```

# Database

## Convert tables to the utf8mb4

```
ALTER TABLE listings CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE listing_images CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE fareharbor_companies CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

# Ruby

```
git clone https://github.com/openssl/openssl.git -b  OpenSSL_1_1_1d OpenSSL_1_1_1d
cd OpenSSL_1_1_1d/
./config --prefix=/usr/local/ssl-1.1.1d --openssldir=/usr/local/ssl-1.1.1d shared zlib
make
make install
```

## Link ca-certificates

```
ln -s /etc/ssl/certs/ca-certificates.crt /usr/local/ssl-1.1.1d/cert.pem
```


```
/usr/share/rvm/bin/rvm autolibs disable
/usr/share/rvm/bin/rvm remove 2.6.5
/usr/share/rvm/bin/rvm install 2.6.5 --with-openssl-dir=/usr/local/ssl-1.1.1d
/usr/share/rvm/bin/rvm 2.6.5 do gem install bundler
```

```
/usr/share/rvm/bin/rvm autolibs disable
/usr/share/rvm/bin/rvm remove 2.7.8
/usr/share/rvm/bin/rvm install 2.7.8 --with-openssl-dir=/usr/local/ssl-1.1.1d
/usr/share/rvm/bin/rvm 2.7.8 do gem install bundler -v 2.4.22
```

## Check openssl

```
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
```

OpenSSL::OPENSSL_VERSION


# Local worstation

https://stackoverflow.com/questions/15511943/troubles-with-rvm-and-openssl

```
rvm autolibs disable

rvm pkg install openssl
rvm remove 2.7.8
rvm install 2.7.8 --with-openssl-dir=$HOME/.rvm/usr
gem install bundler -v 2.4.22
```

# Deploy

Install the appropriate version of ruby directly on your workstation.
The Docker container does not contain your SSH key. Therefore, you cannot deploy
from the docker container.

Make sure that ssh-agent is running on your workstation. Make sure that ssh
keys are being forwarded. The web server will use your ssh key to access
gitlab.ithouse.io

```
cap staging deploy
```

## foreman
systemd is managed by foreman

If sudo errors appear, then you need to fix this file on web server

```
vim /etc/sudoers.d/foreman-staging
vim /etc/sudoers.d/foreman-production
```


```
cap staging foreman:stop
```

This creates new systemd entries/services

```
cap staging foreman:export
```

```
cap staging foreman:start
```

on web server

```
systemctl daemon-reload
systemctl start ownoutdoors-staging.target
```

## nginx

Ensure passenger

```
rvm use ruby-2.7.8
gem install passenger
```

Edit global passenger conf

```
vim /etc/nginx/conf.d/mod-http-passenger.conf
```

Edit virtual host. Add a line with the appropriate ruby version

```
server {
  passenger_ruby /usr/share/rvm/gems/ruby-2.7.8/wrappers/ruby;
}
```

Check logs

```
tail -n 100 /var/log/nginx/error.log
tail -n 100 /var/log/nginx/ownoutdoors.staging.error.log
```

restart nginx

```
service nginx reload
```

Restart passenger in rails root folder

```
touch tmp/restart.txt
```

