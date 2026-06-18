# How it works

The developer uses his favorite text editor and git tools on the host
workstation. The Rails server is running in container "development" mode.

You can edit the code on the host workstation. The change will appear in the
container because it uses "volume" with the current directory.

# Source

https://semaphoreci.com/community/tutorials/dockerizing-a-ruby-on-rails-application


# Running Everything

```
$ docker compose up
```

ERROR: Failed to Setup IP tables: Unable to enable SKIP DNAT rule:
```
sudo systemctl restart docker
```

Web server only without worker
```
$ docker compose up web
```

# Initialize the Database

Run migration
```
$ docker compose run web rake db:migrate
```

This does not work
```
$ docker compose run web rake db:reset
$ docker compose run web rake db:migrate
```

Import existing database
```
$ docker exec -i ownoutdoors-mysql-1 mysql -u rdeveloper -prdeveloper ownoutdoors_development < ../ownoutdoors_production-20220411.sql
```

# Web container

with debugging capabilities
```
docker compose run --rm --service-ports web
```
or
```
docker compose run --rm --service-ports web bash
user@db5f7e178bf7:/opt/app$ bundle exec bin/rails s -b 0.0.0.0
user@db5f7e178bf7:/opt/app$ bundle exec bin/rails c
```

rebuild
```
docker compose up --build web
```

```
docker compose up --build --force-recreate --no-deps [-d] web
```
Options:
    --force-rm              Always remove intermediate containers.
    -m, --memory MEM        Set memory limit for the build container.
    --no-cache              Do not use cache when building the image.
    --no-rm                 Do not remove intermediate containers after a successful build.

## Interactive web for debug
```
docker compose run --rm --service-ports web
```

# Rails console

new container
```
$ docker compose run web rails c
```

existing container
```
$ docker exec -it projektubanka_web_1 rails c
```

# Tests

```
$ docker compose run web rspec
```

# Remove docker build images

```
$ docker rmi `docker images -f "dangling=true" -q`
```
