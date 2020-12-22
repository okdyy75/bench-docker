# FROM php:8.0.0RC5-fpm-alpine3.12
FROM php:7.4-fpm-alpine3.12
# FROM php:5.6-fpm-alpine3.8

RUN apk update && \
    apk add --no-cache bash

RUN docker-php-ext-install bcmath pdo_mysql

COPY ./php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/web
