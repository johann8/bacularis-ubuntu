<h2 align="center">Bacula - Add new Pool for Windows backup</h2>


- A template for windows pools has also been created. You have to adjust some variables in it. Then execute the following commands: 

```bash
cd /opt/bacularis && dcexec bacularis bash
cd /tmp
curl  https://raw.githubusercontent.com/johann8/bacularis-ubuntu/master/add_new_windows_pool_template --output add_new_windows_pool_template
nano add_new_windows_pool_template

bash add_new_windows_pool_template
rm -rf add_new_windows_pool_template
```

- Reload bacula to read new config

```bash
bconsole
reload
q
exit
```
