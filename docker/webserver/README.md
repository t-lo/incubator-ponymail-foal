# Ponymail docker webserver integration

This directory hosts a number of web server configurations to be used for a
stand-alone docker compose set-up. If you have a web server running on the
docker host you don't need this.

To add a web server to the compose mix use the web server's YAML file in
conjunction with the main `docker-compose.yaml` when starting the service.
E.g. for using Caddy, run:
```bash
docker compose -f docker-compose.yaml -f caddy.yaml up
```

## Web server integrations

### Apache httpd

Apache httpd is a full-featured and very powerful web server that has been
powering the web for decades.
See [https://httpd.apache.org/](https://httpd.apache.org/) for more
information.

#### How to use

Copy `httpd-entry.sh`, `httpd.yaml`, and `httpd-ponymail.conf` into the docker compose
root / working directory.

Run
```bash
docker compose -f docker-compose.yaml -f httpd.yaml up
```
to start.

#### Documentation

The integration uses a custom docker entry script to enable a number of required
modules in the default httpd container.
See [httpd-entry.sh](docker/webserver/httpd/httpd-entry.sh) for details.

Modifications to the web server configuration can be persisted in `httpd-ponymail.conf`
which is bind-mounted into the httpd container.
More complex configurations and additional files like TLS certificates may be
supplied via a separate bind mount volume and added to `httpd.yaml`.

### Caddy

Caddy is a lightweight and flexible web server focusing on automation and ease
of integration.
See [https://caddyserver.com/](https://caddyserver.com/) for more information.

#### How to use

Copy  `caddy.yaml` and `Caddyfile` from `docker/webserver/caddy` into the docker
compose root / working directory.

Run
```bash
docker compose -f docker-compose.yaml -f caddy.yaml up
```
to start.

#### Documentation

Caddy integration supports two modes; local HTTP (for development / testing)
and public http+https. Public mode requires a domain name.

Local mode is the default - it will serve ponymail on localhost, port 80 (
though the host port can be changed via the `ports:` setting in `caddy.yaml`).

Public mode requires a host name DNS entry pointing to the host running the
docker compose set-up.
In public mode, Caddy will automatically fetch, install, and renew an ACME
certificate for the service.
To run in public mode, ports `80` and `443` must be exposed, and
`PONYMAIL_SITE_ADDRESS` must be set to a host name pointing to the ponymail
host.
Refer to `production config` in `caddy.yaml` for more information.

## NGINX

NGINX is a fast and lean HTTP and reverse proxy server for heavy load sites.
It powers many high-traffic sites like Netflix or Dropbox.

Check out [https://nginx.org/en/](https://nginx.org/en/) for more information.

#### How to use

Copy  `nginx.yaml` and `nginx.conf` from `docker/webserver/nginx` into the docker
compose root / working directory.

Run
```bash
docker compose -f docker-compose.yaml -f nginx.yaml up
```
to start.

#### Documentation

The integration uses a basic NGINX set-up for http.
Modifications to the web server configuration can be persisted in `nginx.conf`
which is bind-mounted into the httpd container.
More complex configurations and additional files like TLS certificates may be
supplied via a separate bind mount volume and added to `nginx.yaml`.
