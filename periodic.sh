#!/bin/bash

source /cron_env.sh

md5sum /etc/nginx/node.conf.d/* > /tmp/md5.new

if [ ! -f /tmp/md5 ] || [ 0 != $(diff /tmp/md5 /tmp/md5.new | wc -l) ]; then
    mv /tmp/md5.new /tmp/md5
    python3 /app/mergeswarm.py
fi

