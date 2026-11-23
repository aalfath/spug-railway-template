#!/bin/bash
# Railway wrapper around the upstream entrypoint (/entrypoint.sh): listen on $PORT, then run
# the upstream steps (sync code to /data, wait for MySQL, migrate, create the first admin from
# SPUG_ADMIN_USER / SPUG_ADMIN_PASSWORD, start supervisord). If supervisord stops for any reason
# other than Railway stopping the container, exit non-zero so the ON_FAILURE policy restarts it.
set -u

port="${PORT:-80}"
sed -E "s/listen +80 default_server;/listen ${port} default_server;/; s/listen +\[::\]:80 default_server;/listen [::]:${port} default_server;/" \
    /etc/nginx/nginx.conf.orig > /etc/nginx/nginx.conf
rm /run/spug-fatal 2>/dev/null || true

/entrypoint.sh &
child=$!
stopping=
trap 'stopping=1; kill -TERM "$child" 2>/dev/null' TERM INT

while :; do
    wait "$child"; rc=$?
    # wait returns early when a trapped signal arrives; keep waiting for the child to finish
    kill -0 "$child" 2>/dev/null || break
done

if [ -n "$stopping" ] && [ ! -f /run/spug-fatal ]; then
    exit 0
fi
if [ -f /run/spug-fatal ]; then
    echo "[railway] a Spug process kept failing ($(cat /run/spug-fatal)); exiting so Railway restarts the container" >&2
else
    echo "[railway] Spug stopped unexpectedly (exit $rc); exiting non-zero so Railway restarts the container" >&2
fi
[ "$rc" -eq 0 ] && rc=1
exit "$rc"
