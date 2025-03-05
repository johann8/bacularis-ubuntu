#!/bin/bash
# set -x
#
### === Create Bacularis Project for docker container ===
#

# Variables
PROJECT_DIR=/projects/bacularis/ubuntu
BACULARIS_NEW_VERSION=4.8.0
BACULARIS_OLD_VERSION=4.7.1
BACULARIS_VERSION=${BACULARIS_NEW_VERSION}
#PROJECT_URL=https://github.com/bacularis
#EXTERNAL_URL=https://bacularis.app/downloads/bacularis-external-${BACULARIS_VERSION}.tar.gz
NAME=bacularis

if [[ -d ${PROJECT_DIR} ]]; then
   echo "Project folder exists: ${PROJECT_DIR}"
   cd ${PROJECT_DIR}
else
   echo "Project folder das not exist: ${PROJECT_DIR}"
   exit 0
fi

cd ${PROJECT_DIR}

if [[ -d bacularis_${BACULARIS_OLD_VERSION} ]]; then
   echo "Create Backup of old version"
   mv bacularis_${BACULARIS_OLD_VERSION} bacularis_${BACULARIS_OLD_VERSION}_back
else
   echo "Can not create backup of old version"
   echo -e "Folder \"bacularis_${BACULARIS_OLD_VERSION}\" does not exists.\n"
fi

if [[ -d bacularis ]]; then
   echo "Create Backup of current version"
   mv bacularis  bacularis_${BACULARIS_OLD_VERSION}
else
   echo "Can not create backup of bacularis current version"
   echo "Bacularis directory does not exists."
   echo -e "Creating \"bacularis\" directory... "
   #EMPTY_FOLDER=$(find bacularis -maxdepth 0 -type d -empty -exec echo {} is empty \; | awk -F'[ ]' '{print $3}'); echo $EMPTY_FOLDER
   mkdir -p bacularis
   echo [ DONE ]
fi

echo -ne "Creating temp dir... "
mkdir -p /tmp/45
echo [ DONE ]

cd /tmp/45

if ! [[ -f /usr/local/bin/composer ]]; then
   echo -n "Downloading composer file... "
   curl -s http://getcomposer.org/installer | php
   echo [ DONE ]

   echo -n "Moving composer file... "
   mv composer.phar /usr/local/bin/composer
   echo [ DONE ]
else
   echo "Composer file exists... "
fi


composer create-project bacularis/bacularis-app
mv /tmp/45/bacularis-app ${PROJECT_DIR}/${NAME}
cd /tmp && rm -rf 45
cd ${PROJECT_DIR}/${NAME}
echo -ne "\nDeleting files... "
find ./ -maxdepth 1 -type f -exec rm -f {} \;
echo [ DONE ]
ls -la ./ && cd ../

