FROM alpine:3.17 AS builder
LABEL maintainer Naba Das <hello@get-deck.com>

# Persistent runtime dependencies
ARG DEPS="\
        nginx \
        php82 \
        php82-phar \
        php82-bcmath \
        php82-calendar \
        php82-mbstring \
        php82-exif \
        php82-ftp \
        # composer \
        php82-openssl \
        php82-zip \
        php82-sysvsem \
        php82-sysvshm \
        php82-sysvmsg \
        php82-shmop \
        php82-sockets \
        php82-zlib \
        php82-bz2 \
        php82-curl \
        php82-simplexml \
        php82-xml \
        php82-opcache \
        php82-dom \
        php82-xmlreader \
        php82-xmlwriter \
        php82-tokenizer \
        php82-ctype \
        php82-session \
        php82-fileinfo \
        php82-iconv \
        php82-json \
        php82-posix \
        php82-pdo \
        php82-pdo_dblib \
        php82-pdo_mysql \
        php82-pdo_odbc \
        php82-pdo_pgsql\
        php82-pdo_sqlite \
        php82-mysqli \
        php82-mysqlnd \
        php82-dev \
        php82-fpm \
        php82-pear \
	git \
        curl \
        ca-certificates \
        runit \
        php82-intl \
	    snappy \
        bash \
"
RUN set -x \
    && echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


COPY nginx /
COPY default.conf /etc/nginx/conf.d/default.conf
ARG SERVER_ROOT
RUN sed -i "s#{SERVER_ROOT}#${SERVER_ROOT}#g" /etc/nginx/conf.d/default.conf
RUN ln -s /usr/bin/php82 /usr/bin/php
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
WORKDIR /var/www
COPY php_ini/php.ini /etc/php82/php.ini
RUN apk add curl nodejs npm
RUN apk add --no-cache php82-pecl-mongodb
RUN apk upgrade

FROM scratch
COPY --from=builder / /
WORKDIR /var/www
EXPOSE 80
EXPOSE 443
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start
RUN chmod +x /etc/service/nginx/run
RUN chmod +x /etc/service/php-fpm/run

CMD ["/sbin/runit-wrapper"]
