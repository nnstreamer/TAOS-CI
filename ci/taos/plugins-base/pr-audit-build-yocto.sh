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
# @file pr-audit-build-yocto.sh
# @brief Build package with OpenEmbedded/devtool to verify a build validation on YOCTO platform
# @see      https://wiki.yoctoproject.org/wiki/Application_Development_with_Extensible_SDK
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @note
# $ sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib
# $ sudo apt-get -y install build-essential chrpath socat libsdl1.2-dev xterm
# Note that the devtool command is located in the Extensible SDK (eSDK). It means that you cannot install it with apt command.
#
# #### Case study: Poky eSDK (x86-i586)
# wget https://downloads.yoctoproject.org/tools/support/workflow/poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
# chmod +x ./poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
# ./poky-glibc-x86_64-core-image-minimal-i586-toolchain-ext-2.2.sh
# source /var/www/html/poky_sdk/environment-setup-i586-poky-linux
#
# #### Case study: Kairos  eSDK (x86-x64)
# $ wget http://10.113.136.32/download_qb/releases/Milestone/SR/RS7-SmartMachine/build/genericx86-64/latest/kairos-glibc-x86_64-smartmachine-jay-core2-64-toolchain-ext-1.0.sh
# chmod +x kairos-glibc-x86_64-smartmachine-*-toolchain-ext-1.0.sh
# ./kairos-glibc-x86_64-smartmachine-*-toolchain-ext-1.0.sh -d /var/www/kairos_sdk
# source /var/www/kairos_sdk/environment-setup-core2-64-smp-linux
#
# $ devtool add hello-world-sample git@github.com:nnsuite/hello-world-sample.git
# ($ devtool add hello-world-sample https://github.com/nnsuite/hello-world-sample.git)
# $ cd /var/www/kairos_sdk/workspace/sources/hello-world-sample/
# $ devtool edit-recipe hello-world-sample
# $ devtool build hello-world-sample
# $ devtool package hello-world-sample
# $ devtool reset hello-world-sample
#

# @brief [MODULE] TAOS/pr-audit-build-yocto-wait-queue
function pr-audit-build-yocto-wait-queue(){
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-yocto-ready-queue
function pr-audit-build-yocto-ready-queue(){
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-yocto-run-queue
function pr-audit-build-yocto-run-queue(){
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-audit-build-yocto: check build process for YOCTO distribution"

    # Note that you have to declare language set to avoid the execution error of "devtool add/build" command because
    # Python can not change the filesystem locale after loading so we need a UTF-8 when python starts or things won't work.
    # Use a locale setting which supports utf-8.
    # See https://github.com/openembedded/openembedded-core/blob/master/scripts/devtool#L212
    # See https://github.com/openembedded/bitbake/blob/master/bin/bitbake#L38
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en
    echo "[DEBUG] locale information: start ---------------------------------------------"
    locale
    echo "[DEBUG] locale information: end   ---------------------------------------------"

    # Import environment variables from eSDK to use devtool command
    if [[ "$YOCTO_ESDK_NAME" == "kairos_sdk" ]]; then
        echo "[DEBUG] source $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/environment-setup-core2-64-smp-linux"
        source $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/environment-setup-core2-64-smp-linux
    elif [[ "$YOCTO_ESDK_NAME" == "poky_sdk" ]]; then
        echo "[DEBUG] source $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/environment-setup-i586-poky-linux"
        source $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/environment-setup-i586-poky-linux
    else
        echo "[DEBUG] Oooops. The variable YOCTO_ESDK_NAME is empty."
        echo "[INFO ] Note that administrator of a server has to specify the location of eSDK at first"
    fi

    # Check if dependent packages are installed
    # The required packages are sudo, curl, and eYOCTO(devtool)
    if [[ $YOCTO_ESDK_NAME != "" ]]; then
        check_dependency sudo
        check_dependency curl
        check_dependency devtool
    fi

    echo "[DEBUG] env information: start ---------------------------------------------"
    env
    echo "[DEBUG] env information: end   ---------------------------------------------"

    echo "[DEBUG] starting TAOS/pr-audit-build-yocto facility"

    # BUILD_MODE=0 : run "gbs build" command without generating debugging information.
    # BUILD_MODE=1 : run "gbs build" command with a debug file.
    # BUILD_MODE=99: skip "gbs build" procedures
    BUILD_MODE=$BUILD_MODE_YOCTO

    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Build a package for Yocto
    if [[ $BUILD_MODE == 99 ]]; then
        # Skip a build procedure because BUILD_MODE is 99
        echo -e "[DEBUG] Skipping 'devtool' procedure temporarily because BUILD_MODE is 99."
        # '777' will be used for a fine-graind classification when the values of 'build_result' are increased.
        build_result=777
    elif [[ $YOCTO_ESDK_NAME == "" ]]; then
        # Skip a build procedure because YOCTO_ESDK_NAME is empty
        echo -e "[DEBUG] Skipping 'devtool' procedure temporarily because YOCTO_ESDK_NAME is empty."
        echo -e "[DEBUG] Ask administrator of a server to install Yocto eSDK."
        # '888' will be used for a fine-graind classification when the values of 'build_result' are increased.
        build_result=888
    else
        # Build a package with devtool. The devtool command requires root privilege.
        # Note that you have to set no-password condition after running 'visudo' command.
        # www-data    ALL=(ALL) NOPASSWD:ALL
        echo -e "[DEBUG] The current folder is $(pwd)."

        echo "[DEBUG] Checking $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/recipes/${PRJ_REPO_UPSTREAM}-${input_commit}"
        if [[ -d $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/recipes/${PRJ_REPO_UPSTREAM}-${input_commit} ]]; then
            echo "[DEBUG] devtool reset ${PRJ_REPO_UPSTREAM}-${input_commit}"
            devtool reset ${PRJ_REPO_UPSTREAM}-${input_commit} \
            2> ../report/build_log_${input_pr}_devtool_reset_yocto_error.txt 1> ../report/build_log_${input_pr}_devtool_reset_yocto_output.txt
            if [[ -d $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/sources/${PRJ_REPO_UPSTREAM}-${input_commit} ]]; then
                echo -e "[DEBUG] Removing $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/sources/${PRJ_REPO_UPSTREAM}-${input_commit} folder"
                echo -e "[DEBUG] rm -rf $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/sources/${PRJ_REPO_UPSTREAM}-${input_commit}"
                rm -rf $YOCTO_ESDK_DIR/${YOCTO_ESDK_NAME}/workspace/sources/${PRJ_REPO_UPSTREAM}-${input_commit}
                if [[ $? -ne 0 ]]; then
                    echo -e "[DEBUG][FAILED] Oooops!!!!!! the source folder is still not removed."
                else
                    echo -e "[DEBUG][PASSED] Okay. the source folder is successfully removed."
                fi
            fi
        fi
        # create unique recipe folder to handle lots of PRs that can be submitted at the same time
        check_dependency devtool
        id -a

        github_site="github.com"
        echo "[DEBUG] devtool add ${PRJ_REPO_UPSTREAM}-${input_commit} git@${github_site}:${GITHUB_ACCOUNT}/${PRJ_REPO_UPSTREAM}.git"
        devtool add ${PRJ_REPO_UPSTREAM}-${input_commit} git@${github_site}:${GITHUB_ACCOUNT}/${PRJ_REPO_UPSTREAM}.git \
        2> ../report/build_log_${input_pr}_devtool_add_yocto_error.txt 1> ../report/build_log_${input_pr}_devtool_add_yocto_output.txt
        echo "[DEBUG] The return value of 'devtool add' command is $?."

        echo -e "[DEBUG] starting 'devtool build' command."
        # @todo: Note that all recipes install dependant packages from the same local cache folder. It means that build process is not completely consistent.
        echo "[DEBUG] devtool build ${PRJ_REPO_UPSTREAM}-${input_commit} "
        devtool build ${PRJ_REPO_UPSTREAM}-${input_commit} \
        2> ../report/build_log_${input_pr}_devtool_build_yocto_error.txt 1> ../report/build_log_${input_pr}_devtool_build_yocto_output.txt
        build_result=$?
    fi

    echo "[DEBUG] The return value (build_result) of 'devtool build' command is $build_result."

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    # Report a build result of Yocto package
    # Let's do the build procedure of or skip the build procedure according to $BUILD_MODE
    if [[ $BUILD_MODE == 99 ]]; then
        # Do not run "devtool" command in order to skip unnecessary examination if there are no buildable files.
        echo -e "BUILD_MODE == 99"
        echo -e "[DEBUG] Let's skip the devtool procedure because BUILD_MODE of Yocto is 99."
        echo -e "[DEBUG] So, we stop remained all tasks at this time."

        message="Skipped devtool procedure. No buildable files found. Commit number is $input_commit."
        cibot_report $TOKEN "success" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        message="Skipped devtool procedure. Successfully all audit modules are passed. Commit number is $input_commit."
        cibot_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        echo -e "[DEBUG] devtool procedure is skipped - it is ready to review! :shipit: Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."
    elif [[ $YOCTO_ESDK_NAME == "" ]]; then
        # Do not run "devtool" command in order to skip unnecessary examination if there eSDK is not installed by administrator.
        echo -e "YOCTO_ESDK_NAME == ''"
        echo -e "[DEBUG] Let's skip the devtool procedure because eSDK is not installed by administrator."
        echo -e "[DEBUG] So, we stop remained all tasks at this time."

        message="Skipped devtool procedure. eSDK is not installed. Commit number is $input_commit."
        cibot_report $TOKEN "success" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        message="Skipped devtool procedure. Successfully all audit modules are passed. Commit number is $input_commit."
        cibot_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        echo -e "[DEBUG] devtool procedure is skipped - it is ready to review! :shipit: Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."
    else
        echo -e "BUILD_MODE != 99"
        echo -e "[DEBUG] The return value of devtool command is $build_result."
        # Let's check if build procedure is normally done.
        if [[ $build_result -eq 0 ]]; then
            echo -e "[DEBUG] Successfully YOCTO build checker is passed. Return value is ($build_result)."
            check_result="success"
        else
            echo -e "[DEBUG] Oooops!!!!!! YOCTO build checker is failed. Return value is ($build_result)."
            check_result="failure"
            global_check_result="failure"
        fi

        # Let's report build result of source code
        if [[ $check_result == "success" ]]; then
            message="Yocto.build Successful in $time_build_cost. Commit number is '$input_commit'."
            cibot_report $TOKEN "success" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
        else
            message="Yocto.build Failure after $time_build_cost. Commit number is $input_commit."
            cibot_report $TOKEN "failure" "TAOS/pr-audit-build-yocto" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

            export BUILD_TEST_FAIL=1
        fi
    fi

}
