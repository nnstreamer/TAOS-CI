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
# @file     pr-format-signed-off-by.sh
# @brief    Check if contributor write Sigend-off-by message
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Sewon oh <sewon.oh@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-signed-off-by
function pr-format-signed-off-by(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-signed-off-by: Check the commit message body"
    check_result="success"
    echo "             #### signed-off-by check result ####            " > ../report/signed-off-by-result.txt
    for filename in ../report/000*.patch; do
        echo " * $filename " >> ../report/signed-off-by-result.txt
        result=0
        # let's do the while-loop statement to read data line by line
        while IFS= read -r line; do
            #If the line starts with "Subject*" then set var to "yes".
            if [[ $line == Subject* ]]; then
                bodyline="yes"
                # Just t make each line start very clear, remove in use.
                echo "============== commit body: start =====================" >> ../report/signed-off-by-result.txt
                continue
            fi
            #If the line starts with "---*" then set var to "no".
            if [[ $line == ---* ]]; then
                bodyline="no"
                # Just to make each line end very clear, remove in use.
                echo "============== commit body: end   =====================" >> ../report/signed-off-by-result.txt
                break
            fi
            # If variable is yes, print the line.
            if [[ $bodyline == "yes" ]]; then
                echo "[DEBUG] $line"   >> ../report/signed-off-by-result.txt
                if [[ $line == Signed-off-by* ]]; then
                    result=1
                fi
            fi
        done < "$filename"
    
        # determine if a commit body has Signed-off-by message.
        echo "[DEBUG] result is $result"
        if  [[ $result -eq 0 ]]; then
            echo "[DEBUG] signed-off-by checker is FAILED. patch file name: $filename"
            echo "[DEBUG] current directory is `pwd`"
            check_result="failure"
            global_check_result="failure"
        else
            echo "[DEBUG] signed-off-by checker is PASSED. patch file name: $filename"
            echo "[DEBUG] current directory is `pwd`"
        fi
    done
    if [[ $check_result == "success" ]]; then
        # in case of success
        echo "[DEBUG] Passed. There is no signed-off-by issue."
        message="Successfully signedoff! This PR includes Signed-off-by: string."
        cibot_report $TOKEN "success" "TAOS/pr-format-signed-off-by" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    elif [[ $check_result == "failure" ]]; then
        echo "[DEBUG] Failed. There is no signed-off-by in this commit."
        # in case of failure
        message="Oooops. No signedoff found. This PR does not include 'Signed-off-by:' string. The lawyers tell us we must have it."
        cibot_report $TOKEN "failure" "TAOS/pr-format-signed-off-by" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

        # inform contributors of meaning of Signed-off-by: statement
        message="To contributor, We have used '**Signed-off-by:**' notation by default to handle the license issues, that result from contributors. Note that 'Is there a Signed-off-by line?' is important because lawyers tell us we must have to it **to cleanly maintain the open-source license issues** even though it has nothing to do with the code itself."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    else
        # in case of CI error
        message="Oooops. It seems that CI bot includes bug(s). CI bot has to be fixed."
        cibot_report $TOKEN "error" "TAOS/pr-format-signed-off-by" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi
}

