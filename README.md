# Aplicación de prueba de gestión de cookies 

Empleada en la Tarea 3.2 de la asignatura de Seguridad (44835) del Master
TWCNAM de la Universidad de Valencia en el curso 2018-2019.

## Descripción

Aplicación [flask](http://flask.pocoo.org/) que ajusta _cookies_ en el
navegador y muestra las que recibe del cliente.

La aplicación está preparada para ejecutarse en el contenedor
[uwsgi-nginx-flask](https://hub.docker.com/r/tiangolo/uwsgi-nginx-flask) y
lanza un segundo contenedor que hace de proxy inverso empleando la imagen
[tls-proxy](https://hub.docker.com/r/flaccid/tls-proxy)

## Ejecución

Para ejecutar la aplicación usar el script `./docker.sh`.
