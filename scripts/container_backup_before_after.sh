#!/bin/bash
# for debug
# set -x

#
### === Set variables ===
#

### CUSTOM - LV vars: please adjust
LVM_PARTITION_DOCKER=yes              # is there LVM Partition for docker container: yes | no
VOLGROUP=ol_docker                    # lvdisplay: name of the volume group
ORIGVOL=opt                           # lvdisplay: name of the logical volume to backup
SNAPVOL=opt_snap                      # name of logical volume snapshot
SNAPSIZE=5G                           # space to allocate for the snapshot in the volume group
MOUNTDIR="/mnt/lvm_snap"              # Path to mount lv snapshot
MOUNT_OPTIONS="-o nouuid"             # Mount option
LOGFILE=/tmp/docker_backup.log        # /config is the location within Bacula docker _data directory

AR_EXCLUDE_B_CONTAINER=(bacularis bacula-db bacula-smtpd) # Array - exclude bacula container

### From here on, you normally do not need to change anything
SYSTEMCTL_COMMAND=`command -v systemctl`
LVREMOVE_COMMAND=`command -v lvremove`
LVCREATE_COMMAND=`command -v lvcreate`
MOUNT_COMMAND=`command -v mount`
UMOUNT_COMMAND=`command -v umount`

#
### === Set functions ===
#

# Docker state message
print_container_state() {
   if [ "${DOCSTATE}" == "false" ]; then
      echo -e "${1}" | tee /proc/1/fd/1 -a ${LOGFILE}
   else
      echo -e "${2}" | tee /proc/1/fd/1 -a ${LOGFILE}
   fi
}

# Stop monit service
stop_monit_service() {
   if [ ${S_MONIT} == 1 ]; then
      echo -e "Stopping monit service..." | tee /proc/1/fd/1 -a ${LOGFILE}
      ${SYSTEMCTL_COMMAND} stop monit

      if [ $? == 0 ]; then
         echo -e "Monit service was successfully stopped." | tee /proc/1/fd/1 -a ${LOGFILE}
      else
         echo -e "Monit service could not be stopped." | tee /proc/1/fd/1 -a ${LOGFILE}
      fi
   fi
}

# Start monit service
start_monit_service() {
   if [ ${S_MONIT} == 1 ]; then
      echo -e "Starting monit service..." | tee /proc/1/fd/1 -a ${LOGFILE}
      ${SYSTEMCTL_COMMAND} start monit

      if [ $? == 0 ]; then
         echo -e "Monit service was successfully started." | tee /proc/1/fd/1 -a ${LOGFILE}
      else
         echo -e "Monit service could not be started." | tee /proc/1/fd/1 -a ${LOGFILE}
      fi
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
         echo -e "Container \"${CONTAINER_NAME}\" will be skipped..." | tee /proc/1/fd/1 -a ${LOGFILE}
      else
         echo -e "Stopping container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container)..." | tee /proc/1/fd/1 -a ${LOGFILE}
         docker stop $container > /dev/null 2>&1

         DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
         echo -e "Container running state: ${DOCSTATE}" | tee /proc/1/fd/1 -a ${LOGFILE}
         print_container_state "Container stopped." "Container ${CONTAINER_NAME} ($container) still not running, should be started!!!"
      fi
      echo -e "....................................................." | tee /proc/1/fd/1 -a ${LOGFILE}
      done
   else
      echo -e "No Docker containers found." | tee /proc/1/fd/1 -a ${LOGFILE}
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
            echo -e "Container \"${CONTAINER_NAME}\" will be skipped..." | tee /proc/1/fd/1 -a ${LOGFILE}
         else
            echo -e " Starting container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container)..." | tee /proc/1/fd/1 -a ${LOGFILE}
            docker start $container > /dev/null 2>&1

            DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
             echo -e "Container running state: ${DOCSTATE}" | tee /proc/1/fd/1 -a ${LOGFILE}
             print_container_state "Container ${CONTAINER_NAME} ($container) still not running, should be started!!!" "Container started."
         fi
            echo -e "....................................................." | tee /proc/1/fd/1 -a ${LOGFILE}
      done
   else
      echo -e "No Docker containers found." | tee /proc/1/fd/1 -a ${LOGFILE}
   fi
}

# Umount and remove LVM snapshot
remove_lvm_snapshot() {
   if [ -e "/dev/${VOLGROUP}/${SNAPVOL}" ]; then
      echo -e "LVM snapshot exists. It will be destroyed." | tee /proc/1/fd/1 -a ${LOGFILEi}

      # check if snapshot mounted
      if [ -d "${MOUNTDIR}/${ORIGVOL}/bacula" ]; then
         # umount snapshot
         echo -e "Unmounting LV snapshot..." | tee /proc/1/fd/1 -a ${LOGFILE}
         ${UMOUNT_COMMAND} ${MOUNTDIR}/${ORIGVOL}
         RES=$?

         if [ "$RES" != '0' ]; then
            echo -e "Cannot unmount LVM snapshot." | tee /proc/1/fd/1 -a ${LOGFILE}
         else
            # remove snapshot
            if ! ${LVREMOVE_COMMAND} -f /dev/${VOLGROUP}/${SNAPVOL} >/dev/null 2>&1; then
               echo -e "cannot remove the LV snapshot: /dev/${VOLGROUP}/${SNAPVOL}" | tee /proc/1/fd/1 -a ${LOGFILE}
            else
               echo -e "LV snapshot removed: /dev/${VOLGROUP}/${SNAPVOL}" | tee /proc/1/fd/1 -a ${LOGFILE}
            fi
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
echo -e " " | tee /proc/1/fd/1 -a ${LOGFILE}
echo -e "${SEPARATOR}" | tee /proc/1/fd/1 -a ${LOGFILE}
echo -e "${SCRIPT_PARAM}" | tee /proc/1/fd/1 -a ${LOGFILE}
echo -e "${SEPARATOR}" | tee /proc/1/fd/1 -a ${LOGFILE}
echo -e "Script start: $(date)" | tee /proc/1/fd/1 -a ${LOGFILE}

# check if service monit is available.
if [[ -x /usr/local/bin/monit ]]; then
   echo -e "Monit service is available." | tee /proc/1/fd/1 -a ${LOGFILE}
   S_MONIT=1
else
   echo -e "Monit service is not available." | tee /proc/1/fd/1 -a ${LOGFILE}
   S_MONIT=0
fi

# Check if command (file) NOT exist OR IS empty.
if [ ! -s "${SYSTEMCTL_COMMAND}" ]; then
   echo -e "Command \"${SYSTEMCTL_COMMAND}\" is not available." | tee /proc/1/fd/1 -a ${LOGFILE}
else
   echo -e "Command \"${SYSTEMCTL_COMMAND}\" is available." | tee /proc/1/fd/1 -a ${LOGFILE}
fi


# run script before
if [ ${1} == "BEFORE" ] || [ ${1} == "before" ]; then
   echo -e "Bacula running script BEFORE..." | tee /proc/1/fd/1 -a ${LOGFILE}
   echo -e "Found $(docker ps -aq | wc -l) Docker containers." | tee /proc/1/fd/1 -a ${LOGFILE}
   CONTAINERS=$(docker ps -aq)
   TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
   CONTAINER_COUNTER=0
   echo -e "....................................................." | tee /proc/1/fd/1 -a ${LOGFILE}
   stop_monit_service
   stop_docker_container

   # if a LVM partition for docker container exists, then a snapshot will be created and only then does Bacula the backup
   if [[ ${LVM_PARTITION_DOCKER} == "yes" ]]; then

      # check, that the snapshot does not already exist and remove it
      remove_lvm_snapshot

      # create the lvm snapshot
      if ! ${LVCREATE_COMMAND} -L${SNAPSIZE} -s -n ${SNAPVOL} /dev/${VOLGROUP}/${ORIGVOL}  >/dev/null 2>&1; then
         echo -e "Creating of the LVM snapshot failed" | tee /proc/1/fd/1 -a ${LOGFILE}
      fi

      # check that the mount point does not already exist, mount snapshot
      if ! [ -d ${MOUNTDIR}/${ORIGVOL} ]; then
         # create mount point
         echo -e "Creating mount point... \"${MOUNTDIR}/${ORIGVOL}\"" | tee /proc/1/fd/1 -a ${LOGFILE}
         mkdir -p ${MOUNTDIR}/${ORIGVOL}
      else
         echo -e "Mount point exists: \"${MOUNTDIR}/${ORIGVOL}\"" | tee /proc/1/fd/1 -a ${LOGFILE}
      fi

      # check if FS ist XFS
      FS_XFS=$(df -hT |grep -w '/opt' |awk '{print $2}')

      if [ "${FS_XFS}" = "xfs" ]; then
         # mount snapshot
         echo -e "Mounting LV snapshot... /dev/${VOLGROUP}/${SNAPVOL}"  | tee /proc/1/fd/1 -a ${LOGFILE}
         ${MOUNT_COMMAND} ${MOUNT_OPTIONS} /dev/${VOLGROUP}/${SNAPVOL} ${MOUNTDIR}/${ORIGVOL}
         RES=$?

         if [ "$RES" != '0' ]; then
            echo -e "Cannot mount LVM snapshot: /dev/${VOLGROUP}/${SNAPVOL}" | tee /proc/1/fd/1 -a ${LOGFILE}
         fi
      else
         # mount snapshot
         echo -e "Mounting LVM snapshot... /dev/${VOLGROUP}/${SNAPVOL}" | tee /proc/1/fd/1 -a ${LOGFILE}
         ${MOUNT_COMMAND} /dev/${VOLGROUP}/${SNAPVOL} ${MOUNTDIR}/${ORIGVOL}
         RES=$?

         if [ "$RES" != '0' ]; then
            echo -e "Cannot mount LVM snapshot: /dev/${VOLGROUP}/${SNAPVOL}" | tee /proc/1/fd/1 -a ${LOGFILE}
         fi
      fi
   else
      echo -e "There is no LVM Partition for docker container."
   fi
# run script after
elif [ ${1} == "AFTER" ] || [ ${1} == "after" ]; then
   echo -e "Bacula running script AFTER..." | tee /proc/1/fd/1 -a ${LOGFILE}
   echo -e "Found $(docker ps -aq | wc -l) Docker containers." | tee /proc/1/fd/1 -a ${LOGFILE}
   echo -e "....................................................." | tee /proc/1/fd/1 -a ${LOGFILE}
   CONTAINERS=$(docker ps -aq)
   TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
   CONTAINER_COUNTER=0
   start_docker_container

   ### if a LVM snapshot was previously created, then snapshot will be unmounted and destroyed
   if [[ ${LVM_PARTITION_DOCKER} == "no" ]]; then
      echo -e "There is no LVM Partition for docker container."
   else
      # umount and remove snapshot
      remove_lvm_snapshot
   fi
else
   echo -e "ERROR: No matching variable was passed." | tee /proc/1/fd/1 -a ${LOGFILE}
fi

echo -e "Script stopped: $(date)" | tee /proc/1/fd/1 -a ${LOGFILE}
echo -e "${SEPARATOR}" | tee /proc/1/fd/1 -a ${LOGFILE}

