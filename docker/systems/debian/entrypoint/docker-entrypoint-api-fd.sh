#!/usr/bin/env bash

set -e

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

. /docker-entrypoint.inc


function start()
{
    start_bacula_fd
    start_php_fpm
    
}

function stop()
{
    stop_php_fpm
    stop_bacula_fd
}

start

exec "$@"