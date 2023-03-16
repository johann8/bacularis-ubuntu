#!/bin/bash
# set -x
#
### === Create Config for new client for bacula - client side ===
#

# Set variables
#MD5_PASSWORD=                                                                    #  On bacula server: cat bacula-dir.conf ( Client {  Name = "oraclel8-fd" Password = "[md5]a1e10524f1a33eae3496d1104b056f3e"} )
SCRIPT_VERSION=0.3
DIRECTOR_ADDRESS=192.168.15.16                                                    # IP Address of docker host wher bacula server is running
DIRECTOR_NAME=bacula-dir                                                          # The name of bacula server director (bacula-dir)
DIRECTOR_CONSOLE_MONITOR_NAME=bacula-mon                                          # The name of bacula server console (bacula-mon)
DIRECTOR_CONSOLE_MONITOR_PASSWORD='Vy1holhTDZ3xPYB6s0QaqW26/1levNlVNqU07i+rLQUt'  # On bacula server: cat bacula-dir.conf ( Console {Name = "bacula-mon" Password = "Vy1holhTDZ3xPYB6s0QaqW26/1levNlVNqU07i+rLQUt" } )

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

# Create config files
if [[ -f /opt/bacula/etc/bacula-fd.conf ]]; then
   echo -n "Creating backup of \"bacula-fd.conf\"..."
   cp /opt/bacula/etc/bacula-fd.conf /opt/bacula/etc/bacula-fd.conf.backup
   echo [DONE]
fi

if [[ -f /opt/bacula/etc/bconsole.conf ]]; then
   echo -n "Creating backup of \"bconsole.conf\"..."
   cp /opt/bacula/etc/bconsole.conf /opt/bacula/etc/bconsole.conf.backup
   echo [DONE]
fi

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
      sed -i -e "s/###CLIENT_NAME###/${CLIENT_NAME}/" \
             -e "s/###MD5_PASSWORD###/${MD5_PASSWORD}/" \
             -e "s/###DIRECTOR_NAME###/${DIRECTOR_NAME}/" \
             -e "s/###DIRECTOR_CONSOLE_MONITOR_NAME###/${DIRECTOR_CONSOLE_MONITOR_NAME}/" \
             -e "s!###DIRECTOR_CONSOLE_MONITOR_PASSWORD###!${DIRECTOR_CONSOLE_MONITOR_PASSWORD}!" ${CONFIG_FOLDER}/${BACULA_FD_CONFIG_FILE}
      echo [DONE]
   
      echo -n "Inserting variables into \"bconsole.conf\" file...        "
      sed -i -e "s/###DIRECTOR_NAME###/${DIRECTOR_NAME}/" \
             -e "s/###DIRECTOR_ADDRESS###/${DIRECTOR_ADDRESS}/" \
             -e "s/###MD5_PASSWORD###/${MD5_PASSWORD}/" ${CONFIG_FOLDER}/${BCONSOLE_CONFIG_FILE}
      echo [DONE]  
   fi
fi

exit 0

cat > bacula-fd_template.conf << 'EOL'
# cat /opt/bacula/etc/bacula-fd.conf
#
# Default  Bacula File Daemon Configuration file
#

#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = ###DIRECTOR_NAME###
  Password = "###MD5_PASSWORD###"
}

#
# Restricted Director, used by tray-monitor to get the
#   status of the file daemon
#
Director {
  Name = ###DIRECTOR_CONSOLE_MONITOR_NAME###
  Password = "###DIRECTOR_CONSOLE_MONITOR_PASSWORD###"
  Monitor = yes
}

#
# "Global" File daemon configuration specifications
#
FileDaemon {                               # this is me
  Name = ###CLIENT_NAME###
  FDport = 9102                             # where we listen for the director
  WorkingDirectory = /opt/bacula/working
  Pid Directory = /opt/bacula/working
  Maximum Concurrent Jobs = 20
  Plugin Directory = /opt/bacula/plugins
}

# Send all messages except skipped files back to Director
Messages {
  Name = Standard
  director = ###DIRECTOR_NAME### = all, !skipped, !restored, !verified, !saved
}
EOL

cat > bconsole_template.conf << 'EOL'
# cat /opt/bacula/etc/bconsole.conf
#
# Bacula User Agent (or Console) Configuration File
#

Director {
  Name = ###DIRECTOR_NAME###
  DIRport = 9101
  address = ###DIRECTOR_ADDRESS###
  Password = "###MD5_PASSWORD###"
}
EOL

# Unter Windows
Director Name: bacula-dir                                    # Bacula server - Director Name
Director Password: [md5]ecd4dc823c8699998de286ed5183b75e     # Run under linux: PASSWORD="$(pwgen 32 1)"; MD5_PASSWORD=$(echo -n "$PASSWORD"|md5sum| sed -r 's/\s+.*$//;s/^/[md5]/'); echo "Password: ${PASSWORD}"; echo "MD5 Password: ${MD5_PASSWORD}"
Director Address: 192.168.15.16                              # ip a sh
