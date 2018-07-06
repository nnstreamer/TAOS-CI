# How to build [Tizen](https://source.tizen.org/documentation/reference/git-build-system/usage/gbs-build) RPM package
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
# How to build [Ubuntu](https://wiki.ubuntu.com/PbuilderHowto) DEB package
You have to execute ***pdebuild*** command before submitting your PR.
```bash
$ sudo apt install pbuilder debootstrap devscripts
$ vi ~/.pbuilderrc  # in case of x86 64bit architecture
# man 5 pbuilderrc
DISTRIBUTION=xenial
OTHERMIRROR="deb http://archive.ubuntu.com/ubuntu xenial universe multiverse"
$ sudo ln -s  ~/.pbuilderrc /root/.pbuilderrc
$ sudo pbuilder create
$ pdebuild  # build package to generate *.deb file
$ ls -al /var/cache/pbuilder/result/*.deb
```
