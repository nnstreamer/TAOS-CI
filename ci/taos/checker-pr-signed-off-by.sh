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
# @file checker-pr-signed-off-by.sh
# @brief signedoff facility to check automatically whenever PR is submitted by contributor
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @param
#  arg1: PR number
#  arg2: Commit number (based on SHA)
#  arg3: Result value (success or failure) by checking "Signed-off-by: " rule
#         from commit message of PR
# @note
# First of all, We have to understand why we have to use "Signed-off-by" statement.
# We recommend that we have to require "Signed-off-by" line in git commit messages
# to author on our project as well as Linux community. "Is there a Signed-off-by" line?"
# is important because lawyers tell us we must have to it to cleanly maintain the license
# issues even though it has nothing to do with the code itself. So, the activity that we
# do append "Signed-off-by" line is helpful to developers as well as lawyers.
#
# [FYI] How to give the developers zero cost:
#
# $ vi ~/.gitconfig
#   [user]
#           name = Gildong Hong
#           email = gildong.hong@samsung.com
# $ git commit -a -s
# // -s (--signoff) means automated signed-off-by statement
#
#
# Lots of opensource communities have been using "Signed-off-by:" notation by default to handle the license issues that result from contributors.
# Refer to the below websites:
# * Signed-off-by Process by LinuxFoundation - https://ltsi.linuxfoundation.org/developers/signed-process
# * Signed-off-by lines and the DCO - http://elinux.org/Legal_Issues#Signed-off-by_lines_and_the_DCO
# * Gerrit Code Review - Signed-off-by Lines - https://git.eclipse.org/r/Documentation/user-signedoffby.html
# 

# --------------------------- Pre-setting module ----------------------------------------------------------------------

source ./config/config-environment.sh
source ./common/api_collection.sh

# check if input argument is correct. 
if [[ $1 == "" || $2 == "" || $3 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

input_pr=$1
input_commit=$2
input_result=$3

# --------------------------- CI Trigger ------------------------------------------------------------------------------
# attach a trigger to TAOS/pr-format-signedoff context.
cibot_report $TOKEN "pending" "TAOS/pr-format-signedoff" "Triggered. The commit number is $input_commit" "$CISERVER" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"


 # -------------------------- Report module: submit check result to github-website ----------------------------
# execute a check result by checking a Signed-off-by string.
# https://developer.github.com/enterprise/2.10/v3/repos/statuses/#create-a-status

if [[ $input_result == "success" ]]; then
    # in case of success
    message="Successfully signedoff! This PR includes Signed-off-by: string."
    cibot_report $TOKEN "success" "TAOS/pr-format-signedoff" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
elif [[ $input_result == "failure" ]]; then
    # in case of failure
    message="Oooops. No signedoff found. This PR does not include 'Signed-off-by:' string. The lawyers tell us we must have it."
    cibot_report $TOKEN "failure" "TAOS/pr-format-signedoff" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform contributors of meaning of Signed-off-by: statement
    message="To contributor, We have used '**Signed-off-by:**' notation by default to handle the license issues, that result from contributors. Note that 'Is there a Signed-off-by line?' is important because lawyers tell us we must have to it **to cleanly maintain the open-source license issues** even though it has nothing to do with the code itself."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
else
    # in case of CI error
    message="Oooops. It seems that CI bot includes bug(s). CI bot has to be fixed."
    cibot_report $TOKEN "error" "TAOS/pr-format-signedoff" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
fi
