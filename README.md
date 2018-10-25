[![GitHub license](https://dmlc.github.io/img/apache2.svg)](./LICENSE)

[Build Status](http://invain.mooo.com/TAOS-CI/ci/taos/) |
[Documentation](ci/doc/doxygen-documentation.md) |
[Contributing](ci/doc/contributing.md) |
[Chat Room](https://gitter.im/login) |
[Release Notes](https://github.com/nnsuite/TAOS-CI/wiki/Release-Plan)


# Introduction
TAOS-CI is an automated project coordinator to achieve "**Review less, merge faster**" with a tool-based review system. It accelerates a software development based on the GitHub webhook API. We aim to prevent a regression, find bugs, and reduce a nonproductive review process because of incorrect PRs in https://github.com. Actually, Submitting the incorrect PRs is a PITA in case of continuous integration. Basically, PRs causing regressions will not be automatically merged. As a result of that, it drastically reduces the existing burdens of reviewers.
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
  - Tizen: https://www.tizen.org/
  - Yocto: https://www.yoctoproject.org/
  - TBD & TBI

<img src=./image/screenshot01.png border=0 width=350 height=250></img>
<img src=./image/screenshot03.png border=0 width=350 height=250></img>


## Goals	
It is designed and implemented with a light-weight system approach to support a desktop computer based servers that have out-of-date CPUs and low memory capacity. Also, if you want to enable your project specific CI facilities, It will be easily customizable for your github repository because it just requires APACHE, PHP, and BASH package. Especially, we are mainly concentrating on the three goals as follows among a lot of action items.

* Automating tests (both build and run)
* Preventing Performance regression
* Finding potential bugs at a proper time

## Maintenance
Please refer to [Here](./ci/doc/maintenance.md).

# Overall flow
The below diagram shows an overall flow of our system. The TAOS-CI system performs (1) the format checker (before the build) and (2) the audit checker (after the build) by separating an inspection procedure with two steps whenever contributors submit a Pull Request (PR).

* Geunsik Lim, MyungJoo Ham, Jijoong Moon, Wook Song, Sangjung Woo, and Sewon Oh, "**TAOS-CI: Lightweight & Modular Continuous Integration System for Edge Computing,**" 37th IEEE International Conference on Consumer Electronics (ICCE), Las Vegas, USA, Jan. 2019. (Accepted)

<img src=./image/architecture.png border=0 width=550 height=400></img>

# How to install
Please refer to [How to install TAOS-CI](ci/doc/how-to-install-taos-ci.md).

# How to use new CI module
Please refer to [How to use new CI module](ci/doc/how-to-use-taos-ci-module.md).
Current plugable facilities are as follows:
   - **Format** (before a build): File size, New line, No body, Signed-off, Clang-format, Doxygen, Timestamp, Hardcoded-path, Executable, RPM-spec, CPPcheck, Pylint, Indent, Resource checker, and so on.
   - **Audit** (after a build): Ubuntu builder, Tizen builder, Yocto builder, and Android (Coming Soon).

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
* https://developer.github.com/webhooks/
* https://gogs.io/
* https://curl.haxx.se/docs/ 
* Papers
   * [ICSE2018, "Modern code review: a case study at google"](https://dl.acm.org/citation.cfm?id=3183525)
   * [ICSE2015, "Do Not Find Bugs: how the Current Code Review Best Practice Slows Us Down"](https://dl.acm.org/citation.cfm?id=2819015)
   * [IFIPAICT, "The Impact of a Low Level of Agreement Among Reviewers in a Code Review Process"](https://link.springer.com/chapter/10.1007/978-3-319-39225-7_8)
