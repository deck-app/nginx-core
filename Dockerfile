FROM alpine:3.8
LABEL maintainer Naba Das <hello@get-deck.com>
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/deck-app/nginx-stack.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.0" \
      org.label-schema.vendor="PHP" \
      org.label-schema.name="docker-php" \
      org.label-schema.description="Docker For PHP Developers - Docker image with PHP 7.4.24, Nginx, and Alpine" \
      org.label-schema.url="https://github.com/deck-app/nginx-stack"

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php7

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
ARG DEPS="\
        nginx \
        nginx-mod-http-headers-more \
        php7 \
        php7-fpm \
        curl \
        ca-certificates \
        runit \
        php7-phar \
        php7-bcmath \
        php7-calendar \
        php7-mbstring \
        php7-exif \
        php7-ftp \
        php7-openssl \
        php7-zip \
        php7-sysvsem \
        php7-sysvshm \
        php7-sysvmsg \
        php7-shmop \
        php7-sockets \
        php7-zlib \
        php7-bz2 \
        php7-curl \
        php7-simplexml \
        php7-xml \
        php7-opcache \
        php7-dom \
        php7-xmlreader \
        php7-xmlwriter \
        php7-tokenizer \
        php7-ctype \
        php7-session \
        php7-fileinfo \
        php7-iconv \
        php7-mysqli \
        php7-json \
        php7-posix \
        php7-simplexml \
        php7-pdo \
        php7-dev \
        php7-pear \
        php7-gd \
"
RUN set -x \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log 

# COPY nginx /
COPY nginx/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/etc/nginx/nginx_back.conf /etc/nginx/nginx.conf
COPY nginx/etc/service/nginx/run /etc/service/nginx/run
COPY nginx/etc/service/php-fpm/run /etc/service/php-fpm/run
COPY nginx/sbin/runit-wrapper /sbin/runit-wrapper
COPY nginx/sbin/runsvdir-start /sbin/runsvdir-start


COPY default.conf /etc/nginx/conf.d/default.conf
ARG SERVER_ROOT

RUN sed -i "s#{SERVER_ROOT}#$SERVER_ROOT#g" /etc/nginx/conf.d/default.conf
VOLUME [ "/var/www/" ]
WORKDIR /var/www
COPY php_ini/php.ini /etc/php7/php.ini
RUN mv /usr/bin/php7 /usr/bin/php


ARG DISPLAY_PHPERROR
RUN if [ ${DISPLAY_PHPERROR} = true ]; then \
sed -i "s#{DISPLAY}#On#g" /etc/php7/php.ini \
;else \
sed -i "s#{DISPLAY}#Off#g" /etc/php7/php.ini \
;fi

# mongodb installation
RUN apk add --no-cache ca-certificates curl zip unzip gdbm libsasl snappy git nodejs npm shadow openssl openssl-dev python2 gcc make zlib-dev gdbm libsasl snappy openrc nano bash g++
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories
# RUN apk add php7-pecl-mongodb nodejs npm shadow

    #Xdebug enable or disable
    # ARG XDEBUG
    # RUN if [ ${XDEBUG} = true ]; then \
    # apk add php7-xdebug \
    # && echo "zend_extension=/usr/lib/php7/modules/xdebug.so" >> /etc/php7/php.ini \
    # ;fi
#     RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories
#     RUN apk update
# RUN apk add --no-cache php7-mongodb


# Composer install 
# RUN apk add --no-cache openssl openssl-dev python2 gcc make zlib-dev gdbm libsasl snappy openrc nano bash g++
RUN apk update
# RUN apk upgrade
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN apk add php7-intl php7-soap \
    && rm -rf /var/cache/apk/*

# RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main" >> /etc/apk/repositories
# RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories
RUN apk update \
    && apk add php7-mongodb

EXPOSE 80
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start
RUN chmod +x /etc/service/nginx/run
RUN chmod +x /etc/service/php-fpm/run

CMD ["/sbin/runit-wrapper"]