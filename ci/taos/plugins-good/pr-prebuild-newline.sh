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
# @file pr-prebuild-newline.sh
# @brief Check if there is a newline issue in a text file
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-newline
function pr-prebuild-newline(){
    echo -e "########################################################################################"
    echo -e "[MODULE] ${BOT_NAME}/pr-prebuild-newline: Check the illegal newline handlings in text files"
    # Investigate generated all *.patch files
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    for current_file in ${FILELIST}; do
        # Handle only text files in case that there are lots of files in one commit.
        echo -e "[DEBUG] file name is ( $current_file )."

        # Initialize default values
	newline_count=0
	check_result="success"

        # If a file is "ASCII text" type, let's check a newline rule.
        if [[ `file $current_file | grep "ASCII text" | wc -l` -gt 0 ]]; then
            echo -e "[DEBUG] ( $current_file ) file is a text file (Type: ASCII text)."
            num=$(( $num + 1 ))
            # fetch patch content of a specified file from  a commit.
            echo -e "[DEBUG] git show $current_file > ../report/${num}.patch "
            git show $current_file > ../report/${num}.patch
            # check if the last line of a patch file includes "\ No newline....." statement.
            newline_count=$(cat ../report/${num}.patch  | tail -1 | grep '^\\ No newline' | wc -l)
            if  [[ $newline_count == 0 ]]; then
                echo -e "[DEBUG] Newline checker is passed. patch file name: $current_file. The number of newlines is $newline_count."
                check_result="success"

            elif  [[ $current_file =~ "$SKIP_CI_PATHS_FORMAT" ]]; then
                echo -e "[DEBUG] Newline checker skipped because a patch file $current_file is located in the $SKIP_CI_PATHS_FORMAT."
                echo -e "[DEBUG] The file size is $FILESIZE_NUM."
                check_result="success"
            else
                echo -e "[DEBUG] Newline checker is failed. patch file name: $current_file. The number of newlines is $newline_count."
                touch ../report/newline-error-${num}.patch
                echo -e " There are ${newline_count} '\ No newline ...' statements in the ${num}.patch file." > ../report/newline-error-${num}.patch
                check_result="failure"
                global_check_result="failure"
                break
            fi
        # If a file is not "ASCII text" type, the file will be skipped.
        else
            check_result="skip"
        fi
    done

    # get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
    i_filename=$(basename $current_file)

    if [[ $check_result == "success" ]]; then
        echo -e "[DEBUG] Passed. No newline anomaly."
        message="Successfully all text files are passed without newline issue."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-newline" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "skip" ]]; then
        echo -e "[DEBUG] Skipped. The file is not 'ASCII text' type."
        message="Skipped. The file is not 'ASCII text' type."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-newline" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo -e "[DEBUG] Failed. A newline anomaly happened."
        message="Oooops. New line checker is failed at $i_filename."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-newline" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

        # inform PR submitter of a hint in more detail
        message=":octocat: **cibot**: $user_id, The last line of a text file must have a newline character. Please append a new line at the end of the line in $current_file."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}
