#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

HOST_PORT="1081"
CONTAINER_PORT="80"
CONTAINER_NAME=web-local-test

docker rm -f web-local-test || true

echo "checking tool versions"
docker run -it `awk '{print $1}' .docker_image` php --version | grep "PHP 5"
docker run -it `awk '{print $1}' .docker_image` drush --version
docker run -it `awk '{print $1}' .docker_image` wp --version

echo "starting container for tests"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=docroot" -d --name web-local-test -d `awk '{print $1}' .docker_image`
./test/containercheck.sh

echo "testing php and email"
curl --fail localhost:$HOST_PORT/test/phptest.php
curl -s localhost:$HOST_PORT/test/test-email.php | grep "Test email sent"
docker rm -f $CONTAINER_NAME

echo "testing use of custom nginx config"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=potato" -v `pwd`/test/test-custom.conf:/var/www/html/.ddev/nginx-site.conf -d --name $CONTAINER_NAME `awk '{print $1}' .docker_image`
docker exec -it $CONTAINER_NAME cat /etc/nginx/sites-enabled/nginx-site.conf | grep "docroot is /var/www/html/potato in custom conf"
docker rm -f $CONTAINER_NAME
