#!/bin/bash

export PGDATA='/var/lib/postgresql/data'
POSTGRESQL_USER='postgres'
BACULA_USER='bacula'

function initdb()
{
    chown ${POSTGRESQL_USER} ${PGDATA}
    chmod 700 ${PGDATA}
    su ${POSTGRESQL_USER} -c 'initdb'
}

function start_postgresql()
{
    if [ -z "$(ls -A "$PGDATA")" ];
    then
        initdb
    fi
    su ${POSTGRESQL_USER} -c 'pg_ctl start'
}

function stop_postgresql()
{
        su ${POSTGRESQL_USER} -c "pg_ctl stop"
}

function init_bacula()
{
        su ${POSTGRESQL_USER} -c '/opt/bacula/scripts/create_postgresql_database'
        su ${POSTGRESQL_USER} -c '/opt/bacula/scripts/make_postgresql_tables'
        su ${POSTGRESQL_USER} -c '/opt/bacula/scripts/grant_postgresql_privileges'
}

function start_bacula_dir()
{
    if ! su ${POSTGRESQL_USER} -c 'psql -l' | grep '^ bacula' 1>/dev/null
    then
        init_bacula
    fi

    /opt/bacula/scripts/bacula-ctl-dir start
}

function stop_bacula_dir()
{
    /opt/bacula/scripts/bacula-ctl-dir stop
}

function start_bacula_sd()
{
    /opt/bacula/scripts/bacula-ctl-sd start
}

function stop_bacula_sd()
{
    /opt/bacula/scripts/bacula-ctl-sd stop
}

function start_bacula_fd()
{
    /opt/bacula/scripts/bacula-ctl-fd start
}

function stop_bacula_fd()
{
    /opt/bacula/scripts/bacula-ctl-fd stop
}

function start_php_fpm()
{
    /etc/init.d/php8.1-fpm start
}

function stop_php_fpm()
{
    /etc/init.d/php8.1-fpm stop
}
