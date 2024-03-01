#!/bin/bash
# Backup MySQL Databases

# Directory to store backups
DST=/var/backup/container/mysql

# The MySQL username and password
DBUSER="root"
DBPASS=""
DBHOST=""
DBPORT=""

# A regex, passed to egrep -v, for which databases to ignore
IGNREG='^information_schema$|^performance_schema$'

# Date to create folder
DATE=$(date  +%Y-%m-%d)

# Check if mysqldump exist
MYSQLDUMP_COMMAND=$(command -v mysqldump)
if [ ! -s "${MYSQLDUMP_COMMAND}" ]; then
        echo "Check if command '${MYSQLDUMP_COMMAND}' was found................[FAILED]"
        echo "Run this on CentOS/Rocky/Oracle \"dnf install mariadb\" to install mysqldump."
        echo "Run this on Debian/Ubuntu \"apt-get install mariadb-client\" to install mysqldump."    
        exit 11
else
        echo "Check if command '${MYSQLDUMP_COMMAND}' was found................[  OK  ]"
fi

# Check if password exist
if [ -n "$DBPASS" ]; then
    PASSWD="-p$DBPASS"
else
    PASSWD=""
fi

# Check if DBHOST exist
if [ -n "${DBHOST}" ]; then
    DBHOST="-h ${DBHOST}"
else
    DBHOST=""
fi

# Check if DBPORT exist
if [ -n "${DBPORT}" ]; then
    DBPORT="-P ${DBPORT}"
else
    DBPORT=""
fi


# Check if destination folder exist
if [ -d "${DST}" ]; then
    echo "Destination folder \"${DST}\"exist."
else
    echo -n "Creating Destination folder...        "
    mkdir -p ${DST}
    echo "[ DONE ]"
fi

# Remove older backups
cd ${DST}
find ${DST} -type f -name *.sql -exec rm -f {} \;
rmdir $DST/* 2>/dev/null

# Create folder with the current date
mkdir -p ${DST}/${DATE}

# Create MySQL Backups
for db in $(echo 'show databases;' | mysql --silent ${DBHOST} ${DBPORT} -u ${DBUSER} ${PASSWD} | egrep -v ${IGNREG}) ; do
   echo -n "Backing up ${db}...                    "
   mysqldump --opt ${DBHOST} ${DBPORT} -u ${DBUSER} ${PASSWD} $db --routines --triggers --databases --add-drop-database --complete-insert > ${DST}/${DATE}/${db}.sql
   echo "[ DONE ]"
done

exit 0
