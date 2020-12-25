FROM php:8.0.0-fpm-alpine3.12

RUN apk update && \
    apk add --no-cache bash

RUN docker-php-ext-install bcmath pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/web
