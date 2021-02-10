FROM php:8.0-fpm-alpine3.13

RUN apk update && \
    apk add --no-cache bash

RUN docker-php-ext-install bcmath pdo_mysql

COPY ./php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/web
