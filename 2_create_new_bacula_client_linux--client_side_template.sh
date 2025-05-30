#!/bin/bash
# set -x
#
### === Create Config for new client for bacula - client side ===
#

# Set variables
SCRIPT_VERSION=0.5

# IP Address of docker host wher bacula server is running
DIRECTOR_ADDRESS=$(ip addr show $(ip route | awk '/default/ {print $5}') |grep -w inet | awk '/inet/ {print $2}' | cut -d'/' -f1)
CLIENT_INSTALL_DIR="/opt/bacula/etc"                                   # Bacula client install dir
DIRECTOR_NAME=bacula-dir                                               # The name of bacula server director (bacula-dir)
DIRECTOR_CONSOLE_MONITOR_NAME=bacula-mon                               # The name of bacula server console (bacula-mon)
DIRECTOR_CONSOLE_MONITOR_PASSWORD='###BACULA_DIR_MON_PASSWORD###'      # On bacula server: cat bacula-dir.conf ( Console {Name = "bacula-mon" Password = "Vy1holhTDZ3xPYB6s0QaqW26/1levNlVNqU07i+rLQUt" } )

# Function
show_help() {
    echo ""
    echo "<-------------- HELP -------------->"
    echo "Usage: $0 -n pc-01"
    echo "Or"
    echo "Usage: $0 --name pc-02"
    echo ""
    echo "Create bacula client config files."
    echo ""
    echo "-h,  --help              Show help and exit."
    echo "-v,  --version           Show script version and exit."
    #echo "-ip, --ipaddress         IP address of bacula client - example: \"192.168.20.45\""
    echo "-n,  --name              Name of bacula client - example: \"oracle8\""
    echo ""
}

# Expect to get  positional arguments.
if [[ $# -eq 0 ]]
then
    echo ""
    echo "Script: Please specify a positional argument."
    show_help
    exit 1
fi

# Menu
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo ""
            echo "Script: Will show script version."
            echo "Script: Version is: ${SCRIPT_VERSION}"
            exit 0
            ;;
        -n|--name)
            shift
            BACULA_CLIENT_NAME=$1
            shift
            ;;
        -*|--*)
            echo ""
            echo "Script: Unrecognized option: '$key'"
            echo "Script: See 'Script -h|--help' for supported options."
            exit 0
            ;;
        *)  # unknown option
            echo ""
            echo "Script: Unrecognized option: '$key'"
            echo "Script: See 'Script -h|--help' for supported options."
            exit 0
            ;;
    esac
done

# verify var BACULA_CLIENT_NAME
if [[ -z ${BACULA_CLIENT_NAME} ]]
then
    echo ""
    echo "Script: Please specify a client name."
    show_help
    exit 1
fi

# Pass variables
CLIENT_NAME=${BACULA_CLIENT_NAME}
BACULA_FD_CONFIG_FILE_TEMPLATE=bacula-fd_template.conf
BACULA_FD_CONFIG_FILE=bacula-fd_${CLIENT_NAME}.conf
BCONSOLE_CONFIG_FILE_TEMPLATE=bconsole_template.conf
BCONSOLE_CONFIG_FILE=bconsole_${CLIENT_NAME}.conf
CONFIG_FOLDER=config_files
MD5_PASSWORD=$(cat ${CONFIG_FOLDER}/bacula-dir_${CLIENT_NAME}.conf |grep Password |cut -f 2 -d '"')

### create folder for config files
if [[ ! -d ${CONFIG_FOLDER} ]]; then
   echo -n "Creating folder \"${CONFIG_FOLDER}\"...                       "
   mkdir ${CONFIG_FOLDER}
   echo [DONE]
fi

if [[ -f ${BACULA_FD_CONFIG_FILE_TEMPLATE} ]] && [[ -f ${BCONSOLE_CONFIG_FILE_TEMPLATE} ]]; then

   # Create config file
   echo -n "creating files: \"bacula-fd.conf\" and \"bconsole.conf\"... "
   cp ${BACULA_FD_CONFIG_FILE_TEMPLATE} ${CONFIG_FOLDER}/${BACULA_FD_CONFIG_FILE} && \
   cp ${BCONSOLE_CONFIG_FILE_TEMPLATE} ${CONFIG_FOLDER}/${BCONSOLE_CONFIG_FILE}
   echo [DONE]

   # Setting variables
   if [[ ! -z ${MD5_PASSWORD} ]] && [[ ! -z ${CLIENT_NAME} ]] && [[ ! -z ${DIRECTOR_NAME} ]] && [[ ! -z ${DIRECTOR_ADDRESS} ]]; then
      echo "Client name: ${CLIENT_NAME}"
      echo "MD5 Password: ${MD5_PASSWORD}"
      echo "Director name: ${DIRECTOR_NAME}"
      echo "Director IP Address: ${DIRECTOR_ADDRESS}"
      echo "Director console monitor name: ${DIRECTOR_CONSOLE_MONITOR_NAME}"

      echo -n "Inserting variables into \"bacula-fd.conf\" file...       "
      sed -i -e "s%###CLIENT_NAME###%${CLIENT_NAME}%" \
             -e "s%###MD5_PASSWORD###%${MD5_PASSWORD}%" \
             -e "s%###DIRECTOR_NAME###%${DIRECTOR_NAME}%" \
             -e "s%###DIRECTOR_CONSOLE_MONITOR_NAME###%${DIRECTOR_CONSOLE_MONITOR_NAME}%" \
             -e "s%###DIRECTOR_CONSOLE_MONITOR_PASSWORD###%${DIRECTOR_CONSOLE_MONITOR_PASSWORD}%" ${CONFIG_FOLDER}/${BACULA_FD_CONFIG_FILE}
      echo [DONE]
   
      echo -n "Inserting variables into \"bconsole.conf\" file...        "
      sed -i -e "s%###DIRECTOR_NAME###%${DIRECTOR_NAME}%" \
             -e "s%###DIRECTOR_ADDRESS###%${DIRECTOR_ADDRESS}%" \
             -e "s%###MD5_PASSWORD###%${MD5_PASSWORD}%" ${CONFIG_FOLDER}/${BCONSOLE_CONFIG_FILE}
      echo [DONE]  
   fi
fi

exit 0

### Only for bacula client on docker host
# copy files to client install dir
if [[ -d ${CLIENT_INSTALL_DIR} ]]; then
   echo -n "Copying \"bacula-fd.conf\" file...    "
   \cp ${CONFIG_FOLDER}/${BACULA_FD_CONFIG_FILE} ${CLIENT_INSTALL_DIR}/bacula-fd.conf
   echo [DONE]

   echo -n "Copying \"bconsole.conf\" file...    "
   \cp ${CONFIG_FOLDER}/${BCONSOLE_CONFIG_FILE} ${CLIENT_INSTALL_DIR}/bconsole.conf
   echo [DONE]
fi 

### Unter Windows
# Director Name: bacula-dir                                    # Bacula server - Director Name
# Director Password: [md5]ecd4dc823c8699998de286ed5183b75e     # Run under linux: PASSWORD="$(pwgen 32 1)"; MD5_PASSWORD=$(echo -n "$PASSWORD"|md5sum| sed -r 's/\s+.*$//;s/^/[md5]/'); echo "Password: ${PASSWORD}"; echo "MD5 Password: ${MD5_PASSWORD}"
# Director Address: 192.168.15.16                              # ip a sh
