# About

This base Ubuntu 14.04 docker container comes configured with tools for Drupal 7 and Drupal 8 projects.

When developing, this project should be used in conjunction with [docker-drupal-ubuntu-dev](https://github.com/andrewholgate/docker-drupal-ubuntu-dev)

# Included Tools

- [Linux troubleshooting tools](http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load)
- PHP 5.5.x with production settings
- [git](http://git-scm.com/) (latest version)
- [Composer](https://getcomposer.org/)
- [Drush](https://github.com/drush-ops/drush)
- Apache configured for HTTP & HTTPS and with minimal modules installed
- MySQL client
- Syslog and common log directory
- Guest user (`ubuntu`)

# Installation

## Create Presistant Database data-only container

```bash
# Build database image based off MySQL 5.5
sudo docker run -d --name mysql-drupal mysql:5.5 --entrypoint /bin/echo MySQL data-only container for Drupal MySQL
```

## Build Drupal Base Image

```bash
# Clone Drupal docker repository
git clone https://github.com/andrewholgate/docker-drupal-ubuntu14.04.git
# Build docker image
cd docker-drupal-ubuntu14.04
sudo docker build --rm=true --tag="drupal-ubuntu14.04" .
```

## Build Project using fig

```bash
# Build docker containers using fig.
sudo fig build
sudo fig up -d
```

## Host Access

From the host server, add the web container IP address to the hosts file.

```bash
# Add IP address to hosts file.
sudo bash -c "echo $(sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
dockerdrupalubuntu1404_drupalubuntu14web_1) \
drupal.example.com \
>> /etc/hosts"
```

## Logging into Web Front-end

```bash
# Using the container name of the web frontend.
sudo docker exec -it dockerdrupalubuntu1404_drupalubuntu14web_1 su - ubuntu
```
