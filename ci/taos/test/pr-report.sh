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
# @file     pr-report.sh
# @brief    This script is to send "success" message manually with Webhook API
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

#----------- Configuration: Do edit the below statements -----------------------
# Type a website of GitHub Webhook API.
# Note that community and enterprise edition have a different address structure.
# GITHUB_WEBHOOK_API="https://github.enterprise.com/api/v3/repos/STAR/TAOS-CI"
GITHUB_WEBHOOK_API="https://api.github.com/repos/nnsuite/nnstreamer"

# Type a token ID that has write permission to a website of GitHub Webhook API.
TOKEN="xxx"

# Type your website address
WEB_URL="http://nnsuite.mooo.com"

# Add a context name of a plugin module that you want to mark a success symbol.
declare -i idx=-1
context_modules[++idx]="(INFO)TAOS/pr-format-all"
context_modules[++idx]="(INFO)TAOS/pr-audit-all"
context_modules[++idx]="TAOS/pr-audit-build-tizen-aarch64"

#----------- Code area: Do not edit the below statements -----------------------
# Type a commit number.
# For example, input_commit is 6967adfe5fea652b9959c58110fc8d7f280c8a43
input_commit=$1

if [[ $1 == "" ]]; then
    echo -e "Usage: '$0 {COMMIT_NO}'"
    echo -e ""
    exit 1
fi

# Send "success" message to a website of Github Webhook API.
for module in ${context_modules[*]}
do
    # send a PR status message into a commit of a PR
    MESSAGE="Successfully done. It is manually executed by administrator."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"$module\",\"description\":\"$MESSAGE\",\"target_url\":\"$WEB_URL\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
done

# Inform a CI administrator of a helpful message for debugging.
echo -e "[DEBUG] Tip: How to fix a trouble"
echo -e "[DEBUG]   a. If webhook server replies \"message\": \"Not Found\", add a privileged user id at 'Setting - Collaborators'."
echo -e "[DEBUG]   b. The privileged user id has to be appended by \"Write\" permission."
echo -e "[DEBUG]   c. If webhook server replies \"message\": \"Bad credentials\", try do it again with a correct token key."
echo -e "[DEBUG]   d. If the return value of the curl command is 0, it means that webhook operation is normal."

