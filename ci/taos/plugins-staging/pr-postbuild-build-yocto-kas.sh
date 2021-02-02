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
# @file pr-postbuild-build-yocto-kas.sh
# @brief Build Yocto image with python module kas to verify yocto meta-layer
# @see      https://github.com/nnstreamer/TAOS-CI
# @author   Yongjoo Ahn <yongjoo1.ahn@samusng.com>
# @note
# $ sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib
# $ sudo apt-get -y install build-essential chrpath socat libsdl1.2-dev xterm
# $ sudo pip3 install kas
#

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-yocto-kas-wait-queue
function pr-postbuild-build-yocto-kas-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-yocto-kas" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-yocto-kas-ready-queue
function pr-postbuild-build-yocto-kas-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-yocto-kas" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] ${BOT_NAME}/pr-postbuild-build-yocto-kas-run-queue
function pr-postbuild-build-yocto-kas-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-build-yocto-kas" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "########################################################################################"
    echo "[MODULE] ${BOT_NAME}/pr-postbuild-build-yocto-kas: check build process for yocto image creation with kas"

    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    build_result=0

    # Note that you have to set no-password condition after running 'visudo' command.
    # www-data    ALL=(ALL) NOPASSWD:ALL
    source_dir=$(pwd)
    mkdir -p ./kas-build
    pushd ./kas-build

    # Copy pre-defined kas yml files from config directory
    cp ../../../../../taos/config/kas-files/*.yml ./

    # Replace layer url to current source directory
    sed -i "s|PATH_WILL_BE_REPLACED_BY_CI|${source_dir}|" *.yml

    # Do yocto build
    python3 -m kas build $(ls -xm --width=10000 | sed "s|,\ |:|g") 2> ../../report/build_log_${input_pr}_yocto_kas_log.txt 1> ../../report/build_log_${input_pr}_yocto_kas_aux.txt

    build_result=$?

    # Remove build results (It is about a few Giga Bytes)
    rm -rf ./build/tmp/
    popd

    echo "[DEBUG] The return value (build_result) of kas build command is $build_result."

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    # Report build result
    if [[ $build_result -eq 0 ]]; then
        echo -e "[DEBUG] Successfully yocto-kas build checker is passed. Return value is ($build_result)."
        check_result="success"
    else
        echo -e "[DEBUG] Oooops!!!!!! yocto-kas build checker is failed. Return value is ($build_result)."
        check_result="failure"
        global_check_result="failure"
    fi

    # Let's report build result of source code
    if [[ $check_result == "success" ]]; then
        message="yocto-kas.build Successful in $time_build_cost. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-postbuild-build-yocto-kas" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="yocto-kas.build Failure after $time_build_cost. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-postbuild-build-yocto-kas" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        export BUILD_TEST_FAIL=1
    fi

}
