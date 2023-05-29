#!/bin/bash
# set -x
#
### === Create Bacularis Project for docker container ===
#

# Variables
PROJECT_DIR=/projects/bacularis/ubuntu
# BACULARIS_VERSION=1.3.0
BACULARIS_NEW_VERSION=1.6.0
BACULARIS_OLD_VERSION=1.5.0
BACULARIS_VERSION=${BACULARIS_NEW_VERSION}
PROJECT_URL=https://github.com/bacularis
EXTERNAL_URL=https://bacularis.app/downloads/bacularis-external-${BACULARIS_VERSION}.tar.gz
NAME=bacularis

if [[ -d ${PROJECT_DIR} ]]; then
   echo "Project folder exists: ${PROJECT_DIR}"
   cd ${PROJECT_DIR}
else
   echo "Project folder das not exist: ${PROJECT_DIR}"
   exit 0
fi

if [[ -d bacularis_${BACULARIS_OLD_VERSION} ]]; then
   echo "Create Backup of old version"
   mv bacularis_${BACULARIS_OLD_VERSION} bacularis_${BACULARIS_OLD_VERSION}_back
else
   echo "Can not create backup of old version"
   echo "Folder \"bacularis_${BACULARIS_OLD_VERSION}\" does not exists."
fi

if [[ -d bacularis ]]; then
   echo "Create Backup of current version"
   mv bacularis  bacularis_${BACULARIS_OLD_VERSION}
else
   echo "Can not create backup of current version"
   echo "Folder \"bacularis\" does not exists."
fi

if [[ -d ${PROJECT_DIR} ]]; then
   #
   echo -n "Cloning bacularis-app from git... "
   git clone ${PROJECT_URL}/${NAME}-app.git
   git clone ${PROJECT_URL}/${NAME}-common.git
   git clone ${PROJECT_URL}/${NAME}-api.git
   git clone ${PROJECT_URL}/${NAME}-web.git
   echo [DONE]

   echo -n "Cloning bacularis-external... "
   wget "$EXTERNAL_URL"
   echo [DONE]

   echo -n "Unpacking tar... "
   tar -zxvf bacularis-external-${BACULARIS_VERSION}.tar.gz
   # tar --strip-components=1 -zxvf bacularis-external-${BACULARIS_VERSION}.tar.gz
   echo [DONE]

   echo -n "Moving bacularis data... "
   mv bacularis-external-${BACULARIS_VERSION} bacularis-external
   echo [DONE]

   echo -n "Creating folders... "
   mkdir -p \
	"${NAME}/protected/vendor/${NAME}/${NAME}-common" \
	"${NAME}/protected/vendor/${NAME}/${NAME}-api" \
	"${NAME}/protected/vendor/${NAME}/${NAME}-web" \
	"${NAME}/protected/runtime" \
	"${NAME}/htdocs/assets"
   echo [DONE]

   echo -n "Creating bacularis project... "
   cp -a ${NAME}-common/project/* ${NAME}/ && \
   cp -r ${NAME}-common/* ${NAME}/protected/vendor/${NAME}/${NAME}-common/ && \
   cp -r ${NAME}-api/* ${NAME}/protected/vendor/${NAME}/${NAME}-api/ && \
   cp -r ${NAME}-web/* ${NAME}/protected/vendor/${NAME}/${NAME}-web/ && \
   cp -r ${NAME}-external/vendor/* ${NAME}/protected/vendor/ && \
   cp ${NAME}/protected/samples/webserver/${NAME}.users.sample ${NAME}/protected/vendor/${NAME}/${NAME}-api/API/Config/${NAME}.users && \
   cp ${NAME}/protected/samples/webserver/${NAME}.users.sample ${NAME}/protected/vendor/${NAME}/${NAME}-web/Web/Config/${NAME}.users
   echo [DONE]

   echo -n "Creating symlinks... "
   cd ${NAME}/protected/ && \
   ln -sf vendor/${NAME}/${NAME}-common/Common ./ && \
   ln -sf vendor/${NAME}/${NAME}-api/API ./ && \
   ln -sf vendor/${NAME}/${NAME}-web/Web ./ && \
   ls -la && \
   cd ../ && \
   cd ../
   echo [DONE]

   echo -n "Coping CSS... "
   cp ${NAME}/protected/vendor/bower-asset/fontawesome/css/all.min.css ${NAME}/htdocs/themes/Baculum-v2/fonts/css/fontawesome-all.min.css
   echo [DONE]

   echo -n "Coping fonts... "
   cp -r ${NAME}/protected/vendor/bower-asset/fontawesome/webfonts/* ${NAME}/htdocs/themes/Baculum-v2/fonts/webfonts/
   echo [DONE]

   echo -n "Deleting files... "
   rm -rf bacularis-*
   echo [DONE]

   echo -e "*** All tasks are done ***"
fi

