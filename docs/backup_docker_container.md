<h1 align="center">Bacula - Backup docker container</h1>

- [Backup using bash script](#backup-docker-container-using-bash-script)
- [Backup using bash script and lvm snapshot](#backup-docker-container-using-bash-script-and-lvm-snapshot)
- [Backup using Bacula docker plugin](#backup-docker-container-using-bacula-docker-plugin)

## Backup docker container using bash script

- Change `Director` config `bacula-dir.conf`

```bash
# You need to pass the variable `before | after` to script
# Example for client `oraclel8-fd`

#
### If LVM snapshot will not be used
#
cd /opt/bacularis && docker-compose down
BACULA_DIR_CONFIG=/opt/bacularis/data/bacula/config/etc/bacula-dir.conf
CLIENT_NAME=oraclel8

cat >> ${BACULA_DIR_CONFIG} << EOL
Job {
  Name = "backup-${CLIENT_NAME}-docker-stopScript"
  Description = "Backup all docker container with container stop script"
  JobDefs = "${CLIENT_NAME}-docker-stopScript-job"
  Runscript {
    RunsWhen = "Before"
    Command = "/opt/bacula/scripts/script_before_after.sh before"
  }
  Runscript {
    RunsWhen = "After"
    Command = "/opt/bacula/scripts/script_before_after.sh after"
  }
}
Fileset {
  Name = "${CLIENT_NAME}-docker-stopScript-fs"
  Description = "Backup all docker container with container stop script"
  EnableVss = no
  Include {
    File = "/opt"   
    Options {
      Compression = "LZO"
      Signature = "SHA1"
      OneFs = "yes"
    }
  }
  Exclude {
    File = "/opt/containerd"
    File = "/opt/lost+found"
    File = "/opt/bacularis"
    File = "/opt/bacularisalp"	
  }
}
JobDefs {
  Name = "${CLIENT_NAME}-docker-stopScript-job"
  Description = "Backup all docker container with container stop script"
  Type = "Backup"
  Level = "Incremental"
  Messages = "Standard"
  Storage = "File1"
  Pool = "Incremental"
  FullBackupPool = "Full"
  IncrementalBackupPool = "Incremental"
  DifferentialBackupPool = "Differential"
  Client = "${CLIENT_NAME}-fd"
  Fileset = "${CLIENT_NAME}-docker-stopScript-fs"
  Schedule = "WeeklyCycle"
  WriteBootstrap = "/opt/bacula/working/%c.bsr"
  SpoolAttributes = yes
  Priority = 10
}
EOL

```

- Download bash script into install path `/opt/bacula/scripts`

```bash
# add script and adjust vars
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/refs/heads/master/scripts/container_backup_before_after.sh -O /opt/bacula/scripts/script_before_after.sh
chmod a+x /opt/bacula/scripts/script_before_after.sh
vim /opt/bacula/scripts/script_before_after.sh

cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```

## Backup docker container using bash script and lvm snapshot

- Change `Director` config `bacula-dir.conf`

```bash
# You need to pass the variable `before | after` to script
# Example for client `oraclel8-fd`

#
### If LVM snapshot will be used
#
cd /opt/bacularis && docker-compose down
BACULA_DIR_CONFIG=/opt/bacularis/data/bacula/config/etc/bacula-dir.conf
CLIENT_NAME=oraclel8

cat >> ${BACULA_DIR_CONFIG} << EOL
Job {
  Name = "backup-${CLIENT_NAME}-docker-stopScript"
  Description = "Backup all docker container with container stop script"
  JobDefs = "${CLIENT_NAME}-docker-stopScript-job"
  Runscript {
    RunsWhen = "Before"
    Command = "/opt/bacula/scripts/script_before_after.sh before"
  }
  Runscript {
    RunsWhen = "After"
    Command = "/opt/bacula/scripts/script_before_after.sh after"
  }
}
Fileset {
  Name = "${CLIENT_NAME}-docker-stopScript-fs"
  Description = "Backup all docker container with container stop script"
  EnableVss = no
  Include {
    File = "/mnt/lvm_snap/opt"   
    Options {
      Compression = "LZO"
      Signature = "SHA1"
      OneFs = "yes"
    }
  }
  Exclude {
    File = "/mnt/lvm_snap/opt/containerd"
    File = "/mnt/lvm_snap/opt/lost+found"
    File = "/mnt/lvm_snap/opt/bacularisalp"	
  }
}
JobDefs {
  Name = "${CLIENT_NAME}-docker-stopScript-job"
  Description = "Backup all docker container with container stop script"
  Type = "Backup"
  Level = "Incremental"
  Messages = "Standard"
  Storage = "File1"
  Pool = "Incremental"
  FullBackupPool = "Full"
  IncrementalBackupPool = "Incremental"
  DifferentialBackupPool = "Differential"
  Client = "${CLIENT_NAME}-fd"
  Fileset = "${CLIENT_NAME}-docker-stopScript-fs"
  Schedule = "WeeklyCycle"
  WriteBootstrap = "/opt/bacula/working/%c.bsr"
  SpoolAttributes = yes
  Priority = 10
}
EOL

```

- Download bash script into install path `/opt/bacula/scripts`

```bash
# add script and adjust vars
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/refs/heads/master/scripts/container_backup_before_after.sh -O /opt/bacula/scripts/script_before_after.sh
chmod a+x /opt/bacula/scripts/script_before_after.sh
vim /opt/bacula/scripts/script_before_after.sh

cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```

## Backup docker container using Bacula docker plugin

- Install `Bacula` docker-plugin
```bash
# Red Hat Enterprise Linux / Centos / Rocky / Oracle
dnf install bacula-docker-plugin bacula-docker-tools

# Debian / Ubuntu
apt-get install bacula-docker-plugin bacula-docker-tools
```

- Change `Director` config `bacula-dir.conf`

```bash
# You need to exclude all bacula containers
# Example for client `oraclel8-fd`

cd /opt/bacularis && docker-compose down
BACULA_DIR_CONFIG=/opt/bacularis/data/bacula/config/etc/bacula-dir.conf
CLIENT_NAME=oraclel8

cat >> ${BACULA_DIR_CONFIG} << EOL
Job {
  Name = "backup-${CLIENT_NAME}-docker-plugin"
  Description = "Backup all docker container with docker-plugin"
  JobDefs = "${CLIENT_NAME}-docker-plugin-job"
}
Fileset {
  Name = "${CLIENT_NAME}-docker-plugin-fs"
  Description = "Backup all docker container with docker-plugin"
  EnableVss = no
  Include {
    Plugin = "docker: include_container=.* exclude_container=^bacula"
      Options {
      Compression = "LZO"
      Signature = "SHA1"
      OneFs = "yes"
    }
  }
}
JobDefs {
  Name = "${CLIENT_NAME}-docker-plugin-job"
  Description = "Backup all docker container with docker-plugin"
  Type = "Backup"
  Level = "Incremental"
  Messages = "Standard"
  Storage = "File1"
  Pool = "Incremental"
  FullBackupPool = "Full"
  IncrementalBackupPool = "Incremental"
  DifferentialBackupPool = "Differential"
  Client = "${CLIENT_NAME}-fd"
  Fileset = "${CLIENT_NAME}-docker-plugin-fs"
  Schedule = "WeeklyCycle"
  WriteBootstrap = "/opt/bacula/working/%c.bsr"
  SpoolAttributes = yes
  Priority = 10
}
EOL

```
- Start `Bacula` docker stack and check logs

```bash
cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```

