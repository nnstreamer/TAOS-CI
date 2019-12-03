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
# @file pr-prebuild-file-size.sh
# @brief    Check the file size to not include big binary files
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] ${BOT_NAME/}/pr-prebuild-file-size
function pr-prebuild-file-size(){
    echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME/}/pr-prebuild-file-size: Check the file size to not include big binary files"
    
    # investigate generated all *.patch files
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    
    for current_file in ${FILELIST}; do
        FILESIZE=$(stat -c%s "$current_file")
        echo "[DEBUG] current file name is ($current_file). file size is \"$FILESIZE\". "
        # Add thousands separator in a number
        FILESIZE_NUM=`echo $FILESIZE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
        # check the files in case that there are files that exceed 5MB.
        if  [[ $FILESIZE -le ${filesize_limit}*1024*1024 ]]; then
            echo "[DEBUG] Passed. patch file name: $current_file. value is $FILESIZE_NUM."
            check_result="success"
        elif  [[ $current_file =~ "$SKIP_CI_PATHS_FORMAT" ]]; then
            echo "[DEBUG] Skipped because a patch file $current_file is located in $SKIP_CI_PATHS_FORMAT."
            echo "[DEBUG] The file size is $FILESIZE_NUM."
            check_result="success"
        else
            echo "[DEBUG] Failed. patch file name: $current_file. value is $FILESIZE_NUM."
            check_result="failure"
            global_check_result="failure"
            break
        fi
    done
    
    
    # get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
    i_filename=$(basename $current_file)
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. File size."
        message="Successfully all files are passed without any issue of file size."
        cibot_report $TOKEN "success" "${BOT_NAME/}/pr-prebuild-filesize" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. File size."
        message="Oooops. File size checker is failed at $i_filename."
        cibot_report $TOKEN "failure" "${BOT_NAME/}/pr-prebuild-filesize" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        # inform PR submitter of a hint in more detail
        message=":octocat: **cibot**: '$user_id', Oooops. Note that you can not upload a big file that exceeds ${filesize_limit} Mbytes. The file name is ($current_file). The file size is \"$FILESIZE_NUM\". If you have to temporarily upload binary files unavoidably, please share this issue to all members after uploading the files in **/${SKIP_CI_PATHS_FORMAT}** folder."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi

}
