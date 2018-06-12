# How to Install Packages from the SPIN/TRBS Infrastructure

## SPIN-related Addresses

You need firewall access (use IT4U) to 10.113.136.204, 10.113.136.201, 10.113.136.32 of Seoul-RnD.

- [SPIN Main](http://10.113.136.204/)
- [SPIN-TRBS OBS Service](http://10.113.136.201/)
- [SPIN-TRBS OBS Build Mgt. / Tizen:5.0:AutoDriving](http://10.113.136.201/project/show/Tizen:5.0:AutoDriving)
- [SPIN-TRBS OBS Build Mgt. / Tizen:5.0:AutoDriving Ubuntu Tools](http://10.113.136.201/project/show/Tizen:5.0:AutoDriving:UbuntuTools)
- [RPM-repo / Build Results of Tizen:5.0:AutoDriving](http://10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving/standard/): Need Spin Account
- [DEB-repo / Build Results of Tizen:5.0:AutoDriving Ubuntu 16.04 Tools](http://10.113.136.32/download_trbs/newlive/Tizen:/5.0:/AutoDriving:/UbuntuTools/Ubuntu16.04/)
- [Account Creation Process (confluence page)](http://suprem.sec.samsung.net/confluence/display/NEWCOMM/Account)

## Manual Download from RPM/DEB-repo

```
$ wget http://SPINID:SPINPASSWORD@rest_of_url.rpm

$ # RPM install (in Tizen machine)
$ # in Ubuntu, use RPM install at your own risk; it works in many cases though.

# rpm -U filename.rpm # in Tizen/root
OR
$ sudo rpm -U filename.rpm # in Ubuntu/user

$ # DEB install (in Ubuntu machine)
$ sudo dpkg -i filename.deb
```

## Use Zypper in Tizen-AutoDriving System

- Zypper setup for Tizen-AutoDriving is automatically done if your image has "autodriving_repository" package.
- Images created with [AutoDriving Platform Tool](https://github.sec.samsung.net/RS7-AutoDriving/AutoDriving_Platform) has it.

### Install a new package from the infrastructure (RPM repo)

```
# zypper install algo_application_new_whatever
```
Then, zypper will install the most recent version of algo_application_new_whatever along with everything it requires!
