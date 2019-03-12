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
# @file pr-audit-build-android.sh
# @brief Build a native C/C++ source code with ndk-build command to support Android.
#
# This module builds C/C++ source code with the ndk-build command of Android
# in order to inspect a compiliation of C/C++ source code on Android platform
#
# @see      https://developer.android.com/ndk
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @note
# Note that the ndk-build command is located in the Android NDK toolkit.
# It means that you cannot install it with apt command.
#
# @note
# CI administrator has to execute this instruction as a mandatory obligation
# to enable this module in order that this CI module compile the nnstreamer
# source code on Ubuntu 16.04
#
# Prerequisites
# Step 1/2: Download Android NDK r12b to use ndk-build command
# mkdir -p /var/www/html/android/
# cd /var/www/html/android/
# wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
# vi ~/.bashrc
# # Android NDK
# export ANDROID_NDK=/var/www/html/android/android-ndk-r12b
# export PATH=$ANDROID_NDK:$PATH
#
# Step 2/2: Download prebuilt gst-android libraries
# You must copy your custom prebuilt gst-android files to the below folder.
# For arm64, /var/www/html/android/gst_root_android/arm64/ directory.
#
# mkdir -p /var/www/html/android/gst_root_android/arm64/
# cd /var/www/html/android/gst_root_android/arm64/
# wget http://nnsuite.mooo.com/warehouse/gstreamer-prebuilts-for-android-device/gst_root_android-custom-1.12.4-ndkr12b-20190213-0900/gstreamer-1.0-android-arm64-1.12.4-runtime.tar.bz2
# wget http://nnsuite.mooo.com/warehouse/gstreamer-prebuilts-for-android-device/gst_root_android-custom-1.12.4-ndkr12b-20190213-0900/gstreamer-1.0-android-arm64-1.12.4.tar.bz2
# tar xjf gstreamer-1.0-android-arm64-1.12.4-runtime.tar.bz2
# tar xjf gstreamer-1.0-android-arm64-1.12.4.tar.bz2
#
# vi ~/.bashrc
# # gst-android prebuilt binary (e.g., .a, .so, .h)
# export GSTREAMER_ROOT_ANDROID=/var/www/html/android/gst_root_android/
#

# @brief [MODULE] TAOS/pr-audit-build-android-wait-queue
function pr-audit-build-android-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-android-ready-queue
function pr-audit-build-android-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-android-run-queue
function pr-audit-build-android-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-audit-build-android: check a build process for Android platform"

    echo "Running 'source /etc/environment'"
    source /etc/environment

    # Android NDK
    export ANDROID_NDK=/var/www/html/android/android-ndk-r12b
    export PATH=$ANDROID_NDK:$PATH
    echo "Exporting an ANDROID_NDK path ..."
    echo $PATH
    ndk-build --help

    # gst-android prebuilt binary (e.g., .a, .so, .h)
    export GSTREAMER_ROOT_ANDROID=/var/www/html/android/gst_root_android/
    echo "Exporting a GSTREMER_ROOT_ANDROID path..."
    echo $GSTREAMER_ROOT_ANDROID

    # Check if dependent packages are installed. Please add required packages here.
    check_dependency sudo
    check_dependency curl
    check_dependency ndk-build

    echo "[DEBUG] starting TAOS/pr-audit-build-android facility"

    # BUILD_MODE=0 : run "ndk-build" command without generating debugging information.
    # BUILD_MODE=1 : run "ndk-build" command with a debug file.
    # BUILD_MODE=99: skip "ndk-build" procedures
    BUILD_MODE=$BUILD_MODE_ANDROID

    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Build a package
    result=0
    if [[ $BUILD_MODE == 99 ]]; then
        # Skip a build procedure
        echo -e "BUILD_MODE = 99"
        echo -e "Skipping the 'ndk-build' procedure temporarily."
        $result=999
    else
        # Build a package with the 'ndk-build' command.
        # Note that you have to set no-password condition after running 'visudo' command.
        # www-data    ALL=(ALL) NOPASSWD:ALL
        echo -e "[DEBUG] current folder is $(pwd)."

        # Options:
        # a. TODO: A trigger option is to be used as PR number and PR time (a trick)
        #          to support Out-of-PR (OOP) killer.
        # b. TODO: If you meet a privilege issue, you need to execute a local test with
        #          "sudo -Hu www-data ndk-build" statement.
        echo -e "[DEBUG] Starting 'ndk-build ...' command."
        echo -e "[DEBUG] The ndk-build starts at $(date -R)"
        echo -e "[DEBUG] The current directory: $(pwd)."
        pushd ./jni/
        # Build a nnstreamer library (e.g., libnnstreamer.so)
        echo -e "[DEBUG] Compiling  a nnstreamer library: $(pwd)."
        rm -f $GSTREAMER_ROOT_ANDROID/arm64/lib/gstreamer-1.0/libnnstreamer.so
        echo -e "time ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android-nnstreamer.mk NDK_APPLICATION_MK=./Application.mk -j$(nproc)"
        time ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android-nnstreamer.mk NDK_APPLICATION_MK=./Application.mk -j$(nproc) \
        2> ../../report/build_log_${input_pr}_android_error.txt \
        1> ../../report/build_log_${input_pr}_android_output.txt
        result=$(($result+$?))
        cp ./libs/arm64-v8a/libnnstreamer.so $GSTREAMER_ROOT_ANDROID/arm64/lib/gstreamer-1.0/
        # Build a test application
        echo -e "[DEBUG] Compiling  a nnstreamer-based application: $(pwd)."
        echo -e "time ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android-app.mk NDK_APPLICATION_MK=./Application.mk -j$(nproc)"
        time ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android-app.mk NDK_APPLICATION_MK=./Application.mk -j$(nproc) \
        2>> ../../report/build_log_${input_pr}_android_error.txt \
        1>> ../../report/build_log_${input_pr}_android_output.txt
        result=$(($result+$?))
        ls -al ./libs/arm64-v8a/

        echo -e "[DEBUG] The ndk-build finished at $(date -R)"

        # If the binary files are generated, let's remove these files after archiving the files.
        android_dirs=(../out/)
        if [[ -d ${android_dirs[0]} ]]; then
            echo "Archiving generated Android binary files..."
            mkdir -p ../$PACK_BIN_FOLDER/ANDROID
            sudo mv ../out ../$PACK_BIN_FOLDER/ANDROID/
            echo "Removing unnecessary Android binary files..."
            sudo rm -rf ../obj
            if [[ $? -ne 0 ]]; then
                echo "[DEBUG][FAILED] Android/ndk-build: Oooops!!!!! Unnecessary files are not removed."
            else
                echo "[DEBUG][PASSED] Android/ndk-build: It is okay. Unnecessary files are successfully removed."
            fi
        fi
        popd
        echo -e "[DEBUG] The current directory: $(pwd)."

    fi
    echo "[DEBUG] The result value is '$result'."

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    # Report a test result
    # Let's run the build procedure. Or skip the build procedure according to $BUILD_MODE.
    if [[ $BUILD_MODE == 99 ]]; then
        # Do not run "ndk-build" command in order to skip unnecessary examination if there are no buildable files.
        echo -e "BUILD_MODE == 99"
        echo -e "[DEBUG] Let's skip the ndk-build procedure. All files may be skipped."
        echo -e "[DEBUG] So, we stop remained all tasks at this time."

        message="Skipped the ndk-build procedure. No buildable files found. Commit number is $input_commit."
        cibot_report $TOKEN "success" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        message="Skipped the ndk-build procedure. Successfully all audit modules are passed. Commit number is $input_commit."
        cibot_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        echo -e "[DEBUG] The ndk-build procedure is skipped - it is ready to review! :shipit: Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."
    else
        echo -e "BUILD_MODE != 99"
        echo -e "[DEBUG] The return value of ndk-build command is $result."
        # Let's check if build procedure is normally done.
        if [[ $result -eq 0 ]]; then
                echo -e "[DEBUG][PASSED] Successfully Android C/C++ JNI build checker is passed. Return value is ($result)."
                check_result="success"
        else
                echo -e "[DEBUG][FAILED] Oooops!!!!!! Android C/C++ JNI build checker is failed. Return value is ($result)."
                check_result="failure"
                global_check_result="failure"
        fi

        # Let's report build result of source code
        if [[ $check_result == "success" ]]; then
            message="Android.build Successful in $time_build_cost. Commit number is '$input_commit'."
            cibot_report $TOKEN "success" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
        else
            message="Android.build Failure after $time_build_cost. Resubmit the PR after fixing correctly. Commit number is $input_commit."
            cibot_report $TOKEN "failure" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

            export BUILD_TEST_FAIL=1
        fi
    fi
 
}
