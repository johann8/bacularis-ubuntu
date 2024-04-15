#!/bin/bash
#
# For debug
# set -x
#

# Set script version
SCRIPT_VERSION="0.1.0"

# CUSTOM Vars
MOUNT_NAME=BareOS                          # The name of mount point - case sensitive | df -hT
MOUNT_PATH=/mnt/NAS_BareOS                 # Mount point PATH | df -hT
STORAGE_NAME=bacula                        # Name of storage folder | ls -la ${MOUNT_PATH}

# check mount path
MOUNT_PATH_IDENTIFIED=$(cat /proc/mounts |grep ${MOUNT_NAME} | awk '{print $2}')

if [[ $(df -h |grep ${MOUNT_NAME}) ]] && [[ ${MOUNT_PATH} = ${MOUNT_PATH_IDENTIFIED} ]] && [[ -d ${MOUNT_PATH}/${STORAGE_NAME}/archive ]]; then
   # Bacula can be started
   echo "Bacula: Storage is mounted."
   exit 0
else
   # Bacula can not be started
   echo "Bacula: Storage is not mounted."
   exit 1
fi
