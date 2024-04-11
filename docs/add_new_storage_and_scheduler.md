<h2 align="center">Bacula - Add new Storage for Archive and new Scheduler</h2>


- After you have created the autochanger, you must also create a storage unit. A template has also been created for this. You have to adjust some variables in it. Two new schedulers will be created at the same time `MonthlyCycle-Archive-Win` and `MonthlyCycle-Archive-Lin`. If you do not need them, please delete them from the template.Then execute the following commands: 

```bash
cd /opt/bacularis && dcexec bacularis bash
cd /tmp
curl  https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/add_new_storage_pool_schedule_template --output add_new_storage_pool_schedule_template
nano add_new_storage_pool_schedule_template

bash add_new_storage_pool_schedule_template
rm -rf add_new_storage_pool_schedule_template
```

- Reload bacula to read new config

```bash
bconsole
reload
q
exit
```
