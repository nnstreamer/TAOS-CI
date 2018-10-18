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
# @file     pr-audit-nnstreamer-ubuntu-apptest.sh
# @brief    Check if nnstreamer sample apps normally work 
#           with a commit of a Pull Request (PR).
# @see      https://github.com/nnsuite/TAOS-CI
# @see      https://github.com/nnsuite/nnstreamer/wiki/usage-examples-screenshots
# @author   Sewon Oh <sewon.oh@samsung.com>
#
# Note: In order to run this module, A server administrator must add
# 'www-data' (user id of Apache webserver) into the video group (/etc/group) as follows.
# $ sudo usermod -a -G video www-data
#


# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-wait-queue
function pr-audit-nnstreamer-ubuntu-apptest-wait-queue(){
    echo -e "[DEBUG] Waiting CI trigger to run nnstreamer sample app actually."
    message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-ready-queue
function pr-audit-nnstreamer-ubuntu-apptest-ready-queue(){
    echo -e "[DEBUG] Readying CI trigger to run nnstreamer sample app actually."
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-nnstreamer-ubuntu-apptest-run-queue
function pr-audit-nnstreamer-ubuntu-apptest-run-queue() {
    echo -e "[DEBUG] Starting CI trigger to run nnstreamer sample app actually."
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    echo -e "########################################################################################"
    echo -e "[MODULE] TAOS/pr-nnstreamer-apptest: Starting sample app test"
    check_dependency cmake
    check_dependency make
    check_dependency wget
    check_dependency python
    check_dependency Xvnc
    check_dependency git
    check_dependency insmod
    check_dependency cat
    check_dependency grep
    check_dependency usermod

    # Set-up environment variables.
    export NNST_ROOT="${dir_ci}/${dir_commit}/${PRJ_REPO_OWNER}"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NNST_ROOT/lib
    export GST_PLUGIN_PATH=$GST_PLUGIN_PATH:$NNST_ROOT/lib
    echo -e "[DEBUG] NNST_ROOT is '$NNST_ROOT'"
    echo -e "[DEBUG] LD_LIBRARY_PATH is '$LD_LIBRARY_PATH'"
    echo -e "[DEBUG] GST_PLUGIN_PATH is '$GST_PLUGIN_PATH'"
    
    declare -i result=0

    # Build and install nnstreamer library
    pushd ${NNST_ROOT}
    if [[ -d ./build ]]; then
        rm -rf ./build/*
    else
        mkdir build
    fi
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=${NNST_ROOT} \
    -DINCLUDE_INSTALL_DIR=${NNST_ROOT}/include \
    -DGST_INSTALL_DIR=${NNST_ROOT}/lib ..
    make install
    cd ..

    # Set-up testing environment.
    mkdir bin
    cp build/nnstreamer_example/example_filter/nnstreamer_example_filter bin/
    cp nnstreamer_example/example_filter/nnstreamer_example_filter.py bin/
    cp build/nnstreamer_example/example_cam/nnstreamer_example_cam bin/
    cp build/nnstreamer_example/example_sink/nnstreamer_sink_example bin/
    cp build/nnstreamer_example/example_sink/nnstreamer_sink_example_play bin/
    rm -rf build
    cd bin    

    # Download tensorflow-lite model file and labels.
    mkdir tflite_model
    cd tflite_model
    echo -e "" >> ../../../report/nnstreamer-apptest-output.log
    echo -e "[DEBUG] Starting wget tflite model..." >> ../../../report/nnstreamer-apptest-output.log
    wget https://github.com/nnsuite/testcases/raw/master/DeepLearningModels/tensorflow-lite/Mobilenet_v1_1.0_224_quant/mobilenet_v1_1.0_224_quant.tflite 2>> ../../../report/nnstreamer-apptest-error.log 1>> ../../../report/nnstreamer-apptest-output.log
    result+=$?
    echo -e "" >> ../../../report/nnstreamer-apptest-output.log
    echo -e "[DEBUG] Starting wget tflite label..." >> ../../../report/nnstreamer-apptest-output.log
    wget https://raw.githubusercontent.com/nnsuite/testcases/master/DeepLearningModels/tensorflow-lite/Mobilenet_v1_1.0_224_quant/labels.txt 2>> ../../../report/nnstreamer-apptest-error.log 1>> ../../../report/nnstreamer-apptest-output.log
    result+=$?
    cd ..

    if [[ ${result} -ne 0 ]]; then
        echo -e "[DEBUG][FAILED] Oooops!!!!!! apptest is failed."
        echo -e "[DEBUG][FAILED] The data files was not downloaded. Please check the log file to get a hint"
        echo -e ""
        check_result="failure"
        global_check_result="failure"

        message="Oooops. apptest is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        # comment a hint on failed PR to author.
        message=":octocat: **cibot**: $user_id, apptest could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/checker-pr-audit.log"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

        return ${result}
    fi
    
    # Test with sample apps
    # - [RunTest] fake USB camera for NNStreamer video apps
    if [[ ! -f /dev/video0 ]]; then
        echo -e "[DEBUG] USB Camera device is not enabled. It is required by {nnstreamer_example_filter|nnstreamer_example_cam}."
        echo -e "[DEBUG] Enabling virtual cam camera..." 

        # Install a 'v4l2loopback' kernel module to use a virtual camera device
        # if it is not installed.
        if [[ ! -d ${REFERENCE_REPOSITORY}/v4l2loopback ]]; then
            echo -e "[DEBUG] Install virtual camera device..."
            pushd ${REFERENCE_REPOSITORY}
            git clone https://github.com/umlaeute/v4l2loopback.git
            popd
        fi        

        # Create virtual camera device and change authority for all.
        pushd ${REFERENCE_REPOSITORY}/v4l2loopback
        make clean && make
        # Dependency of kernel modules: media.ko --> videodev.ko --> v4l2loopback.ko
        sudo insmod /lib/modules/`uname -r`/kernel/drivers/media/media.ko
        sudo insmod /lib/modules/`uname -r`/kernel/drivers/media/v4l2-core/videodev.ko
        sudo insmod ./v4l2loopback.ko

        # Note that the server administrator must add 'www-data' (webapp id) account to 'video' group to access /dev/video*
        # Do not use '777' permission  to avoid a security vulnerability
        echo -e "[DEBUG] The group account 'video' includes the below user accounts:"
        cat /etc/group | grep video

        # Leave '${REFERENCE_REPOSITORY}/v4l2loopback' directory
        popd    
        
        # To avoid a conflict possiblity with existing vnc service ports(5900 ~ 5910),
        # run a vnc service with a port number more than 5911.
        Xvnc :11 &
        export DISPLAY=0.0:11
        
        # Produce sample video frames.
        gst-launch-1.0 videotestsrc ! v4l2sink device=/dev/video0 &
        producer_id=$!
    fi

    # Test that video image classification.
    # Testing while 2seconds. 2seconds is arbitrary.
    # and then kill process, otherwise, process run forever.
    echo -e "" >> ../../report/nnstreamer-apptest-error.log
    echo -e "[DEBUG] Starting nnstreamer_example_filter test..." >> ../../report/nnstreamer-apptest-error.log
    ./nnstreamer_example_filter 2>> ../../report/nnstreamer-apptest-error.log 1>> ../../report/nnstreamer-apptest-output.log & 
    pid=$!
    sleep 2
    kill ${pid}
    result+=$?

    # Same as above. Differencs is to run with python.
    echo -e "" >> ../../report/nnstreamer-apptest-error.log
    echo -e "[DEBUG] Starting nnstreamer_example_filter.py test..." >> ../../report/nnstreamer-apptest-error.log
    python nnstreamer_example_filter.py 2>> ../../report/nnstreamer-apptest-error.log 1>> ../../report/nnstreamer-apptest-output.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$?

    # Test that video mixer with nnstreamer plug-in
    # Testing while 2seconds. 2seconds is arbitrary.
    # and then kill process, otherwise, process run forever.
    echo -e "" >> ../../report/nnstreamer-apptest-error.log
    echo -e "[DEBUG] Starting nnstreamer_example_cam test..." >> ../../report/nnstreamer-apptest-error.log
    ./nnstreamer_example_cam 2>> ../../report/nnstreamer-apptest-error.log 1>> ../../report/nnstreamer-apptest-output.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$?

    # Test to convert video images to tensor.
    echo -e "" >> ../../report/nnstreamer-apptest-error.log
    echo -e "[DEBUG] Starting nnstreamer_sink_example test..." >> ../../report/nnstreamer-apptest-error.log
    ./nnstreamer_sink_example 2>> ../../report/nnstreamer-apptest-error.log 1>> ../../report/nnstreamer-apptest-output.log
    result+=$?
    
    # Test to convert video images to tensor, tensor buffer pass another pipeline,
    # and convert tensor to video images.
    # Testing while 2seconds. 2seconds is arbitrary.
    # and then kill process, otherwise, process run forever.
    echo -e "" >> ../../report/nnstreamer-apptest-error.log
    echo -e "[DEBUG] Starting nnstreamer_sink_example_play test..." >> ../../report/nnstreamer-apptest-error.log
    ./nnstreamer_sink_example_play 2>> ../../report/nnstreamer-apptest-error.log 1>> ../../report/nnstreamer-apptest-output.log &
    pid=$!
    sleep 2
    kill ${pid}
    result+=$?
    
    kill ${producer_id}

    popd

    if [[ ${result} -ne 0 ]]; then
        echo -e "[DEBUG][FAILED] Oooops!!!!!! apptest is failed. Resubmit the PR after fixing correctly."
        echo -e ""
        check_result="failure"
        global_check_result="failure"
    else
        echo -e "[DEBUG][PASSED] Successfully apptest is passed."
        check_result="success"
    fi
    
    echo -e "[DEBUG] report the execution result of apptest. result is ${result}. "
    if [[ $check_result == "success" ]]; then
        message="Successfully apptest is passed. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="Oooops. apptest is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "TAOS/pr-audit-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        # comment a hint on failed PR to author.
        message=":octocat: **cibot**: $user_id, apptest could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/checker-pr-audit.log"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}

