<h2 align="center">Bacula - Using script check storage is mounted</h2>

If the storage is e.g. a USB hard disk or NAS server share, then `bacula` should check on the `docker host` whether the hard disk or NAS share is connected. You can use a script to check this.

- Download the script and customize it

```bash
wget https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/scripts/check_mount_storage.sh -O /opt/bacula/scripts/check_mount_storage.sh
chmod a+x /opt/bacula/scripts/check_mount_storage.sh

# set variables
vim /opt/bacula/scripts/check_mount_storage.sh
```
- Log in to the Bacula web interface go to: Director ->Configure director ->Job ->backup-oraclel8-fd ->Edit
- Click on `+ Add` and fill out the webform as shown in the picture (Script path: /opt/bacula/scripts/check_mount_storage.sh)

![Add run script to job](https://github.com/johann8/bacularis-ubuntu/raw/master/docs/assets/screenshots/Add_run_script_to_job.png)

