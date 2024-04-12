<h1 align="center">Install bacula client on linux</h1>

- [RPM based Linux distributions](#rpm-based-linux-distributions)
- [DEB based Linux distributions](#deb-based-linux-distributions)

Register [here](https://www.bacula.org/bacula-binary-package-download/) to receive `access-key`\
You can find [Community installation guide](https://www.bacula.org/whitepapers/CommunityInstallationGuide.pdf) useful

## RPM based Linux distributions

### RedHat | Oracle | Rocky | CentOS

- Import the GPG key

```bash
cd /tmp
wget https://www.bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc
rpm --import Bacula-4096-Distribution-Verification-key.asc
rm Bacula-4096-Distribution-Verification-key.asc
```

- Package Manager Configuration

```bash
## @access-key@ - refers to your personalized area string
vim /etc/yum.repos.d/Bacula.repo
--------------------------------
[Bacula-Community]
name=CentOS - Bacula - Community
baseurl=https://www.bacula.org/packages/@access-key@/rpms/15.0.2/el8/x86_64/
enabled=1
protect=0
gpgcheck=1
gpgkey=https://www.bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc
-------------------------------
```
- Install bacula client

```bash
dnf install bacula-client
or
yum install bacula-client

# Additional package - 
Doker: bacula-docker-plugin bacula-docker-tools
Kubernetes: bacula-kubernetes-plugin bacula-kubernetes-tools
CDP: bacula-cdp-plugin
```


## DEB based Linux distributions

### Debian | Ubuntu

- Additional Package Installation

```bash
apt-get update
apt-get install apt-transport-https
```
- Import the GPG key

```bash
cd /tmp
wget https://www.bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc
apt-key add Bacula-4096-Distribution-Verification-key.asc
rm Bacula-4096-Distribution-Verification-key.asc
```
- Package Manager Configuration

```bash
vi /etc/apt/sources.list.d/Bacula-Community.list
------------------
# Bacula Community
deb https://www.bacula.org/packages/6367abb52d166/debs/15.0.2 bookworm main
# deb https://www.bacula.org/packages/6367abb52d166/debs/15.0.2 bullseye main
# deb https://www.bacula.org/packages/6367abb52d166/debs/15.0.2 jammy main
# deb https://www.bacula.org/packages/6367abb52d166/debs/15.0.2 focal main
------------------
```
- Install bacula client

```bash
apt-get update
apt-get install bacula-client 

# Additional package -
Doker: bacula-docker-plugin bacula-docker-tools
Kubernetes: bacula-kubernetes-plugin bacula-kubernetes-tools
CDP: bacula-cdp-plugin
```
## If you see `apt-get` warning:
 
- Show `Bacula` key

```bash
apt-key list Bacula
------------
pub   rsa4096 2018-09-03 [SC]
      5235 F5B6 68D8 1DB6 1704  A82D C0BE 2A5F E9DF 3643
uid           [ unknown] Bacula 4096 Distribution Verification Key (www.bacula.org) <kern@bacula.org>
sub   rsa4096 2018-09-03 [E]
-----------
```
- Export GPG Key to `trusted.gpg.d` foler
```bash
# Note: The BE1229CF value comes from the last 8 characters of the pub code
apt-key export E9DF3643 | gpg --dearmor -o /etc/apt/trusted.gpg.d/bacula.gpg
apt-get update
```

```bash

```






