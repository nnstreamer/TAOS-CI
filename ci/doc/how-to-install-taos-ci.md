---
title: How to install taos-ci
...

# Step 1: Set-up the CI server
We explain how to set-up your own CI server on Ubuntu 16.04 x86_64 (Recommended) even though TAOS-CI is completely compatible with most of the Linux distributions. Please refer to a set-up guide of a CI server to install required packages.
* [Setting up a CI server](ci/doc/how-to-setup-taos-ci-server.md) 


# Step 2: How to install TAOS-CI system
* PHP: a widely-used general-purpose scripting language can be embedded into HTML.
* Bash: sh-compatible command language interpreter that can be configured to be POSIX-conformant by default.
* Curl: tool to transfer data to a CI server using the supported protocol such as HTTP/HTTPS.

Then, please press 'Watch', 'Star', and 'Fork' on the top right to monitor latest feature changes of TAOS-CI repository. Next, please modify the configuration files for your CI server.

```bash
$ cd /var/www/html/
$ git clone https://github.com/{your_github_account}/{your_prj_name}.git
$ cd {your_prj_name}
$ git submodule add https://github.com/nnstreamer/TAOS-CI.git
$ ln -s ./TAOS-CI/ci ./ci
$ vi ./ci/taos/config/config-server-administrator.sh
$ vi ./ci/taos/config/config-webhook.json
$ vi ./ci/taos/config/config-environment.sh
$ vi ./ci/taos/config/config-plugins-prebuild.sh
$ vi ./ci/taos/config/config-plugins-postbuild.sh
```
That's all. Enjoy TAOS-CI after setting-up a webhook API of github.

# Step 3: How to set-up with a GitHub webhook API
A webhook handler of TAOS-CI receives an event message from a github repository, in order to inspect pull requests that are submitted by contributors.
```bash
$ firefox https://github.com/{your_github_account}/{your_prj_name}/settings
```

Press the **Hooks** menu - Press the **Add webhook** button. Note that you have to ask a firewall manager to get a network access such as 80 and 443 port between your own CI server and a github server if your company is running a firewall system.
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
