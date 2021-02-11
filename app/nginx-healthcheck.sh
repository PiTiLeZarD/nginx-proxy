#!/bin/sh

if [ -z "$(cat /etc/hosts | grep health.check)" ]; then
    echo "127.0.0.1 health.check" >> /etc/hosts
fi

curl --fail http://health.check/ping
exit $?
