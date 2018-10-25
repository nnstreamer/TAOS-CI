# How to Build for Tizen Target

- [Build with Tizen-GBS. Full, Standard](#build)
- [Build with Tizen-GBS. Cached. Faster](#build-faster-with-caching)
- [Build with Tizen-GBS. A Module Only, Faster](#build-partially-a-single-ros-module-only)
- You may combile the two "faster" methods to make it even faster.

## Firewall Access / Accounts / Official Guides

While we use a internal OBS build system of your company, not the public Tizen OBS system, we need firewall access to the following servers

You need an OBS account if you want to access OBS (update commit ID of a package in the build system)
- Note that OBS account is only for those who updates commitID of built (for OS image) packages: project managers and maintainers.
- For readonly access, you may use ```obs_viewer``` / ```obs_viewer```.

Official Guides on Building Tizen Packages
- [Official Guide on 'Building Packages Locally with GBS' (source.tizen.org)](https://source.tizen.org/documentation/developer-guide/getting-started-guide/building-packages-locally-gbs)

## Sample gbs.conf for Auto-Driving Project
```
[general]
profile = profile.tizen
tmpdir = /var/tmp
editor = vim
packaging_branch = tizen
workdir = .

[profile.tizen]
user = TIZENUSERID (optional)
passwd = TIZENPASSWD (optional)
obs = obs.tizen

repos = repo.autodrv, repo.unified, repo.base
buildroot = ~/GBS-ROOT/

[obs.tizen]
url = https://api.tizen.org
user = TIZENUSERID (optional)
passwd = TIZENPASSWD (optional)

[repo.base]
url = http://download.tizen.org/snapshots/tizen/base/latest/repos/standard/packages/

[repo.unified]
url = http://download.tizen.org/snapshots/tizen/unified/latest/repos/standard/packages/

[repo.autodrv]
url = http://SPINID:SPINPASSWD@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving/standard/
```

## Install build infrastructure

[Official Guide at tizen.org](https://source.tizen.org/documentation/developer-guide/getting-started-guide/installing-development-tools)

### Ubuntu 16.04

1. Add ```deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ /``` to ```/etc/apt/sources.list```

```
$ sudo apt-get update
$ sudo apt-get install gbs mic
```

### Ubuntu 14.04

2. Add ```deb http://download.tizen.org/tools/latest-release/Ubuntu_14.04/ /``` to ```/etc/apt/sources.list```

```
$ sudo apt-get update
$ sudo apt-get install gbs mic
```

## Build

CAUTION!: uncommitted files won't be included for build.

```
AuDri$ gbs build
```

You will see the built rpm files at ~/GBS-ROOT/local/repos/tizen/$ARCH/RPMS/
($ARCH is x86_64 if you use x64 machine and did not supply -A option)

If you want to build armv7l images:
```
AuDri$ gbs build -A armv7l
```

If you want to build with uncommitted files or contents:
```
AuDri$ gbs build --include-all
```

For more details:
```
$ man gbs
```

## Build partially (a single ROS module only)

```
$ gbs build --define "app rqt_adlog"
```
will build and package rqt_adlog only (and autodrive that is required by rqt_adlog)

## Build Faster with Caching

```
$ gbs build --skip-srcrpm --ccache
```

If you have a large memory, you may let GBS use memory-based tmpfs to boost further.

## Analyze unit test coverage

```
$ gbs build --define "testcoverage 1"
```
will analyze unit test coverage with gcov and lcov.

With ```testcoverage 1``` option, there will be an additional RPM subpackage, ```<your_prj_name>-unittest-coverage```, which installs the resulting web pages to /usr/share/<your_prj_name>/unittest/result/.

Note that this option may be used along with --define "app APPNAME" option.

## Dive into the build system

```
$ gbs chroot ~/GBS-ROOT/local/BUILD-ROOTS/scratch.$ARCH.0/
info: chroot /home/mzx/GBS-ROOT/local/BUILD-ROOTS/scratch.x86_64.0
(tizen-build-env)@HOSTNAME /]$ ls -l /
total 84
lrwxrwxrwx  1 root root     7 Nov 16 06:45 bin -> usr/bin
dr-xr-xr-x  2 root root  4096 Aug 25 05:29 boot
drwxr-xr-x  4 root root  4096 Aug 25 05:29 dev
drwxr-xr-x 21 root root  4096 Nov 16 07:36 etc
drwxr-xr-x  3 root root  4096 Nov 16 06:45 home
drwxr-xr-x  2 root root 20480 Nov 16 06:50 installed-pkg
lrwxrwxrwx  1 root root     7 Nov 16 06:45 lib -> usr/lib
lrwxrwxrwx  1 root root     9 Nov 16 06:45 lib64 -> usr/lib64
lrwxrwxrwx  1 root root     9 Nov 16 06:45 media -> opt/media
drwxr-xr-x  2 root root  4096 Aug 25 05:29 mnt
drwxr-xr-x 11 root root  4096 Nov 16 06:47 opt
drwxr-xr-x  2 root root  4096 Nov 16 06:45 proc
dr-xr-x---  2 root root  4096 Nov 16 06:50 root
drwxr-xr-x  3 root root  4096 Aug 25 05:29 run
lrwxrwxrwx  1 root root     8 Nov 16 06:45 sbin -> usr/sbin
drwxr-xr-x  2 root root  4096 Aug 25 05:29 srv
drwxr-xr-x  2 root root  4096 Aug 25 05:29 sys
-rw-r--r--  1 root root  6116 Nov 16 06:57 tizen.conf
drwxrwxrwt  2 root root  4096 Nov 16 06:56 tmp
drwxr-xr-x 15 root root  4096 Nov 16 06:45 usr
drwxr-xr-x 14 root root  4096 Nov 16 06:45 var
(tizen-build-env)@HOSTNAME /]$
```

# How to Build for Ubuntu-based Target

## pdebuild, the recommended build mechanism for Ubuntu

### If you have already configured pdebuild.
```
$ cd AuDri
$ pdebuild
...
$ ls /var/cache/pbuilder/result/ -l
-rw-r--r-- 1 mzx  mzx       1343 Nov 14 16:05 your_prj_name_2017.11.7_amd64.changes
-rw-r--r-- 1 mzx  mzx     169934 Nov 14 16:05 your_prj_name_2017.11.7_amd64.deb
-rw-rw-r-- 1 mzx  mzx       1060 Nov 14 16:04 your_prj_name_2017.11.7.dsc
-rw-r--r-- 1 mzx  mzx  777126748 Nov 14 16:04 your_prj_name_2017.11.7.tar.gz
...
$ dpkg -i /var/cache/pbuilder/your_prj_name_2017.11.7_amd64.deb
...
```

### How to configure pdebuild

1. If you want to use deb files built in your local machine. (replace xenial with trusty if you want packages for Ubuntu 14.04)
```
$ cat ~/.pbuilderrc
COMPONENT="main restricted universe multiverse"
OTHERMIRROR="deb [trusted=yes] file:///var/cache/pbuilder/result ./"
BINDMOUNTS="/var/cache/pbuilder/result"
$ sudo pbuilder update xenial --override-config
$ pushd /var/cache/pbuilder/result
$ sudo -c "dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz"
$ popd
```

Note that you need to run ```$ sudo -c "dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz"``` at pbuilder result directory whenever you've create deb files with pdebuild.

For ```sudo pbuilder```, use ```xenial``` if you want 16.04 deb packages. use ```trusty``` if you want 14.04 deb package.
(You can create any Ubuntu packages regardless of the installed Ubuntu version)

2. If you want to use deb files available in SPIN/TRBS (Need firewall access to Seoul-RnD)
```
COMPONENT="main restricted universe multiverse"
OTHERMIRROR="deb [trusted=yes] http://SPINID:SPINPASSWORD@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/Ubuntu16.04/ /"
$ sudo pbuilder update xenial --override-config
```

For ```sudo pbuilder```, use ```xenial``` if you want 16.04 deb packages. use ```trusty``` if you want 14.04 deb package.
For OTHERMIRROR, If you want to build ```trusty (14.04```, replace 16.04 with 14.04.
(You can create any Ubuntu packages regardless of the installed Ubuntu version)

Note that you may list multiple "OTHERMIRROR" with ```|```; e.g., ```OTHERMIRROT="deb x|deb y|..."```.



## debuild, if the component's dependency is not cleaned, yet

### If you have your own public keys configured

```
$ debuild
```

### If you do not have your own public keys configured

```
$ debuild -uc -us
```

The resulting .deb files will appear at ```../```


## Case study: AuDri Project

manual build, if the component is too messy for deb packaging.

Developers of each component should make sure that their component is gbs buildable.
However, for manual build, each component must be able to be built with:

If you use Ubuntu14.04+ROS-Indigo (Docker-AD)
```bash
$ CIP=/opt/ros/indigo/
```
If you use Tizen + ROS-Kinetic (gbs chroot or target machine with Tizen)
```bash
$ CIP=/usr/lib/ros/kinetic/
```

```bash
AuDri$ . ${CIP}setup.sh
AuDri$ cd ROS/component_name
AuDri/ROS/component_name$ rm -Rf build
AuDri/ROS/component_name$ mkdir build
AuDri/ROS/component_name$ cd build
AuDri/ROS/component_name/build$ cd build
AuDri/ROS/component_name/build$ cmake .. -DCMAKE_INSTALL_PREFIX=${CIP}
AuDri/ROS/component_name/build$ make -j8
```

Then, you can install by:

```bash
AuDri/ROS/component_name/build$ sudo sh -c ". ${CIP}setup.sh; make install"
```


Here is a shell script I'm using for Ubuntu 14.04 Docker-AD (ROS Indigo):
```bash
$ cd AuDri/ROS
$ cat run.sh 
. /opt/ros/indigo/setup.sh
pushd $1
echo $1
rm -Rf build
mkdir -p build
pushd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/ros/indigo
make -j8
sudo sh -c ". /opt/ros/indigo/setup.sh; make install"
popd
popd
```
hehe
