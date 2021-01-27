---
title: Self assessment
...

In this page, we describe how to verify if your commit(s) is valid. To do source code verification,
we strongly recommend that you execute a clean build with a latest version of a software platform.
Note that partial validation inspection of software cause potential defects when the software is
integrated into the software platform.

# How to build [Ubuntu](https://wiki.ubuntu.com/PbuilderHowto) DEB package with pdebuild
You have to execute ***pdebuild*** command before submitting your PR.
```bash
$ sudo apt install pbuilder debootstrap devscripts
$ vi ~/.pbuilderrc  # In case of x86 64bit architecture
# man 5 pbuilderrc
DISTRIBUTION=xenial
OTHERMIRROR="deb http://archive.ubuntu.com/ubuntu xenial universe multiverse |deb [trusted=yes] http://ppa.launchpad.net/nnstreamer/ppa/ubuntu xenial main"
$ sudo ln -s  ~/.pbuilderrc /root/.pbuilderrc
$ sudo pbuilder create
$ sudo vi /etc/crontab
#### Update pdebuild/pbuilder to keep latest apt repositories, /var/cache/pbuilder/base.tgz
30 7 * * * root pbuilder update --override-config
$
$ pdebuild  # generate *.deb file with chroot technique
$ ls -al /var/cache/pbuilder/result/*.deb
```

# How to build [Tizen](https://source.tizen.org/documentation/reference/git-build-system/usage/gbs-build) RPM package with gbs
You have to execute ***gbs build*** command before submitting your PR.
```bash
$ sudo vi /etc/apt/sources.list.d/tizen.list
deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ / # upgraded to xenial
$ sudo apt update
$ sudo install gbs
$ cp TAOS-CI/packaging/.gbs.conf ~/
$ time gbs build -A x86_64  --clean --include-all  # Generate *.rpm from source for x86_64
$ time gbs build -A aarch64 --clean --include-all  # Generate *.rpm from source for aarch64
```

# How to build [Yocto](https://wiki.yoctoproject.org/wiki/Application_Development_with_Extensible_SDK) DEB package with devtool
We assume that your work folder is /var/www/html/poky_sdk folder. Note that 'devtool' command is located in Yocto SDK folder.

```bash
$ mkdir -p /var/www/html/poky_sdk
$ cd /var/www/html/poky_sdk
$ wget https://downloads.yoctoproject.org/tools/support/workflow/poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
$ chmod +x ./poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
$ ./poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
$ source /var/www/html/poky_sdk/environment-setup-i586-poky-linux

$ devtool add hello-world-sample https://github.com/{...}/hello-world-sample.git
$ cd /var/www/kairos_sdk/workspace/sources/hello-world-sample/
$ devtool edit-recipe hello-world-sample
$ devtool build hello-world-sample
$ devtool package hello-world-sample
$ devtool reset hello-world-sample
```

The source code below is an example in case that you have to write helloYocto source code in your own github repository.
Yocto provides three build methods to compile a source code as following:

* CMake-based hello-world project (Recommended)
```bash
$ cat ./CMakeLists.txt
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(hello-world)

ADD_EXECUTABLE(hello-world helloYocto.cpp)
INSTALL(TARGETS hello-world DESTINATION bin)

$
$ cat ./helloYocto.cpp
#include <iostream>
int main(int argc, char *argv[]){
   std::cout << "Hello World!" << std::endl;
   return 0;
}
```
* Makefile-based hello-world project
```bash
$ cat ./Makefile
CC      = gcc
CFLAGS  = -g
RM      = rm -f

default: all

all: hello-world

hello-world: helloYocto.c
    $(CC) $(CFLAGS) -o hello-world helloYocto.c

clean veryclean:
    $(RM) hello-world

$
$ cat ./helloYocto.c
#include <stdio.h>
int main(int argc, char *argv[]){
    printf("Hello world\n");
    return 0;
}
```

* Autotool-based hello-world project
Please refer to https://www.yoctoproject.org/docs/2.1/sdk-manual/sdk-manual.html#autotools-based-projects.
