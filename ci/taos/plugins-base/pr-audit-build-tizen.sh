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
# @file pr-audit-build-tizen.sh
# @brief Build package with gbs command  to verify build validation on Tizen software platform
# @see      https://github.com/nnsuite/TAOS-CI
# @see      https://source.tizen.org/documentation/reference/git-build-system
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @requirement
# $ sudo apt install gbs

# @brief [MODULE] TAOS/pr-audit-build-tizen-wait-queue
function pr-audit-build-tizen-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-tizen-ready-queue
function pr-audit-build-tizen-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-tizen-run-queue
function pr-audit-build-tizen-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "[MODULE] TAOS/pr-audit-build-tizen-$1: Check if 'gbs build -A $1' can be successfully passed."
    pwd

    # check if dependent packages are installed
    # the required packages are gbs.
    check_dependency sudo
    check_dependency curl
    check_dependency gbs
    check_dependency tee

    # BUILD_MODE=0 : run "gbs build" command without generating debugging information.
    # BUILD_MODE=1 : run "gbs build" command with a debug file.
    # BUILD_MODE=99: skip "gbs build" procedures
    BUILD_MODE=$BUILD_MODE_TIZEN

    # build package
    if [[ $BUILD_MODE == 99 ]]; then
        echo -e "BUILD_MODE = 99"
        echo -e "Skipping 'gbs build -A $1' procedure temporarily."
    elif [[ $BUILD_MODE == 1 ]]; then
        echo -e "BUILD_MODE = 1"
        sudo -Hu www-data gbs build \
        -A $1 \
        --clean \
        --define "_smp_mflags -j${CPU_NUM}" \
        --define "_pr_context pr-audit" \
        --define "_pr_number ${input_pr}" \
        --define "__ros_verify_enable 1" \
        --define "_pr_start_time ${input_date}" \
        --define "_skip_debug_rpm 1" \
        --buildroot ./GBS-ROOT/  | tee ../report/build_log_${input_pr}_tizen_$1_output.txt
    else
        echo -e "BUILD_MODE = 0"
        sudo -Hu www-data gbs build \
        -A $1 \
        --clean \
        --define "_smp_mflags -j${CPU_NUM}" \
        --define "_pr_context pr-audit" \
        --define "_pr_number ${input_pr}" \
        --define "__ros_verify_enable 1" \
        --define "_pr_start_time ${input_date}" \
        --define "_skip_debug_rpm 1" \
        --buildroot ./GBS-ROOT/ 2> ../report/build_log_${input_pr}_tizen_$1_error.txt 1> ../report/build_log_${input_pr}_tizen_$1_output.txt
    fi
    result=$?
    echo "[DEBUG] The variable result value is $result."
    
    if [[ $BUILD_MODE == 99 ]]; then
        # Do not run "gbs build" command in order to skip unnecessary examination if there are no buildable files.
        echo -e "BUILD_MODE == 99"
        echo -e "[DEBUG] Let's skip the 'gbs build -A $1' procedure because there is not source code. All files may be skipped."
        echo -e "[DEBUG] So, we stop remained all tasks at this time."
    
        message="Skipped gbs build -A $1 procedure. No buildable files found. Commit number is $input_commit."
        cibot_pr_report $TOKEN "success" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        message="Skipped gbs build -A $1 procedure. Successfully all audit modules are passed. Commit number is $input_commit."
        cibot_pr_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        echo -e "[DEBUG] All audit modules are passed (gbs build -A $1 procedure is skipped) - it is ready to review!"
    else
        echo -e "BUILD_MODE != 99"
        echo -e "[DEBUG] The return value of gbs build -A $1 command is $result."
        # Let's check if build procedure is normally done.
        if [[ $result -eq 0 ]]; then
                echo "[DEBUG][PASSED] Successfully build checker is passed. Return value is ($result)."
                check_result="success"
        else
                echo "[DEBUG][FAILED] Oooops!!!!!! build checker is failed. Return value is ($result)."
                check_result="failure"
                global_check_result="failure"
        fi
    
        # Let's report build result of source code
        if [[ $check_result == "success" ]]; then
            message="Successfully a build checker is passed. Commit number is '$input_commit'."
            cibot_pr_report $TOKEN "success" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
        else
            message="Oooops. A build checker is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
            cibot_pr_report $TOKEN "failure" "TAOS/pr-audit-build-tizen-$1" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
            # comment a hint on failed PR to author.
            message=":octocat: **cibot**: $user_id, A builder checker could not be completed because one of the checkers is not completed. In order to find out a reason, please go to ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/."
            cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
        fi
    fi
    
}
