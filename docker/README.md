# Self-contained Ponymail Container

This directory contains Dockerfiles and helper scripts for a self-contained
Ponymail container image.
It ships ponymail and httpd in an Alpine container and largely automates set-up
and mailbox imports.

Intention of this container set-up is to allow for fully automated, unattended
deployments. It should also be helpful for new users getting started with ponymail
as it significantly eases first-time set-up.

## How to use

### tl;dr

```bash
docker/build_image.sh -t ponymail

# set up
mkdir /opt/ponymail
cp docker/docker-compose.yaml /opt/ponymail
cd /opt/ponymail
mkdir -p /opt/ponymail/ponymail-data/elasticsearch
chmod g+rwx /opt/ponymail/ponymail-data/elasticsearch

# pick a web server, e.g. caddy. Uncomment ponymail port export
# in docker-compose.yaml to use host mailserver.
cp docker/webserver/caddy/* /opt/ponymail/

# run
cd /opt/ponymail
docker-compose -d up
```
Ponymail is now available on localhost port 80; connect via
[https://127.0.0.1:80/](https://127.0.0.1:80/).

`ponymail-import` (bind-mounted into the ponymail container) can be used to
auto-import mailboxes when the container starts.
See "Importing mailboxes" below for more information.

### Build

For now the image is not released / published anywhere so we need to build it
locally first.
The build uses its own dockerignore file, `Dockerfile.alpine.dockerignore`, as
the build copies ponymail sources into the container image during build.
This requires `docker buildx` - the legacy `docker build` does not support
per-dockerfile dockerignore.
For legacy builds, a wrapper script `build_image.sh` is provided which
replaces the default `.dockerignore` with `Dockerfile.alpine.dockerignore` and
restores the original after the build.

To build, run
```bash
docker buildx build -f docker/Dockerfile.alpine -t ponymail .
```
or
```bash
docker/build_image.sh -t ponymail
```
respectively.

The resulting image contains ponymail, httpd, a docker entrypoint script that
automates first-time set-up, and a helper script for importing mailboxes.

### Set Up

From the previous step you should have a `ponymail` docker image available
locally.
We will now set up a basic environment to run this image.
This should not be done in the repository but in a separate directory.
For the purpose of this documentation we'll use `/opt/ponymail`, which is
assumed to be empty.
You can of course use whatever path / directory meets your needs.

The set-up uses local directories as volumes bind-mounted into the containers
to allow for customisation and back-up.
Most directories we can leave to `docker compose` auto-creation, with one
exception: the Elasticsearch data directory.
The Elasticsearch container does not change the ownership of files in its data
directory; the local directories created by `docker compose` will have the
wrong permissions, and Elasticsearch will fail to start.

Let's create the target directory and the Elasticsearch subdir:
```bash
mkdir /opt/ponymail
mkdir -p /opt/ponymail/ponymail-data/elasticsearch
chmod g+rwx /opt/ponymail/ponymail-data/elasticsearch
```

Copy the ponymail docker compose configuration into our environment:
```bash
cp docker/docker-compose.yaml /opt/ponymail
```

Now it's time to pick a web server.
The docker compose set-up ships with example configurations for Apache httpd,
NGINX, and Caddy. Refer to the [webserver readme](webserver/README.md))
for more information.
The example below uses Caddy.
```bash
cp docker/webserver/caddy/* /opt/ponymail/
```

You can skip the last step if your host runs a web server and you want to use that:
* Uncomment the ponymail service port 8080 export in `docker-compose.yaml`
* point your web server's wwwroot to `/opt/ponymail/ponymail-data/www/webgui`
* and set up a reverse proxy for `<ponyhost>/api/*` to `localhost:8080`.

You're all set now.

### Run and Operate the Ponymail Container

Change into the path we set up above and run `docker compose up`.
If you want to run a web server as part of the set-up, include the server's YAML:
```bash
# Plain service w/o webserver
docker compose up

# Service with Caddy
docker compose -f docker-compose.yaml -f caddy.yaml up
```
On legacy systems you might need to use `docker-compose` instead of `docker compose`.

After a brief start-up phase the ponymail container will become available at 
[https://127.0.0.1:80/](https://127.0.0.1:80/).


Local directories (container volume bind-mounts) used:
* `ponymail-data/elasticsearch` - Elasticsearch state
* `ponymail-data/www`- ponymail's python code.
   Synched / updated from the container at start except for files / patterns listed in
   `docker/container/rsync.exclude` (to preserve user settings).
*  `ponymail-import/maildir-import/` - Import directory to drop mbox / maildir data to
   for auto-import (at container start-up).
All three should be covered by your backup strategy.

Web server containers might use additional volume bind-mounts for state; consult the respective
server's yaml file for more information.

#### Import Mailboxes

The ponymail container includes basic automation to import mailboxes into its database
(implemented in [import-mailboxes.sh](container/import-mailboxes.sh)).

Import happens at container start-up and is controlled via `ponymail-import/`, which is bind-
mounted into the ponymail container.

To import a mailbox, put a file `<mailboxname>.import` into `ponymail-import/`.
`<mailboxname>` can be freely chosen.
This file contains arguments passed to [`import-mbox.py`](../tools/import-mbox.py).
The import's working directory is `ponymail-import/`; local files and directories
like `mbox` files and Maildirs can be stored in the same folder and referenced in the
`--source <>` argument of the respective `.import` file.

On start-up, [`import-mbox.py`](../tools/import-mbox.py) will be called for each `.import`
file.

For example, import an mbox file `mylist.mbox` with the following set-up:
```bash
$ ls
mylist.mbox
slurp-mylist.import

$ cat slurp-mylist.import
--source mylist.mbox --lid myfunkylist@mylist.net
```
`import-mbox.py` will be run with the contents of `slurp-mylist.import` as its arguments,
importing `mylist.mbox` with a custom list ID (the `--lid` option).

Once imported, the automation will create a file `<mailboxname>.import.done`.
This will skip importing the respective mailbox at next start-up.
You can remove the file manually to trigger a re-import.
Emails already imported will trigger an error message during import; only new emails will actually
be imported.

## Future work

- There is no well defined way to interface with the archiver.
  The ponymail container image should ship a well-defined way to feed mail into the system via
  `tools/archiver.py` (i.e. other than `docker compose exec`), e.g. through a wrapper script for
  `docker-compose exec ...`
