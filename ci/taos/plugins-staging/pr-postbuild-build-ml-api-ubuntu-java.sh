#!/usr/bin/env bash

##
# Copyright (c) 2021 Samsung Electronics Co., Ltd. All Rights Reserved.
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
# @file     pr-postbuild-build-ml-api-ubuntu-java.sh
# @brief    build NNStreamer API library for Ubuntu
# @see      https://github.com/nnstreamer/TAOS-CI
# @see      https://github.com/nnstreamer/api
# @see      https://github.com/nnstreamer/nnstreamer
# @author   Gichan Jang <gichan2.jang@samsung.com>
# @note
#

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java-wait-queue
function pr-postbuild-build-ml-api-ubuntu-java-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java-ready-queue
function pr-postbuild-build-ml-api-ubuntu-java-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java-run-queue
function pr-postbuild-build-ml-api-ubuntu-java-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java: check build process for NNStreamer Java API library for Ubuntu"

    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Build a package
    result=0

    export ML_API_ROOT=$(pwd)
    # Set to use the same jdk with Android build.
    export JAVA_DIR=/opt/android-studio/jre

    echo -e "[DEBUG] ML_API_ROOT is $ML_API_ROOT"
    echo -e "[DEBUG] JAVA_DIR is $JAVA_DIR"

    # Start to build NNStreamer ML API for Ubuntu.
    echo "[DEBUG] Starting Build NNStreamer Java API library for Ubuntu."

    # Directory for build result
    result_dir=${dir_ci}/${dir_commit}/${PACK_BIN_FOLDER}/UBUNTU_JAVA
    mkdir -p $result_dir

    build_log=../report/build_log_${input_pr}_ubuntu_java_output.txt

    # Build NNStreamer Java API library
    bash $ML_API_ROOT/java/build-nnstreamer-ubuntu.sh --java_home=$JAVA_DIR --ml_api_dir=$ML_API_ROOT --result_dir=$result_dir >> $build_log
    result=$(($result+$?))

    echo "[DEBUG] The result value is '$result'."

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    # Report a test result
    echo -e "[DEBUG] The return value of the build is $result."
    # Let's check if build procedure is normally done.
    if [[ $result -eq 0 ]]; then
        echo -e "[DEBUG][PASSED] Successfully NNStreamer Java API library for Ubuntu build checker is passed. Return value is ($result)."
        check_result="success"
    else
        echo -e "[DEBUG][FAILED] Oooops!!!!!! NNStreamer Java API library for Ubuntu build checker is failed. Return value is ($result)."
        check_result="failure"
        global_check_result="failure"
    fi

    # Let's report build result of source code
    if [[ $check_result == "success" ]]; then
        message="NNStreamer Java API library for Ubuntu build Successful in $time_build_cost. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="NNStreamer Java API library for Ubuntu build Failure after $time_build_cost. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-postbuild-build-ml-api-ubuntu-java" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        export BUILD_TEST_FAIL=1
    fi
}
