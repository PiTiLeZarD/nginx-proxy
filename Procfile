cron: cron -f
dockergen: docker-gen -watch -notify "python3 /app/mergeswarm.py" /app/nginx.tmpl /etc/nginx/node.conf.d/${NODE_HOSTNAME:-`hostname`}.conf
nginx: nginx
