FROM ubuntu:24.04

# install utilities
RUN apt update && apt install -y unzip git supervisor cron nano curl apache2

# install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt install -y nodejs

# prepare apache for rootless mode
RUN rm -rf /etc/apache2/sites-available /etc/apache2/sites-enabled /etc/apache2/conf-*/other-vhosts-access-log.conf /var/www/html/*
RUN mkdir -p /var/run/apache2
RUN chown -R www-data:www-data /var/cache/apache2 /var/www/html /etc/apache2 /var/run/apache2 \
    && chmod -R g+w /var/cache/apache2 /etc/apache2 /var/run/apache2

# install php
RUN apt install -y software-properties-common && add-apt-repository ppa:ondrej/php && apt update
RUN apt install -y php8.4 php8.4-fpm php8.4-curl php8.4-cli php8.4-mbstring php8.4-gd php8.4-mysql php8.4-xml php8.4-xmlrpc php8.4-soap php8.4-intl php8.4-zip php8.4-bcmath php8.4-imagick
RUN rm -rf /var/lib/apt/lists/*

# configure php-fpm
RUN sed -e 's/run\/php/tmp/' -i /etc/php/8.4/fpm/php-fpm.conf
COPY includes/config/www-pool.conf /etc/php/8.4/fpm/pool.d/www.conf
COPY includes/config/php.ini /etc/php/8.4/fpm/php.ini
RUN touch /var/log/php8.4-fpm.log
RUN chown -R www-data:www-data /var/log/php8.4-fpm.log /etc/php/8.4/fpm

# install composer
WORKDIR /root
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# set up supervisor
COPY includes/config/supervisord.conf /etc/supervisor/supervisord.conf
RUN touch /var/log/supervisord.log && chown www-data:www-data /var/log/supervisord.log

# set up apache
USER root
COPY includes/config/apache2.conf /etc/apache2/apache2.conf
RUN usermod -d /var/www www-data \
    && chown www-data:www-data /var/www \
    && chmod 0777 /var/www
RUN a2enconf php8.4-fpm
RUN a2enmod proxy_fcgi rewrite headers expires

# add entrypoint scripts
COPY includes/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["sh", "/entrypoint.sh"]
