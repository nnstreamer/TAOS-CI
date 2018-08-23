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
# @file     pr-format-timestamp.sh
# @brief    Check the timestamp of the commit
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-timestamp
function pr-format-timestamp(){
echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-timestamp: Check the timestamp of the commit"
check_result="success"
TIMESTAMP=`git show --pretty="%ct" --no-notes -s`
TIMESTAMP_READ=`git show --pretty="%cD" --no-notes -s`
TIMESTAMP_BUF_3M=$(( $TIMESTAMP - 180 ))
# Let's "accept" 3 minutes of clock drift.
NOW=`date +%s`
NOW_READ=`date`

if [[ $TIMESTAMP_BUF_3M -gt $NOW ]]; then
    check_result="failure"
    global_check_reulst="failure"
elif [[ $TIMESTAMP -gt $NOW ]]; then
    check_result="failure"
    global_check_reulst="failure"
else
    check_result="success"
fi

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A timestamp."
    message="Successfully the commit has no timestamp error."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-timestamp" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A timestamp."
    message="Timestamp error: files are from the future: ${TIMESTAMP_READ} > (now) ${NOW_READ}."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-timestamp" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
fi


}

