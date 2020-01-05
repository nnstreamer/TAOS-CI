
## shields.io
Shields.io provides quality metadata badges for open source projects.
They serve fast and scalable informational images as badges
for GitHub, Travis CI, Jenkins, WordPress and many more services.
* https://shields.io


## Case study: Generating a Coverity badge for the Coverity module
 
First of all, please look at the lines that include "badge_coverity.json" word in the "./plugins-good/pr-prebuild-coverity.sh" file (the Coverity module). The Coverity module is run when the developers submitted a PRs. At this time, the Coverity module execution is dependent on the passed time of the previous Coverity module (The default time is 12 hours.)  As an execution result of the script file, a JSON file (e.g., badge_coverity.json) is generated in "./ci/badge/" folder. The badge_coverity.json file includes the below contents for shield.

```bash
$ cat ./badge/badge_coverity.json 
{
    "schemaVersion": 1,
    "label": "coverity",
    "message": "3 defects",
    "color": "brightgreen",
    "style": "flat"
}
```

Then, append the below statement in a README.md.
```bash
<a href="https://scan.coverity.com/projects/nnsuite-nnstreamer">
<img alt="Coverity Scan Defect Status" src="https://img.shields.io/endpoint?url=https://nnsuite.mooo.com/nnstreamer/ci/badge/badge_coverity.json" />
</a> 
```
From now on, you can see the Coverity badge icon at the README.md file.
