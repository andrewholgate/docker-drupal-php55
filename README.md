# About

Dockerised Drupal container using PHP 5.5 on Ubuntu 14.04 and configured with Drupal tools.

For example of how to use this container, see [docker-drupal-project-example](https://github.com/andrewholgate/docker-drupal-project-example)

# Included Tools

- Apache with PHP-FPM + Event MPM configured for HTTP & HTTPS and with minimal modules installed.
- MySQL 5.6 client
- PHP 5.5.x with production settings.
- [Redis 3.x](http://redis.io/)
- [Linux troubleshooting tools](http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load)
- [git](http://git-scm.com/) (latest version)
- [Composer](https://getcomposer.org/) - PHP dependency management.
- Rsyslog and common log directory
- Guest user (`ubuntu`)

# Installation

## Create Presistant Database data-only container

```bash
# Build database image based off MySQL 5.6
sudo docker run -d --name mysql-drupal-php55 mysql:5.6 --entrypoint /bin/echo MySQL data-only container for Drupal PHP 5.5 MySQL
```

## Build Drupal Base Image

```bash
# Clone Drupal docker repository
git clone https://github.com/andrewholgate/docker-drupal-php55.git
cd docker-drupal-php55

# Build docker image
sudo docker build --rm=true --tag="drupal-php55" . | tee ./build.log
```

## Build Project using Docker Compose

```bash
# Customise docker-compose.yml configurations for environment.
cp docker-compose.yml.dist docker-compose.yml
vim docker-compose.yml

# Build docker containers using Docker Compose.
sudo docker-compose build
sudo docker-compose up -d
```

## Host Access

From the host server, add the web container IP address to the hosts file.

```bash
# Add IP address to hosts file.
sudo bash -c "echo $(sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
dockerdrupalphp55_drupalphp55web_1) \
drupalphp55.example.com \
>> /etc/hosts"
```

## Logging into Web Front-end

```bash
# Using the container name of the web frontend.
sudo docker exec -it dockerdrupalphp55_drupalphp55web_1 su - ubuntu
```
