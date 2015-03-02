FROM ubuntu:14.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl apache2 mysql-client supervisor php5 libapache2-mod-php5 php5-gd php5-mysql openssh-client rsyslog make libpcre3-dev php-pear php5-curl software-properties-common php5-dev

# Install latest git version.
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git

# I/O, Network Other useful troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sysstat iotop htop ethtool nmap dnsutils traceroute wget nano

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu
RUN ln -s /var/www /home/ubuntu/www
RUN chown -R ubuntu:ubuntu /home/ubuntu

# Install Uploadprogress
RUN pecl install uploadprogress
COPY uploadprogress.ini /etc/php5/mods-available/uploadprogress.ini
RUN ln -s ../../mods-available/uploadprogress.ini /etc/php5/apache2/conf.d/20-uploadprogress.ini

# Install Composer
ENV COMPOSER_HOME /home/ubuntu/.composer
RUN echo "export COMPOSER_HOME=/home/ubuntu/.composer" >> /etc/bash.bashrc && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install drush & Console Table.
USER ubuntu
WORKDIR /home/ubuntu/
RUN composer global require drush/drush:6.*
COPY drushrc.php /home/ubuntu/.drush/drushrc.php
USER root
RUN pear install Console_Table
RUN ln -s /home/ubuntu/.composer/vendor/drush/drush/drush /usr/local/bin/drush

# Confiure Apache
COPY default.conf /etc/apache2/sites-available/default.conf
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite ssl && \
    a2dissite 000-default && \
    a2ensite default default-ssl

# Disable all Apache modules (need to disable specific ones first to avoid error codes)
RUN printf "authz_host authz_user ssl" | a2dismod
RUN printf "*" | a2dismod
# Only enable necessary Apache modules.
RUN a2enmod access_compat alias authz_host deflate dir expires headers mime mpm_prefork php5 rewrite ssl

# Allow for Overrides in path /var/www/
RUN sed -i '166s/None/All/' /etc/apache2/apache2.conf

# Add Drupal logs to syslog
RUN echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;opcache.enable=0/opcache.enable=1/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^;date.timezone\s*=/date.timezone = "Europe\/Rome"/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/cli/php.ini

# Configurations for bash.
RUN echo "export TERM=xterm" >> /etc/bash.bashrc

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/www/log && \
    ln -s /var/log/apache2/error.log /var/www/log/ && \
    ln -s /var/log/apache2/access.log /var/www/log/ && \
    ln -s /var/log/drupal.log /var/www/log/ && \
    ln -s /var/log/syslog /var/www/log/

USER ubuntu
RUN echo "alias taillog='tail -f /var/www/log/syslog /var/www/log/*.log'" >> ~/.bashrc
USER root

# Need to install OpCache GUI, such as https://github.com/PeeHaa/OpCacheGUI

# Set user ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu/

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean

RUN /etc/init.d/apache2 restart

EXPOSE 80 443 22

ENTRYPOINT ["/usr/local/bin/run"]
