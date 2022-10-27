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
# @file pr-postbuild-build-ml-api-android.sh
# @brief Build ML API android library
# @see      https://github.com/nnstreamer/TAOS-CI
# @see      https://github.com/nnstreamer/api
# @see      https://github.com/nnstreamer/nnstreamer
# @author   Yongjoo Ahn <yongjoo1.ahn@samsung.com>
# @note
#

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-android-wait-queue
function pr-postbuild-build-ml-api-android-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-android-ready-queue
function pr-postbuild-build-ml-api-android-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-android-run-queue
function pr-postbuild-build-ml-api-android-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-ml-api-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME}/pr-postbuild-build-ml-api-android: check build process for ML API android library with nnstreamer"

    # Set the path about Android build tools
    export ROOT_ANDROID_CI=/var/www/html/android

    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Build a package
    result=0

    # Build a package with the 'ndk-build' command.
    # Note that you have to set no-password condition after running 'visudo' command.
    # www-data    ALL=(ALL) NOPASSWD:ALL
    echo -e "[DEBUG] current folder is $(pwd)."

    export ML_API_ROOT=$(pwd)

    # NNStreamer root directory for build.
    # Clone from github repo
    git clone https://github.com/nnstreamer/nnstreamer.git nnstreamer-tmp
    export NNSTREAMER_ROOT=$(pwd)/nnstreamer-tmp

    # nnstreamer-edge root directory for build.
    git clone https://github.com/nnstreamer/nnstreamer-edge.git nnstreamer-edge-tmp

    echo -e "[DEBUG] ML_API_ROOT is $ML_API_ROOT"
    echo -e "[DEBUG] NNSTREAMER_ROOT is $NNSTREAMER_ROOT"
    echo -e "[DEBUG] NNSTREAMER_EDGE_ROOT is $NNSTREAMER_EDGE_ROOT"

    # Start to build NNStreamer ML API for Android.
    echo "[DEBUG] Starting gradle build for ML API android library."

    # Directory for build result
    android_result_dir=${dir_ci}/${dir_commit}/${PACK_BIN_FOLDER}/ANDROID
    mkdir -p $android_result_dir

    # Android SDK
    android_sdk=/var/www/ubuntu/Android/Sdk
    android_ndk=$ROOT_ANDROID_CI/android-ndk-r20b

    # GStreamer binaries
    gst_android_dir=$ROOT_ANDROID_CI/gstreamer-1.0-android-universal-1.16.2

    # Set build option
    common_option="--gstreamer_dir=$gst_android_dir --nnstreamer_dir=$NNSTREAMER_ROOT --nnstreamer_edge_dir=$NNSTREAMER_EDGE_ROOT --android_sdk_dir=$android_sdk --android_ndk_dir=$android_ndk --result_dir=$android_result_dir"

    api_build_log=../report/build_log_${input_pr}_android_api_output.txt

    # Build Android library
    bash $ML_API_ROOT/java/build-nnstreamer-android.sh $common_option --build_type=all >> $api_build_log
    result=$(($result+$?))

    bash $ML_API_ROOT/java/build-nnstreamer-android.sh $common_option --build_type=single >> $api_build_log
    result=$(($result+$?))

    echo "[DEBUG] The result value is '$result'."

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    # Report a test result
    echo -e "[DEBUG] The return value of ndk-build command is $result."
    # Let's check if build procedure is normally done.
    if [[ $result -eq 0 ]]; then
        echo -e "[DEBUG][PASSED] Successfully Android ML API library build checker is passed. Return value is ($result)."
        check_result="success"
    else
        echo -e "[DEBUG][FAILED] Oooops!!!!!! Android ML API library build checker is failed. Return value is ($result)."
        check_result="failure"
        global_check_result="failure"
    fi

    # Let's report build result of source code
    if [[ $check_result == "success" ]]; then
        message="ML_API-Android.build Successful in $time_build_cost. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-postbuild-build-ml-api-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="ML_API-Android.build Failure after $time_build_cost. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-postbuild-build-ml-api-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        export BUILD_TEST_FAIL=1
    fi

}
