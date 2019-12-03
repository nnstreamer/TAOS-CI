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
# @file pr-prebuild-exclusive-vio.sh
# @brief Check the issue #279 (VIO commits should be exclusive)
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Myungjoo Ham <myungjoo.ham@samsung.com>
#

##
# @brief [MODULE] ${BOT_NAME}/pr-prebuild-exclusive-vio
#
# Check issue #279. VIO commits should not touch non VIO files.
#
function pr-prebuild-exclusive-vio(){
    echo "##################################################################################################"
    echo "[DEBUG] Starting pr-prebuild-exclusive-vio function to investigate if a VIO commit is not exclusive."
    FILELIST=`git show --pretty="format:" --name-only`
    VIO_DIRECTORY="ROS/.*VIO/"
    CHECKVIO=0
    CHECKNONVIO=0
    for X in $FILELIST; do
        if [[ $X =~ ^$VIO_DIRECTORY ]]; then
            CHECKVIO=1
        else
            CHECKNONVIO=1
        fi
    done
    if [[ "$CHECKVIO" -eq 1 && "$CHECKNONVIO" -eq 1 ]]; then
        global_check_result="failure"
        echo "[DEBUG] Failed. A VIO commit is not exclusive."
        message="Oooops. This commit has VIO files and non-VIO files at the same time, violating issue #279."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-exclusive-vio" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Passed. No violation of issue #279."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-exclusive-vio" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi
}
