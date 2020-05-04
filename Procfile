cron: cron -f
dockergen: docker-gen -watch /app/nginx.tmpl /etc/nginx/node.conf.d/${NODE_HOSTNAME:-`hostname`}.conf
nginx: nginx
