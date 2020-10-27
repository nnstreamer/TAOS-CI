
How to build package with gbs
===============================

We assume that you are using Ubuntu 16.04 X86_64. 
This document is to help Tizen newbies that try to build RPM package of Tizen.

# Pre-requisites
```bash
$ sudo vi /etc/profile
#### Network proxy to run apt-get in terminal (Since Apr-08-2016)
export http_proxy=http://10.112.1.184:8080
export https_proxy=https://10.112.1.184:8080
export ftp_proxy=ftp://10.112.1.184:8080
$
$ sudo vi /etc/apt/sources.list.d/tizen.list
deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_18.04/ / # upgraded to xenial
$ sudo apt update
$ sudo apt install gbs lthor mic
```

# Build
```bash
$ cp ./packaging/.gbs.conf  ~/
$ time gbs build
```


# Reference
* https://source.tizen.org/ (for platform developers)
* https://developer.tizen.org/ (for application developers)
* https://craftroom.tizen.org/ (for IoT developers)
