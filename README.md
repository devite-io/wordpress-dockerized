# WordPress dockerized

This is a production-ready dockerized setup for WordPress.

## Starting webserver

```bash
docker compose up -d
```

## Stopping webserver

```bash
docker compose down
```

## Installing WordPress

```bash
bash ./bin/install-wordpress.sh wordpress-frontend-1
```