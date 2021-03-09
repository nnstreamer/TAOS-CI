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
# @file     pr-prebuild-executable.sh
# @brief    Check executable bits for .cpp, .c, .hpp, .h, .prototxt, .caffemodel, .txt., .init
# @see      https://github.com/nnstreamer/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-executable
function pr-prebuild-executable(){

echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME}/pr-prebuild-executable: Check executable bits for .cpp, .c, .hpp, .h, .prototxt, .caffemodel, .txt., .init"

    check_result="success"

    # Please add more types if you feel proper.
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    for X in $FILELIST; do
        echo "[DEBUG] exectuable check - file name is \"$FILELIST\"."
        if [[ $X =~ \.cpp$ || $X =~ \.c$ || $X =~ \.hpp$ || $X =~ \.h$ || $X =~ \.prototxt$ || $X =~ \.caffemodel$ || $X =~ \.txt$ || $X =~ \.ini$ ]]; then
            if [[ -f "$X" && -x "$X" ]]; then
                # It is a text file (.cpp, .c, ...) and is executable. This is invalid!
                check_result="failure"
                global_check_result="failure"
                break
            fi
        fi
    done
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A executable bits."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-executable" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A executable bits."
        message="Oooops. The commit has an invalid executable file ${X}. Please turn the executable bits off."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-executable" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        message=":octocat: **cibot**: $user_id, Oooops. The commit has an invalid executable file. The file is **${X}**. Please turn the executable bits off. Run **chmod 644 file-name** command."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
    

}

