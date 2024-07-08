#!/bin/sh

en_mod () {
    local mod="$1"

    if ! grep -qE "^[[:space:]]*#*LoadModule cgi_module" \
            /usr/local/apache2/conf/*.conf \
            /usr/local/apache2/conf/extra/*.conf ; then
        echo "Required module '$mod' not supported by httpd container. Failing."
        exit 1
    fi

    echo "Enabling module $mod"
    sed -i "/^[[:space:]]*#LoadModule ${mod}_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
    sed -i "/^[[:space:]]*#LoadModule ${mod}_module/s/^#//g" /usr/local/apache2/conf/extra/*.conf
}

en_mod cgi
en_mod headers
en_mod rewrite
en_mod ldap
en_mod authnz_ldap
en_mod speling
en_mod remoteip
en_mod expires
en_mod proxy
en_mod proxy_http

echo "Include conf/httpd-ponymail.conf" >> /usr/local/apache2/conf/httpd.conf

httpd-foreground
