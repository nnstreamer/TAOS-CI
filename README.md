
# Introduction
TAOS-CI is an automated project coordinator to prevent a regression, find bugs, and reduce a nonproductive review process because of incorrect PRs in github.com. Actually, Submitting the incorrect PRs is a PITA in case of continuous integration. Basically, PRs causing regressions will not be automatically merged. As a result of that, it will reduce the burdens of reviewers.

- Minimize a nonproductive review process
- Provide a test automation (both build and run)
- Prevent a performance regression
- Find bugs at a proper time before merging buggy codes
- Generate a doxygen-based developer manual
- Support modulable facilities with plug-in interface
- Integrate the existing opensource tools easily
- Verify an integrity of a package by supporting a platform build
- Support multiple operating system as following:
  - Ubuntu: https://www.ubuntu.com/
  - Tizen: https://www.tizen.org/
  - Yocto: https://www.yoctoproject.org/
  - TBD & TBI

<img src=https://github.com/nnsuite/TAOS-CI/blob/tizen/screenshot01.png border=0 width=350 height=250></img>
<img src=https://github.com/nnsuite/TAOS-CI/blob/tizen/screenshot02.png border=0 width=350 height=250></img>


## Goals	
It is designed and implemented with a light-weight system approach to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, It will be easily customizable for your github repository because it just requires APACHE, PHP, and BASH package. Especially, we are mainly concentrating on the three goals as follows among a lot of action items.

* Test automation (both build and run)
* Preventing Performance regression
* Finding potential bugs at a proper time


## Maintainers
* Geunsik Lim (geunsik.lim@samsung.com)

## Committers	
* Jijoong Mon (jijoon.moon@samsung.com)
* MyungJoo Ham (myungjoo.ham@samsung.com)
* Sangjung Woo (sangjung.woo@samsung.com)
* Wook Song (wook16.song@samsung.com)
* Sewon Oh (sewon.oh@samsung.com) for nnstreamer
* ByoungOh Kim (byoungo.kim@samsung.com) for another repository
* Seungchul Oh (saint.oh@samsung.com) for another repository

# Overall flow
The below diagram shows an overall flow of CI system.
```bash
 | <----------------------------- Jenkins: Server Diagnosis ------------------------------> |
                   | <------------ TAOS-CI: Inspect & Verify ------------> | <---- CD ---->
                   |        /------ Tizen, Ubuntu, and SMP(TODO)           |
  +-----+     +----+     +--|----+     +-----+     +--------+     +-------+     +---------+             
  |Issue| --> | PR | --> | Build | --> | Run | --> | Review | --> | Merge | --> | Release |
  +-----+     +----+     +-------+     +-----+     +--------+     +-------+     +---------+ 
     |          |           |             |             |             |             |
  (user)     (user)      (CIbot)          |(CIbot)   (reviewers)  (reviewers)       |-- SR(Submit Request)
                |           |         Git Blame            Scancode --|             |  
                |           |-- Audit Modules                  Doxygen Book         |-- Pre-flight   
                |      Unit testing                                                 `Tizen PMB(Image)
                 `Format Modules                                                   
```

# How to install
Please refer to [How to install TAOS-CI](ci/doc/how-to-install-taos-ci.md).

# How to use new CI module
Please refer to [How to use new CI module](ci/doc/how-to-use-taos-ci-module.md).

# Self assessment before submitting PR
Please refer to [How to build a package](ci/doc/self-assessment-before-submitting-pr.md).

# Terminology
* CI: Continuous Integration
* CD: Continuous Deployment
* PR: Pull Request
* TBD: To Be Defined
* TBI: To Be Implemented

# Reference
* https://developer.github.com/webhooks/
* https://gogs.io/
* https://curl.haxx.se/docs/ 
