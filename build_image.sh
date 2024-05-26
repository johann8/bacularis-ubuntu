#!/bin/bash

# set variables
_VERSION=3.1.0

# create build
docker build -t johann8/bacularis:${_VERSION}-ubuntu .
_BUILD=$?
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a 
   docker tag johann8/bacularis:${_VERSION}-ubuntu johann8/bacularis:latest-ubuntu
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/bacularis:latest-ubuntu
   docker push johann8/bacularis:${_VERSION}-ubuntu
   _PUSH=$?
   docker images -a |grep bacularis
fi


#delete build
if [ ${_PUSH=} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/bacularis:latest-ubuntu
   #docker images -a
   docker rmi johann8/bacularis:${_VERSION}-ubuntu
   #docker images -a
   #docker rmi ubuntu
   docker images -a
fi

# Delete none images
# docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
