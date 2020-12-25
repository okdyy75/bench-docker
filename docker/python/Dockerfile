FROM python:3.9-alpine3.12

RUN apk update && \
    apk --no-cache add bash mariadb-dev gcc musl-dev

RUN pip install --upgrade pip

WORKDIR /var/www/web
