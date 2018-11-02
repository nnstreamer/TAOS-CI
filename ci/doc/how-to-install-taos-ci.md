
# Step 1: Set-up CI server
We explain how to set-up your own CI server on Ubuntu 16.04 x86_64 (Recommended) even though TAOS-CI is completely compatible with most of the Linux distributions. Please refer to a set-up guide of a CI server to install required packages.
* [Setting up a CI server](./how-to-setup-taos-ci-server.md) 

# Step 2: Install base packages
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

# Step 3: How to install TAOS-CI system
```bash
$ cd /var/www/html/
$ git clone https://github.com/{your_github_account}/{your_prj_name}.git
$ cd {your_prj_name}
Then, please press 'Watch', 'Star', and 'Fork' on the top right to monitor feature changes of TAOS-CI repository.
$ git submodule add https://github.com/nnsuite/TAOS-CI.git
$ ln -s ./TAOS-CI/ci ./ci
$ vi ./ci/taos/config/config-server-administrator.sh
  : Please modify configuration variables for CI server.
$ vi ./ci/taos/config/config-webhook.json
  : Please modify configuration variables for a webhook handler.
$ vi ./ci/taos/config/config-environment.sh
  : Please modify configuration variables for CI modules.
```
That's all. Enjoy TAOS-CI after setting-up webhook API of github.

# Step 4: How to set-up github webhook API
A webhook handler of TAOS-CI receives an event message from a github repository, in order to inspect pull requests that are submitted by contributors.
```bash
$ firefox https://github.com/{your_github_account}/{your_prj_name}/settings
```

Press the `Hooks` menu - Press the `Add webhook` button. Note that you have to ask a firewall manager to get a network access such as 80 and 443 port between your own CI server and a github server if your company is running a firewall system.
```bash
* Webhooks/ Add webhook
  - Payload URL:
    http://{your_hostname}.mooo.com/{your_prj_name}/ci/taos/webhook.php
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
From now on, enjoy a CI world for more collaborative and productive software development!!!
