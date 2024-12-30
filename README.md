<h1 align="center">Bacularis and Bacula community edition - Docker</h1>

- [Docker Images](#docker-images)
- [Bacula](#bacula)
  - [Bacula linux binaries](#bacula-linux-binaries)
  - [Bacula windows binaries](#bacula-windows-binaries)
  - [Create bacula client config files](#create-bacula-client-config-files)
  - [Install bacula client on linux](docs/install_bacula_client_on_linux.md)
- [Bacularis](#bacularis---the-bacula-web-interface)
  - [For Linux](#for-linux)
  - [For Windows](#for-windows)
- [Install docker container](#install-docker-container)
  - [Docker variables](#docker-variables)
  - [Access WebUI](#access-webui)
  - [Access bconsole](#access-bconsole)
  - [DNS Records](#dns-records)
  - [Firewall rules](#firewall-rules)
  - [Add new autochanger](docs/add_new_autochanger.md)
  - [Add new storage and scheduler](docs/add_new_storage_and_scheduler.md)
  - [Add new windows_pool](docs/add_new_windows_pool.md)
  - [Customize notification from bacula](#Customize-notification-from-bacula)
  - [Docker Exim Relay Image](#docker-exim-relay-image)
  - [Script check storage is mounted](docs/using_script_check_storage_is__mounted.md)
- [Backup](#backup)
  - [Backup mysql database](#backup-mysql-database)
  - [Backup postgres database](#backup-postgres-database)
  - [Backup docker container](docs/backup_docker_container.md)
  - [Script check storage is mounted](docs/using_script_check_storage_is_mounted.md)
- [My Docker hub](#my-docker-hub)

## Docker images 🐋

Images are based on [Ubuntu 22](https://hub.docker.com/repository/docker/johann8/bacularis/general) or [Alpine 3.21](https://hub.docker.com/repository/docker/johann8/bacularis/general). Unfortunately, [Alpine](https://pkgs.alpinelinux.org/packages?page=1&branch=v3.21&name=bacula%2A) repository does not include a cloud driver for bacula storage. Bacula community repository for [Ubuntu](https://www.bacula.org/packages/6367abb52d166/debs/15.0.2/dists/jammy/main/binary-amd64/), on the other hand, does have a cloud driver for bacula storage. Therefore I had to create two docker images. Ubuntu docker image does have a cloud driver for bacula storage.

| pull | size ubuntu | size alpine | version ubuntu | version alpine | platform |
|:---------------------------------:|:--------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/bacularis?logo=docker&label=pulls&style=flat-square&color=blue) | ![Docker Image Size](https://img.shields.io/docker/image-size/johann8/bacularis/latest-ubuntu?logo=docker&style=flat-square&color=blue&sort=semver) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/bacularis/latest-alpine?logo=docker&style=flat-square&color=blue&sort=semver) | [![](https://img.shields.io/docker/v/johann8/bacularis/latest-ubuntu?logo=docker&style=flat-square&color=blue&sort=semver)](https://hub.docker.com/r/johann8/bacularis/tags "Version badge") | [![](https://img.shields.io/docker/v/johann8/bacularis/latest-alpine?logo=docker&style=flat-square&color=blue&sort=semver)](https://hub.docker.com/r/johann8/bacularis/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") |

| ALpine version | Ubuntu version | Bacularis version |
|:---------------------------------:|:--------------------------------:|:--------------------------------:|
| [![Alpine Version](https://img.shields.io/badge/Alpine%20version-v3.21.0-blue.svg?style=flat-square)](https://alpinelinux.org/) | [![Ubuntu Version](https://img.shields.io/badge/Ubuntu%20version-22.04-blue.svg?style=flat-square)](https://ubuntu.com/) | [![Bacularis Version](https://img.shields.io/badge/Bacularis%20version-4.5.1-orange.svg?style=flat-square)](https://bacularis.app/) |

## Bacula
[Bacula](https://www.bacula.org/) is a set of Open Source, computer programs that permit you to manage backup, recovery, and verification of computer data across a network of computers.

## Bacularis - The Bacula web interface
[Bacularis](https://github.com/bacularis/bacularis-app) is a web interface to configure, manage and monitor Bacula backup environment. It is a complete solution for setting up backup jobs, doing restore data, managing tape or disk volumes in local and remote storage, work with backup clients, and doing daily administrative work with backup.

## Bacula linux binaries
[Bacula](https://www.bacula.org/) linux binaries Deb / Rpm can be found on [Bacula website](https://www.bacula.org/bacula-binary-package-download/). To access these binaries, you will need an access key, which will be provided when you complete a simple registration.

## Bacula windows binaries
[Bacula](https://www.bacula.org/)  windows binaries can be found on [Bacula website](https://www.bacula.org/binary-download-center/).

## Install docker container

- Create folders, set permissions

```bash
# create folders
mkdir -p /opt/bacularis/data/{bacularis,bacula,pgsql}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-api/API/{Config,Logs}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-web/Web/{Config,Logs}
mkdir -p /opt/bacularis/data/bacula/{etc,working}
mkdir -p /opt/bacularis/data/pgsql/{data,socket}
mkdir -p /opt/bacularis/data/smtp/secret
tree -d -L 6 /opt/bacularis

# create bacula storage folder
mkdir -p /mnt/USB_NFS_PVE01/bstorage/archive

# set rights: 101 - bacula user uid and gid; 26 - tape group gid
chown 101:101 /opt/bacularis/data/bacula/etc
chown 101:101 /opt/bacularis/data/bacula/working
chown 101:26  /mnt/USB_NFS_PVE01/bacula/archive
```
- Create [docker-compose.yml](https://github.com/johann8/bacularis-ubuntu/blob/master/docker-compose.yml)\
or
- Download all files below

```bash
cd /opt/bacularis
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/docker-compose.override.yml
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/.env

# show used subnets
cd /opt/bacularis && grep -r SUBNET /opt/*
```
- Customize variables in all files
- Generate `admin` user `password` [here](https://www.web2generators.com/apache-tools/htpasswd-generator). You need both passwords decrypt and encrypted

```
# generate admin password
pwgen -1cnsB 20 5

# Example
Username: admin
Password decrypt: N04X1UYYbZ2J69sAYLb0N04
Password encrypted: $apr1$o2vlak5p$saFj/wl/MeGxQysvc462R1 
```

- Customize the file `docker-compose.override.yml` if you use [trafik](https://traefik.io/)
- Run docker container

```bash
cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```
- check if all services in container are running
```bash
dcexec bacularis bash
ss -tln
exit
```

- Adjust postgres database access rights file pg_hba.conf

```bash
# show IP Address of bacula-db
CONTAINER_NAME=$(docker ps --format 'table {{.ID}}\t{{.Names}}' |grep bacula-db |awk '{print $1}')
dcexec bacula-db cat /etc/hosts |grep ${CONTAINER_NAME}

# change pg_hba.conf
vim /opt/bacularis/data/pgsql/data/pg_hba.conf
---------------
from
...
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
...

to
...
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             172.26.2.0/24           trust
...
-------------
```
- Change var DB_INIT=true to DB_INIT=false

```bash
cd /opt/bacularis && vim docker-compose.yml
--------------
    environment:
from
...
      - DB_INIT=true
...

to
...
      - DB_INIT=false
...
-------------
```
- Disable accwss to `pgsql socket`

```bash
cd /opt/bacularis && vim docker-compose.yml
--------------
...
    volumes:
...

from

      - ${DOCKERDIR}/data/pgsql/socket:/var/run/postgresql          # comment after install
to
      #- ${DOCKERDIR}/data/pgsql/socket:/var/run/postgresql          # comment after install
...
-------------
```

- First access to bacularis

```bash
URL: https://bacularis.mydomain.de
User: admin
```
- First restart of docker container

```bash
cd /opt/bacularis
docker-compose down && docker-compose up -d
```


# Docker variables
- Bacularis docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| TZ | Europe/Berlin | Time zone |
| DB_INIT | true or false | true - required for DB init only (first run) |
| DB_UPDATE | false or true | true - required for DB update only |
| DB_HOST | bacula-db | PostgreSQL db host name  |
| DB_PORT | 5432 | PostgreSQL db port  |
| DB_NAME | bacula  | bacula database name |
| DB_USER | bacula  | bacula user name  |
| DB_PASSWORD | MyDBPassword  | password use to access to the bareos database |
| DB_ADMIN_USER | postgres  | PostgreSQL root user name (required for DB init only) |
| DB_ADMIN_PASSWORD | MyDBAdminPassword | Password for PostgreSQL root user (required for DB init only) |
| BUILD_DAEMON_NAME | build-3-17-x86_64 |  from alpine assigned bacula daemons name |
| DESIRED_DAEMON_NAME | bacula | desired name for bacula daemons |
| WEB_ADMIN_USER | admin | User name for bacula web interface |
| WEB_ADMIN_PASSWORD_DECRYPT | MyWebPassword  | User password (decrypt) for bacula web interface |
| WEB_ADMIN_PASSWORD_ENCRYPTED | $apr1$1fvq6ki0$AScxxxx | User password (encrypted) for bacula web interface  |
| SMTP_HOST | smtpd:8025 | docker container smtp service - name & port |
| ADMIN_MAIL | admin@mydomain.de | your email address |
| ADD_STORAGE_POOL | true or false | true - standard pool are replaced by Incremental, Differential and Full |
| DOCKER_HOST_IP | 192.168.2.10 | IP address of docker host |
| DOCKERDIR | /opt/bacularis | Docker container config and data folder |
| PORT_BACULARIS | 9097 | Bacula port for Web interface |
| PORT_STORAGE | 9103  | Bacula port for storage daemon: bacula-sd |
| PORT_DIRECTOR | 9101  | Bacula port for director daemon: bacula-dir  |
| MEMORY_LIMIT | 1024 MB | PHP memory_limit in MB |

- bacula-db docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| TZ | Europe/Berlin | Time zone |
| DB_ADMIN_USER | postgres | PostgreSQL root user name (required for DB init only) |
| DB_ADMIN_PASSWORD | MyPostgresRootPassword | Password for PostgreSQL root user (required for DB init only) |

- smtpd docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| HOSTNAME_SMTP | bacularis.mydomain.de | hostname of smtp server |
| SMARTHOST | smtp.mydomain.de | smtp server FQDN |
| SMTP_USERNAME | backup@mydomain.de | smtp server user name |
| SMTP_PASSWORD | SmtpUserPassword | smtp server user password |

## Access WebUI

- Open `http://host.domain.com:9097` or via traefik `https://host.domain.com` in your web browser then sign-in
- Login with your `admin` user credentials (user: `admin` / pass: `<ADMIN_PASSWORD_DECRYPT>`)
- Check the `bacula director` settings

## Access bconsole

- With docker
```bash
docker exec -it bacularis bconsole
```

- With docker-compose
```bash
cd /opt/bacularis
docker-compose exec bacularis bconsole
```

## DNS Records

| Name | Type | Data |
|-------------------:|:--------------------:|:---------------------|
| bacularis  | CNAME | traefik-host.mydomain.de |
| bacula-dir | CNAME | docker-host.mydomain.de  |
| bacula-sd  | CNAME | docker-host.mydomain.de  |


## Customize notification from bacula
- If you have several companies / customers, it quickly becomes confusing when checking the emails. To avoid this, add the company/customer name to the `bacula-dir` configuration. For example:

```bash
# customize variable
FIRMA=MyFirma
PATH_TO_BACULA_DIR=/opt/bacularis/data/bacula/etc/bacula-dir.conf

sed -i -e "s/Bacula:/Bacula ${FIRMA}:/" ${PATH_TO_BACULA_DIR}
cat ${PATH_TO_BACULA_DIR}  |grep "Bacula ${FIRMA}:"

sed -i -e "s/Bacula daemon message/Bacula ${FIRMA} daemon message/" ${PATH_TO_BACULA_DIR}
cat ${PATH_TO_BACULA_DIR} |grep "Bacula ${FIRMA} daemon message"
```

## Firewall rules

Ports that need to be opened in firewall.

| port | protocol | description |
|-------------------:|:--------------------:|:-------------------------------------------------|
| 9102 | TCP |For bacula-fd file daemon |
| 9103 | TCP |For bacula-sd storage daemon |
| 9097 | TCP |For Bacularis-APP without RP (Traefik) |
|  443 | TCP |For Bacularis-APP with RP (Traefik) |

- Example for CentOS/Oracle/Rocky Linux

```bash
firewall-cmd --permanent --zone=public --add-port=9102/tcp
firewall-cmd --permanent --zone=public --add-port=9103/tcp
firewall-cmd --permanent --zone=public --add-port=9097/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --reload
firewall-cmd --list-all
```

## Docker Exim Relay Image
[Exim mail relay](https://exim.org) is a lightweight Docker image, based on the official Alpine image. You can see the documentation for this [here](https://github.com/devture/exim-relay)

## Create bacula client config files
You can create client config files automatically. For this you can find some scripts and templates on the repo. You load the files into a directory and start the bash scripts. Run `scriptname -h / --help` to see help.

### For Linux

---
- SSH login to `bacula docker host`
- Download files below in a directory

```bash
cd /tmp
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template_windows.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bconsole_template.conf
chmod u+x *.sh
```
- To create configuration for Bacula `Linux` client on server side, you need to pass two parameters to script 1, namely `client name` and `IP address`
- To create configuration for Bacula `Linux` client on client side, you need to pass only one parametes to script 2, namely `client name`
- The MD5 `bacula client` password will be automatically created by the script
- The `bacula-mon` password will be automatically read from `bacula server` configuration.
- When everything is ready, run the scripts to create bacula linux client config files. Here is an example:

```bash
CLIENT_NAME=srv01
IP_ADDRESS=$(ip addr show $(ip route | awk '/default/ {print $5}') |grep -w inet | awk '/inet/ {print $2}' | cut -d'/' -f1)
echo ${IP_ADDRESS}

./1_create_new_bacula_client_linux--server_side_template.sh -n ${CLIENT_NAME} -ip ${IP_ADDRESS}
./2_create_new_bacula_client_linux--client_side_template.sh -n ${CLIENT_NAME}
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
# stop bacula docker stack
cd /opt/bacularis && docker-compose down
cd -

# add client config to bacula-dir
cat config_files/bacula-dir_srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula-dir.conf

# run bacula docker stack
cd /opt/bacularis && docker-compose up -d && docker-compose exec bacularis bash

# reread config
bconsole
reload
q
exit
cd -

```
- The created files `bacula-fd_srv01.conf` and `bconsole_srv01.conf` must be copied from `bacula docker host` to client by folder `/opt/bacula/etc`
- SSH to `bacula client` host
- Copy files `bacula-fd_srv01.conf` and `bconsole_srv01.conf` from `bacula docker host`

```bash
# on docker host - copy config files to bacula client host
scp config_files/bacula-fd_pve01.conf config_files/bconsole_pve01.conf user@bacula-client-ip:/tmp
ssh user@bacula-client-ip
cd /opt/bacula/etc

# create backup of old files
mv bacula-fd.conf bacula-fd.conf.back
mv bconsole.conf bconsole.conf.back

# move files
mv /tmp/bacula-fd_srv01.conf bacula-fd.conf
mv /tmp/bconsole_srv01.conf bconsole.conf
systemctl restart bacula-fd.service

# delete files
cd /tmp
rm -rf bacula-* bconsole_template.conf config_files *.sh

#
### if bacula client is running on the docker host, than
#
cd /opt/bacula/etc
mv bacula-fd.conf bacula-fd.conf.back
mv bconsole.conf bconsole.conf.back
\cp /tmp/config_files/bacula-fd_oraclel8.conf ./bacula-fd.conf
\cp /tmp/config_files/bconsole_oraclel8.conf ./bconsole.conf
systemctl restart bacula-fd.service

# delete files
cd /tmp
rm -rf bacula-* bconsole_template.conf config_files *.sh
```

### For Windows

---
- Download files below in a directory

```bash
cd /tmp
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-dir_template_windows.conf
chmod u+x *.sh
```
- To create configuration for Bacula `Windows` client on server side, you need to pass two parameters to script 3, namely `client name` and `IP address`
- The MD5 Bacula client password is automatically created by the script
- When everything is ready, run the scripts to create bacula windows client config files. Here is an example:

```bash
cd /tmp
CLIENT_NAME=win-srv01
IP_ADDRESS="192.168.155.5"
./3_create_new_bacula_client_windows--server_side_template.sh -n win-srv01 -ip 192.168.155.8
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_win-srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
cat config_files/bacula-dir_win-srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cd /opt/bacularis && docker-compose exec bacularis bash
bconsole
reload
q
exit
```
### Bacula Windows client install

For the installation of Bacula Windows client you need the name of Bacula Director `bacula-dir`, MD5 password of bacula windows client and the ip address of docker host.

- You can read out MD5 bacula client password from created config file `bacula-dir_win-srv01.conf`

```bash
cat config_files/bacula-dir_win-srv01.conf | sed -n '/Client {/,+4p' | grep -w Password |cut -f 2 -d '"'
```

As a result comes something like this: `[md5]607e60c2c1f4f859679fbe9d742b0c59`

- You need the ip address of `docker host`. This ip address is specified as `bacula-dir` ip address. You can execute the following command on `docker host` to find out the ip address:

```bash
ip addr show $(ip route | awk '/default/ {print $5}') |grep -w inet | awk '/inet/ {print $2}' | cut -d'/' -f1
```
As a result comes something like this: `192.168.155.15`

- Download [Bacula](https://www.bacula.org/) windows binaries from [Bacula website](https://www.bacula.org/binary-download-center/)
- Run bacula installation
- Fill in the data as in the picture
![Bacula_Windows_Install](https://raw.githubusercontent.com/johann8/bacularis/master/docs/assets/screenshots/bacula_win_install.png)
- Finish the installation
- Open the file `C:\Program Files\Bacula\bacula-fd.conf`
- Find the section

```
#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = bacula-dir
  Password = "Ck7WxwW8xfew45stslKdXoPGIAk+8QyB07tli92W1XWC"        # Director must know this password

```

- Replace the password with the MD5 password from the client

```
#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = bacula-dir
  Password = "[md5]607e60c2c1f4f859679fbe9d742b0c59"        # Director must know this password

```

- Restart Windows bacula daemon
- Windows firewall configuration - unblock ports 9102/TCP and 9103/TCP for incoming rules

# Backup
## Backup mysql database

- Download script below to the client

```bash
cd /opt/bacula/scripts/
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/scripts/backup_mysql.sh
chmod a+x backup_mysql.sh
cd -
```
- Start Bacularis-App and browse to: Director => Configure director => Job => Name => Edit => +Add => +Add Runscript block
- Fill out as in the picture (Path to the location of the script)
![Job_Add_run_script](https://github.com/johann8/bacularis-ubuntu/raw/master/docs/assets/screenshots/add_run_script_job.png)

- Browse to: Director => Configure director => Fileset => Name => Edit => Include #1 +Add => +Add single file/directory
- Fill out as in the picture (Var "DST" from script /var/backup/container/mysql)
![Fileset_Add_singe_file_directory](https://github.com/johann8/bacularis-ubuntu/raw/master/docs/assets/screenshots/fileset_add_single_file-directory.png)

## Backup postgres database

For Postgres DB backup the Script [autopostgresqlbackup](https://github.com/k0lter/autopostgresqlbackup) is used. There is a [docker container](https://hub.docker.com/r/rogersik/autopostgresqlbackup) with this script. You can find a description and configaration example [here](https://gitea.sikorski.cloud/RogerSik/docker-autopostgresqlbackup).

- Here is an example of how to backup Postgres database in a docker container

```bash
# create backup destination
mkdir -p /var/backup/container/postgres

# Add to the docker container where the dostgres database runs

...
  autopgbackup:
    image: rogersik/autopostgresqlbackup:latest
    container_name: autopgbackup
    environment:
      - DBHOST=${POSTGRES_HOST}
      - USERNAME=${POSTGRES_USER}
      - PASSWORD=${POSTGRES_PASSWORD}
      - CRON_LOG_LEVEL=0                            # Most verbose is 0, less verbose is 8
      - CRON_SCHEDULE=50 22 * * *                   # valid cron specification
      - LATEST=yes                                  # Additionally keep a copy of the most recent backup in a seperate directory
    volumes:
     - /var/backup/container/postgres:/backups
     - /etc/localtime:/etc/localtime:ro
    depends_on:
      - postgresdb
...
```
- Start Bacularis-App and browse to: Director => Configure director => Fileset => Name => Edit => Include #1 +Add => +Add single file/directory
- Fill out as in the picture (Volume path fron docker-compose.yml: /var/backup/container/postgres)
![Fileset_Add_singe_file_directory](https://github.com/johann8/bacularis-ubuntu/raw/master/docs/assets/screenshots/fileset_add_single_file-directory.png)

## My Docker hub

- [Docker images](https://hub.docker.com/repository/docker/johann8/bacularis/general)

Enjoy !

