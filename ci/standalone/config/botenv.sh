#!/usr/bin/env bash

######################################################################################
## @file botenv.sh
## @brief Environment file to control all scripts commonly for CI bot
##
## This script to maintain consistently all scripts files via this file. 
## In the near future, all configuration variables will be integrated into this file. 
##
## In case that you have to run this CI script at the below environment, Please change
## the contents appropriately.
## a. In case that you want to apply this CI script to another repository
## b. In case that you have to install CI in a new CI server for more high-performance
## c. In case that you need to create new project
######################################################################################


################### Common Area ######################################################

# Connecting to a repository using token id instead of git.bot.sec@samsung.com id
# because of two-authentification. Refer to https://github.sec.samsung.net/settings/tokens
TOKEN="01eec554abcaae8755c06c2b06f5d6bb84d4b4a5"

# Email-address
# Note that we have to log-in at least 3 times per a month to avoid deletion of the ID
# according to announcement of "전자녹스포탈" (knoxportal.sec@samsung.com).
EMAIL="git.bot.sec@samsung.com"

# Projcet name
PROJECT="AuDri"

# Reference repository to speed up "git clone" command
REFERENCE_REPOSITORY="/var/www/html/AuDri/"

# RPM repo cache for GBS build
REPOCACHE="/var/www/html/AuDri/repo_cache/"

# Github repostiroy webaddress
REPOSITORY_WEB="https://github.sec.samsung.net/STAR/AuDri"
REPOSITORY_GIT="https://github.sec.samsung.net/STAR/AuDri.git"

# Github webhook API
GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/STAR/AuDri"

# CI Server webaddress. Should end with /
CISERVER="http://aaci.mooo.com/"


################### Format Area (pr-format) ##############################################

# Check prohibited hardcoded paths (e.g., /home/* for now).
HARDCODED_PATH_LIST=`echo "${FILELIST}" | grep "ROS/.*/" | sed -e "s|.*ROS/\([a-zA-Z0-9_]*\)/.*|\1|" | sort -u`



################### Audit Area (pr-audit) ################################################

# Skip build-checker / unit-test checker if all changes are limited to:
# The path starts without / and it denotes the full paths in the git repo. (regex)
SKIP_CI_PATHS="^ci/.*|^Documentation/.*|^\.github/.*|^obsolete/.*|^README\.md"

# Define the number of CPUs to build source codes in parallel
# We recommend that you define appropriate # of CPUs that does not result in
# Out-Of-Memory and Too mnay task migration among the CPUs.
CPU_NUM=3

