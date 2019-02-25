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
# wget https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
# wget https://dl.google.com/android/repository/android-ndk-r18b-linux-x86_64.zip
# vi ~/.bashrc
# # Android NDK
# export ANDROID_NDK=/var/www/html/android/android-ndk-r12b
# export PATH=$ANDROID_NDK:$PATH
#
# Step 2/2: Download prebuilt gst-android libraries
# You must copy your custom prebuilt gst-android files to the below folder.
# In case of ARM64 architecture, the folder has to be /var/www/html/android/gst_root_android/arm64.
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

    echo "source /etc/environment"
    source /etc/environment
    # Check if dependent packages are installed. Please add required packages here.
    check_dependency sudo
    check_dependency curl
    check_dependency ndk-build

    echo "[DEBUG] starting TAOS/pr-audit-build-android facility"

    # BUILD_MODE=0 : run "ndk-build" command without generating debugging information.
    # BUILD_MODE=1 : run "ndk-build" command with a debug file.
    # BUILD_MODE=99: skip "ndk-build" procedures
    BUILD_MODE=$BUILD_MODE_ANDROID

    # Build a package
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
        time ndk-build -j2 \
        2> ../report/build_log_${input_pr}_android_error.txt \
        1> ../report/build_log_${input_pr}_android_output.txt
        result=$?
        echo -e "[DEBUG] The ndk-build finished at $(date -R)"

        # If the binary files are generated, let's remove these files after archiving the files.
        android_files=(../out/)
        if [[ -d ${android_files[0]} ]]; then
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
            message="Successfully Android build checker is passed. Commit number is '$input_commit'."
            cibot_report $TOKEN "success" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
        else
            message="Oooops. Android build checker is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
            cibot_report $TOKEN "failure" "TAOS/pr-audit-build-android" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

            export BUILD_TEST_FAIL=1
        fi
    fi
 
}
