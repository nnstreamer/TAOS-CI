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
# @file pr-nnstreamer-apptest.sh
# @brief Check nnstreamer sample app working well.
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Sewon Oh <sewon.oh@samsung.com>

# @brief Set variable to run
export nnstreamer_apptest=1

# @brief [MODULE] TAOS/pr-nnstreamer-apptest-trigger-queue
function pr-nnstreamer-apptest-trigger-queue(){
    message="Trigger: queued. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-nnstreamer-apptest-trigger-run
function pr-nnstreamer-apptest-trigger-run(){
    echo "[DEBUG] Starting CI trigger to run nnstreamer sample app actually."
    message="Trigger: running. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-nnstreamer-apptest" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-nnstreamer-apptest
function pr-nnstreamer-apptest() {
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-nnstreamer-apptest: Starting sample app test"

    check_dependency cmake
    check_dependency make
    check_dependency python

    # Set-up environment variables.
    export NNST_ROOT="${dir_ci}/${dir_commit}/${PRJ_REPO_OWNER}"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NNST_ROOT/lib
    export GST_PLUGIN_PATH=$GST_PLUGIN_PATH:$NNST_ROOT/lib

    # build and install nnstreamer library
    cd ${NNST_ROOT}
    mkdir build
    cd build
    rm -rf *
    cmake -DCMAKE_INSTALL_PREFIX=${NNST_ROOT} \
    -DINCLUDE_INSTALL_DIR=${NNST_ROOT}/include \
    -DGST_INSTALL_DIR=${NNST_ROOT}/lib ..
    make install
    cd ..

    # Set-up testing environment.
    mkdir bin
    cp build/nnstreamer_example/example_filter/nnstreamer_example_filter bin/
    cp nnstreamer_example_filter/example_filter/nnstreamer_example_filter.py bin/
    cp build/nnstreamer_example/example_cam/nnstreamer_example_cam bin/
    cp build/nnstreamer_example/example_sink/nnstreamer_sink_example bin/
    cp build/nnstreamer_example/example_sink/nnstreamer_sink_example_play bin/
    rm -rf build
    cd bin

    # Download tensorflow-lite model file and labels.
    mkdir tflite_model; cd tflite_model
    wget https://github.com/nnsuite/testcases/tree/master/DeepLearningModels/tensorflow-lite/Mobilenet_1.0_224_quant/mobilenet_v1_1.0_224_quant.tflite
    tar xvzf ./mobilenet_v1_1.0_224_quant.tgz
    wget https://raw.githubusercontent.com/nnsuite/testcases/master/DeepLearningModels/tensorflow-lite/Mobilenet_1.0_224_quant/labels.txt
    cd ..

    # Test with sample apps
    # @todo Tests should be changed.
    ./nnstreamer_example_filter
    python nnstreamer_example_filter.py
    ./nnstreamer_example_cam
    ./nnstreamer_sink_example
    ./nnstreamer_sink_example_play
    
    result=$?

    if [[ ${result} -ne 0 ]]; then
        echo "[DEBUG][FAILED] Oooops!!!!!! apptest is failed. Please check the log file"
        echo ""
        check_result="failure"
        global_check_result="failure"
    else
        echo "[DEBUG][PASSED] Successfully apptest is passed."
        check_result="success"
    fi
    
    echo "report the execution result of apptest. check_result is ${check_result}. "
    if [[ $check_result == "success" ]]; then
        message="Successfully apptest is passed. Commit number is '$input_commit'."
        cibot_pr_report $TOKEN "success" "TAOS/pr-nnstreamer-apptest" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        message="Oooops. apptest is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-nnstreamer-apptest" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    
        # comment a hint on failed PR to author.
        message=":octocat: **cibot**: $user_id, apptest could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/checker-pr-audit.log"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi

}

