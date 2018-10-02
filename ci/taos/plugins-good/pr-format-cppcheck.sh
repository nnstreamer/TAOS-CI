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
# @file     pr-format-cppcheck.sh
# @brief    Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck
#
# The possible severities (e.g., --enable=warning,unusedFunction) for messages are as following:
# Note that by default Cppcheck only writes error messages if it is certain.
# 1. error  : used when bugs are found
# 2. warning: suggestions about defensive programming to prevent bugs
# 3. style  : stylistic issues related to code cleanup (unused functions, redundant code, constness, and such)
# 4. performance: Suggestions for making the code faster. These suggestions are only based on common knowledge.
# 5. portability: portability warnings. 64-bit portability. code might work different on different compilers. etc.
# 6. information: Informational messages about checking problems.
# 7. unusedFunction: enable unusedFunction checking. This is not enabled by --enable=style
#    because it does not work well on libraries.
# 8. all: enable all messages. It should also only be used when the whole program is scanned.
#
# @see      https://github.com/nnsuite/TAOS-CI
# @see      https://github.com/danmar/cppcheck
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-cppcheck
function pr-format-cppcheck(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-cppcheck: Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck"

    check_result="skip"

    # investigate generated all *.patch files
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    for i in ${FILELIST}; do
        # skip obsolete folder
        if [[ $i =~ ^obsolete/.* ]]; then
            continue
        fi
        # skip external folder
        if [[ $i =~ ^external/.* ]]; then
            continue
        fi
        # Handle only text files in case that there are lots of files in one commit.
        echo "[DEBUG] file name is ( $i )."
        if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
            # in case of source code files: *.c|*.cpp)
            case $i in
                # in case of C/C++ code
                *.c|*.cpp)
                    echo "[DEBUG] ( $i ) file is source code with the text format."
                    static_analysis_sw="cppcheck"
                    if [[ $pr_cppcheck_check_level -eq 0 ]]; then
                        echo "[DEBUG] cppcheck: It's okay. The value of the cppcheck level is $pr_cppcheck_check_level."
                        static_analysis_rules="--std=posix"
                    elif [[ $pr_cppcheck_check_level -eq 1 ]]; then
                        echo "[DEBUG] cppcheck: It's okay. The value of the cppcheck level is $pr_cppcheck_check_level."
                        static_analysis_rules="--enable=warning,performance --std=posix"
                    else
                        echo "[DEBUG] cppcheck: Oooops. The value of the cppcheck level is $pr_cppcheck_check_level."
                        echo "[DEBUG] cppcheck: Note that you have to declare one between 0 and 1."
                        echo "[DEBUG] cppcheck: The module executes an inspection proceudre with level 0."
                        static_analysis_rules="--std=posix"
                    fi

                    cppcheck_result="cppcheck_result.txt"
                    # Check C/C++ file, enable all checks.
                    $static_analysis_sw $static_analysis_rules $i 2> ../report/$cppcheck_result
                    bug_line=`cat ../report/$cppcheck_result | wc -l `
                    if  [[ $bug_line -gt 0 ]]; then
                        echo "[DEBUG] $static_analysis_sw: failed. file name: $i, There are $bug_line bug(s)."
                        check_result="failure"
                        global_check_result="failure"
                        break
                    else
                        echo "[DEBUG] $static_analysis_sw: passed. file name: $i, There are $bug_line bug(s)."
                        check_result="success"
                    fi
                    ;;
                * )
                    echo "[DEBUG] ( $i ) file can not be investigated by cppcheck (statid code analysis tool)."
                    ;;
            esac
        fi
    done
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. static code analysis tool - cppcheck."
        message="Successfully source code(s) is written without dangerous coding constructs."
        cibot_pr_report $TOKEN "success" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "skip" ]]; then
        echo "[DEBUG] Skipped. static code analysis tool - cppcheck."
        message="Skipped. Your PR does not include c/c++ code(s)."
        cibot_pr_report $TOKEN "success" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. static code analysis tool - cppcheck."
        message="Oooops. cppcheck is failed. Please, read $cppcheck_result for more details."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        # inform PR submitter of a hint in more detail
        message=":octocat: **cibot**: $user_id, **$i** includes bug(s). You must fix incorrect coding constructs in the source code before entering a review process."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
    

}

