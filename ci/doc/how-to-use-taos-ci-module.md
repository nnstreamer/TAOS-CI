
## How to develop new module
Please implement a module in `./plugins-{base|good|staging}` folder if you need to develop new CI module for your own project. We recommend that you use two APIs such as `cibot_comment()` and `cibot_report()` in case that you have to send a webhook message to a GitHub website. You can easily develop new CI module by referencing the existing CI modules because we follow up the Wiki philosophy.
   - `plugins-base`: it is a well-maintained collection of CI plugins. A wide rang of Tizen (gbs) and Ubuntu (pdebuild) are included.
   - `plugins-good`: it is a set of plug-ins that we consider to have good quality code, correct functionality, our preferred license (Apache for the plug-in code).
   - `plugins-staging`: it is a set of plug-ins that are not up to par compared to the rest. They might be close to being good quality, but they are missing something - be it a good code review, some documentation, a set of tests, or aging test.


## How to enable new module
First, open `./config/config-plugins-{format|audit}.sh`. Then, append a function name of a module that you want to attach newly. If you are poor at CI module, we recommend that you refer to the existing examples.


## Requirement before submitting a pull request
First of all, **Note** that you have to run the below statement in order to check the grammar error of a CI module that your write.
```bash
$ bash ./pr-{type}-{module-name}.sh
```

When you submit a pull request to merge your CI module to TAOS-CI repository, Please note that reviewers check 4 requirements as follows before merging your pull request.
* Maintenance: The module has to be normally executed as a CI component after enabling the module via a configuration file.
* Readability: Most of the developer should be able to read source code of the CI module without difficulty.
* Execution time: The time required to execute the module should not be long.
* Compatibility: The module should be able to run on most Linux distributions as well as Ubuntu.
Interesting.
