# Bacularis and Bacula community edition - Docker

- [Docker Images](#docker-images)
- [Bacula](#bacula)
  - [Bacula linux binaries](#bacula-linux-binaries)
  - [Bacula windows binaries](#bacula-windows-binaries)
  - [Create bacula client config files](#create-bacula-client-config-files)
- [Bacularis](#bacularis---the-bacula-web-interface)
  - [For Linux](#for-linux)
  - [For Windows](#for-windows)
- [Install docker container](#install-docker-container)

## Docker images

Images are based on [Ubuntu 22](https://hub.docker.com/repository/docker/johann8/bacularis/general) or [Alpine 3.17](https://hub.docker.com/repository/docker/johann8/bacularis/general)

| pull | size ubuntu | size alpine |
|:---------------------------------------:|:---------------------------------------:|:-------------------------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/bacularis?style=flat-square) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/bacularis/latest-ubuntu) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/bacularis/latest-alpine) |

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
mkdir -p /opt/bacularis/data/{bacularis,bacula,pgsql}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-api/API/{Config,Logs}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-web/Web/{Config,Logs}
mkdir -p /opt/bacularis/data/bacula/{config,data}     
mkdir -p /opt/bacularis/data/bacula/config/etc/bacula
mkdir -p /opt/bacularis/data/bacula/data/director/{archive,working}
mkdir -p /opt/bacularis/data/pgsql/{data,socket}
mkdir -p /opt/bacularis/data/smtp/secret
chown 101:101 /opt/bacularis/data/bacula/data/director/working
chown 101:26 /opt/bacularis/data/bacula/data/director/archive
tree -d -L 4 /opt/bacularis
```
- Create [docker-compose.yml](https://github.com/johann8/bacularis-ubuntu/blob/master/docker-compose.yml)\
or
- Download all files below

```bash
cd /opt/bacularis
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/docker-compose.override.yml
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-dir_template_windows.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/bconsole_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/.env
```
- Customize variables in all files
- Generate `admin` user `password` [here](https://www.web2generators.com/apache-tools/htpasswd-generator). You need both passwords decrypt and encrypted

```
# Example
Username: admin
Password: N04X1UYYbZ2J69sAYLb0N04
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

- Starte `http://dost.domain.com:9097` or via traefik `http://host.domain.com`
- Login with your `admin` user credentials
- Check the `bacula director` settings

## Create bacula client config files
You can create client config files automatically. For this you can find some scripts and templates on the repo. You load the files into a directory and start the bash scripts. Run `scriptname -h / --help` to see help.

### For Linux

---
- Download files below in a directory

```bash
wget https://raw.githubusercontent.com/johann8/bacularis/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis/master/bconsole_template.conf
```
- To create configuration for Bacula `Linux` client on server side, you need to pass two parameters to script 1, namely `client name` and `IP address`
- To create configuration for Bacula `Linux` client on client side, you need to pass only one parametes to script 2, namely `client name`
- The MD5 Bacula client password is automatically created by the script
- The `bacula-mon` password you can read out from server configuration. After that you can insert the password into the script: `2_create_new_bacula_client_linux--client_side_template.sh`. The variable is called `DIRECTOR_CONSOLE_MONITOR_PASSWORD`. You must use single quote marks. Here is an example:\
`DIRECTOR_CONSOLE_MONITOR_PASSWORD='MySuperPassword'`
- An example: login to the server where docker container is running with bacula server. Adjust the path of `bacula-dir` configuration file and execute the commands below

```bash
BACULA_SERVER_CONFIG_DIR_DOCKER=/opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cat ${BACULA_SERVER_CONFIG_DIR_DOCKER} |sed -n '/bacula-mon/,+1p' |grep Password |cut -f 2 -d '"'
vim 2_create_new_bacula_client_linux--client_side_template.sh            # And insert "bacula-mon" password    
```
- When everything is ready, run the scripts to create bacula linux client config files. Here is an example:

```bash
./1_create_new_bacula_client_linux--server_side_template.sh -n srv01 -ip 192.168.155.5
./2_create_new_bacula_client_linux--client_side_template.sh -n srv01
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
cat config_files/bacula-dir_srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cd /opt/bacularis && docker-compose exec bacularis bash
bconsole
reload
```
- The created files `bacula-fd_srv01.conf` and `bconsole_srv01.conf` must be copied to client by folder `/opt/bacula/etc`

```bash
cd /opt/bacula/etc
# create backup of old files
mv bacula-fd.conf bacula-fd.conf.back
mv bconsole.conf bconsole.conf.back

# rename files
mv bacula-fd_srv01.conf bacula-fd.conf
mv bconsole_srv01.conf bconsole.conf
systemctl restart bacula-fd.service
```
### For Windows

---
- Download files below in a directory

```bash
wget https://raw.githubusercontent.com/johann8/bacularis/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-dir_template_windows.conf
```
- To create configuration for Bacula `Windows` client on server side, you need to pass two parameters to script 3, namely `client name` and `IP address`
- The MD5 Bacula client password is automatically created by the script
- When everything is ready, run the scripts to create bacula windows client config files. Here is an example:

```bash
./3_create_new_bacula_client_windows--server_side_template.sh -n win-srv01 -ip 192.168.155.8
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_win-srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
cat config_files/bacula-dir_win-srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cd /opt/bacularis && docker-compose exec bacularis bash
bconsole
reload
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

