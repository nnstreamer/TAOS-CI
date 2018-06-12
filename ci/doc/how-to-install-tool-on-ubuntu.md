# How to install TAOS tool & customized packages on Ubuntu

In order to internally share some Ubuntu packages such as TOAS tool, NPU toolchain and some customized Ubuntu packages (e.g. opencv3 by @byoungo-kim), local TAOS debian server is created. You can easily search and install these packages using **apt** command in the same way.
* http://10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/


## Set *no_proxy* environment variable

First of all, you should add the TRBS IP (i.e. 10.113.136.32) into **no_proxy** environment variable as below.
```bash
$ cat /etc/environment
no_proxy="localhost,127.0.0.1,10.113.136.32"
$ soruce /etc/envrionment
```

## Add the TAOS tool repository into your apt list

In order to access the Ubuntu tools for TAOS,, your private **AD (Active Directory) ID** and its **Password** are required. Please create **taos.list** file into */etc/apt/sources.list.d* directory for your Ubuntu version as below.


### For Ubuntu 16.04

```bash
$ cat /etc/apt/sources.list.d/taos.list
deb [trusted=yes] http://[AD ID]:[PASSWORD]@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/Ubuntu16.04/ /
```

### For Ubuntu 14.04

```bash
$ cat /etc/apt/sources.list.d/taos.list
deb [trusted=yes] http://[AD ID]:[PASSWORD]@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/Ubuntu14.04/ /
```

### Fail to access the TRBS

If you face some problems to access the TRBS server, then visit the below AD Membership site and reset your password.
* https://addcplus.sec.samsung.net/ADUser


## Get new lists of TAOS tool packages

Before installing the package that you want, you have to retrieve new lists of debian package by executing **apt-get update** command. After then, you can install the TAOS tools in your Ubuntu using **apt-get install** command as below.

```bash
$ sudo apt-get update
Hit:1 http://10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/Ubuntu16.04  Release
... (skip)
$ sudo apt-get install taos-tool
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following NEW packages will be installed:
  taos-tool
0 upgraded, 1 newly installed, 0 to remove and 1 not upgraded.
```
