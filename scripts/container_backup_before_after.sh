#!/bin/bash
# for debug
# set -x

##############################################################################
# Script-Name : container_backup_before_after.sh                             #
# Description : Script to create and to backup the LVM Snapshot              #
#               On successful execution starts Bacula to back up data        #
#               On error Bacula does not start to back up data               #
#                                                                            #
# Created     : 02.08.2022                                                   #
# Last update : 09.09.2024                                                   #
# Version     : 0.2.5                                                        #
#                                                                            #
# Author      : Johann Hahn, <j.hahn@wassermann*****technik.de>              #
# DokuWiki    : https://docu.***.wassermanngruppe.de                         #
# Homepage    : https://wassermanngruppe.de                                  #
# GitHub      : https://github.com/johann8/bacularis-alpine                  #
# Download    : https://raw.githubusercontent.com/johann8/bacularis-alpine/\ #
#               master/scripts/container_backup_before_after.sh              #
#                                                                            #
#  +----------------------------------------------------------------------+  #
#  | This program is free software; you can redistribute it and/or modify |  #
#  | it under the terms of the GNU General Public License as published by |  #
#  | the Free Software Foundation; either version 2 of the License, or    |  #
#  | (at your option) any later version.                                  |  #
#  +----------------------------------------------------------------------+  #
#                                                                            #
# Copyright (c) 2022 - 2024 by Johann Hahn                                   #
#                                                                            #
##############################################################################

##############################################################################
# >>> Please edit following lines for personal settings and custom usages. ! #
##############################################################################

# CUSTOM LV vars - please adjust
LVM_PARTITION_DOCKER=yes                                  # is there LVM Partition for docker container: yes | no
LV_DOCKER_NAME=opt                                        # Docker containers are installed on the Logical Volume named "opt". If empty, the containers will not be stopped.
VOLGROUP=rl_vmd63899                                      # lvdisplay: name of the volume group
LV_NAME=opt,var                                           # lvdisplay: name of the logical volume to backup. Getrennt mit Komma oder Leerzeichen
SNAP_SUFFIX=snap                                          #
SNAP_LV_NAME=opt_${SNAP_SUFFIX},var_${SNAP_SUFFIX}        # name of logical volume snapshot. Getrennt mit Komma oder Leerzeichen
SNAPSIZE=1G                                               # space to allocate for the snapshot in the volume group
MOUNTDIR="/mnt/lvm_snap"                                  # Path to mount point of lv snapshot
MOUNT_OPTIONS="-o nouuid"                                 # Mount option for xfs FS

# CUSTOM - script
SCRIPT_NAME="script_before_after.sh"
BASENAME=${SCRIPT_NAME}
SCRIPT_VERSION="0.2.5"
TIMESTAMP="$(date +%Y%m%d-%Hh%Mm)"
_DATUM="$(date '+%Y-%m-%d %Hh:%Mm:%Ss')"
SCRIPT_START_TIME=$SECONDS                                # Script start time

# CUSTOM - logs
FILE_LAST_LOG='/tmp/'${SCRIPT_NAME}'.log'                 # Script log file

# CUSTOM - Exlude containers name
AR_EXCLUDE_B_CONTAINER=(bacularis bacula-db bacula-smtpd) # Array - exclude bacula container

### From here on, you normally do not need to change anything
SYSTEMCTL_COMMAND=`command -v systemctl`
LVREMOVE_COMMAND=`command -v lvremove`
LVCREATE_COMMAND=`command -v lvcreate`
LVDISPLAY_COMMAND=`command -v lvdisplay`
MOUNT_COMMAND=`command -v mount`
UMOUNT_COMMAND=`command -v umount`

#
### === Set functions ===
#

# Stop monit service
stop_monit_service() {
   if [ ${S_MONIT} == 1 ]; then
      echo -e "Info: Stopping monit service ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      ${SYSTEMCTL_COMMAND} stop monit

      if [ $? == 0 ]; then
         echo -e "Info: Monit service was successfully stopped. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      else
         echo -e "Error: Monit service could not be stopped. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      fi
   fi
}

# Start monit service
start_monit_service() {
   if [ ${S_MONIT} == 1 ]; then
      echo -e "Info: Starting monit service ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      ${SYSTEMCTL_COMMAND} start monit

      if [ $? == 0 ]; then
         echo -e "Info: Monit service was successfully started. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      else
         echo -e "Error: Monit service could not be started. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      fi
   fi
}

# Docker state message
print_container_state() {
   if [ "${DOCSTATE}" == "false" ]; then
      echo -e "${1}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   else
      echo -e "${2}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   fi
}

# Stop docker containers
stop_docker_container() {
   if [ -n "$CONTAINERS" ]; then
      for container in $CONTAINERS; do
         CONTAINER_COUNTER=$((CONTAINER_COUNTER+1))
         CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $container | sed 's/^\///')

         # skip container"bacula-smtpd bacularis bacula-db"
         if [[ ${CONTAINER_NAME} =  ${AR_EXCLUDE_B_CONTAINER[0]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[1]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[2]} ]]; then
            echo -e "Info: Container \"${CONTAINER_NAME}\" will be skipped ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         else
            echo -e "Info: Stopping container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container) ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            docker stop $container > /dev/null 2>&1

            DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
            echo -e "Info: Container running state: ${DOCSTATE}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            print_container_state "Info: Container stopped." "Info: Container ${CONTAINER_NAME} ($container) still not running, should be started!!!"
         fi

         echo -e "....................................................." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      done
   else
      echo -e "Info: No Docker containers found." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   fi
}

# Start docker containers
start_docker_container() {
   if [ -n "$CONTAINERS" ]; then
      for container in $CONTAINERS; do
         CONTAINER_COUNTER=$((CONTAINER_COUNTER+1))
         CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $container | sed 's/^\///')

         # skip container Bacula
         if [[ ${CONTAINER_NAME} =  ${AR_EXCLUDE_B_CONTAINER[0]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[1]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[2]} ]]; then
            echo -e "Info: Container \"${CONTAINER_NAME}\" will be skipped ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         else
            echo -e "Info: Starting container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container) ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            docker start $container > /dev/null 2>&1

            DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
            echo -e "Info: Container running state: ${DOCSTATE}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            print_container_state "Info: Container ${CONTAINER_NAME} ($container) still not running, should be started!!!" "Info: Container started."
         fi

         echo -e "....................................................." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      done
   else
      echo -e "Info: No Docker containers found." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   fi
}


# Umount and remove LVM snapshot
remove_lvm_snapshot() {
   if [ -e "/dev/${VOLGROUP}/$1" ]; then
      echo " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      echo -e "Info: LVM snapshot \"$1\" exists. It will be destroyed." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}

      # check if snapshot mounted
      if [[ $(df -hT | grep ${MOUNTDIR}/$1) ]]; then
         # umount snapshot
         echo -e "Info: Unmounting LV snapshot \"$1\" ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         ${UMOUNT_COMMAND} ${MOUNTDIR}/$1
         RES=$?

         if [ "$RES" != '0' ]; then
            echo -e "Error: Cannot unmount LVM snapshot \"$1\"." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            exit 0
         else
            # remove snapshot
            if ! ${LVREMOVE_COMMAND} -f /dev/${VOLGROUP}/$1 >/dev/null 2>&1; then
               echo -e "Error: Cannot remove the LV snapshot \"/dev/${VOLGROUP}/$1\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               exit 0
            else
               echo -e "Info: LV snapshot removed \"/dev/${VOLGROUP}/$1\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            fi
         fi
      else
         # remove snapshot
         if ! ${LVREMOVE_COMMAND} -f /dev/${VOLGROUP}/$1 >/dev/null 2>&1; then
            echo -e "Error: Cannot remove the LV snapshot \"/dev/${VOLGROUP}/$1\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            exit 0
         else
            echo -e "Info: LV snapshot removed \"/dev/${VOLGROUP}/$1\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         fi
      fi
   fi
}

#
### === Main Script ===
#

# delete log file
#if [[ -f ${LOGFILE} ]]; then
#    echo "Deleting log file.."
#    rm -rf ${LOGFILE}
#fi

SCRIPT_PARAM="Run script ${1}"
SEPARATOR_LENGTH=$(( ${#SCRIPT_PARAM} + 1 ))
SEPARATOR=$(printf '=%.0s' $(seq 1 ${SEPARATOR_LENGTH}))
echo -e "Started on \"$(hostname -f)\" at \"${_DATUM}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e "Script version is: \"${SCRIPT_VERSION}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e "${SEPARATOR}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e "${SCRIPT_PARAM}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e "${SEPARATOR}" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}

# check if $1 is empty
if [[ -z $1 ]]; then 
   echo -e "Error: You have not passed a parameter to Script." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   exit 1
else
   echo -e "Info: You have passed the parameter \"$1\" to Script." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
fi

# check if service monit is available.
if [[ -x /usr/local/bin/monit ]]; then
   echo -e "Info: Monit service is available." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   S_MONIT=1
else
   echo -e "Error: Monit service is not available." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   S_MONIT=0
fi

# Check if command (file) NOT exist OR IS empty.
if [ ! -s "${SYSTEMCTL_COMMAND}" ]; then
   echo -e "Error: Command \"${SYSTEMCTL_COMMAND}\" is not available. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
else
   echo -e "Info: Command \"${SYSTEMCTL_COMMAND}\" is available. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
fi

# Create array
LV_NAME_AR=($(echo ${LV_NAME} |sed -e 's/,/ /'));             # echo ${LV_NAME_AR[*]}
SNAP_LV_NAME_AR=($(echo ${SNAP_LV_NAME} |sed -e 's/,/ /'));   # echo ${SNAP_LV_NAME_AR[*]}

#
### run script before
#
if [ "${1}" == "BEFORE" ] || [ "${1}" == "before" ] || [ "${1}" == "Before" ]; then
   echo -e "Bacula running script BEFORE..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   echo -e "Found $(docker ps -aq | wc -l) Docker containers." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   CONTAINERS=$(docker ps -aq)
   TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
   CONTAINER_COUNTER=0
   echo -e "....................................................." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
   stop_monit_service
   stop_docker_container

   # if a LVM partition for docker container exists, then a snapshot will be created and only then does Bacula the backup
   if [[ ${LVM_PARTITION_DOCKER} == "yes" ]]; then

      # Create LV Snapshot
      for i in ${LV_NAME_AR[*]}; do

         # check, that the snapshot does not already exist and remove it
         remove_lvm_snapshot ${i}_${SNAP_SUFFIX}

         # Stop docker container, if i=opt
         if [[ "${i}" == "${LV_DOCKER_NAME}" ]]; then

            # stop monit service
            stop_monit_service

            # stop docker container
            echo -e "Info: Found $(docker ps -aq | wc -l) Docker containers." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            echo -e "Info: Stopping all docker containers ..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            CONTAINERS=$(docker ps -aq)
            TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
            CONTAINER_COUNTER=0
            echo -e "....................................................." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            stop_docker_container

            # Set var STOP_RES=0, if docker container stopped
            STOP_RES=0
         fi

         # create the lvm snapshot
         if ! ${LVCREATE_COMMAND} -L${SNAPSIZE} -s -n ${i}_${SNAP_SUFFIX} /dev/${VOLGROUP}/${i}  >/dev/null 2>&1; then
            echo -e "Error: Creating of the LVM snapshot \"${i}_${SNAP_SUFFIX}\" failed" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            exit 0
         else
            echo -e "Info: LVM snapshot \"${i}_${SNAP_SUFFIX}\" was successfully created." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}

            # Check LV snap state (active | INACTIVE)
            LVM_SNAP_STATE=$(${LVDISPLAY_COMMAND} /dev/${VOLGROUP}/${i}_${SNAP_SUFFIX} |grep 'LV snapshot status' |awk '{print $4}')
            if [[ ${LVM_SNAP_STATE} == 'active' ]]; then
               echo -e "Info: LVM snapshot \"${i}_${SNAP_SUFFIX}\" state is \"active\"." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            else
               echo -e "Error: LVM snapshot \"${i}_${SNAP_SUFFIX}\" state is \"INACTIVE\"." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               echo -e "Info: The wrong size of LVM snapshot \"${i}_${SNAP_SUFFIX}\" was chosen." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               exit 0
            fi
         fi

         # check that the mount point does not already exist, mount snapshot MOUNTDIR="/mnt/lvm_snap"
         if ! [ -d ${MOUNTDIR}/${i} ]; then
            # create mount point
            # echo " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            echo -e "Info: Creating mount point \"${MOUNTDIR}/${i}\" ... " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            mkdir -p ${MOUNTDIR}/${i}
         else
            # echo " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            echo -e "Info: Mount point exists \"${MOUNTDIR}/${i}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         fi

         # check if FS ist XFS
         FS_XFS=$(df -hT | grep -w "dev" | grep -w "$i" | awk '{print $2}')

         if [ "${FS_XFS}" = "xfs" ]; then
            # mount snapshot
            echo -e "Info: Mounting LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" ... "  | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            ${MOUNT_COMMAND} ${MOUNT_OPTIONS} /dev/${VOLGROUP}/${i}_${SNAP_SUFFIX} ${MOUNTDIR}/${i}
            RES=$?
 
            if [ "$RES" != '0' ]; then
               echo -e "Error: Cannot mount LVM snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               exit 0
            else
               echo -e "Info: LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" was successfully mounted. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            fi
         else
            # mount snapshot
            echo -e "Info: Mounting LVM snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" ... " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            ${MOUNT_COMMAND} /dev/${VOLGROUP}/${i}_${SNAP_SUFFIX} ${MOUNTDIR}/${i}
            RES=$?

            if [ "$RES" != '0' ]; then
               echo -e "Error: Cannot mount LVM snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               exit 0
            else
               echo -e "Info: LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" was successfully mounted. \n" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            fi
         fi
      done
      # Set var SNAP_RES
      SNAP_RES=0
	  
	  # Start Docker Container if var SNAP_RES=0
      if [ "${SNAP_RES}" = '0' ]; then

         # Start docker container, if STOP_RES=0
         if [[ "${STOP_RES}" = '0' ]]; then

            # stop docker container
            echo -e "Info: Found $(docker ps -aq | wc -l) Docker containers." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            echo -e "Info: Starting all stopped docker containers ... " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            CONTAINERS=$(docker ps -aq)
            TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
            CONTAINER_COUNTER=0
            echo -e "....................................................." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            start_docker_container
         fi

         # Start monit service
         #echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         start_monit_service
         echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
      fi	  
   else
      echo -e "There is no LVM Partition for docker container."
   fi
#
### run script after
#
elif [ "${1}" == "AFTER" ] || [ "${1}" == "after" ] || [ "${1}" == "After" ]; then
   echo -e "Bacula running script AFTER..." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}

   ### if a LVM snapshot was previously created, then snapshot will be unmounted and destroyed
   if [[ ${LVM_PARTITION_DOCKER} == "no" ]]; then
      echo -e "There is no LVM Partition for docker container."
   else
      for i in ${LV_NAME_AR[*]}; do 

         # umount snapshot
         echo -e "Info: Unmounting LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" ... " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
         ${UMOUNT_COMMAND} ${MOUNTDIR}/${i}
         U_RES=$?

         # remove snapshot
         if [ "${U_RES}" = '0' ]; then
            # Unmount success message
            echo -e "Info: LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" was successfully unmounted."

            # remove LV snapshot
            if ! /usr/sbin/lvremove -f /dev/${VOLGROUP}/${i}_${SNAP_SUFFIX} >/dev/null 2>&1; then
               echo -e "Error: Cannot remove LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\"" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               exit 0
            else
               echo -e "Info: LV snapshot \"/dev/${VOLGROUP}/${i}_${SNAP_SUFFIX}\" successfully removed." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
               echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
            fi
         fi
      done
   fi
else
   echo -e "ERROR: No matching variable was passed." | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
fi

# print "end of script"
echo -e "/------------ Script ended at: \"${_DATUM}\" ------------/" | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}


# Script run time calculate
#
#SCRIPT_START_TIME=$SECONDS
SCRIPT_END_TIME=$SECONDS
let deltatime=SCRIPT_END_TIME-SCRIPT_START_TIME
let hours=deltatime/3600
let minutes=(deltatime/60)%60
let seconds=deltatime%60
printf "Time elapsed: %d:%02d:%02d\n" $hours $minutes $seconds | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
echo -e " " | tee /proc/1/fd/1 -a ${FILE_LAST_LOG}
