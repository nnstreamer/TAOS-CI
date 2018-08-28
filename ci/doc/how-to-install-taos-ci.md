
# Step 1: Set-up CI server
We explain how to set-up your own CI server on Ubuntu 16.04 x86_64 (Recommended) even though TAOS-CI is completely compatible with most of the Linux distributions. Please refer to the [set-up guide of Standalone CI server](../../ci/taos/ci-server/README.md) page to install required packages.

# Step 2: Install CI software
### How to install base packages for TAOS-CI
* PHP: a widely-used general-purpose scripting language can be embedded into HTML.
* Bash: sh-compatible command language interpreter that can be configured to be POSIX-conformant by default.
* Curl: tool to transfer data to a CI server using the supported protocol such as HTTP/HTTPS.

You can easily install required packages with `apt-get` command as follows.

```bash
$ sudo apt-get -y install bash php curl
$ sudo apt-get -y install apache2
$ sudo apt-get -y install php php-cgi libapache2-mod-php php-common php-pear php-mbstring
$ sudo systemctl restart apache2
```

### How to install base packages for Jenkins (Optional)
It is optional. We assume that you are using Ubuntu 16.04 64bit distribution. You can easily install Jenkins package with apt-get command. Utilize script files of `./jenkins/` folder after installing Jenkins software (https://jenkins.io/) in case that your team develop a large & scalable project. For more details, please visit https://jenkins.io.

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

# Step 3: How to install TAOS-CI software
```bash
$ cd /var/www/html/
$ git clone https://github.com/<your_account>/<your_prj_name>.git <your_prj_name>.git
$ cd <your_prj_name>.git
$ git submodule add https://github.com/<your_account/TAOS-CI.git
$ ln -s ./TAOS-CI/ci ./ci
$ vi ./ci/taos/config/config-cibot.sh
  (Please modify configuration variables appropriately.)
$ vi ./ci/taos/config/config-environment.sh
  (Please modify configuration variables appropriately.)
```
That's all. Enjoy TAOS-CI after setting-up webhook API of github.

# Step 4: How to set-up github webhook API
A CI bot of TAOS-CI works as a github webhook handler of a github repository in order to inspect automatically issues and PRs that are submitted by lots of contributors.
```bash
$ chromium-browser https://github.com/<your_account>/<your_prj_name>/settings
```

Press `Hooks` menu - Press `Add webhook` button - 
```bash
* Webhooks/ Add webhook
  - Payload URL:
    http://<your_hostname>.mooo.com/<your_prj_name>/ci/taos/webhook.php
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

As a final step, press `Add webhook` button. That's all. 
From now on, enjoy CI world for more collaborative and productive software development!!!
