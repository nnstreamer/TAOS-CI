
# What is Jenkins?
Jenkins is a self-contained, open source automation server which can be used to automate all sorts of tasks related to building, testing, and delivering or deploying software. 

# How to install packages for Jenkins
We assume that you are using Ubuntu 16.04 x86_64 distribution. You can easily install Jenkins package with apt-get command. Utilize script files of `./jenkins/` folder after installing Jenkins software (https://jenkins.io/) in case that your team develop a large & scalable project. For more details, please visit https://jenkins.io.

```bash
wget -q -O - http://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
sudo echo 'jenkins ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

sudo service jenkins stop 
sudo service jenkins start 
sudo service jenkins restart
```

# How to use Jenkins
For more details, please connect to https://jenkins.io/doc/.

```bash
firefox http://localhost:8080/
```
