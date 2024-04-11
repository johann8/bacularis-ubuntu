#!/bin/bash
# set -x
#
### === Create Config for new client for bacula - server side ===
#

# Set variables
SCRIPT_VERSION=0.4
PASSWORD="$(pwgen 32 1)"
MD5_PASSWORD=$(echo -n "$PASSWORD"|md5sum| sed -r 's/\s+.*$//;s/^/[md5]/')
CLIENT_NAME=
IP_ADDRESS=
BACULA_SERVER_CONFIG_DIR_DOCKER="/opt/bacularis/data/bacula/config/etc/bacula-dir.conf"
SCRIPT_NAME_CLIENT="2_create_new_bacula_client_linux--client_side_template.sh"
BACULA_DIR_CONFIG_FILE_TEMPLATE="bacula-dir_template.conf"
CONFIG_FOLDER="config_files"


# Function
show_help() {
    echo ""
    echo "<-------------- HELP -------------->"
    echo "Usage: $0 -n pc-01 -ip 10.0.2.5"
    echo "Usage: $0 --name pc-02 --ipaddress 10.0.2.5"
    echo ""
    echo "Create bacula client config files."
    echo ""
    echo "-h,  --help              Show help and exit."
    echo "-v,  --version           Show script version and exit."
    echo "-ip, --ipaddress         IP address of bacula client - example: \"192.168.20.45\""
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
        -ip|--ipaddress)
            shift
            BACULA_CLIENT_IP_ADDRESS=$1
            shift
            ;;
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

# verify var BACULA_CLIENT_IP_ADDRESS
if [[ -z ${BACULA_CLIENT_IP_ADDRESS} ]]
then
    echo ""
    echo "Script: Please specify a client IP address."
    show_help
    exit 1
fi

# Pass variables
CLIENT_NAME=${BACULA_CLIENT_NAME}
IP_ADDRESS=${BACULA_CLIENT_IP_ADDRESS}
BACULA_DIR_CONFIG_FILE=bacula-dir_${CLIENT_NAME}.conf

# create config folder
if [[ ! -d ${CONFIG_FOLDER} ]]; then
   echo -n "Creating folder \"${CONFIG_FOLDER}\"...        "
   mkdir ${CONFIG_FOLDER}
   echo [DONE]
fi

# create config file
if [[ -f ${BACULA_DIR_CONFIG_FILE_TEMPLATE} ]]; then

   # Create config file
   echo -n "Creating file: \"bacula-dir.conf\"...      "
   cp ${BACULA_DIR_CONFIG_FILE_TEMPLATE} ${CONFIG_FOLDER}/${BACULA_DIR_CONFIG_FILE}
   echo [DONE]

   # Create template
   if [[ ! -z ${MD5_PASSWORD} ]] && [[ ! -z ${CLIENT_NAME} ]] && [[ ! -z ${IP_ADDRESS} ]]; then
      echo "Password: ${PASSWORD}"
      echo "MD5 Password: ${MD5_PASSWORD}"
      echo "Client name: ${CLIENT_NAME}"
      echo "IP Address: ${IP_ADDRESS}"

      echo -n "Inserting variables into config file...  "
      sed -i -e "s/###CLIENT_NAME###/${CLIENT_NAME}/" \
             -e "s/###IP_ADDRESS###/${IP_ADDRESS}/" \
             -e "s/###MD5_PASSWORD###/${MD5_PASSWORD}/" ${CONFIG_FOLDER}/${BACULA_DIR_CONFIG_FILE}
      echo [DONE]
   fi
fi

# read bacula-mon password
WORKING_DIR=$(pwd)
if [[ -f ${WORKING_DIR}/${SCRIPT_NAME_CLIENT} ]]; then
   # read bacula-dir monitor pw
   echo -n "Reading bacula-dir monitor pw..."
   BACULA_DIR_MON_PW=$(cat ${BACULA_SERVER_CONFIG_DIR_DOCKER} |sed -n '/bacula-mon/,+1p' |grep Password |cut -f 2 -d '"')
   echo [DONE]

   # insert passwort in script
   echo -n "Inserting password to script... "
   sed -i -e "s/###BACULA_DIR_MON_PASSWORD###/${BACULA_DIR_MON_PW}/" ${WORKING_DIR}/${SCRIPT_NAME_CLIENT}
   echo [DONE]
else
   echo "Script \"${WORKING_DIR}/${SCRIPT_NAME_CLIENT}\" could not be find."
fi

exit 0
