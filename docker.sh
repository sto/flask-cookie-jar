#!/bin/sh
APP_NAME="flask-cookiejar-app"
APP_DEV_ENV="-e FLASK_APP=main -e FLASK_DEBUG=1 -e FLASK_ENVIRONMENT=development"
APP_DEV_CMD="flask run --host=0.0.0.0 --port=80"
APP_RUN_ENV="-e STATIC_PATH=/app/static"
APP_VMAP="$(pwd)/app:/app"
APP_IMAGE="tiangolo/uwsgi-nginx-flask:python3.6-alpine3.7"

TLS_NAME="flask-cookiejar-tls"
TLS_FQDN="$TLS_NAME.docker.local"
TLS_CERT_SUBJECT="/C=ES/ST=Valencia/L=Burjassot/O=UV/OU=ETSE/CN=$TLS_FQDN"
TLS_ENV="-e ENABLE_WEBSOCKET=true -e FORCE_HTTPS=true -e SELF_SIGNED=true"
TLS_ENV="$TLS_ENV -e SELF_SIGNED_SUBJECT=$TLS_CERT_SUBJECT"
TLS_ENV="$TLS_ENV -e SERVER_NAME=$TLS_FQDN"
TLS_PORTS="-p 127.0.0.1:80:80 -p 127.0.0.1:443:443"
TLS_IMAGE="flaccid/tls-proxy"

container_ip() {
    docker inspect \
		   -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

case "$1" in
dev)
    docker run --rm -d $APP_DEV_ENV --name "$APP_NAME" -v "$APP_VMAP" \
               "$APP_IMAGE" $APP_DEV_CMD
	TLS_ENV="-e UPSTREAM_HOST=$(container_ip $APP_NAME) $TLS_ENV"
    docker run --rm -d $TLS_ENV $TLS_PORTS --name "$TLS_NAME" \
			   "$TLS_IMAGE" $TLS_CMD
;;
logs)
    docker logs -f "$APP_NAME"
;;
reload)
    docker exec "$APP_NAME" touch /run/uwsgi.reload
;;
run)
    docker run --rm -d $APP_RUN_ENV --name "$APP_NAME" -v "$APP_VMAP" \
			   "$APP_IMAGE"
	TLS_ENV="-e UPSTREAM_HOST=$(container_ip $APP_NAME) $TLS_ENV"
    docker run --rm -d $TLS_ENV $TLS_PORTS --name "$TLS_NAME" \
			   "$TLS_IMAGE" $TLS_CMD
;;
shell)
    docker exec -ti "$APP_NAME" /bin/sh
;;
status)
    docker ps -f name="$APP_NAME" -f name="$TLS_NAME"
;;
stop)
    docker stop "$TLS_NAME"
    docker stop "$APP_NAME"
;;
*)
	echo "Uso: $0 [dev|logs|reload|run|shell|status|stop]"
esac
