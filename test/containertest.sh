#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

HOST_PORT="1081"
CONTAINER_PORT="80"

echo "checking tool versions"
docker run -it `awk '{print $1}' .docker_image` php --version | grep "PHP 7"
docker run -it `awk '{print $1}' .docker_image` drush --version
docker run -it `awk '{print $1}' .docker_image` wp --version

echo "starting container for tests"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=docroot" -d --name web-local-test -d `awk '{print $1}' .docker_image`
CONTAINER_NAME=web-local-test ./test/containercheck.sh

function cleanup {
	echo "Removing web-local-test"
	docker rm -f web-local-test 2>/dev/null
}
trap cleanup EXIT

echo "testing error states"
# These are just the standard nginx 403 and 404 pages
curl localhost:$HOST_PORT/ | grep "403 Forbidden"
curl localhost:$HOST_PORT/asdf | grep "404 Not Found"
# We're just checking the error code here - there's not much more we can do in
# this case because the container is *NOT* intercepting 50x errors.
curl -w "%{http_code}" localhost:$HOST_PORT/test/500.php | grep 500
# 400 and 401 errors are intercepted by the same page.
curl localhost:$HOST_PORT/test/400.php | grep "ddev web container"
curl localhost:$HOST_PORT/test/401.php | grep "ddev web container"

echo "testing php and email"
curl --fail localhost:$HOST_PORT/test/phptest.php
curl -s localhost:$HOST_PORT/test/test-email.php | grep "Test email sent"
docker stop web-local-test && docker rm web-local-test

echo "testing use of custom nginx config"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=potato" -v `pwd`/test/test-custom.conf:/var/www/html/.ddev/nginx-site.conf -d --name web-local-test -d `awk '{print $1}' .docker_image`
docker exec -it web-local-test cat /etc/nginx/sites-enabled/nginx-site.conf | grep "docroot is /var/www/html/potato in custom conf"

