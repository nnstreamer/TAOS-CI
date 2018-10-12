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
# @file     pr-format-sloccount.sh
# @brief    Count physical source lines of code (SLOC)
#
# It is a set of tools for counting physical Source Lines of Code (SLOC) in a large
# number of languages of a potentially large set of programs.
#
# @see      https://packages.ubuntu.com/search?keywords=sloccount
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-sloccount
function pr-format-sloccount(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-sloccount: Count physical source lines of code (SLOC)"
    pwd

    # Check if server administrator install required commands
    check_dependency sloccount
    check_dependency git
    check_dependency file
    check_dependency mkdir
    check_dependency grep

    # Read file names that a contributor modified(e.g., added, moved, deleted, and updated) from a last commit.
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`

    # Inspect all files that contributor modifed.
    for i in ${FILELIST}; do
        # default value of check_result is "skip".
        check_result="skip"

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
            # Run a SLOCCount module in case that a PR includes source codes.
            case $i in
                *.c | *.cpp | *.py | *.sh | *.php )
                    echo "[DEBUG] ( $i ) file is a source code with a ASCII text format."
                    sloc_analysis_sw="sloccount"
                    sloc_data_folder="~/.slocdata"
                    if [[ ! -d $sloc_data_folder ]]; then
                        mkdir -p $sloc_data_folder
                    fi
                    sloc_analysis_rules="--wide --multiproject --datadir $sloc_data_folder"
                    sloc_target_dir=${SRC_PATH}
                    sloc_check_result="sloccount_result.txt"

                    # Run this module
                    $sloc_analysis_sw $sloc_analysis_rules $sloc_target_dir > ../report/${sloc_check_result}
                    run_result=$?
                    if [[ $run_result -eq 0 ]]; then
                        check_result="success"
                    else
                        check_result="failure"
                    fi
                    # Exit from 'for' loop statement to run just once when a commit includes lots of source code files.
                    break
                    ;;
                * )
                    echo "[DEBUG] SLOCCount does not check ( $i ) file because it is not a source code."
                    check_result="skip"
                    ;;
            esac
        fi
    done

    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A sloc check tool - sloccount."
        message="Successfully source code(s) is analyzed by sloccount command."
        cibot_report $TOKEN "success" "TAOS/pr-format-sloccount" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    elif [[ $check_result == "skip" ]]; then
        echo "[DEBUG] Skipped. A sloc check tool - sloccount."
        message="Skipped. Your PR does not include source codes."
        cibot_report $TOKEN "success" "TAOS/pr-format-sloccount" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    else
        echo "[DEBUG] Failed. A sloc check tool - sloccount."
        message="Oooops. sloccount checker is failed because the check_result is not either 'success' or 'skip'."
        cibot_report $TOKEN "failure" "TAOS/pr-format-sloccount" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    fi

}
