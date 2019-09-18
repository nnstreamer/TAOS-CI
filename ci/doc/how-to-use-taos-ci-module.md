
## How to develop a new module
Please implement a module in `./plugins-{base|good|staging}` folder if you need to develop new CI module for your own project.
You can easily develop new CI module by referencing the existing CI modules because we follow up the Wiki philosophy.
* `plugins-base`: it is a well-maintained collection of CI plugins. A wide rang of Tizen (gbs) and Ubuntu (pdebuild) are included.
* `plugins-good`: it is a set of plug-ins that we consider to have good quality code, correct functionality, our preferred license (Apache for the plug-in code).
* `plugins-staging`: it is a set of plug-ins that are not up to par compared to the rest. They might be close to being good quality, but they are missing something - be it a good code review, some documentation, a set of tests, or aging test.

## Public APIs for developing a new module
We recommend that you use two APIs such as `cibot_comment()` and `cibot_report()` in case that you have to send a webhook message to a GitHub website. Also, we provide the `goto_repodir()` to go to a git repository folder as a work folder.
* cibot_comment(): This API write a requested message into a webpage of issue number or PR number.
* cibot_report(): The API update the current status of the context of the module.
* goto_repodir(): This API is to change a folder location from a current directory to a git repository directory.
* check_dependency(): This API is to check if required commands are installed in the server.

## How to enable a new module
First, open `./config/config-plugins-{format|audit}.sh`. Then, append a function name of a module that you want to attach newly. If you are poor at CI module, we recommend that you refer to the existing examples.
```bash
$ vi ./config/config-plugins-{format|audit}.sh

format_plugins[++idx]="pr-format-{module_name}"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check a syntax error in a shell script file"
echo "[DEBUG] The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

```
Then, if you have to install a debian package additioanlly for a new module, Please modify the `install-package-base.sh` file. In this case, we assume that you have to install the `shellcheck` debian package.
```bash
$ cd TAOS-CI
$ sudo ./ci/taos/webapp/install-packages-base.sh

echo -e "\n\n\n########## for CI-system: Installing packages for shellcheck package"
sudo apt -y install shellcheck || func-pack-fail
```

## Requirement before contributing a new module
First of all, **Note** that you have to run the below statement in order to check the grammar error of a CI module that your write.
```bash
$ bash -n ./pr-{type}-{module-name}.sh
```

When you submit a pull request to merge your CI module to TAOS-CI repository, Please note that reviewers check 4 requirements as follows before merging your pull request.
* Maintenance: The module has to be normally executed as a CI component after enabling the module via a configuration file.
* Readability: Most of the developer should be able to read the source code of the new module.
* Execution time: The time required to execute the module should not be long.
* Compatibility: The module should be able to run on Ubuntu distribution by default.
