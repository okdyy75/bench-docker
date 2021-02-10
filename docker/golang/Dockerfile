FROM golang:1.15-alpine3.13

RUN apk update && \
    apk add --no-cache bash git && \
    go get github.com/go-sql-driver/mysql

RUN ln -s /go/src/www /var/www

WORKDIR /var/www/web
