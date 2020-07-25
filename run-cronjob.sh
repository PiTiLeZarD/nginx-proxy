#!/bin/bash

source /cron_env.sh

log() {
    printf '[%s %s]: %s\n' "$(date +%F)" "$(date +%T)" "$*"
}

if [ -z "$1" ]; then
    log ERROR "need name of cron job as first argument" >&2
    exit 1
fi

if [ ! -x "$1" ]; then
    log ERROR "cron job file $1 not executable, exiting" >&2
    exit 1
fi

if "$1"; then
    exit 0
else
    log ERROR "cron job $1 failed! ($*)" 2>/proc/1/fd/2 >&2
    exit 1
fi