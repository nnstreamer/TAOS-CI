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
# @file     pr-prebuild-prohibited-words.sh
# @brief    Check if there are prohibited words in the text files
#
# It to check a prohibited word if there are unnecessary words in the source codes.
#
# @see      https://github.com/nnstreamer/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-prohibited-words
function pr-prebuild-prohibited-words(){
    echo -e "########################################################################################"
    echo -e "[MODULE] ${BOT_NAME}/pr-prebuild-prohibited-words: Check if there are prohibited words in the text files."
    pwd

    # Check if a server administrator install required commands.
    check_cmd_dep git
    check_cmd_dep grep
    check_cmd_dep wc

    # Read file names that a contributor modified(e.g., added, moved, deleted, and updated) from a last commit.
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`

    # Inspect all files that contributor modifed.
    target_files=""
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
        # Handle only text files among files in one commit.
        echo -e "[DEBUG] file name is ( $i )."
        if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
            case $i in
                # Declare source code files to inspect a prohibited word
                *.c | *.h | *.cpp | *.hpp| *.py | *.sh | *.php | *.md )
                    echo -e "[DEBUG] ( $i ) file is a source code with a ASCII text format."
                    target_files="$target_files $i"
                    ;;
                * )
                    echo -e "[DEBUG] prohibited-words does not check ( $i ) file because it is not a source code file."
                    ;;
            esac
        fi
    done

    # Run a prohibited-words module in case that a PR includes text files.
    if [[ -n "${target_files/[ ]*\n/}" ]]; then
        echo -e "[DEBUG] The variable target_file is not empty or contains space characters."
        bad_words_sw="grep"
        bad_words_list="./config/prohibited-words.txt"
        if [[ ! -f $bad_words_list ]]; then
            echo -e "[DEBUG] Oooops. Not found $pword_list file."
        fi
        bad_words_rules="--color -n -r -H -f $bad_words_list"
        bad_words_log_file="prohibited-words_result.txt"

        # Step 1: Run this module to filter prohibited words from a text file.
        # (e.g., grep --color -f "$PROHIBITED_WORDS" $filename)
        $bad_words_sw $bad_words_rules $target_files > ../report/${bad_words_log_file}

        # Step 2: Display the execution result for debugging in case of a failure
        cat ../report/${bad_words_log_file}

        # Step 3: Count prohibited words from variable result_content
        result_count=$(cat ../report/${bad_word_log_file} | grep -c '^' )

        # Step 4: change a value of the check result
        if [[ $result_count -gt 0 ]]; then
            echo -e "Oooops. We found prohibited words: $result_count"
            check_result="failure"
        else
            echo -e "It's okay.We did not find any prohibited words: $result_count"
            check_result="success"
        fi
    else
        echo -e "[DEBUG] The variable target_file is empty."
        echo -e "[DEBUG] So, the variable chechk_result is declared with a 'skip' value."
        check_result="skip"
    fi

    # Report a check result as final step.
    if [[ $check_result == "success" ]]; then
        echo -e "[DEBUG] Passed. A prohibited words tool."
        message="Succeeded. A prohibited words checker is done successfully."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-prohibited-words" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    elif [[ $check_result == "skip" ]]; then
        echo -e "[DEBUG] Skipped. A prohibited words tool."
        message="Skipped. Your PR does not include a text file."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-prohibited-words" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    elif [[ $check_result == "failure" ]]; then
        echo -e "[DEBUG] Failed. A prohibited words tool."
        message="Failed. Your PR includes one of the prohibited words at least."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-prohibited-words" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    else
        echo -e "[DEBUG] Unexpected Error. A prohibited words tool."
        message="Oooops. It seems that a prohibited words checker has a bug."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-prohibited-words" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    fi

}
