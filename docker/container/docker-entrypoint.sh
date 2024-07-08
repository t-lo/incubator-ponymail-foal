#!/bin/ash

set -eu

echo "[ENTRY] Updating ponymail wwwroot"

rsync -vrlDog --chown ponymail:ponymail --delete \
      --exclude-from=/rsync.exclude /opt/ponymail/ /var/www/ponymail/

if [ ! -f "/var/www/ponymail/webui/js/config.js" ] ; then
    cp -v /opt/ponymail/webui/js/config.js /var/www/ponymail/webui/js/
    chown ponymail:ponymail /var/www/ponymail/webui/js/config.js
fi

echo "[ENTRY] Checking ES indices and regenerating YAML config if necessary."
cd /var/www/ponymail/tools

#
# Configure from container env
#

# Regenerate Elasticsearch data only if necessary
setup_opts="--defaults --skiponexist"

from_env() {
    local prev="$1"
    local arg="$2"
    local env
    eval env=\"\$\{"$3":-\}\"

    if [ -n "$env" ] ; then
        echo "$prev" "$arg" "$env"
    else
        echo "$prev"
    fi
}

setup_opts="$(from_env "$setup_opts" "--dburl" "ELASTICSEARCH_URL")"
setup_opts="$(from_env "$setup_opts" "--dbname" "ELASTICSEARCH_DBNAME")"
setup_opts="$(from_env "$setup_opts" "--dbshards" "ELASTICSEARCH_NUM_SHARDS")"
setup_opts="$(from_env "$setup_opts" "--dbreplicas" "ELASTICSEARCH_NUM_REPLICAS")"

setup_opts="$(from_env "$setup_opts" "--mailserver" "OUTGOING_MAIL_SERVER")"
setup_opts="$(from_env "$setup_opts" "--mldom" "OUTGOING_MAIL_DOMAIN")"

setup_opts="$(from_env "$setup_opts" "--generator" "DOCUMENT_GENERATOR")"
setup_opts="$(from_env "$setup_opts" "--nonce" "DKIM_GENERATOR_NONCE")"

setup_opts="$(from_env "$setup_opts" "--nocloud" "WEBGUI_NO_WORD_CLOUD")"

setup_opts="$(from_env "$setup_opts" "--bind-address" "PONYSERVER_BIND_ADDRESS")"
setup_opts="$(from_env "$setup_opts" "--bind-port" "PONYSERVER_BIND_PORT")"

# TODO: oauth etc.

echo "[ENTRY] Starting ponymail server with '$setup_opts'"
python3 setup.py $setup_opts

/import-mailboxes.sh

echo "[ENTRY] Starting ponymail"
cd /var/www/ponymail/server
exec su -s /usr/bin/python3 ponymail main.py
