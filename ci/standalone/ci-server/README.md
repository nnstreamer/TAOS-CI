# Administrator guide for standalone CI server

## Configuration of current CI server

- Server address: http://localhost/
- Ubuntu 16.04

```
$ cat /etc/os-release |grep VERSION_ID
VERSION_ID="16.04.3"
```

## Install prerequisites

```bash
$ sudo apt-get install sed, ps, cat, aha, git, which grep, touch, find, wca, cppcheck
$ sudo vi /etc/apt/sources.list.d/tizen.list
  deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ / # upgraded to xenial
$ sudo apt-get update
$ sudo apt-get install mic gbs
```

## Install Apache+PHP for CI Server

NPUT Compiler's CI server is equipped with Apache and PHP script language to run lightwegith automation server
instead of Jenkins. Builds has been triggered by last commit number by scheduling a Pull Request (PR) with NPU bot, that is based on Webhooks API and JASON format.

**for Ubuntu 16.04**

```bash
$ sudo apt-get update
$ sudo apt-get install apache2
$ sudo apt-get install php php-cgi libapache2-mod-php php-common php-pear php-mbstring
$ sudo a2enconf php7.0-cgi
$ sudo vi /etc/apache2/conf-enabled/php7.0-cgi.conf
  <FilesMatch ".+\.taos$">
     SetHandler application/x-httpd-php
  </FilesMatch>
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

Then, let's enable www-data as system account.

```bash
$ su -
# vi /etc/passwd
www-data:x:33:33:www-data:/var/www:/bin/bash
# cd /var/
# chown -R www-data:www-data /var/www/
# cp /root/.bashrc /var/www/
# chwon www-data:www-data  /var/www/.bashrc
# su - www-data
$ vi ~/.netrc
machine github.sec.samsung.net
        login git.bot.sec
        password bdd8f27d1e718f878ff5c7120a45440ff63fxxxx
machine 10.113.136.32
        login git.bot.sec
        password npuxxxx
```

## Setting gbs configuration file

You have to write `~/.gbs.conf` in order that `www-data` id can build a pakcage with **gbs build** command.
We assume that you are using `git.bot.sec` samsung id as a default id of a repository webserver.

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
user = git.bot.sec
passwd = npuxxxx
obs = obs.tizen

repos = repo.autodrv, repo.unified, repo.base
buildroot = ~/GBS-ROOT-5.0/

[obs.tizen]
#OBS API URL pointing to a remote OBS.
url = https://api.tizen.org

# in case that one of the Tizen rpm repositories is broken, specify stable version as follows instead of "latest".
# https://github.com/01org/gbs/blob/master/docs/GBS.rst#34-shell-style-variable-references
# ver_base=tizen-base_20180427.1
# ver_unified=tizen-unified_20180504.2
# ver_autodrv=tizen-5.0-taos_20180504.2

[repo.base]
url = http://git.bot.sec:npuxxxx@165.213.149.200/download/public_mirror/tizen/base/latest/repos/standard/packages/

[repo.unified]
url = http://git.bot.sec:npuxxxx@165.213.149.200/download/public_mirror/tizen/unified/latest/repos/standard/packages/

[repo.autodrv]
url = http://git.bot.sec:npuxxxx@165.213.149.200/download/snapshots/tizen/5.0-taos/latest/repos/standard/packages/
```

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

Please make sure before executing rm whether targets are intended files.
You can check the target folders by specifying **maxdepth** option as the argument of find.

```bash
$ find /var/www/html/<your_prj_name>/ci/repo-workers/ -maxdepth 2 -type d -mtime +15
```

## How to speed up build time

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
