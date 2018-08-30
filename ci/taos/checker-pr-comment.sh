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
# @file  checker-pr-comment.sh
# @brief Automatic PR commenter to announce information automatically whenever contributor submits a PR
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @param
#  arg1: PR number
#

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/config-environment.sh
source ./common/api_collection.sh

# check if input argument is correct. 
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please, use a correct PR number.\n"
    exit 1
fi

input_pr=$1

 # --------------------------- Report module: submit check result to github-website --------------
# execute automatic comment to handle new PR that include commits more than 2.

if [[ $pr_comment_notice == 1 ]]; then
    # inform PR submitter of a rule to pass the CI process
    message=":memo: Version: ${VERSION}. Thank you for submitting PR #${input_pr}. Your PR must pass all verificiation processes of cibot before starting a review process from reviewers. If you are new member to join this project, please read manuals in documentation folder and wiki page. In order to monitor a progress status of your PR in more detail, visit ${CISERVER}."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_self_merge == 1 ]]; then
    # inform PR submitter that they do not have to merge their own PR directly.
    message="Note that **you do not have to merge your own PR** directly."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_many_commit == 1 ]]; then
    # infrom PR submitter of how to submit a PR that include lots of commits.
    message="If you have to submit +2 commits per PR, paste the output in your PR body after running `$ git format-patch --cover-letter -{number-of-commits}`."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_pr_monitor == 1 ]]; then
    # inform PR submitter of the webpage address in order that they can monitor the current status of their PR.
    message="If you want to monitor the current build status of your PR, Please refer to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/taos/webapp/monitor.php"
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

