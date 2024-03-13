#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

sed -i s/__RENDER_EXTERNAL_HOSTNAME__/"${RENDER_EXTERNAL_HOSTNAME}"/g /etc/apache2/sites-enabled/apache.conf

. /etc/apache2/envvars

curl -sSLO https://raw.githubusercontent.com/tshr20180821/render-12/main/start_after.sh?"$(date +%s)"

chmod +x ./start_after.sh

sleep 5s && ./start_after.sh &

cat /etc/apache2/apache2.conf

# apache start

exec /usr/sbin/apache2 -DFOREGROUND
