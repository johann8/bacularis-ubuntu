<h2 align="center">Bacula - Add new autochanger for Archive Storage</h2>


- A new autochanger will be set up for `bacula` archive backup. A template has been prepared for this. Two variables must be adjusted: `AUTOCHANGER_NAME` and `MEDIA_TYPE`. Then execute the following commands:

```bash
cd /opt/bacularis && dcexec bacularis bash
cd /tmp
curl   https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/add_new_autochanger_template --output add_new_autochanger_template
nano add_new_autochanger_template

bash add_new_autochanger_template
rm -rf add_new_storage_pool_schedule_template
```
- Reload bacula to read new config
```bash
bconsole
reload
q
exit
```
