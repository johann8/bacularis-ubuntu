#!/bin/bash

# set variables
# set variables
D_IMAGE_VERSION=6.0.0
PHP_VERSION=8.3
BACULA_VERSION=15.0.3
BACULARIS_VERSION=6.0.0
UBUNTU_VERSION=24.04


# build docker image
# docker build -t johann8/bacularis:${_VERSION}-ubuntu . 2>&1 | tee ./build.log
docker build \
  --build-arg=BACULARIS_VERSION=${BACULARIS_VERSION} \
  --build-arg=BACULA_VERSION=${BACULA_VERSION} \
  --build-arg=PHP_VERSION=${PHP_VERSION} \
  --platform=linux/amd64 \
  --tag=johann8/bacularis:${D_IMAGE_VERSION}-ubuntu-${UBUNTU_VERSION} \
  --file=./Dockerfile_U24.04 . 2>&1 | tee ./build.log

_BUILD=$?

if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a 
   docker tag johann8/bacularis:${D_IMAGE_VERSION}-ubuntu-${UBUNTU_VERSION} johann8/bacularis:latest-ubuntu-${UBUNTU_VERSION}
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/bacularis:latest-ubuntu-${UBUNTU_VERSION}
   docker push johann8/bacularis:${D_IMAGE_VERSION}-ubuntu-${UBUNTU_VERSION}
   _PUSH=$?
   docker images -a |grep bacularis
fi

#delete build
if [ ${_PUSH=} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/bacularis:latest-ubuntu-${UBUNTU_VERSION}
   docker rmi johann8/bacularis:${D_IMAGE_VERSION}-ubuntu-${UBUNTU_VERSION}
   docker images -a
   #docker rmi ubuntu
fi

# Delete none images
# docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
