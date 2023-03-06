#!/usr/bin/env bash

set -e

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

. /docker-entrypoint.inc


function start()
{
    start_postgresql
    start_bacula_dir
    start_php_fpm
    
}

function stop()
{
    stop_bacula_dir
    stop_postgresql
    stop_php_fpm
}

start

exec "$@"