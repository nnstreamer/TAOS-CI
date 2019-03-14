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
# @file     pr-comment.sh
# @brief    This script is to send a comment message manually with Webhook API
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

#----------- Configuration: Do edit the below statements -----------------------
# Type a website of GitHub Webhook API.
# Note that community and enterprise edition have a different address structure.
# GITHUB_WEBHOOK_API="https://github.enterprise.com/api/v3/repos/STAR/TAOS-CI"
GITHUB_WEBHOOK_API="https://api.github.com/repos/nnsuite/nnstreamer"

# Type a token ID that has write permission to a website of GitHub Webhook API.
TOKEN="xxx"

#----------- Code area: Do not edit the below statements -----------------------

input_pr=$1

if [[ $1 == "" ]]; then
    echo -e "Oooops. Run '$0 {PR_NO}'"
    exit 1
fi

# write a comment message into a PR
MESSAGE="This PR looks great - This message is manually sent by administrator."
/usr/bin/curl -H "Content-Type: application/json" \
 -H "Authorization: token "$TOKEN"  " \
 --data "{\"body\":\":octocat: **cibot**: :+1: $MESSAGE \"}" \
 ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

