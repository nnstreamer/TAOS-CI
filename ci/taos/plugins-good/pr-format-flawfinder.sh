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
# @file     pr-format-flawfinder.sh
# @brief    This module examines C/C++ source code to find a possible security weaknesses.
#
#  Flawfinder searches through C/C++ source code looking for potential security flaws. It examines
#  all of the project's C/C++ source code. It is very useful for quickly finding and removing some
#  security problems before a program is widely released.
#
#  Flawfinder produces a list of `hits` (potential security flaws), sorted by risk; the riskiest
#  hits are shown first. The risk level is shown inside square brackets and varies from 0 (very
#  little risk) to 5 (great risk). This risk level depends not only on the function,
#  but on the values of the parameters of the function. For example, constant strings are often less risky
#  than fully variable strings in many contexts, and in those contexts the hit will have a lower risk level.
#  Hit descriptions also note the relevant Common Weakness Enumeration (CWE) identifier(s) in parentheses.
#
# @see      https://dwheeler.com/flawfinder/
# @see      https://sourceforge.net/projects/flawfinder/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

# @brief [MODULE] TAOS/pr-format-flawfinder
function pr-format-flawfinder(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-flawfinder: Check security problems in C/C++ source codes with flawfinder"
    pwd

    # Check if server administrator install required commands
    check_dependency flawfinder
    check_dependency file
    check_dependency grep
    check_dependency cat
    check_dependency wc
    check_dependency git
    check_dependency awk

    check_result="skip"

    # Display the flawfinder version that is installed in the CI server.
    # Note that the out-of-date version can generate an incorrect result.
    flawfinder --version

    # Read file names that a contributor modified (e.g., added, moved, deleted, and updated) from a last commit.
    # Then, inspect C/C++ source code files from *.patch files of the last commit.
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    for i in ${FILELIST}; do
        # Skip the obsolete folder
        if [[ ${i} =~ ^obsolete/.* ]]; then
            continue
        fi
        # Skip the external folder
        if [[ ${i} =~ ^external/.* ]]; then
            continue
        fi
        # Handle only text files in case that there are lots of files in one commit.
        echo "[DEBUG] file name is (${i})."
        if [[ `file ${i} | grep "ASCII text" | wc -l` -gt 0 ]]; then
            # in case of C/C++ source code
            case ${i} in
                # in case of C/C++ code
                *.c|*.cc|*.cpp|*.c++)
                    echo "[DEBUG] (${i}) file is source code with the text format."
                    static_analysis_sw="flawfinder"
                    if [[ ! -z $pr_flawfinder_check_level ]]; then
                        echo "[DEBUG] flawfinder: It's okay. The value of the flawfinder level is $pr_flawfinder_check_level."
                        static_analysis_rules="--html --context --minlevel=$pr_flawfinder_check_level"
                    else
                        echo "[DEBUG] flawfinder: It's okay. The value of the flawfinder level (e.g. pr_flawfinder_check_level) is empty."
                        echo "[DEBUG] flawfinder: You can declare the check level between 1(default) and 5 in the configuration file."
                        echo "[DEBUG] flawfinder: The module executes a flaw inspection with level 1 by default."
                        static_analysis_rules="--html --context"
                    fi

                    flawfinder_result="flawfinder_security_flaw_result"
                    # Check C/C++ file.
                    $static_analysis_sw $static_analysis_rules ${i} > ../report/${flawfinder_result}_${i}.html
                    bug_nums=`cat ../report/${flawfinder_result}_${i}.html | grep "Hits = " | awk '{print $3}'`
                  
                    # Report the execution result.
                    if  [[ $bug_nums -gt 0 ]]; then
                        echo "[DEBUG] $static_analysis_sw: failed. file name: ${i}, There are $bug_nums bug(s)."
                        check_result="failure"
                        global_check_result="failure"
                        # Note: Let's keep "step-by-step" style instead of "all report" style.
                        # If we meet new cases in the near future, let's customize this module again
                        # to give contributors efficiency and convenience.
                        break
                    else
                        echo "[DEBUG] $static_analysis_sw: passed. file name: ${i}, There are $bug_nums bug(s)."
                        check_result="success"
                    fi
                    ;;
                * )
                    echo "[DEBUG] The flawfinder (a static analysis tool for security) module does not scan (${i}) file."
                    ;;
            esac
        fi
    done
   
    # Send the webhook message to a GitHub repository.
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. Static code analysis tool for security - flawfinder."
        message="Successfully source code(s) is written without securty flaws."
        cibot_report $TOKEN "success" "TAOS/pr-format-flawfinder" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "skip" ]]; then
        echo "[DEBUG] Skipped. Static code analysis tool for security - flawfinder."
        message="Skipped. Your PR does not include c/c++ code(s)."
        cibot_report $TOKEN "success" "TAOS/pr-format-flawfinder" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. Static code analysis tool for security - flawfinder."
        message="Oooops. flawfinder is failed. Please read $flawfinder_result for more details."
        cibot_report $TOKEN "failure" "TAOS/pr-format-flawfinder" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        # Inform PR submitter of a hint in more detail
        message=":octocat: **cibot**: $user_id, **${i}** includes bug(s). Please fix security flaws in your commit before entering a review process."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
    

}

