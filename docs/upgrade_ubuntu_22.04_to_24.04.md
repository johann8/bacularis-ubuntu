<h1 align="center">Bacula - Upgrade Docker Image Ubuntu 22.04 zu 24.04</h1>

Ubuntu 22.04 hat die PostgreSQL Version 14. Ubuntu 24.04 hat die PostgreSQL Version 16. D.h. wir müssen bei der Umstellung des Docker Images auch das Upgrade der Datenbank durchführen.
 
> ⚠️ **Attention**: Bacula User unter Ubuntu 24.04 hat **`UID=100`** statt **`UID=101`** unter Ubuntu 22.04.


##  Bacula - Upgrade PostgreSQL

### Vor dem Upgrade

- Auf `bash` im Container zugreifen

```bash
cd /opt/bacularis
docker compose exec bacula-db bash
```

- Info über die Datenbank anzeigen lassen

```bash
### show databases, users and rights
# psql --username postgres --dbname bacula
psql --username postgres

# list dbs
postgres=# \l

# list user
postgres=# \du

# postgres shell verlassen
postgres=# \q

# PostgesSQL Version anzeigen lassen
psql -V

# container verlassen
exit
```

- Rechte für den PostgresSQL DB Ordner anzeigen lassen

```bash 
ls -la ls -la data/pgsql/
----
drwx------ 19   70 root 4096 20. Feb 23:26 data
----

ls -la data/pgsql/data/
----
...
drwx------  6   70   70  4096 18. Jul 2022  base
drwx------  2   70   70  4096 20. Feb 23:27 global
...
----
```

- `Dump` von PostgreSQL DB `bacula` erstellen

```bash
docker compose exec bacula-db pg_dump -U postgres -d bacula -cC > upgrade_backup_pg14.sql    
```

- Ergebnis anzeigen lassen

```bash title="ls -lah"
-rw-r--r--  1 root root 326M 25. Feb 15:25 upgrade_backup_pg14.sql
```

- Monitoring Tool `monit` anhalten

```bash
systemctl stop monit
systemctl status monit
```

- Docker Stack anhalten

```bash
cd /opt/bacularis
docker compose down
```
- Baculas `working` Verzeichnis bereinigen

```bash
cd /opt/bacularis
ls -la data/bacula/data/director/working
rm -rf data/bacula/data/director/working/*.pid
rm -rf data/bacula/data/director/working/*.state
rm -rf data/bacula/data/director/working/*.conmsg
ls -la data/bacula/data/director/working
```

- Altes PostgreSQL DB Verzeichnis umbenennen

```bash
mv data/pgsql/data data/pgsql/db-data_14
```

- Neues PostgreSQL DB Verzeichnis erstellen

```bash
mkdir -p data/postgres/{db-data,socket}
chown 70 data/postgres/db-data
chown 70 data/postgres/socket
chmod 0700 data/postgres/db-data
chmod 0700 data/postgres/socket
```

- Verzeichnisstruktur anzeigen lassen

```bash title="ls -la data/postgres/"
drwx------  2   70 root 4096 21. Feb 12:07 db-data
drwx------ 19   70 root 4096 21. Feb 12:07 db-data_14
```

### PostgreSQL Upgrade starten

- Datei `docker-compose.yml` ändern

```bash
cd /opt/bacularis
vim docker-compose.yml
----
services:
  bacularis:
    ...
    volumes:
      # Bacula volumes
      #- ${DOCKERDIR}/data/bacula/config/etc:/opt/bacula/etc                   # Bacula config files & scripts
      #- ${DOCKERDIR}/data/bacula/data/director/working:/opt/bacula/working    # Bacula working folder
      #- ${DOCKERDIR}/data/bacula/data/director/bsr:/opt/bacula/bsr            # Bacula bsr folder
      #- /mnt/NAS_BareOS/bacula/archive:/opt/bacula/archive                    # Bacula storage folder

      - ./config:/opt/bacula/etc
      - ./working-data:/opt/bacula/working
      - ./storage:/opt/bacula/archive
      # Bacularis volumes
      - ${DOCKERDIR}/data/bacularis/www/bacularis-api/API/Config:/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config
      - ${DOCKERDIR}/data/bacularis/www/bacularis-api/API/Logs:/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Logs
      - ${DOCKERDIR}/data/bacularis/www/bacularis-web/Web/Config:/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config
      - ${DOCKERDIR}/data/bacularis/www/bacularis-web/Web/Logs:/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Logs
    ...
    environment:
      ...
      - DB_INIT=true                                            #should be 'true' if bareos db does not exist
      ...

  bacula-db:
    image: postgres:${DB_VERSION}
    container_name: bacula-db
    volumes:
      #- ${DOCKERDIR}/data/pgsql/data:/var/lib/postgresql/data
      #- ${DOCKERDIR}/data/pgsql/socket:/var/run/postgresql
      - ${DOCKERDIR}/data/postgres/db-data:/var/lib/postgresql/data
      - ${DOCKERDIR}/data/postgres/socket:/var/run/postgresql
  ...
----
```

- Datei `.env` ändern

```bash
cd /opt/bacularis
vim .env
----
...
#B_VERSION=latest-ubuntu
B_VERSION=latest-ubuntu-24.04
...
#DB_VERSION=14-alpine
DB_VERSION=16-alpine
...
----
```

- Download PostgreSQL Docker Image Version 16

```bash
docker compose pull
```

- Start Docker Stack

```bash
docker compose up -d bacula-db
docker compose ps
docker compose logs -f
----
bacula-db     | 2025-12-18 15:23:17.673 CET [73] FATAL:  password authentication failed for user "bacula"
bacula-db     | 2025-12-18 15:23:17.673 CET [73] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha
----
```

- Stop Docker Stack

```bash
docker compose down
```

- `SUBNET` anzeigen lassen

```bash
cat .env |grep SUBNET
----
SUBNET=172.26.2
----
```
- Datei `pg_hba.conf` ändern

```bash
vim data/postgres/db-data/pg_hba.conf
----
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             172.26.2.0/24           trust
----
```

- Start PostgreSQL Docker Container

```bash
docker compose down
docker compose up -d bacula-db
docker compose ps

docker compose logs -f
----
bacula-db  | PostgreSQL Database directory appears to contain a database; Skipping initialization
bacula-db  |
bacula-db  | 2026-03-03 12:41:16.030 CET [1] LOG:  starting PostgreSQL 16.13 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
bacula-db  | 2026-03-03 12:41:16.030 CET [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
bacula-db  | 2026-03-03 12:41:16.030 CET [1] LOG:  listening on IPv6 address "::", port 5432
bacula-db  | 2026-03-03 12:41:16.032 CET [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
bacula-db  | 2026-03-03 12:41:16.036 CET [30] LOG:  database system was shut down at 2026-03-03 12:40:31 CET
bacula-db  | 2026-03-03 12:41:16.041 CET [1] LOG:  database system is ready to accept connections
----
```

- Stoppe Docker Stack

```bash
docker compose down
docker compose ps
```

- Starte Docker Stack

```bash
docker compose up -d 
docker compose ps
docker compose logs -f
```

- Prüfe, dass die Datenbank und der User erstellt wurden

```bash
docker compose exec bacula-db bash
psql -U postgres
----
postgres=# \l
postgres=# \du
                             List of roles
 Role name |                         Attributes
-----------+------------------------------------------------------------
 bacula    | Create role, Create DB
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS

postgres=# \q
----
psql -V
exit
```
- Prüfe, ob die Verbindung zur Datenbank aus dem `Bacularis` Container heraus funktioniert.

```bash
docker compose exec bacularis bash
ls -la /opt/bacula/
cat /opt/bacula/.pgpass

# Verbindug herstellen
pg_isready --host=bacula-db --port=5432 --user=postgres

# Verbindug herstellen übrt Passworteingabe
env
psql -h bacula-db -p 5432 -U bacula -d bacula -W
bacula=> \q

# show bacula user UID and GID
cat /etc/passwd
-----
...
bacula:x:100:101:Bacula:/opt/bacula:/bin/bash
...
----

# show group tape GID
cat /etc/group
----
...
tape:x:26:bacula
...
----
exit
```
- Prüfen, ob die Startseite von Bacularis erreichbar ist und teste die Funktion

```bash
cat .env |grep ^ADMIN
ADMIN_USER=admin
ADMIN_MAIL=user@mydomain.de
ADMIN_PASSWORD_DECRYPT='xxxxxxxxxxxxxxxxxxxxx'
ADMIN_PASSWORD_ENCRYPTED='xxxxxxxxxxxxxxxxxxxxx'

# Login 
https://bacularis.mydomain.de/web/login/
```
- Wenn alles gut gelaufen ist - stoppe Docker Stack

```bash
docker compose down
docker compose ps
```

### PostgreSQL DB `dump` wiederherstellen

- Die Größe des Datenbankordners anzeigen und `Restore` starten

```bash
cd /opt/bacularis
ncdu data/postgres/db-data/
cat upgrade_backup_pg14.sql | docker compose exec -T bacula-db psql -U postgres
ncdu data/postgres/db-data/
```

- Stoppe Docker Stack

```bash
docker compose down
docker compose ps
```

- Datei `docker-compose.yml` ändern

```bash
cd /opt/bacularis
vim docker-compose.yml
----
...
services:
  bacularis:
...
    volumes:
      # Bacula volumes
      - ${DOCKERDIR}/data/bacula/config/etc:/opt/bacula/etc                   # Bacula config files & scripts
      - ${DOCKERDIR}/data/bacula/data/director/working:/opt/bacula/working    # Bacula bsr folder
      - /mnt/NAS_BareOS/bacula/archive:/opt/bacula/archive                    # Bacula storage folder
      #- ./config:/opt/bacula/etc
      #- ./working-data:/opt/bacula/working
      #- ./storage:/opt/bacula/archive
...
    environment:
...
      - DB_INIT=false                                            #should be 'true' if bareos db does not exist
...
----
```

- Zugrifsrechte anpassen

> ⚠️ **Attention**: Bacula User unter Ubuntu 24.04 hat **`UID=100`** statt **`UID=101`** unter Ubuntu 22.04.

```bash
cd /opt/bacularis

# Config Verzeichnis
ls -la data/bacula/config/etc/
chown -R 100:101 data/bacula/config/etc/bacula
ls -la data/bacula/config/etc/

# Working Verzeichnis
ls -la data/bacula/data/director/
chown -R 100:101 data/bacula/data/director/working
ls -la data/bacula/data/director/

# Archiv Verzeichnis
ls -la /mnt/NAS_BareOS/bacula/
chown -R 100:26 /mnt/NAS_BareOS/bacula/archive
ls -la /mnt/NAS_BareOS/bacula/

# Den Alten key manager löschen und neu initialisieren, wenn Docker Stack dtsrtet
mv data/bacula/config/etc/bacula/key-manager.conf data/bacula/config/etc/bacula/key-manager.conf_old
mv data/bacula/config/etc/bacula/gnupg data/bacula/config/etc/bacula/gnupg_old
cp config/key-manager.conf data/bacula/config/etc/bacula/
chown 100:101 data/bacula/config/etc/bacula/key-manager.conf
ls -la data/bacula/config/etc/bacula
```

- Starte Docker Stack

```bash
docker compose up -d
docker compose ps
docker compose logs -f
docker compose logs -f bacularis
```
- Ubuntu Version im Docker Container anzeigen lassen

```bash
docker compose exec bacularis bash
cat /etc/os-release
----
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
----
exit
```
- Prüfen, ob Bacula Services im Container laufen laufen

```bash
docker compose exec bacularis bash
ss -t -a
exit
```
- Key-Manager im Container installieren und aufräumen

```bash
/opt/bacula/scripts/install-key-manager.sh install
ls -la /opt/bacula/etc
ls -la /opt/bacula/etc/gnupg

rm -rf /opt/bacula/etc/key-manager.conf_old
rm -rf /opt/bacula/etc/gnupg_old/
ls -la /opt/bacula/etc/
exit
```

- Prüfen, ob die Startseite von Bacularis erreichbar ist und teste die Funktion

```bash
cat .env |grep ^ADMIN
ADMIN_USER=admin
ADMIN_MAIL=user@mydomain.de
ADMIN_PASSWORD_DECRYPT='xxxxxxxxxxxxxxxxxxxxx'
ADMIN_PASSWORD_ENCRYPTED='xxxxxxxxxxxxxxxxxxxxx'

# Login
https://bacularis.mydomain.de/web/login/
```

### Nach dem Upgrade


- Datei docker-compose.yml bereinigen

```bash
cd /opt/bacularis
vim docker-compose.yml
----
services:
  bacularis:
...
    volumes:
      # Bacula volumes
      - ${DOCKERDIR}/data/bacula/config/etc:/opt/bacula/etc                   # Bacula config files
      - /mnt/NAS_BareOS/bacula/archive:/opt/bacula/archive                    # Bacula storage folder
      - ${DOCKERDIR}/data/bacula/data/director/working:/opt/bacula/working    # Bacula pid, atate and bsr folder
...
  bacula-db:
...
    volumes:
      - ${DOCKERDIR}/data/postgres/db-data:/var/lib/postgresql/data
      - ${DOCKERDIR}/data/postgres/socket:/var/run/postgresql
...
----
```
- Überflüssige Verzeichnisse und Dateien löschen

```bash
cd /opt/bacularis
rm -rf config/ working-data/ storage/ data/pgsql/db-data_14/ upgrade_backup_pg14.sql
ls -la
```

- Docker Stack stoppen und wieder starten

```bash
docker compose down
docker compose up -d
docker compose ps
docker compose logs -f
```

- Prüfen, ob die Startseite von Bacularis erreichbar ist und teste die Funktion

```bash
https://bacularis.mydomain.de/web/login/
```

- Monitoring Tool `monit` starten

```bash
systemctl start monit
systemctl status monit
```

