# Spug on Railway: the official all-in-one image (nginx + Redis + the Spug API, websocket,
# worker, monitor and scheduler under supervisord), pinned by version and digest.
# Upstream: https://github.com/openspug/spug  (release v4.1.2)
FROM openspug/spug:4.1.2@sha256:d60b06ca87e80bdf98a47aac0d1252d2c04ab47bc7f1256c96d763945f9482a9

# supervisord config: upstream's program list plus log rotation caps and a listener that stops
# the container (non-zero exit) when a Spug process keeps crashing, so Railway restarts it.
COPY supervisord.conf /etc/supervisord.conf
COPY start.sh /usr/local/bin/railway-start.sh
COPY fatal-listener.py /usr/local/bin/fatal-listener.py

# Small-plan sizing: nginx workers and the API's gunicorn workers follow env vars instead of the
# host's CPU count, and the in-container Redis (cache and console streams only) is capped at 96 MB.
# First-run migrations are written to a file (printed only on failure) to stay under Railway's log rate limit.
RUN chmod 755 /usr/local/bin/railway-start.sh /usr/local/bin/fatal-listener.py \
    && sed -i 's/^worker_processes auto;/worker_processes 2;/' /etc/nginx/nginx.conf \
    && cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig \
    && sed -i 's/^maxmemory 2GB/maxmemory 96mb/' /etc/redis.conf \
    && sed -i 's|^python3 manage.py updatedb$|python3 manage.py updatedb > /tmp/updatedb.log 2>\&1 \|\| { tail -n 40 /tmp/updatedb.log >\&2; exit 1; }; log "database schema is up to date"|' /entrypoint.sh \
    && grep -q 'updatedb > /tmp/updatedb.log' /entrypoint.sh \
    && sed -i 's/-w 2 --threads 8/-w ${SPUG_API_WORKERS:-1} --threads ${SPUG_API_THREADS:-8}/' /opt/spug/spug_api/tools/start-api.sh \
    && grep -q 'SPUG_API_WORKERS' /opt/spug/spug_api/tools/start-api.sh \
    && grep -q '^maxmemory 96mb' /etc/redis.conf \
    && grep -q '^worker_processes 2;' /etc/nginx/nginx.conf.orig

ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
