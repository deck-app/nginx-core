FROM alpine:3.16 AS builder
LABEL maintainer Naba Das <hello@get-deck.com>
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/deck-app/nginx-stack.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.0" \
      org.label-schema.vendor="PHP" \
      org.label-schema.name="docker-php" \
      org.label-schema.description="Docker For PHP Developers - Docker image with PHP 8.0.11, Nginx, and Alpine" \
      org.label-schema.url="https://github.com/deck-app/nginx-stack"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php8

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
ARG DEPS="\
        nginx \
        nginx-mod-http-headers-more \
        php8 \
        php8-fpm \
        composer \
        curl \
        ca-certificates \
        runit \
        php8-phar \
        php8-bcmath \
        php8-calendar \
        php8-mbstring \
        php8-exif \
        php8-ftp \
        php8-openssl \
        php8-zip \
        php8-sysvsem \
        php8-sysvshm \
        php8-sysvmsg \
        php8-shmop \
        php8-sockets \
        php8-zlib \
        php8-bz2 \
        php8-curl \
        php8-simplexml \
        php8-xml \
        php8-opcache \
        php8-dom \
        php8-xmlreader \
        php8-xmlwriter \
        php8-tokenizer \
        php8-ctype \
        php8-session \
        php8-fileinfo \
        php8-iconv \
        php8-mysqli \
        php8-json \
        php8-posix \
        php8-pdo \
        php8-dev \
        php8-pear \
"

RUN set -x \
    && apk add --no-cache $DEPS \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

RUN apk add openrc nodejs npm shadow
RUN apk add nano
RUN apk add bash
RUN apk add icu-libs git

COPY nginx /

COPY default.conf /etc/nginx/conf.d/default.conf
ARG SERVER_ROOT

RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/nginx/conf.d/default.conf
VOLUME [ "/var/www/" ]
WORKDIR /var/www
COPY php_ini/php.ini /etc/php8/php.ini

# Composer install
RUN apk add --no-cache openssl openssl-dev
RUN apk add curl

ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php8/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php8/php.ini \
;fi

RUN apk add gcc make g++ zlib-dev
#RUN ln -s /usr/bin/php8 /usr/bin/php

# mongodb installation

#RUN ln -s /usr/bin/phar8 /usr/bin/phar
RUN apk add --no-cache gdbm libsasl snappy
RUN apk add --no-cache php8-pecl-mongodb
RUN apk upgrade
RUN apk add php8-intl

FROM scratch
COPY --from=builder / /
WORKDIR /var/www
EXPOSE 80
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start
RUN chmod +x /etc/service/nginx/run
RUN chmod +x /etc/service/php-fpm/run

CMD ["/sbin/runit-wrapper"]
