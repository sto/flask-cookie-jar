#!/bin/sh

set -e

APP_NAME="flask-cookiejar-app"
APP_DEV_ENV="-e FLASK_APP=main -e FLASK_DEBUG=1 -e FLASK_ENVIRONMENT=development"
APP_DEV_CMD="flask run --host=0.0.0.0 --port=80"
APP_RUN_ENV="-e STATIC_PATH=/app/static"
APP_VMAP="$(pwd)/app:/app"
APP_IMAGE="tiangolo/uwsgi-nginx-flask:python3.6-alpine3.7"

TLS_NAME="flask-cookiejar-tls"
TLS_FQDN="$TLS_NAME.docker.local"
TLS_ENV="-e ENABLE_WEBSOCKET=true -e FORCE_HTTPS=true -e SERVER_NAME=$TLS_FQDN"
TLS_PORTS="-p 127.0.0.1:80:80 -p 127.0.0.1:443:443"
TLS_IMAGE="flaccid/tls-proxy"

CRT_FILE="cert.pem"
CRT_SUBJ="/C=ES/ST=Valencia/L=Burjassot/O=UV/OU=ETSE/CN=$TLS_FQDN"
KEY_FILE="key.pem"
SSL_WDIR="ssl"

check_cert() {
    OPENSSL="stodh/openssl";
    CRT="/ssl/$CRT_FILE";
    KEY="/ssl/$KEY_FILE";
    if [ ! -f "$SSL_WDIR/$CRT_FILE" -o ! -f "$SSL_WDIR/$KEY_FILE" ]; then
        test -d "$SSL_WDIR" || mkdir "$SSL_WDIR"
        docker run --rm -it -u "$(id -u):$(id -g)" -v "$(pwd)/$SSL_WDIR:/ssl" \
               $OPENSSL req -x509 -nodes -new -newkey rsa:4096 -days 365 \
                            -keyout "$KEY" -out "$CRT" -subj "$CRT_SUBJ";
    fi
}

container_ip() {
    docker inspect \
           -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

# MAIN

# Change the workdir to the current script dir
cd "$( dirname "$( readlink -f "$0" ) ")"

case "$1" in
dev)
    check_cert
    docker run --rm -d $APP_DEV_ENV --name "$APP_NAME" -v "$APP_VMAP" \
               "$APP_IMAGE" $APP_DEV_CMD
    docker run --rm -d $TLS_ENV -e UPSTREAM_HOST="$(container_ip $APP_NAME)" \
               -e TLS_CERTIFICATE="$(cat $SSL_WDIR/$CRT_FILE)" \
               -e TLS_KEY="$(cat $SSL_WDIR/$KEY_FILE)" \
               $TLS_PORTS --name "$TLS_NAME" "$TLS_IMAGE" $TLS_CMD
;;
logs)
    docker logs -f "$APP_NAME"
;;
reload)
    docker exec "$APP_NAME" touch /run/uwsgi.reload
;;
run)
    check_cert
    docker run --rm -d $APP_RUN_ENV --name "$APP_NAME" -v "$APP_VMAP" \
               "$APP_IMAGE"
    docker run --rm -d $TLS_ENV -e UPSTREAM_HOST="$(container_ip $APP_NAME)" \
               -e TLS_CERTIFICATE="$(cat $SSL_WDIR/$CRT_FILE)" \
               -e TLS_KEY="$(cat $SSL_WDIR/$KEY_FILE)" \
               $TLS_PORTS --name "$TLS_NAME" "$TLS_IMAGE" $TLS_CMD
;;
shell)
    docker exec -ti "$APP_NAME" /bin/sh
;;
status)
    docker ps -f name="$APP_NAME" -f name="$TLS_NAME"
;;
stop)
    docker stop "$TLS_NAME" || true
    docker stop "$APP_NAME" || true
;;
*)
    echo "Uso: $0 [dev|logs|reload|run|shell|status|stop]"
esac
