# Administrator guide for TAOS-CI server

We assume that you already installed Ubuntu 16.04 x86_64 distribution in your own computer.
First of all, let's enable www-data as a system account for debugging and setting-up the TAOS-CI solution.
Please replace "/bin/no-login" with "/bin/bash".
Note that you must restore "/bin/no-login" to avoid an unexpected security issue after doing all setup procedures.

```bash
$ sudo su 
# vi /etc/passwd
www-data:x:33:33:www-data:/var/www/html:/bin/bash
# cd /var/www/html
# chown -R www-data:www-data /var/www/html
# cp /root/.bashrc /var/www/html
# chown -R www-data:www-data  /var/www/html.bashrc
# exit
$
```

## Prerequisites
* For a physical machine, http://mirror.kakao.com/ubuntu-releases/xenial/
* For a virtual machine, https://www.osboxes.org/ubuntu/
* For a docker image, https://hub.docker.com/_/ubuntu/

```
$ cat /etc/os-release |grep VERSION_ID
VERSION_ID="16.04.3"
```
In order to run all modules of TAOS-CI normally, you have to install required packages as a first step.
Please run **install-packages-base.sh** that is located in the [ci/taos/webapp](../taos/webapp/) folder.
```bash
$ cd TAOS-CI
$ sudo ./ci/taos/webapp/install-packages-base.sh
```

## Allowing www-data to do a sudo privilege

You have to update `/etc/sudoers` to give `www-data` user sudo access with **NOPASSWD**  in order to run "git clone" command normally
in Apache/PHP environment as following:

```bash
$ sudo visudo
# User privilege specification for development step
www-data    ALL=(ALL) NOPASSWD:ALL
or
# User privilege specification for robust security
www-data    ALL=(ALL) NOPASSWD: /usr/bin/git , NOPASSWD: /usr/bin/mount
```

If you want to push your commits without a password input procedure, please create `~/.netrc` file as follows.
```bash
$ su - www-data
$ pwd
/var/www/html
$ vi /var/www/html/.netrc
machine github.com
        login {your_gihub_id}
        password {your_token_key_bdff5c7120a4544}
```

## Ubuntu/pdebuild: Set-up configuration file
The pbuilderrc file contains default values used in the pbuilder program invocation.
When pbuilder is invoked by www-data (user id of Apache webserver), `/etc/pbuilderrc` and `${HOME}/.pbuilderrc` are read.
* 1) /etc/pbuilderrc (by default): The configuration file for pbuilder, used in pdebuild.
* 2) /usr/share/pbuilder/pbuilderrc: The default configuration file for pbuilder, used in pdebuild.
* 3) ${HOME}/.pbuilderrc: Configuration file for pbuilder, used in pdebuild.  It overrides /etc/pbuilderrc

It is useful to use `--configfile` option to load up a preset configuration file when switching between configuration files for different distributions.
The file itself is sourced by a shell script, so it is required that the file conforms to shell script conventions.
For more details, refer to http://manpages.ubuntu.com/manpages/trusty/man5/pbuilderrc.5.html
```bash
$ vi /etc/pbuilderrc
# If you want to see more details, please run 'man 5 pbuilderrc' command.
DISTRIBUTION=xenial
OTHERMIRROR="deb http://archive.ubuntu.com/ubuntu xenial universe multiverse |deb [trusted=yes] http://[id]:[password]@[your-own-server]/tools/ubuntu16.04/ /"
$
$ chown -R www-data:www-data /var/cache/pbuilder
$
$ sudo vi /etc/crontab
## Update a base Ubuntu image (e.g., /var/cache/pbuilder/base.tgz) of pdebuild/pbuilder to keep latest apt repositories.
30 7 * * * root pbuilder update --override-config
```
**(Optional)**: How to suppress a storage usage of /var/cache/pbuilder folder
If /var/cache/pbuilder increases a storage usage, we recommend that you try to use a symbolic link.
For example, ```$ sudo ln -s /=/pbuilder /var/cache/pbuilder.```

**(Optional)**: How to use a tmpfs filesystem to spee-up an execution time of pbuilder
If you have lots of RAM (more than 4 GB) putting the pbuilder 'build' chroot on tmpfs will speed it up immensely.
So, add the below statement to `/etc/fstab`. It should be all on one line starting with 'tmpfs' and ending with the second zero.
```bash
$ sudo vi /etc/fstab
tmpfs   /var/cache/pbuilder/build       tmpfs   defaults,size=2400M 0 0
$ sudo mount /var/cache/pbuilder/build
```

## Tizen/gbs: Set-up configuration file

You have to write `~/.gbs.conf` in order that `www-data` id build a package with `gbs build` command.
We assume that you are using your id as a default id of a repository webserver.

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
user = {your-tizen-id}
passwd = {your-password}
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
url = http://<your_id>:<your_pass>@<your_team_server>/download/latest/repos/standard/packages/
```

## Yocto/devtool: Set-up configuration file

In case of Yocto, you can build a package with OpenEmbedded/devtool to verify a build validation on YOCTO platform
For more details, please refer to https://wiki.yoctoproject.org/wiki/Application_Development_with_Extensible_SDK
```bash
$ sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib
$ sudo apt-get -y install build-essential chrpath socat libsdl1.2-dev xterm
```
Note that a devtool command are the configuration file (e.g.,environment-setup-i586-poky-linux) are located in the Extensible Software Development Kit (eSDK) folder. It means that you cannot install the devtool command via the apt command.


## Cron Job to auto delete folder older than 6 days

For example, the description of crontab for deleting files older than 6 days
under the `/var/www/html/<your_prj_name>/ci/repo-workers/pr-checker/*` every day at 5:30 AM is as follows.
mtime means the last modification timestamp and the results of find may not be
the expected files depending on the backup method. Note that too many inodes
results in "No space left on device" issue despite available storage spaces.

```bash
$ sudo vi /etc/crontab
30 5 * * * root find /var/www/html/{your_prj_name}/ci/repo-workers/pr-checker/* -maxdepth 2 -type d -mtime +6 -exec rm -rf {} \;
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

## How to enable SWAP to avoid Out-of-Memory

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

## How to generate HTML/PDF with doxygen

First of all, you have to install latex packages to generate PDF file from latex as follows.

```bash
sudo apt install doxygen
sudo apt install texlive-latex-base texlive-latex-extra
sudo apt install latex-xcolor
sudo apt install unoconv pdfunite  pdftk
sudo apt install libreoffice
```

Then, generate a single PDF file by running the below script in **Documentation** folder.

```bash
$ cd /var/www/html/{your_prj_name}/ci/doxybook/
$ ./book-doxygen-publish.sh
$ evince ./latex/book.pdf
```

Finally, let's generate automatically PDF book per 1 hour with cron table (e.g., /etc/crontab).

```bash
$ sudo vi /etc/crontab
# Generate doxygen document
20 * * * * www-data cd /var/www/html/{your_prj_name}/ ; git pull
30 * * * * www-data /var/www/html/{your_prj_name}/ci/doxybook/book-doxygen-publish.sh
```
* Note that you do not have to run `book-doxygen-publish.sh` file at the same time because the LibreOffice commands can not be executed simultaneously.

## How to inspect license issue with Scancode Toolkit

[ScanCode Toolkit](https://github.com/nexB/scancode-toolkit) is a set of code scanning tools to detect the origin and license of code and dependencies.
It uses a plug-in architecture to run a series of scan-related tools in one process flow.

```bash
sudo apt-get install python-dev bzip2 xz-utils zlib1g libxml2-dev libxslt1-dev
cd /opt
git clone https://github.com/nexB/scancode-toolkit.git
sudo chown -R www-data:www-data /opt/scancode-toolkit/
mkdir  /var/www/html/{your_prj_name}/scancode/
/opt/scancode-toolkit/scancode  --license /var/www/html/{your_prj_name}/{src_folder}  --html-app /var/www/html/{your_prj_name}/scancode/index.html
```

## How to set-up a domain name address
If you want to use your own domain name address instead of IP address for effective maintenance, we recommend that you try to get a host name free of charge at https://freedns.afraid.org.

```bash
$ sudo vi /etc/apache2/sites-enabled/000-default.conf 
<VirtualHost *:80>
        # You can get five host names such as {your_host}.mooo.com free of charge at http://freedns.afraid.org.
        ServerName {your_host}.mooo.com
        ServerAdmin webmaster@localhost
        DocumentRoot /home/taos-ci/public_html
        # Alias /nnstreamer-link /home/taos-ci/public_html/{your_github_repo_name}/ci/taos
        ErrorLog ${APACHE_LOG_DIR}/error.{your_github_repo_name}.log
        CustomLog ${APACHE_LOG_DIR}/access.{your_github_repo_name}.log combined
</VirtualHost>
$ sudo systemctl restart apache2
```



## How to enable .htaccess to protect password files from web access
Open the default Apache configuration file to enable .htaccess file to protect configuration files that include passwords. Then, restart Apache webserver to put these changes into effect.

```bash
$ sudo vim /etc/apache2/apache2.conf
------------- apache2.conf: start ----------------------------
# First,
AccessFileName .htaccess # <--- Remove comment.

# Second,
<Directory /var/www/>
     Options Indexes FollowSymLinks
     AllowOverride None # <--- Replace "None" with "All".
     Require all granted
</Directory>
------------- apache2.conf: end   ----------------------------
$ sudo a2enmod rewrite
$ sudo /etc/init.d/apache2 restart
```

An .htaccess file allows us to modify rewrite rules without accessing server configuration files. 
For this reason, .htaccess is critical to the security of your web application. 

```bash
$ cd   /var/www/html/{your_prj_name}/TAOS-CI/ci/taos/config/
$ cat ./.htaccess
------------- .htaccess: start ----------------------------
AuthName "Restricted area"
AuthType Basic
AuthUserFile /var/www/html/{your_prj_name}/TAOS-CI/ci/taos/config/.htpasswd
<Limit GET POST>
require valid-user
</Limit>
------------- .htaccess: end   ----------------------------
$ touch .htpasswd
$ htpasswd -n {user_id} > .htpasswd
New password: *****
Re-type new password: *****
$ cat .htpasswd
```



