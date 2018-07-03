
# Introduction
The Continuous Integration (CI) system is to prevent a regression and to find bugs due to incorrect PRs.
PRs causing regressions will not be automatically merged. We are going to report the issue at regression test procedure.

- Test automation (both build and run)
- Preventing performance regression
- Finding bugs at a proper time

<img src=https://github.sec.samsung.net/STAR/TAOS-CI/blob/tizen/screenshot01.png border=0 width=350 height=250></img>
<img src=https://github.sec.samsung.net/STAR/TAOS-CI/blob/tizen/screenshot02.png border=0 width=350 height=250></img>


## Goals	
**TAOS-CI** is re-designed and implemented with a light-weight approach based on the existing `AuDri CI` to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, It will be easily customizable for your github repository because it just requires Apache and PHP package.

TAOS-CI is to prevent regressions and bugs due to incorrect PRs as follows. As a mandatory process, PRs causing regressions will not be automatically merged.

* Test automation (both build and run)
* Preventing Performance regression
* Finding bugs at a proper time


## Maintainers
* Geunsik Lim (geunsik.lim@samsung.com)

## Committers	
* Jijoong Mon (jijoon.moon@samsung.com)
* MyungJoo Ham (myungjoo.ham@samsung.com)
* Sangjung Woo (sangjung.woo@samsung.com)
* Wook Song (wook16.song@samsung.com)
* Sewon Oh (sewon.oh@samsung.com) for nnstreamer
* ByoungOh Kim (byoungo.kim@samsung.com) for AuDri 
* Seungchul Oh (saint.oh@samsung.com) for on-device-api

# Overall flow
The below diagram shows an overall flow of CI system.
```bash
 | <----------------------------- Jenkins: Server Diagnosis ------------------------------> |
                   | <------------ TAOS-CI: Inspect & Verify ------------> | <---- CD ---->
                   |                                                       |
  +-----+     +----+     +-------+     +-----+     +--------+     +-------+     +---------+             
  |Issue| --> | PR | --> | Build | --> | Run | --> | Review | --> | Merged| --> | Release |
  +-----+     +----+     +-------+     +-----+     +--------+     +-------+     +---------+ 
     |          |           |             |             |             |             |
  (user)     (user)      (CIbot)          |(CIbot)   (reviewers)  (reviewers)       |-- SR(Submit Request)
                |           |         git blame            scancode --|             |  
                |           |-- Audit Modules                  Doxygen Book         |-- Pre-flight   
                |      Unit testing                                                 `Tizen PMB(Image)
                 `Format Modules                                                   
```

# Prepare CI Server
There are two alternatives to maintain your own CI server.
* Standalone CI server: Use ./standalone/ folder after installing Apache and PHP in case of a small & lightweight project.
  - If you want to run your own CI server firsthand, please read [Anministrator guide for standalone CI server](ci/standalone/ci-server/README.md)
* Jenkins CI server: Use ./jenkins/ folder after installing Jenkins software (https://jenkins.io/) in case of a large & scalable project.

CIbot is github webhook handle template for a github repository in order to control and maintain effectively issues and PRs that are submitted by lots of contributors.
The official ID is git.bot.sec@samsung.com. Note that administrator has to sign-in +3 times every month to avoid a situation that ID is closed by Samsung SDS.

### How to install standalone CI software
* Bash: sh-compatible command language interpreter that can be configured to be POSIX-conformant by default.
* PHP: a widely-used general-purpose scripting language can be embedded into HTML.
* Curl: tool to transfer data to a CI server using the supported protocol such as HTTP/HTTPS.

We assume that you are using Ubuntu 16.04 64bit distribution. You can easily install required packages with apt-get command.

```bash
$ sudo apt-get -y install bash php curl
$ sudo apt-get -y install apache2
$ sudo apt-get -y install php php-cgi libapache2-mod-php php-common php-pear php-mbstring
$ sudo systemctl restart apache2
```

### How to install Jenkins CI software
We assume that you are using Ubuntu 16.04 64bit distribution. You can easily install Jenkins package with apt-get command.

```bash
wget -q -O - http://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
sudo echo 'jenkins ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

sudo service jenkins stop 
sudo service jenkins start 
sudo service jenkins restart
chromium-browser http://localhost:8080/
```

# Self assessment: how to build a package
You have to execute ***gbs build*** command as a self-assessment before submitting your PR.
```bash
# in case of x86 64bit architecture
$ time gbs build -A x86_64  --clean --include-all
# in case of ARM 64bit architecture
$ time gbs build -A aarch64 --clean --include-all
```

# How to apply TAOS-CI into your project
```bash
$ cd /var/www/html/
$ git clone https://github.sec.samsung.net/STAR/<your_prj_name>.git
$ cd <your_prj_name>
$ git submodule add https://github.sec.samsung.net/STAR/TAOS-CI.git
$ ln -s ./TAOS-CI/ci ./ci
$ vi ./ci/standalone/config/config-environment.sh
  (You have to modify configuration variables appropriately.)
```
That's all. Enjoy TAOS-CI after setting-up webhook API.

# How to use a webhook API

```bash
$ chromium-browser https://github.sec.samsung.net/STAR/AuDri/settings
```

Press `Hooks` menu - Press `Add webhook` button - 
```bash
* Webhooks/ Add webhook
  - Payload URL:
    http://<your_hostname>.mooo.com/<prj_name>/ci/standalone/cibot.taos
  - Content type: application/x-www-form-urlencoded
  - Secret: ******
  - Which events would you like to trigger this webhook?
    [ ] Just the push event.
    [ ] Send me everything.
    [x] Let me select individual events.
      [v] Issues
      [v] Issue comment
      [v] Pull request
  - [v] Active
We will deliver event details when this hook is triggered. 
```

As a final step, press `Add webhook` button. That's all. From now on, enjoy CI world for more collaborative and productive software development!!!

# How to use new CI module
### How to develop new module
Please append new CI module in `./plugins-{good|ugly}` folder to customize TAOS-CI for your repository. We recommend that you use two APIs such as `cibot_comment()` and `cibot_pr_report()` in case that you have to send a webhook message to github.sec.samsung.net.
   - plugins-base: it is a well-maintained collection of CI plugins. A wide rang of Tizen (gbs) and Ubuntu (pdebuild) are included.
   - plugins-good: it is a set of plug-ins that we consider to have good quality code, correct functionality, our preferred license (Apache for the plug-in code).
   - plugins-ugly: it is a set of plug-ins that are not up to par compared to the rest. They might be close to being good quality, but they are missing something - be it a good code review, some documentation, a set of tests, or aging test.

### How to attach new module
First, open `./config/config-plugins-{format|audit}.sh`. Then, append a function name of a module that you want to attach newly. If you are poor at CI module, we recommend that you refer to the existing examples.
