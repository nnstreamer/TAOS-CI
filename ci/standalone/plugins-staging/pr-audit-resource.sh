#!/usr/bin/env bash

##
# Copyright 2018 The TAOS-CI Authors. All Rights Reserved.
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
# @file pr-audit-resource.sh
# @brief Check not-installed resources exist
# @see      https://github.sec.samsung.net/STAR/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

##
# @brief Resource checker to inspect not-installed resource files
#
# This function is to provide a resource checker area for ROS modules.
# Check if not-installed resources exist. It is integrated to the build checker,
# so we distinguish the resource cheker was succeed in this phase.
#
function pr-audit-resource(){
    echo "[DEBUG] Starting pr-audit-resource function to investigate if not-installed resources exist."

    # Resource checker area
    # Check if not-installed resources exist
    # It is integrated to the build checker, so we distinguish the resource cheker was succeed in this phase.
    
    echo "[DEBUG] Check if not-installed resources exist"
    PKGLIST=`git show --pretty="format:" --name-only --diff-filter=AMRC | grep ROS | sed "s/.*ROS\/\([^\/]*\)\/.*/\1/"`
    
    cat /dev/null > ../report/resource_check_${input_pr}_error.txt
    grep "Resource is not installed" ../report/build_log_${input_pr}_output.txt | grep -v "echo" > ../report/err.txt
    
    echo "[MODULE] if ../report/err.txt file exists, append package list to log file. "
    if [ -e "../report/err.txt" ]; then
        for pkg in ${PKGLIST[@]}; do
            grep $pkg ../report/err.txt >>  ../report/resource_check_${input_pr}_error.txt
        done
        # There is file(s) that is not installed. let's archive this contents with log file.
        mv ../report/err.txt ../report/resource_check_${input_pr}_not_installed.txt
    fi
    
    echo "[MODULE] if there are statements including 'could not find package' line, append the contents to log file. "
    grep "Couldn't find package" ../report/build_log_${input_pr}_output.txt | grep -v "echo"  >> ../report/resource_check_${input_pr}_error.txt
    
    declare -i res_errs=0
    res_errs+=`cat ../report/resource_check_${input_pr}_error.txt | wc -l`
    
    if [[ ${res_errs} -gt 0 ]]; then
        echo "[DEBUG][FAILED] Oooops!!!!!! resource checker is failed. Please check the not-installed resouces."
        echo ""
        echo "======= Not-installed Resources ======" >> ../report/build_log_${input_pr}_error.txt
        cat ../report/resource_check_${input_pr}_error.txt >> ../report/build_log_${input_pr}_error.txt
        check_result="failure"
        global_check_result="failure"
    else
        echo "[DEBUG][PASSED] Successfully resource checker is passed."
        check_result="success"
    fi
    
    echo "report the execution result of resource checker. check_result is ${check_result}. "
    if [[ $check_result == "success" ]]; then
        message="Successfully Resource checker is passed. Commit number is '$input_commit'."
        cibot_pr_report $TOKEN "success" "TAOS/pr-audit-resource" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="Oooops. Resource checker is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-audit-resource" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        # comment a hint on failed PR to author.
        message=":octocat: **cibot**: $user_id, Resource checker could not be completed because not-installed resources exist. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/resource_check_${input_pr}_error.txt."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}
