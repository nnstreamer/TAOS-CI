
# Introduction
This project is to prevent a regression, find bugs, and reduce inefficient review process due to incorrect PRs.
PRs causing regressions will not be automatically merged. We are going to report the issue at regression test procedure.

- Test automation (both build and run)
- Preventing performance regression
- Finding bugs at a proper time

<img src=https://github.com/nnsuite/TAOS-CI/blob/tizen/screenshot01.png border=0 width=350 height=250></img>
<img src=https://github.com/nnsuite/TAOS-CI/blob/tizen/screenshot02.png border=0 width=350 height=250></img>


## Goals	
This project is re-designed and re-implemented with a light-weight approach based on the existing `AuDri CI` to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, It will be easily customizable for your github repository because it just requires Apache and PHP package.

It is to prevent regressions and bugs due to incorrect PRs as follows. As a mandatory process, PRs causing regressions will not be automatically merged.

* Test automation (both build and run)
* Preventing Performance regression
* Finding bugs at a proper time


## Maintainers
* Geunsik Lim (geunsik.lim@samsung.com)

## Committers	
* Jijoong Mon (jijoon.moon@samsung.com)
* MyungJoo Ham (myungjoo.ham@samsung.com)
* Sangjung Woo (sangjung.woo@samsung.com)
* Wook Song (wook16.song@samsung.com)
* Sewon Oh (sewon.oh@samsung.com) for nnstreamer
* ByoungOh Kim (byoungo.kim@samsung.com) for AuDri 
* Seungchul Oh (saint.oh@samsung.com) for on-device-api

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
