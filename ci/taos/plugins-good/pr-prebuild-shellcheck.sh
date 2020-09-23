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
# @file     pr-prebuild-shellcheck.sh
# @brief    This module is a static analysis tool for shell scripts such as sh, bash.
#
#  It is mainly focused on handling typical beginner and intermediate level syntax errors
#  and pitfalls where the shell just gives a cryptic error message or strange behavior,
#  but it also reports on a few more advanced issues where corner cases can cause delayed
#  failures. 
#
# @see      https://www.shellcheck.net/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-shellcheck
function pr-prebuild-shellcheck(){
echo "########################################################################################"
echo "[MODULE] ${BOT_NAME}/pr-prebuild-shellcheck: Check syntax errors in a shell script file with GNU shellcheck"

# Check if required commands are installed by server administrator
check_cmd_dep cat
check_cmd_dep shellcheck
check_cmd_dep file
check_cmd_dep grep
check_cmd_dep wc

# Read file names that a contributor modified(e.g., added, moved, deleted, and updated) from a last commit.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`

# Inspect all files that contributor modifed.
for i in ${FILELIST}; do
    # Default value of check_result is "skip".
    check_result="skip"

    # Skip obsolete folder
    if [[ $i =~ ^obsolete/.* ]]; then
        continue
    fi
    # Skip external folder
    if [[ $i =~ ^external/.* ]]; then
        continue
    fi
    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $i )."
    if [[ `file $i | grep "shell script" | wc -l` -gt 0 ]]; then
        case $i in
            # In case of .sh or .bash file
            *.sh | *.bash)
                echo "[DEBUG] ( $i ) file is a shell script file with the 'shell script' text format."
                shell_syntax_analysis_sw="shellcheck"
                shell_syntax_analysis_rules="-s bash"
                shell_syntax_check_result="shellcheck_syntax_result.txt"

                cat $i | $shell_syntax_analysis_sw $shell_syntax_analysis_rules > ../report/${shell_syntax_check_result}

                line_count=`cat ../report/${shell_syntax_check_result} | wc -l`
                # TODO: 9,000 is declared by heuristic method from our experiment.
                if  [[ $line_count -gt 9000 ]]; then
                    echo "[DEBUG] $shell_syntax_analysis_sw: failed. file name: $i, There are $line_count lines."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $shell_syntax_analysis_sw: passed. file name: $i, There are $line_count lines."
                    check_result="success"
                fi
                ;;
            * )
                echo "[DEBUG] The shellcheck module inspects the ( $i ) file because it is not the bash script file."
                check_result="skip"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A shell script syntax checker - shellcheck."
    message="Successfully source code(s) is written without a syntax error."
    cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-shellcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. A shell script syntax checker - shellcheck."
    message="Skipped. Your PR does not include document file(s) such as .sh and .bash."
    cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-shellcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A shell script syntax checker - shellcheck."
    message="Oooops. The shellcheck module is failed. Please, read $shell_syntax_check_result for more details."
    cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-shellcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, It seems that **$i** includes syntax errors. https://github.com/koalaman/shellcheck/wiki/SC1118. Please read ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${shell_syntax_check_result}, and modify a incorrect statement before starting a review process."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

}
