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
# @file     pr-prebuild-misspelling.sh
# @brief    Check a misspelled statement in a text document file with GNU Aspell
#
# GNU Aspell is a Free and Open Source spell checker designed to eventually replace Ispell.
# It can either be used as a library or as an independent spell checker. Its main feature
# is that it does a superior job of suggesting possible replacements for a misspelled word
# than just about any other spell checker out there for the English language. Unlike Ispell,
# Aspell can also easily check documents in UTF-8 without having to use a special dictionary.
#
# @see      http://aspell.net/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-prebuild-misspelling
function pr-prebuild-misspelling(){
echo "########################################################################################"
echo "[MODULE] TAOS/pr-prebuild-misspelling: Check a misspelled statement in a document file with GNU Aspell"

# Check if required commands are installed by server administrator
check_cmd_dep cat
check_cmd_dep aspell
check_cmd_dep file
check_cmd_dep grep
check_cmd_dep wc

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
        # in case of document file: *.md, *.txt)
        case $i in
            # in case of MarkDown(MD) and text file
            *.md | *.txt)
                echo "[DEBUG] ( $i ) file is a document file with a ASCII text format."
                typo_analysis_sw="aspell"
                typo_analysis_rules=" list -l en "
                typo_check_result="misspelling_result.txt"

                cat $i | $typo_analysis_sw $typo_analysis_rules > ../report/${typo_check_result}

                line_count=`cat ../report/${typo_check_result} | wc -l`
                # TODO: 9,000 is declared by heuristic method from our experiment.
                if  [[ $line_count -gt 9000 ]]; then
                    echo "[DEBUG] $typo_analysis_sw: failed. file name: $i, There are $line_count typo(s)."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $typo_analysis_sw: passed. file name: $i, There are $line_count typo(s)."
                    check_result="success"
                fi
                ;;
            * )
                echo "[DEBUG] ( $i ) file can not be checked by aspell (A spell checker) because it is not a document file."
                check_result="skip"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A spell check tool - aspell."
    message="Successfully source code(s) is written without a misspelled statement."
    cibot_report $TOKEN "success" "TAOS/pr-prebuild-misspelling" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message="**INFO:** You can read if there are misspelled characters at our misspelling check report. Please read ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${typo_check_result}."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. A spell check tool - aspell."
    message="Skipped. Your PR does not include document file(s) such as .txt and .md."
    cibot_report $TOKEN "success" "TAOS/pr-prebuild-misspelling" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

else
    echo "[DEBUG] Failed. A spell check tool - aspell."
    message="Oooops. spelling checker is failed. Please, read $typo_check_result for more details."
    cibot_report $TOKEN "failure" "TAOS/pr-prebuild-misspelling" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, It seems that **$i** includes typo(s). Please modify a misspelled statement before starting a review process."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

}
