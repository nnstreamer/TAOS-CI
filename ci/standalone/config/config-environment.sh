#!/usr/bin/env bash

##
# Copyright (c) 2018 Samsung Electronics Co., Ltd. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##
# @file config-environment.sh
# @brief Environment file to control all scripts commonly for CI bot
# @see      https://github.sec.samsung.net/STAR/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#
# This script to maintain consistently all scripts files via this file. 
# In the near future, all configuration variables will be integrated into this file. 
#
# In case that you have to run this CI script at the below environment, Please change
# the contents appropriately.
# a. In case that you want to apply this CI script to another repository
# b. In case that you have to install CI in a new CI server for more high-performance
# c. In case that you need to create new project
#

################# Modify the below statements for your server  #######################


#### Repository setting
# Name of account (or orgranzation)
GITHUB_ACCOUNT="STAR"

# Project name of github.sec.samsung.net
PRJ_REPO_UPSTREAM="TAOS-CI"

# CI Server webaddress. Should end with /
CISERVER="http://aaci.mooo.com/"

# Format area (pr-format)
# Add root path of source folders
# Specify a path of source code
# 1) to check prohibited hardcoded paths (e.g., /home/* for now)
# 2) to check code formatting sytele with clang-format
SRC_PATH="./ci/"

# Audit Area (pr-audit)
# Skip build-checker / unit-test checker if all changes are limited to:
# The path starts without / and it denotes the full paths in the git repo. (regex)
SKIP_CI_PATHS_AUDIT="^ci/.*|^Documentation/.*|^\.github/.*|^obsolete/.*|^README\.md|^external/.*|^temporal-bin/.*"

# Format Area (pr-format)
# declare a folder name to skip the file size and newline inspection.
# (e.g., <github-repository-name>/temproal-bin/)
SKIP_CI_PATHS_FORMAT="temporal-bin"

# Define the number of CPUs to build source codes in parallel
# We recommend that you define appropriate # of CPUs that does not result in
# Out-Of-Memory and Too mnay task migration among the CPUs.
CPU_NUM=3

#### Automatic PR commenter: enabling(1), disabling(0)

# inform PR submitter of a rule to pass the CI process
pr_comment_notice=1

# inform all developers of their activity whenever PR submitter resubmit their PR after applying comments of reviews
pr_comment_pr_updated=0

# inform PR submitter that they do not have to merge their own PR directly.
pr_comment_self_merge=0

# infrom PR submitter of how to submit a PR that include lots of commits.
pr_comment_many_commit=0

# inform PR submitter of the webpage address in order that they can monitor the current status of their PR.
pr_comment_pr_monitor=0

#### Build test: Write build type to test ex) "x86_64 armv7l" 
pr_build_arch_type="x86_64"

### Check level of doxygen tag:
# Basic = 0 (@file + @brief)
# Advanced = 1 (Basic + "@author, @bug and functions with ctags")
pr_doxygen_check_level=0

#### File size limit
# unit of the file size is MB.
filesize_limit=5


#### Build mode of software platform

# BUILD_MODE_***=0  : execute a build process without a debug file.
# BUILD_MODE_***=1  : execute a build process with a debug file.
# BUILD_MODE_***=99 : skip a build process (by default)
#
# Note: if a packaging management is not normally executed for package build, you must declare `BUILD_MODE_***=99` unavoidably
# 1) Tizen (packaging/*.spec): If a maintainer done the gbs based build process, you may change builde mode from 99 to 0.
# 2) Ubuntu (debian/*.rule)  : If a maintainer done the pdebuild based build process, you may change builde mode from 99 to 0.
# 3) Yocto (CMakeLists.txt)  : If a maintainer done the devtool based build process, you may change builde mode from 99 to 0.
BUILD_MODE_TIZEN=99
BUILD_MODE_UBUNTU=99
BUILD_MODE_YOCTO=99

################# Do not modify the below statements #################################

# Version format: Major.Minor
VERSION="1.20180719"

# Connecting to a repository using token id instead of git.bot.sec@samsung.com id
# because of two-authentification. Refer to https://github.sec.samsung.net/settings/tokens
TOKEN="01eec554abcaae8755c06c2b06f5d6bb84d4b4a5"

# Email-address
# Note that we have to log-in at least 3 times per a month to avoid deletion of the ID
# according to announcement of "전자녹스포탈" (knoxportal.sec@samsung.com).
EMAIL="git.bot.sec@samsung.com"

# Reference repository to speed up "git clone" command
REFERENCE_REPOSITORY="/var/www/html/$PRJ_REPO_UPSTREAM/"

# RPM repo cache for GBS build
REPOCACHE="/var/www/html/$PRJ_REPO_UPSTREAM/repo_cache/"

# Github repostiroy webaddress
REPOSITORY_WEB="https://github.sec.samsung.net/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"
REPOSITORY_GIT="https://github.sec.samsung.net/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM.git"

# Github webhook API
GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/$GITHUB_ACCOUNT/$PRJ_REPO_UPSTREAM"




