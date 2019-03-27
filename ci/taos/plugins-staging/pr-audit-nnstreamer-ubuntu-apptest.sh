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
# @file    pr-audit-nnstreamer-ubuntu-apptest.sh
# @brief   Check if nnstreamer-based sample applications can be run.
#
# This module is to verify the run test if sample applications based on nnstreamer.
# Note that this module has to be executed in nnstreamer repository only.
# Whenever PR is submitted into the nnstreamer github repository, this module
# inspects if the PR generates unexpected execution issues to the existing example
# applications. This module only supports Ubuntu distribution. It means that
# the CI server has to be equipped with Ubuntu 16.04+ x86_64.
#
# @see     https://github.com/nnsuite/TAOS-CI
# @author  Geunsik Lim <geunsik.lim@samsung.com>
# @author  Sewon Oh <sewon.oh@samsung.com>
# @author  Jaeyun Jung <jy1210.jung@samsung.com>
#
# @note:   If you try to modify ths script, Do not forget that you also have to update the below wiki page.
#          https://github.com/nnsuite/nnstreamer/wiki/usage-examples-screenshots
#
# @note::  In order to run this module, A server administrator must add
#          'www-data' (user id of Apache webserver) into the video group (/etc/group) as follows.
#          $ sudo usermod -a -G video www-data
#

##
# @brief Caching the file after getting the specified files
#
# This function downloads a file from the specified URL at first.
# Then, it archives the files /tmp folder. It means that the download
# files are continually archived in /tmp folder until the server willbe rebooted.
# @param
#  arg1: FILENAME    The file name
#  arg2: URL         The web address to download a file
#  arg3: CACHE_PATH  The file path that the file is archived (=cached)
#  arg4: LINK_PATH   The symbolic link path
function func_get_file_cached(){
    echo -e "[DEBUG] ${1} ${2} ${3} ${4}"
    if [[ -f "${3}/${1}" ]]; then
        echo -e "[DEBUG] Caching the file, because the file was downloaded previously."
        ln -s ${3}/${1} ${4}/{1}
        result+=$?
    else
        echo -e "[DEBUG] Downloading the ${1} from the specified URL."
        wget -a wget.log ${2}/${1}
        mkdir -p ${3}
        cp ${4}/${1} ${3}
        result+=$?
    fi
}

# @brief function that append a log message to an appropriate log file via result($1)
# @param
# arg1: The return value of a command
function save_consumer_msg() {
     if [[ $1 -ne 0 ]]; then
        cat temp.log >> ../../report/nnstreamer-apptest-error.log
        echo "[DEBUG][FAIL] It's failed. Oooops. The consumer application is not executed." >> ../../report/nnstreamer-apptest-output.log
     else
        cat temp.log >> ../../report/nnstreamer-apptest-output.log
        echo "[DEBUG][PASS] It's okay. The consumer application is successfully completed." >> ../../report/nnstreamer-apptest-output.log
     fi
     echo "save_consumer_msg=$1"
}

# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-wait-queue
function pr-audit-nnstreamer-ubuntu-apptest-wait-queue(){
    echo -e "[DEBUG] Waiting CI trigger to run nnstreamer sample app actually."
    message="Trigger: wait queue. There are other build jobs and we need to wait for some minutes. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-ready-queue
function pr-audit-nnstreamer-ubuntu-apptest-ready-queue(){
    echo -e "[DEBUG] Readying CI trigger to run nnstreamer sample app actually."
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-run-queue
function pr-audit-nnstreamer-ubuntu-apptest-run-queue() {
    echo -e "[DEBUG] Starting CI trigger to run a sample app of nnstreamer actually."
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo -e "#######################################################################"
    echo -e "[MODULE] TAOS/pr-audit-nnstreamer-apptest: Starting a sample app test"
    echo -e "[DEBUG] Checking dependencies of required command..."
    check_dependency meson
    check_dependency ninja
    check_dependency wget
    check_dependency python
    check_dependency Xvnc
    check_dependency git
    check_dependency insmod
    check_dependency cat
    check_dependency grep
    check_dependency usermod
    check_dependency xauth
    check_dependency touch
    check_dependency awk
    check_dependency grep
    check_dependency ps

    ########## Step 1/6: Set-up environment variables.
    export NNST_ROOT="${dir_ci}/${dir_commit}/${PRJ_REPO_OWNER}"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NNST_ROOT/lib
    export GST_PLUGIN_PATH=$GST_PLUGIN_PATH:$NNST_ROOT/lib/gstreamer-1.0
    echo -e "[DEBUG] NNST_ROOT is '$NNST_ROOT'"
    echo -e "[DEBUG] LD_LIBRARY_PATH is '$LD_LIBRARY_PATH'"
    echo -e "[DEBUG] GST_PLUGIN_PATH is '$GST_PLUGIN_PATH'"

    # nnstreamer env variables and include paths
    export NNSTREAMER_CONF=$NNST_ROOT
    export NNSTREAMER_FILTERS=$NNST_ROOT/lib/nnstreamer/filters
    export NNSTREAMER_DECODERS=$NNST_ROOT/lib/nnstreamer/decoders
    export NNSTREAMER_CUSTOMFILTERS=$NNST_ROOT/lib/nnstreamer/customfilters
    export C_INCLUDE_PATH=$C_INCLUDE_PATH:$NNST_ROOT/include
    export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$NNST_ROOT/include

    declare -i result=0

    pushd ${NNST_ROOT}

    ########## Step 2/6: Build and install source codes.
    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Check if a 'build' folder already exists.
    if [[ -d ./build ]]; then
        rm -rf ./build/*
    else
        mkdir build
    fi

    # Build a source code of the nnstreamer repository
    meson --prefix=${NNST_ROOT} --sysconfdir=${NNST_ROOT} --libdir=lib --bindir=bin --includedir=include build

    # Install a nnstreamer library
    ninja -C build install

    # Clone the nnstreamer-example repository
    git clone https://github.com/nnsuite/nnstreamer-example.git example-tmp

    # Build and install nnstreamer examples
    cd example-tmp
    meson --prefix=${NNST_ROOT} --sysconfdir=${NNST_ROOT} --libdir=lib --bindir=bin --includedir=include build
    ninja -C build install
    cd ..

    # After installation, binary files are installed to 'bin' folder.
    rm -rf example-tmp
    rm -rf build
    cd bin

    ########## Step 3/6: Download a model and label file for Tensorflow-lite.
    mkdir tflite_model
    pushd tflite_model

    # Download a network model file from the github.com
    # For more details on /tmp/ folder, read /etc/default/rcS and /lib/systemd/system/systemd-tmpfiles-clean.service
    echo -e "" > wget.log
    echo -e "[DEBUG] Downloading 'tflite model' with wget command ..." >> wget.log

    func_get_file_cached \
    "mobilenet_v1_1.0_224_quant.tflite" \
    "https://github.com/nnsuite/testcases/raw/master/DeepLearningModels/tensorflow-lite/Mobilenet_v1_1.0_224_quant" \
    "/tmp/nnsuite/tflite_model" \
    "."

    # Download a label file from the github.com
    # For more details on /tmp folder, read /etc/default/rcS and /lib/systemd/system/systemd-tmpfiles-clean.service
    echo -e "" >> wget.log
    echo -e "[DEBUG] Downloading 'tflite label' with wget command ..." >> wget.log

    func_get_file_cached \
    "labels.txt" \
    "https://github.com/nnsuite/testcases/raw/master/DeepLearningModels/tensorflow-lite/Mobilenet_v1_1.0_224_quant" \
    "/tmp/nnsuite/tflite_model" \
    "."

    popd

    # Check if the files are normally downloaded
    if [[ ${result} -ne 0 ]]; then
        echo -e "[DEBUG][FAILED] Oooops!!!!!! apptest is failed."
        echo -e "[DEBUG][FAILED] The data files was not downloaded. Please check the log file to get a hint"
        echo -e ""

        check_result="failure"
        global_check_result="failure"
        cat tflite_model/wget.log >> ../../report/nnstreamer-apptest-error.log

        message="Oooops. apptest is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        # Comment a hint on failed PR to author.
        message=":octocat: **cibot**: $user_id, apptest could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/checker-pr-audit.log"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

        return ${result}
    fi

    cat tflite_model/wget.log >> ../../report/nnstreamer-apptest-output.log

    ########## Step 4/6: Install a fake USB camera device

    # Run a Xvnc service with a port number 6031 in order to avoid a conflict possibility
    # with existing Xvnc service ports(6000 ~ 6030),
    declare -i xvnc_port=31

    # Prepare a fake (=virtual) USB camera to run video applications.
    # Use '-e' option instead of '-f' because /dev/video0 file is a device file (without a normal file).
    if [[ ! -e /dev/video0 ]]; then
        echo -e "[DEBUG] An USB Camera device is not enabled. It is required by {nnstreamer_example_image_classification|nnstreamer_example_cam}."
        echo -e "[DEBUG] Enabling virtual cam camera..."

        # Install a 'v4l2loopback' kernel module to use a virtual camera device
        # if it is not installed.
        if [[ ! -d ${REFERENCE_REPOSITORY}/v4l2loopback ]]; then
            echo -e "[DEBUG] Install virtual camera device..."
            pushd ${REFERENCE_REPOSITORY}
            git clone https://github.com/umlaeute/v4l2loopback.git
            popd
        fi

        # Go to '${REFERENCE_REPOSITORY}/v4l2loopback' directory
        pushd ${REFERENCE_REPOSITORY}/v4l2loopback
        make clean && make

        # Load kernel modules to run a virtual camera device (e.g., /dev/video0).
        # The module dependencies: (1) media.ko --> (2) videodev.ko --> (3) v4l2loopback.ko
        sudo insmod /lib/modules/`uname -r`/kernel/drivers/media/media.ko
        sudo insmod /lib/modules/`uname -r`/kernel/drivers/media/v4l2-core/videodev.ko
        sudo insmod ./v4l2loopback.ko

        # Note that the server administrator must add a 'www-data' (for Apache)
        # into the 'video' group of /etc/group in order that 'www-data' accesses /dev/video*.
        # Please, do not specify a '777' permission to avoid a security vulnerability.
        echo -e "[DEBUG] The group 'video' has to include 'www-data' in the 'video' group."
        cat /etc/group | grep video

        # Leave '${REFERENCE_REPOSITORY}/v4l2loopback' directory
        popd

        # Establish the file newly unless ~/.Xauthority exists
        xauth_file=".Xauthority"
        if [[ -f ~/${xauth_file} ]]; then
            echo -e "[DEBUG][PASS] It's okay. ~/${xauth_file} exists."
        else
            echo -e "[DEBUG][FAIL] It's failed. We can not find ~/${xauth_file}."
            echo -e "[DEBUG] Initializing ~/${xauth_file} newly ..."
            touch ~/${xauth_file}
        fi


        # Kill the Xvnc service if (1)/dev/video0 file does not exist and (2)port 6031 is still opened.
        declare -i xvnc_pid=0
        xvnc_pid=$(ps -A -o pid,cmd | grep "[\:]${xvnc_port}" | awk '{printf $1}')
        if [[ $xvnc_pid -ne 0 ]]; then
            echo -e "[DEBUG] It seems that the network port of the existing Xvnc is not stopped."
            echo -e "[DEBUG] Killing the existing Xvnc (PID: $xvnc_pid) ...."
            kill $xvnc_pid
        fi

        # The VNCserver listens on three ports: 5800 (for VNCweb), 5900 (for VNC), and 6000 (for Xvnc)
        Xvnc :${xvnc_port} &
        export DISPLAY=0.0:${xvnc_port}

    fi

    ########## Step 5/6: Test sample applications (Based on a producer and consumer model)

    # Our test scenario to evaluate sample applications, is as following:
    #  a. Run an appliction while 2 seconds arbitrarily in virtual network environment.
    #  b. Kill a process after 2 seconds. Otherwise, the process runs forever.

    # App (Producer): Make a producer with a 'videotestsrc' plugin and /dev/video0 (fake USB camera)
    # The dependency: /dev/video0, VNC
    export DISPLAY=0.0:${xvnc_port}
    declare -i producer_id=0

    echo -e "[DEBUG] App (Producer): Starting 'gst-launch-1.0 videotestsrc ! v4l2sink device=/dev/video0' test on the VNC environment..."  >> ../../report/nnstreamer-apptest-output.log
    gst-launch-1.0 videotestsrc ! v4l2sink device=/dev/video0 &
    producer_id=$!

    if [[ $producer_id -ne 0 ]]; then
        echo -e "[DEBUG] It's okay. The producer (pid: ${producer_id}) is successfully started."
    else
        echo -e "[DEBUG] It's failed. The producer (pid: ${producer_id}) is not established."
    fi

    # Display a current locale setting.
    echo -e "[DEBUG] -------------------- locale: start --------------------"
    locale
    echo -e "[DEBUG] -------------------- locale: end --------------------"

    # Display a port status to check a port that VNC and Xvnc has opened.
    echo -e "[DEBUG] -------------------- netstat(Xvnc:59xx): start --------------------"
    netstat -natp | grep [^]]:59
    echo -e "[DEBUG] -------------------- netstat(Xvnc:59xx): end   --------------------"
    echo -e "[DEBUG] -------------------- netstat(Xvnc:60xx): start --------------------"
    netstat -natp | grep [^]]:60
    echo -e "[DEBUG] -------------------- netstat(Xvnc:60xx): end   --------------------"

    # Display an environment setting status that is set by Apache/www-data.
    echo -e "[DEBUG] -------------------- env: start ------------------------"
    env
    echo -e "[DEBUG] -------------------- env: end   ------------------------"

    # Display a listing of the .Xauthority file, enter the following.
    echo -e "[DEBUG] -------------------- xauth: start ----------------------"
    xauth list
    echo -e "[DEBUG] -------------------- xauth: end   ----------------------"


    # App (Consumer 1): Test /dev/video0 status with gst-lanch-1.0 command
    # The dependency: /dev/video0, VNC
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer1): Starting 'gst-launch-1.0 v4l2src device=/dev/video0 ! videoconvert ! ximagesink' test on the Xvnc environment..." >> temp.log
    gst-launch-1.0 v4l2src device=/dev/video0 ! videoconvert ! ximagesink &>> temp.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$(save_consumer_msg $?)

    # App (Consumer 2): ./nnstreamer_example_image_classification for a video image classification.
    # The dependency: /dev/video0, VNC
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer2): Starting nnstreamer_example_image_classification test..." >> temp.log
    ./nnstreamer_example_image_classification &>> temp.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$(save_consumer_msg $?)

    # App (Consumer 3): ./nnstreamer_example_image_classification.py for a video image classification.
    # Same as above. The difference is that it just runs with python.
    # The dependency: /dev/video0, VNC
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer3): Starting nnstreamer_example_image_classification.py test..." >> temp.log
    python nnstreamer_example_image_classification.py &>> temp.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$(save_consumer_msg $?)

    # App (Consumer 4): ./nnstreamer_example_cam to test a video mixer with nnstreamer plug-in.
    # The dependency: /dev/video0, VNC
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer4): Starting nnstreamer_example_cam test..." >> temp.log
    ./nnstreamer_example_cam &>> temp.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$(save_consumer_msg $?)

    # App (Consumer 5): ./nnstreamer_sink_example to convert video images to tensor.
    # The dependency: Nothing
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer5): Starting nnstreamer_sink_example test..." >> temp.log
    ./nnstreamer_sink_example &>> temp.log
    result+=$(save_consumer_msg $?)

    # App (Consumer 6): ./nnstreamer_sink_example_play to convert video images to tensor,
    # tensor buffer pass another pipeline, and convert tensor to video images.
    # The dependency: VNC
    echo -e "" > temp.log
    echo -e "[DEBUG] App (Consumer6): Starting nnstreamer_sink_example_play test..." >> temp.log
    ./nnstreamer_sink_example_play &>> temp.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$(save_consumer_msg $?)

    # Let's stop the existing producer ID when all test applications (=consumers) are tested.
    kill ${producer_id}

    popd

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"

    ########## Step 6/6: Report a execution result

    # Summarize a test result before doing final report.
    if [[ ${result} -ne 0 ]]; then
        echo -e "[DEBUG][FAILED] Oooops!!!!!! apptest is failed after $time_build_cost."
        echo -e ""
        check_result="failure"
        global_check_result="failure"
    else
        echo -e "[DEBUG][PASSED] Successfully apptest is passed in $time_build_cost."
        check_result="success"
    fi

    # Report a test result as a final step.
    echo -e "[DEBUG] report the execution result of apptest. The result value is ${result}. "
    if [[ $check_result == "success" ]]; then
        # Report a success.
        message="Ubuntu.apptest Successful in $time_build_cost. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        # Report a failure.
        message="Oooops. apptest is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        # comment a hint why a submitted PR is failed.
        message=":octocat: **cibot**: $user_id, apptest could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/checker-pr-audit.log"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}

