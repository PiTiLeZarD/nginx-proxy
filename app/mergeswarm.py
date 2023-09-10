#!/root/.venvs/crossplane/bin/python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
from crossplane import parse, build

SWARM_CONFIG_FILE = '/etc/nginx/node.conf.d/swarm.conf'
NGINX_OUTPUT = '/etc/nginx/conf.d/default.conf'
NGINX_RELOAD = 'nginx -s reload'

if not os.path.isfile(SWARM_CONFIG_FILE):
    with open(SWARM_CONFIG_FILE, 'w') as f:
        f.write("http { include ./*.conf; }")

def valid_node(f):
    if not f['file']:
        return False
    if 'node.conf.d' not in f['file']:
        return False
    if 'swarm.conf' in f['file']:
        return False
    return not 'docker-gen' in f['file']

nginx_config = []
cache = []
swarm_config = parse(SWARM_CONFIG_FILE)['config']
nodes = [f['parsed'] for f in swarm_config if valid_node(f)]

def get_sub_statements(statement, directive):
    for sub_statement in statement['block']:
        if sub_statement['directive'] == directive:
            yield sub_statement


def get_sub_statement(statement, directive):
    return list(get_sub_statements(statement, directive))[0]


def serialise_statement(statement):
    out = statement['directive']
    out = "{0}={1}".format(out, ";".join(statement['args']))
    if statement['directive'] == 'server':
        server_name = get_sub_statement(statement, 'server_name')
        listen = get_sub_statement(statement, 'listen')
        out = "{0}[{1}/{2}]".format(out, serialise_statement(server_name), serialise_statement(listen))
    return out


for node in nodes:
    for statement in node:
        serialised = serialise_statement(statement)
        if serialised in cache:
            continue

        cache.append(serialised)
        nginx_config.append(statement)

with open(NGINX_OUTPUT, 'w') as f:
    f.write(build(nginx_config))

process = subprocess.Popen(NGINX_RELOAD.split(), stdout=subprocess.PIPE)
output, error = process.communicate()
if output:
    sys.stdout.write(output)
if error:
    sys.stderr.write(error)
