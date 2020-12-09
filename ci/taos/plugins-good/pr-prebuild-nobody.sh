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
# @file     pr-prebuild-nobody.sh
# @brief    Check the commit message body
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-nobody
function pr-prebuild-nobody(){
    echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME}/pr-prebuild-nobody: Check the commit message body"
    check_result="success"
    echo "             #### No body check result ####            " > ../report/nobody-result.txt
    for filename in ../report/000*.patch; do
        echo " * $filename " >> ../report/nobody-result.txt
        line_count=0
        body_count=0
        # let's do the while-loop statement to read data line by line
        while IFS= read -r line; do
            #If the line starts with "Subject*" then set var to "yes".
            if [[ $line == Subject* ]] ; then
                printline="yes"
                # Just t make each line start very clear, remove in use.
                echo "============== commit body: start =====================" >> ../report/nobody-result.txt
                continue
            fi
            #If the line starts with "---*" then set var to "no".
            if [[ $line == ---* ]] ; then
                printline="no"
                # Just to make each line end very clear, remove in use.
                echo "============== commit body: end   =====================" >> ../report/nobody-result.txt
                break
            fi
            # If variable is yes, print the line.
            if [[ $printline == "yes" ]] ; then
                echo "[DEBUG] $line"   >> ../report/nobody-result.txt
                line_count=$(echo $line | wc -w)
                body_count=$(($body_count + $line_count))
            fi
        done < "$filename"
    
        # determine if a commit body exceeds 3 words (Signed-off-by line is already 3 words.)
        echo "[DEBUG] body count is $body_count"
        body_count_criteria=`echo "3+5"|bc`
        if  [[ $body_count -lt $body_count_criteria ]]; then
            echo "[DEBUG] commit body checker is FAILED. patch file name: $filename"
            echo "[DEBUG] current directory is `pwd`"
            check_result="failure"
            global_check_result="failure"
        else
            echo "[DEBUG] commit body checker is PASSED. patch file name: $filename"
            echo "[DEBUG] current directory is `pwd`"
        fi
    done
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. There is no nobody issue."
        message="Successfully commit body includes +5 words."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-nobody" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. There is no the commit body in this commit."
        message="Oooops. Commit message body checker failed. You must write commit message (+5 words) as well as commit title."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-nobody" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    fi

}

