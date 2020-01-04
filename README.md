[![GitHub license](https://dmlc.github.io/img/apache2.svg)](./LICENSE) 
![Gitter](https://img.shields.io/gitter/room/nnsuite/TAOS-CI) ![GitHub repo size](https://img.shields.io/github/repo-size/nnsuite/TAOS-CI) ![GitHub issues](https://img.shields.io/github/issues/nnsuite/TAOS-CI) ![GitHub pull requests](https://img.shields.io/github/issues-pr/nnsuite/TAOS-CI) ![GitHub contributors](https://img.shields.io/github/contributors/nnsuite/TAOS-CI)

[Build Status](http://nnsuite.mooo.com/TAOS-CI/ci/taos/) |
[Documentation](ci/doc/doxygen-documentation.md) |
[Contributing](ci/doc/contributing.md) |
[Chat Room](https://gitter.im/login) |
[Release Notes](https://github.com/nnsuite/TAOS-CI/wiki/Release-Plan)


# Introduction

TAOS-CI is an automated project coordinator to achieve "**Review less, merge faster**" with a tool-based review system. It accelerates a software development based on the GitHub WebHook API. We aim to prevent a regression, find bugs, and reduce a nonproductive review process due to incorrect PRs in https://GitHub.com. Actually, submitting incorrect PRs is a PITA in case of continuous integration. Basically, PRs causing regressions will not be automatically merged. As a result, it drastically reduces the existing burdens of reviewers.
- Minimize a nonproductive review process
- Provide a test automation (both build and run)
- Prevent a performance regression
- Find bugs at a proper time before merging buggy codes
- Generate a doxygen-based developer manual
- Support modulable facilities with plug-in interface
- Integrate the existing opensource tools easily
- Verify an integrity of a package by supporting a platform build
- Support multiple operating systems as follows:
  - Ubuntu: https://www.ubuntu.com/
  - Tizen: https://source.tizen.org/
  - Yocto: https://www.yoctoproject.org/
  - Android: https://source.android.org
  - TBD & TBI

<img src=./image/screenshot01.png border=0 width=350 height=250></img>
<img src=./image/screenshot03.png border=0 width=350 height=250></img>


## Goals	
The proposed system supports a light-weight code review automation approach to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, it will be easily customizable for your GitHub repository because it just requires APACHE, PHP, and BASH packages. Especially, we are mainly concentrating on the following three goals among a number of action items.

* Automating tests (both build and run)
* Preventing Performance regression
* Finding potential bugs at a proper time

## Maintenance
Please refer [Here](./ci/doc/maintenance.md).

## Publications
* Geunsik Lim, MyungJoo Ham, Jijoong Moon, Wook Song, Sangjung Woo, and Sewon Oh, "**<a href='https://ieeexplore.ieee.org/document/8662017'>TAOS-CI: Lightweight & Modular Continuous Integration System for Edge Computing,</a>**" 37th IEEE International Conference on Consumer Electronics (ICCE), Las Vegas, USA, Jan. 2019.

* Geunsik Lim, MyungJoo Ham, and Jaeyun Jung, "**<a href='http://www.riss.kr/link?id=A106329692'>VTB: Cloud-based Testbed for On-Device AI,</a>**" Proc. of KIISE Korea Computer Congress, Jeju, Korea, Jun. 2019. Best Presentation Paper. (in Korean)

* Geunsik Lim, MyungJoo Ham, and Jaeyun Jung, "**VTS: Virtual Testbed System for Cloud-based On-Device AI Application,**" KIISE Transactions on Computing Practices : Computing Practices and Letter (CPL), Jan. 2020. Invited paper. (in Korean)

# How to install
Please refer to [How to install TAOS-CI](ci/doc/how-to-install-taos-ci.md).

# How to use new CI module
Please refer to [How to use new CI module](ci/doc/how-to-use-taos-ci-module.md).

Currently available facilities are as following:
   - **Prebuild Group** (before a build): File size, New line, No body, Signed-off, Clang-format, Doxygen, Timestamp, Hardcoded-path, Executable, RPM-spec, CPPcheck, Pylint, Indent, Resource checker, and so on.
   - **Postbuild Group** (after a build): Ubuntu builder, Tizen builder, Yocto builder, and Android (Coming Soon).

# Self assessment
Note that you have to execute a self assessment before submitting your PR.
Please refer to [How to build a package](ci/doc/self-assessment-before-submitting-pr.md).

# Terminology
* CI: Continuous Integration
* CD: Continuous Deployment
* PR: Pull Request
* TBD: To Be Defined
* TBI: To Be Implemented

# License
* [Apache License 2.0](LICENSE)

# Reference
* https://developer.github.com/WebHooks/
* https://gogs.io/
* https://curl.haxx.se/docs/ 
* Papers
   * [ICSE2018, "Modern code review: a case study at google"](https://dl.acm.org/citation.cfm?id=3183525)
   * [ICSE2015, "Do Not Find Bugs: how the Current Code Review Best Practice Slows Us Down"](https://dl.acm.org/citation.cfm?id=2819015)
   * [IFIPAICT, "The Impact of a Low Level of Agreement Among Reviewers in a Code Review Process"](https://link.springer.com/chapter/10.1007/978-3-319-39225-7_8)
   * [ASE2014, "Automated Unit Test Generation for Classes with Environment Dependencies"](https://dl.acm.org/citation.cfm?id=2642986)
   * [FSE2016, "Why We Refactor? Confessions of GitHub Contributors"](https://dl.acm.org/citation.cfm?id=2950305)
   * [FSE2016, "Factors Influencing Code Review Processes in Industry"](https://dl.acm.org/citation.cfm?id=2950323)

