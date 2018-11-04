#!/bin/sh

BROWSER="firefox"

HTTP_DOCKER_NAME="flask-cookiejar-app"
HTTPS_DOCKER_NAME="flask-cookiejar-tls"
DOCKER_DOMAIN="docker.local"
HTTP_DOCKER_FQDN="$HTTP_DOCKER_NAME.$DOCKER_DOMAIN"
HTTPS_DOCKER_FQDN="$HTTPS_DOCKER_NAME.$DOCKER_DOMAIN"

SERVER_HTTP_URL="http://$HTTP_DOCKER_FQDN/"
SERVER_HTTPS_URL="https://$HTTPS_DOCKER_FQDN/"

LD_PRELOAD="/usr/lib/libnss_wrapper.so"
NSS_WRAPPER_HOSTS="$HOME/.nss_wrapper_hosts"

# Function
docker_ip() {
    docker inspect \
		   -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

update_wrapper_hosts() {
	for dn in $HTTP_DOCKER_NAME $HTTPS_DOCKER_NAME; do
		DOCKER_IP="$(docker_ip $dn)"
		if [ "$dn" = "$HTTP_DOCKER_NAME" ]; then
			DOCKER_FQDN="$HTTP_DOCKER_FQDN"
		else
			DOCKER_FQDN="$HTTPS_DOCKER_FQDN"
		fi
		if [ -z "$DOCKER_IP" ]; then
			echo "Docker container '$dn' not available... "
			echo "Start the container '$dn' before calling this script"
			exit 1
		fi
		if grep -qs "${DOCKER_FQDN}$" "$NSS_WRAPPER_HOSTS"; then
			sed -i -e "/ ${DOCKER_FQDN}$/ { s/^.*$/$DOCKER_IP $DOCKER_FQDN/ }" \
				"$NSS_WRAPPER_HOSTS"
		else
			echo "$DOCKER_IP $DOCKER_FQDN" >> "$NSS_WRAPPER_HOSTS"
		fi
	done
}

export LD_PRELOAD
export NSS_WRAPPER_HOSTS

case "$1" in
	""|http) update_wrapper_hosts; exec $BROWSER $SERVER_HTTP_URL;;
	https)   update_wrapper_hosts; exec $BROWSER $SERVER_HTTPS_URL;;
	*)       echo "Usage: $0 [http|https]";;
esac
