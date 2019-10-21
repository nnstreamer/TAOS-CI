#!/usr/bin/env bash

# Do not append a license statement in the configuration file
# for a differnet license-based repository.

##
# @file     config-environment.sh
# @brief    The configuration file to maintain all scripts
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#
# This script is to maintain consistently all scripts files.
#
# If you have to run this CI script at the below environment, Please change
# the contents appropriately.
# a. In case that you want to apply this CI script to another repository
# b. In case that you have to install CI in a new CI server for more high-performance
# c. In case that you need to create new project
#

################# Modify the below statements for your server  #######################


#### Repository setting

# Add TOKEN ID to access your GitHub repository using WebHook APIs
# Refer to https://github.com/settings/tokens
# WARNING: Do NOT OPEN THE TOKEN ID TO AVOID A SECURITY FLAW.
TOKEN="0000000000111111111122222222223333333333xx"

# Write an account name (or organization name) of the '{master|upstream}' branch
# e.g., https://github-website/{account_name}/{project_name}/
GITHUB_ACCOUNT="nnsuite"

# Write a project name of a github website of the '{master|upstream}' branch
# e.g., https://github-website/{account_name}/{project_name}/
PRJ_REPO_UPSTREAM="TAOS-CI"

# Specify the web address of the CI server. Should end with /
CISERVER="http://<YOUR_CI_DNS>.mooo.com/"

# Prebuild group area (pr-prebuild) to inventigate source code
# Add root path of source folders. For example, specify a path of source code:
# 1) to check prohibited hardcoded paths (e.g., /home/* for now)
# 2) to check code formatting sytele with clang-format
SRC_PATH="./ci/"

# Skip Paths: prebuild group (pr-prebuild)
# declare a folder name to skip the file size and newline inspection.
# (e.g., <github-repository-name>/temproal-bin/)
SKIP_CI_PATHS_FORMAT="temporal-bin"

# Skip Paths: postbuild group (pr-postbuild)
# Skip build-checker / unit-test checker if all changes are limited to:
# The path starts without / and it denotes the full paths in the git repo. (regex)
SKIP_CI_PATHS_AUDIT="^ci/.*|^Documentation/.*|^\.github/.*|^obsolete/.*|^README\.md|^external/.*|^temporal-bin/.*"

# Define the number of CPUs to build source codes in parallel
# We recommend that you define appropriate # of CPUs that does not result in
# Out-Of-Memory and Too mnay task migration among the CPUs.
CPU_NUM=3

#### Automatic PR commenter: enabling(1), disabling(0)

# Inform a PR submitter of a rule to pass the CI process
pr_comment_notice=1

# Inform all developers of their activity whenever PR submitter resubmit their PR after applying comments of reviews
pr_comment_pr_updated=0

# Inform a PR submitter that they do not have to merge their own PR directly.
pr_comment_self_merge=0

# infrom a PR submitter of how to submit a PR that include lots of commits.
pr_comment_many_commit=0

# Inform a PR submitter of the webpage address in order that they can monitor the current status of their PR.
pr_comment_pr_monitor=0

#### Build test: Write a build type to test ex) "x86_64 i586 armv7l aarch64" 
# Currently, this variable is declared to hande the "gbs build" command on Tizen.
pr_build_arch_type="x86_64"

### Check level of doxygen tag:
# Basic = 0 (@file + @brief)
# Advanced = 1 (Basic + "@author, @bug and functions with ctags")
pr_doxygen_check_level=0

### Check level of CPPCheck for a static analysis of C/C++ source code:
# CPPCheck Level 0: The check level is 'err'.
# CPPCheck Level 1: 'err' + 'warning,performance,unusedFunction'
pr_cppcheck_check_level=0


#### File size limit
# Unit of the file size is MB.
filesize_limit=5

#### Dependency policy between prebuild and postbuild group
# No dependency = 0
# Dependency = 1 (based on the order of definition)
# If dependency, PR group running order follows FCFS ordering
dep_policy_between_groups=0


#### Build mode of software platform

# BUILD_MODE_***=0  : execute a build process without a debug file.
# BUILD_MODE_***=1  : execute a build process with a debug file.
# BUILD_MODE_***=99 : skip a build process (by default)
#
# Note: if a package builder is not normally executed to generate package file,
# Please declare `BUILD_MODE_***=99` untile the issue will be fixed.
# 1) Tizen (packaging/*.spec): If a maintainer done the 'gbs' based build process,
#    you may change builde mode among 0, 1, and 99.
# 2) Ubuntu (debian/*.rule)  : If a maintainer done the 'pdebuild' based build process,
#    you may change builde mode among 0, 1, and 99.
# 3) Yocto (CMakeLists.txt)  : If a maintainer done the 'devtool' based build process,
#    you may change builde mode among 0, 1, and 99.
# 4) Android (jni/Android.mk)  : If a maintainer done the 'ndk-build' based build process,
#    you may change builde mode among 0, 1, and 99.
BUILD_MODE_TIZEN=99
BUILD_MODE_UBUNTU=99
BUILD_MODE_YOCTO=99
BUILD_MODE_ANDROID=99

# Pull Request Scheduler: The number of jobs on Run-Queue to process PRs
RUN_QUEUE_PR_JOBS=8

# Version format: Major.Minor.DATE
VERSION="1.3.20190927"

#### Location of the GitHub repository
# We assume that the default folder of the www-data (user-id of Apache webserver) is "/var/www/html/" folder. 

# Reference repository to speed up the exectuion time of the "git clone" command
REFERENCE_REPOSITORY="/var/www/html/$PRJ_REPO_UPSTREAM/"

# Specify RPM repo cache for accerating the GBS build speed of Tizen platform
REPOCACHE="/var/www/html/$PRJ_REPO_UPSTREAM/repo_cache/"

# GitHub repostiroy a web address
REPOSITORY_WEB="https://github.com/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"
REPOSITORY_GIT="https://github.com/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM.git"

# Specify GitHub webhook API address
# a. Community Edition - "https://github.{YOUR_COMPANY_DNS}/api/v3/repos/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"
# b. Enterprise Edition- "https://api.github.com/repos/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"
GITHUB_WEBHOOK_API="https://api.github.com/repos/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"



# Coverity, the configuration variables for the coverity module
# https://scan.coverity.com/dashboard
_cov_build_type="meson"
_cov_email="your-id@gmail.com"
_cov_token="1234567890123456789012"
_cov_site="https://scan.coverity.com/builds?project=nnsuite%2Fnnstreamer"
_cov_prj_website="https://scan.coverity.com/projects/nnsuite-nnstreamer"
