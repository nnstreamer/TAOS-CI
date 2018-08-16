# Administrator guide for standalone CI server

## Configuration of current CI server

- Server address: http://localhost/
- Ubuntu 16.04

```
$ cat /etc/os-release |grep VERSION_ID
VERSION_ID="16.04.3"
```

## Install prerequisites
In order to run all checker modules normally, you have to run [install-packages.sh](install-packages.sh).


## Install Apache+PHP for CI Server
The CI server to run TAOS-CI has to be equipped with Apache and PHP script language to run lightwegith automation server instead of Jenkins.
Builds has been triggered by last commit number by scheduling a Pull Request (PR) with a bot, that is based on Webhook API and JSON.

**for Ubuntu 16.04**

```bash
$ sudo apt-get install apache2
$ sudo apt-get install php php-cgi libapache2-mod-php php-common php-pear php-mbstring
$ sudo a2enconf php7.0-cgi
$ sudo systemctl restart apache2
$ sudo vi /var/www/html/index.php
<?php
phpinfo();
?>
$ firefox http://localhost/index.php
```

Note. If you have a firewall in your network, please make sure that ports for CI server are opened and can accept requests.

## Install clang-format-4.0 for format checker

You have to install clang-format-4.0 (official version to check C++ formatting).

**for Ubuntu 16.04**

```bash
$ sudo vi /etc/apt/sources.list.d/clang.list
  # clang/llvm 4.0 repository for Ubuntu 16.04 (Xenial)
  deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main
  deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main
$ sudo apt update
$ sudo apt install clang-format-4.0
```

## Setting sudo privilege of www-data

You have to update /etc/sudoers for sudo access of www-data with no password in order to run "git clone" command normally
in Apahce/Php environment as following:

```bash
$ sudo visudo
# User privilege specification for development step
www-data    ALL=(ALL) NOPASSWD:ALL
or
# User privilege specification for robust security
www-data    ALL=(ALL) NOPASSWD: /usr/bin/git
```

Then, let's enable www-data as a system account.

```bash
$ su -
# vi /etc/passwd
www-data:x:33:33:www-data:/var/www:/bin/bash
# cd /var/
# chown -R www-data:www-data /var/www/
# cp /root/.bashrc /var/www/
# chwon www-data:www-data  /var/www/.bashrc
# su - www-data
```
If you want to push your commits without a password input procedure, please create ~/.netrc file as follows.
```bash
$ vi ~/.netrc
machine github.com
        login git.bot.sec
        password bdd8f27d1e718f878ff5c7120a45440ff63fxxxx
machine 10.113.136.32
        login git.bot.sec
        password npuxxxx
```

## Ubuntu: Set-up configuration file
The `~/.pbuilderrc` file contains default values used in the pbuilder program invocation.
The file itself is sourced by a shell script, so it is required that the file conforms to
shell script conventions. For more details, refer to http://manpages.ubuntu.com/manpages/trusty/man5/pbuilderrc.5.html
```bash
$ vi ~/.pbuilderrc
# man 5 pbuilderrc
DISTRIBUTION=xenial
OTHERMIRROR="deb http://archive.ubuntu.com/ubuntu xenial universe multiverse |deb [trusted=yes] http://[id]:[password]@[your-own-server]/taos/ubuntutools/ubuntu16.04/ /"

```

## Tizen: Set-up configuration file

You have to write `~/.gbs.conf` in order that `www-data` id can build a pakcage with `gbs build` command.
We assume that you are using `git.bot.sec` id as a default id of a repository webserver.

```bash
[general]
#Current profile name which should match a profile section name
profile = profile.tizen
tmpdir = /var/tmp
editor = vim
packaging_branch = tizen
workdir = .

[profile.tizen]
#Common authentication info for whole profile
#passwd will be automatically encrypted from passwd to passwdx
user = <your-id>
passwd = <your-password>
obs = obs.tizen

repos = repo.extra, repo.unified, repo.base
buildroot = ~/GBS-ROOT-SNAPSHOT/

[obs.tizen]
#OBS API URL pointing to a remote OBS.
url = https://api.tizen.org

# in case that one of the Tizen rpm repositories is broken, specify stable version as follows instead of "latest".
# https://github.com/01org/gbs/blob/master/docs/GBS.rst#34-shell-style-variable-references
# ver_base=tizen-base_20180427.1
# ver_unified=tizen-unified_20180504.2
# ver_extra=tizen-5.0-taos_20180504.2


[repo.base]
url = http://download.tizen.org/snapshots/tizen/base/latest/repos/standard/packages/
 
[repo.unified]
url = http://download.tizen.org/snapshots/tizen/unified/latest/repos/standard/packages/

[repo.extra]
url = http://<your_id>:<your_pass>@<your_ip>/download/latest/repos/standard/packages/
```

## Yocto: Set-up configuration file

In case of Yocto, you can build a package with OpenEmbedded/devtool to verify a build validation on YOCTO platform
For more details, please refer to https://wiki.yoctoproject.org/wiki/Application_Development_with_Extensible_SDK
```bash
$ sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib
$ sudo apt-get -y install build-essential chrpath socat libsdl1.2-dev xterm
```
Note that a devtool command are the configuration file (e.g.,environment-setup-i586-poky-linux) are located in the Extensible Software Development Kit (eSDK) folder. It means that you cannot install the devtool command via the apt command.


## Cron Job to auto delete folder older than 15 days

For example, the description of crontab for deleting files older than 15 days
under the `/var/www/html/<your_prj_name>/ci/repo-workers/` every day at 5:30 AM is as follows.
mtime means the last modification timestamp and the results of find may not be
the expected files depending on the backup method. Note that too many inodes
results in "No space left on device" issue despite available storage spaces.

```bash
$ sudo vi /etc/crontab
30 5 * * * root find /var/www/html/<your_prj_name>/ci/repo-workers/ -maxdepth 2 -type d -mtime +15 -exec rm -rf {} \;
```

Please make sure before executing a rm command whether a target folder is correct or not. 
You can check the target folders by specifying **maxdepth** option as an argument of find command.

```bash
$ find /var/www/html/<your_prj_name>/ci/repo-workers/ -maxdepth 2 -type d -mtime +15
```

## How to speed-up a build time

we recommend that you enable a temporary filesystem (tmpfs) to improve build time and
avoid a situation that the number of inodes exceeds that of maximum inodes.
To monitor # of free inodes, run `$ sudo tune2fs -l /dev/sdax | grep Free` command.
For more details about tmpfs, please refer to https://www.kernel.org/doc/Documentation/filesystems/tmpfs.txt

```bash
$ sudo mount -t tmpfs -o size=5G tmpfs  /tmp
OR
$ sudo vi /etc/fstab
# /tmp was on tempfs during running CI tasks
tmpfs      /tmp        tmpfs   defaults,size=5G    0       0
$
$ df | grep tmpfs
tmpfs            5242880      2520   5240360   1% /tmp
```

## How to enable swap memory space to avoid OOM

In order to avoid OOM operations while running a build process, You may enable swap space with swapfile.
Note that it does not speed up the build time.

```bash
$ cd /data
$ sudo dd if=/dev/zero of=./swapfile-50gb bs=100M count=512
$ sudo mkswap ./swapfile-50gb
$ free
$ sudo swapon ./swapfile-50gb
$ free
```

## How to create a single PDF document from doxygen

First of all, you have to install latex packages to generate PDF file from latex as follows.

```bash
sudo apt install texlive-latex-base texlive-latex-extra
sudo apt install latex-xcolor
sudo apt install unoconv pdfunite  pdftk
sudo apt install libreoffice
```

Then, generate a single PDF file by running the below script in **Documentation** folder.

```bash
$ cd /var/www/html/<prj_name>/doc
$ ./book-hard-copy-prj-generate.sh
$ evince ./latex/book.pdf
```

Finally, let's generate automatically PDF book per 1 hour with cron table (e.g., /etc/crontab).

```bash
$ sudo vi /etc/crontab
# Generate doxygen document
20 * * * * www-data cd /var/www/html/<prj_name>/ ; git pull
30 * * * * www-data /var/www/html/<prj_name>/doc/book-hard-copy-prj-generate.sh
```

## How to use Scancode Toolkit

[ScanCode Toolkit](https://github.com/nexB/scancode-toolkit) is a set of code scanning tools to detect the origin and license of code and dependencies.
It uses a plug-in architecture to run a series of scan-related tools in one process flow.

```bash
sudo apt-get install python-dev bzip2 xz-utils zlib1g libxml2-dev libxslt1-dev
cd /opt
git clone https://github.com/nexB/scancode-toolkit.git
sudo chown -R www-data:www-data /opt/scancode-toolkit/
mkdir  /var/www/html/<prj_name>/scancode/
/opt/scancode-toolkit/scancode  --license /var/www/html/<prj_name>/  --html-app /var/www/html/<prj_name>/scancode/index.html
```
