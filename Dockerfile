FROM alpine:3.7
LABEL maintainer Naba Das <hello@get-deck.com>

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/deck-app/nginx-stack.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.0" \
      org.label-schema.vendor="PHP" \
      org.label-schema.name="docker-php" \
      org.label-schema.description="Docker For PHP Developers - Docker image with PHP 5.6, Nginx, and Alpine" \
      org.label-schema.url="https://github.com/deck-app/nginx-stack"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php5

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
ARG DEPS="\
        nginx \
        nginx-mod-http-headers-more \
        php5 \
        php5-phar \
        php5-fpm \
        php5-dev \
        php5-pear \
        curl \
        ca-certificates \
        runit \
        php5-phar \
        php5-bcmath \
        php5-calendar \
        php5-exif \
        php5-ftp \
        php5-openssl \
        php5-zip \
        php5-sysvsem \
        php5-sysvshm \
        php5-sysvmsg \
        php5-shmop \
        php5-sockets \
        php5-zlib \
        php5-bz2 \
        php5-curl \
        php5-xml \
        php5-opcache \
        php5-dom \
        php5-xmlreader \
        php5-ctype \
        php5-iconv \
        php5-json \
        php5-posix \
        php5-pdo \
        php5-mysqli \
        php5-dev \
        php5-pear \
        php5-intl \
"

# PHP.earth Alpine repository for better developer experience
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

RUN set -x \
    && echo "https://dl-cdn.alpinelinux.org/alpine/v3.6/community/" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

RUN apk add --no-cache openssl openssl-dev gcc make g++ zlib-dev gdbm libsasl snappy openrc nano bash

COPY nginx /

COPY default.conf /etc/nginx/conf.d/default.conf
ARG SERVER_ROOT

RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/nginx/conf.d/default.conf
VOLUME [ "/var/www/" ]
WORKDIR /var/www
COPY php_ini/php.ini /etc/php5/php.ini
RUN ln -s /usr/bin/php5 /usr/bin/php
# Composer install
#RUN apk add curl
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php5/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php5/php.ini \
;fi

#mongodb version update
RUN apk add g++ autoconf automake libtool m4
#RUN pecl install mongodb \
#&& echo "extension=mongodb.so" > /etc/php5/conf.d/mongodb.ini

EXPOSE 80
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start
RUN chmod +x /etc/service/nginx/run
RUN chmod +x /etc/service/php-fpm/run

CMD ["/sbin/runit-wrapper"]