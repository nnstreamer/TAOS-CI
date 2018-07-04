
# Introduction
The Continuous Integration (CI) system is to prevent a regression and to find bugs due to incorrect PRs.
PRs causing regressions will not be automatically merged. We are going to report the issue at regression test procedure.

- Test automation (both build and run)
- Preventing performance regression
- Finding bugs at a proper time

<img src=https://github.sec.samsung.net/STAR/TAOS-CI/blob/tizen/screenshot01.png border=0 width=350 height=250></img>
<img src=https://github.sec.samsung.net/STAR/TAOS-CI/blob/tizen/screenshot02.png border=0 width=350 height=250></img>


## Goals	
**TAOS-CI** is re-designed and implemented with a light-weight approach based on the existing `AuDri CI` to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, It will be easily customizable for your github repository because it just requires Apache and PHP package.

TAOS-CI is to prevent regressions and bugs due to incorrect PRs as follows. As a mandatory process, PRs causing regressions will not be automatically merged.

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
                   |                                                       |
  +-----+     +----+     +-------+     +-----+     +--------+     +-------+     +---------+             
  |Issue| --> | PR | --> | Build | --> | Run | --> | Review | --> | Merged| --> | Release |
  +-----+     +----+     +-------+     +-----+     +--------+     +-------+     +---------+ 
     |          |           |             |             |             |             |
  (user)     (user)      (CIbot)          |(CIbot)   (reviewers)  (reviewers)       |-- SR(Submit Request)
                |           |         git blame            scancode --|             |  
                |           |-- Audit Modules                  Doxygen Book         |-- Pre-flight   
                |      Unit testing                                                 `Tizen PMB(Image)
                 `Format Modules                                                   
```

# How to install
Please refer to [How to install TAOS-CI](ci/doc/how-to-install-taos-ci.md).

# Self assessment: how to build TAOS-CI RPM package
You have to execute ***gbs build*** command as a self-assessment before submitting your PR.
```bash
# in case of x86 64bit architecture
$ time gbs build -A x86_64  --clean --include-all
# in case of ARM 64bit architecture
$ time gbs build -A aarch64 --clean --include-all
```

# How to use new CI module
Please refer to [How to use new CI module](ci/doc/how-to-use-taos-ci-module.md).
