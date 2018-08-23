
There are two alternatives to maintain your own CI server. In this section, We depict in detail how to set-up Standalone CI server.
* Standalone CI server: Use ./standalone/ folder after installing Apache and PHP in case of a small & lightweight project.
  - For more details, please read [Anministrator guide for standalone CI server](../../ci/standalone/ci-server/README.md)
* Jenkins CI server (Optional): Use script files of ./jenkins/ folder after installing Jenkins software (https://jenkins.io/) in case that your team develop a large & scalable project.

The CI bot works as a github webhook handle template for a github repository in order to control and maintain effectively issues and PRs that are submitted by lots of contributors.

# Step1: Install CI software
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

### How to install Jenkins CI software (Optional)
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

# Step2: How to apply TAOS-CI into your project
```bash
$ cd /var/www/html/
$ git clone https://github.com/<your_account>/<your_prj_name>.git
$ cd <your_prj_name>
$ git submodule add https://github.com/<your_account/TAOS-CI.git
$ ln -s ./TAOS-CI/ci ./ci
$ vi ./ci/standalone/config/config-environment.sh
  (You have to modify configuration variables appropriately.)
```
That's all. Enjoy TAOS-CI after setting-up webhook API.

# Step3: How to use a webhook API

```bash
$ chromium-browser https://github.com/<your_account>/<your_prj_name>/settings
```

Press `Hooks` menu - Press `Add webhook` button - 
```bash
* Webhooks/ Add webhook
  - Payload URL:
    http://<your_hostname>.mooo.com/<your_prj_name>/ci/standalone/webhook.php
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
