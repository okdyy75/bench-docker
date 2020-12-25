FROM nginx:1.19-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/nginx/conf.d/php-fpm.conf

CMD ["nginx"]
