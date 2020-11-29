FROM python:3.9-alpine3.12

RUN apk --no-cache add mariadb-dev gcc musl-dev

WORKDIR /var/www

CMD ["python", "-m", "http.server", "8000"]
