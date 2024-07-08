#!/bin/sh

set -euo pipefail
IMPORT_DIR="/var/maildata"

echo "[IMPORT] Checking for imports in ${IMPORT_DIR} ..."

cd "${IMPORT_DIR}"

find "$IMPORT_DIR" -type f -maxdepth 1 -name "*.import" | while read file; do
    donefile="${file}.done"

    leaf="$(basename ${file})"

    if [ -f "${donefile}" ] ; then
        echo "[IMPORT]   Skipping '${leaf}' ("${donefile}" exists)"
        continue
    fi

    echo "[IMPORT]   Running import for ${leaf}."
    /var/www/ponymail/tools/import-mbox.py $(cat "${file}") \
        | sed 's/^/[IMPORT]     /'

    echo "$(date)" > "${donefile}"
done

echo "[IMPORT] Done."
