
## How to develop new module
Please append that in `./plugins-{base|good|ugly}` folder if you need to develop new CI module for your project. We recommend that you use two APIs such as `cibot_comment()` and `cibot_pr_report()` in case that you have to send a webhook message to github.sec.samsung.net. You can easily develop new CI module by referencing the exsiting CI modules.
   - `plugins-base`: it is a well-maintained collection of CI plugins. A wide rang of Tizen (gbs) and Ubuntu (pdebuild) are included.
   - `plugins-good`: it is a set of plug-ins that we consider to have good quality code, correct functionality, our preferred license (Apache for the plug-in code).
   - `plugins-ugly`: it is a set of plug-ins that are not up to par compared to the rest. They might be close to being good quality, but they are missing something - be it a good code review, some documentation, a set of tests, or aging test.

## How to enable new module
First, open `./config/config-plugins-{format|audit}.sh`. Then, append a function name of a module that you want to attach newly. If you are poor at CI module, we recommend that you refer to the existing examples.
