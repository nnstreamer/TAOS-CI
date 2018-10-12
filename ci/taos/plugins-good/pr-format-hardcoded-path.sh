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
# @file     pr-format-hardcoded-path.sh
# @brief    Check prohibited hardcoded paths (/home/* for now)
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-hardcoded-path
function pr-format-hardcoded-path(){

    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-hardcoded-path: Check prohibited hardcoded paths (/home/* for now)"
    hardcoded_file="hardcoded-path.txt"
    if [[ -f ../report/${hardcoded_file}.tmp ]]; then
        rm -f ../report/${hardcoded_file}.tmp
        touch ../report/${hardcoded_file}.tmp
    fi
    for X in `echo "${FILELIST}" | grep "$SRC_PATH/.*/" | sed -e "s|.*$SRC_PATH/\([a-zA-Z0-9_]*\)/.*|\1|" | sort -u`; do
        # README.md is added because grep waits for indefinite time if find gives you NULL.
        grep "\"\/home\/" `find $SRC_PATH/$X -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h"` README.md >> ../report/${hardcoded_file}.tmp
    done
    cat ../report/${hardcoded_file}.tmp | tr '\n' '\r' | sed -e "s|[^\r]*//[^\r]*\"/home/[^\r]*\r||g" | tr '\r' '\n' > ../report/${hardcoded_file}
    rm -f ../report/${hardcoded_file}.tmp
    VIOLATION=`wc -l < ../report/${hardcoded_file}`
    if [[ $VIOLATION -gt 0 ]]
    then
        check_result="failure"
        global_check_result="failure"
    else
        check_result="success"
    fi
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A hardcoded paths."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "TAOS/pr-format-hardcoded-path" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A hardcoded paths."
        message="Oooops. The component you are submitting has hardcoded paths that are not allowed in the source. Please do not hardcode paths."
        cibot_report $TOKEN "failure" "TAOS/pr-format-hardcoded-path" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    fi

    
}

