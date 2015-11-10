FROM ubuntu:14.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

# Add multiverse repos for FASTCGI & PHP-FPM
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu trusty-security universe multiverse" >> /etc/apt/sources.list

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl apache2 mysql-client supervisor php5 libapache2-mod-fastcgi php5-fpm apache2-mpm-event php5-gd php5-mysql php-pear php5-curl php5-dev openssh-client make libpcre3-dev software-properties-common

# I/O, Network Other useful troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget nano vim sysstat iotop htop ethtool nmap dnsutils traceroute

# Install latest git version.
RUN add-apt-repository -y ppa:git-core/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install git

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu

# Configure Apache
COPY default.conf /etc/apache2/sites-available/default.conf
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite ssl && \
    a2dissite 000-default && \
    a2ensite default default-ssl

# Disable all Apache modules (need to disable specific ones first to avoid error codes)
RUN printf "authz_host authz_user ssl" | a2dismod && \
    printf "*" | a2dismod
# Only enable essential Apache modules.
RUN a2enmod access_compat actions alias authz_host deflate dir expires headers mime rewrite ssl fastcgi mpm_event

# Setup PHP-FPM.
COPY php5-fpm.conf /etc/apache2/conf-available/php5-fpm.conf
RUN a2enconf php5-fpm

# Allow for Overrides in path /var/www/
RUN sed -i '166s/None/All/' /etc/apache2/apache2.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install Uploadprogress
RUN pecl channel-update pecl.php.net && \
    pecl install uploadprogress
COPY uploadprogress.ini /etc/php5/mods-available/uploadprogress.ini
RUN ln -s ../../mods-available/uploadprogress.ini /etc/php5/fpm/conf.d/20-uploadprogress.ini

# Install Composer
ENV COMPOSER_HOME /home/ubuntu/.composer
RUN echo "export COMPOSER_HOME=/home/ubuntu/.composer" >> /etc/bash.bashrc && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Add tools installed via composer to PATH and Drupal logs to syslog
RUN echo "export PATH=/home/ubuntu/.composer/vendor/bin:$PATH" >> /etc/bash.bashrc && \
    echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;opcache.enable=0/opcache.enable=1/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^;date.timezone\s*=/date.timezone = "Europe\/Rome"/g' /etc/php5/fpm/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/cli/php.ini

# Configurations for bash.
RUN echo "export TERM=xterm" >> /etc/bash.bashrc

RUN mkdir -p /var/www/log && \
    ln -s /var/log/apache2/error.log /var/www/log/ && \
    ln -s /var/log/apache2/access.log /var/www/log/ && \
    ln -s /var/log/drupal.log /var/www/log/ && \
    ln -s /var/log/syslog /var/www/log/

# Need to install OpCache GUI, such as https://github.com/PeeHaa/OpCacheGUI

# Install Redis
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tcl8.5
RUN wget http://download.redis.io/releases/redis-3.0.5.tar.gz && \
    tar xvzf redis-3.0.5.tar.gz && \
    rm redis-3.0.5.tar.gz && \
    cd redis-3.0.5 && \
    make && \
    make test && \
    make install && \
    rm -Rf ../redis-3.0.5 && \
    mkdir /var/log/redis

# Activate globstar for bash and add alias to tail log files.
RUN echo "alias taillog='tail -f /var/www/log/syslog /var/log/redis/stdout.log /var/www/log/*.log'" >> /home/ubuntu/.bash_aliases && \
    echo "shopt -s globstar" >> /home/ubuntu/.bashrc

# Set user ownership
RUN ln -s /var/www /home/ubuntu/www && \
    chown -R ubuntu:ubuntu /home/ubuntu/ /home/ubuntu/.*

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean && apt-get autoremove

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/run"]
