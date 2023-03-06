#!/usr/bin/env bash

set -e

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

. /docker-entrypoint.inc


function start()
{
    start_php_fpm
}

function stop()
{
    stop_php_fpm
}

start

exec "$@"
