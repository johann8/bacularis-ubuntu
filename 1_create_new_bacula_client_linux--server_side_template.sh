#!/bin/bash
# set -x
#
### === Create Config for new client for bacula - server side ===
#

# Set variables
SCRIPT_VERSION=0.3
PASSWORD="$(pwgen 32 1)"
MD5_PASSWORD=$(echo -n "$PASSWORD"|md5sum| sed -r 's/\s+.*$//;s/^/[md5]/')
CLIENT_NAME=
IP_ADDRESS=

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
BACULA_DIR_CONFIG_FILE_TEMPLATE=bacula-dir_template.conf
BACULA_DIR_CONFIG_FILE=bacula-dir_${CLIENT_NAME}.conf
CONFIG_FOLDER=config_files

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

exit 0

# Template
cat > bacula-dir_template.conf << 'EOL'
Client {
  Name = "###CLIENT_NAME###-fd"
  Address = "###IP_ADDRESS###"
  FdPort = 9102
  Password = "###MD5_PASSWORD###"
  Description = "Backup Host - ###CLIENT_NAME###"
  Catalog = "MyCatalog"
  FileRetention = 5184000
  JobRetention = 15552000
  AutoPrune = yes
}
Job {
  Name = "backup-###CLIENT_NAME###"
  JobDefs = "###CLIENT_NAME###-job"
  Description = "Backup Host - ###CLIENT_NAME###"
}
JobDefs {
  Name = "###CLIENT_NAME###-job"
  Type = "Backup"
  Level = "Incremental"
  Messages = "Standard"
  Storage = "File1"
  Pool = "Incremental"
  FullBackupPool = "Full"
  IncrementalBackupPool = "Incremental"
  DifferentialBackupPool = "Differential"
  Client = "###CLIENT_NAME###-fd"
  Fileset = "###CLIENT_NAME###-fset"
  Schedule = "WeeklyCycle"
  WriteBootstrap = "/var/lib/bacula/%c.bsr"
  SpoolAttributes = yes
  Priority = 10
}
Fileset {
  Name = "###CLIENT_NAME###-fset"
  Include {
    File = "/etc"
    File = "/opt/bacula/etc"
    Options {
      Signature = MD5
      Wild = *.jpg
      Wild = *.png
      Wild = *.gif
      Wild = *.zip
      Wild = *.rar
      Wild = *.7z
      Wild = *.r??
      Wild = *.mpg
      Wild = *.wmv
      Wild = *.avi
      Wild = *.mov
      Wild = *.mkv
      Wild = *.mp3
      Wild = *.mp4
      Wild = *.gz
      Wild = *.bz2
    }
    Options {
      Signature = "Md5"
      Compression = "LZO"
    }
  }
  Exclude {
    File = "/proc"
    File = "/tmp"
    File = "/sys"
    File = "/.journal"
    File = "/.fsck"
    File = "/etc/selinux"
    File = "/etc/udev"
  }
}
EOL

