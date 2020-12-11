#!/usr/bin/env bash

##
# Copyright (c) 2020 Samsung Electronics Co., Ltd. All Rights Reserved.
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
# @file    pr-postbuild-bazel-ubuntu.sh
# @brief   Check if Bazel executes a build-test and a run-test on Ubuntu
#          distribution (x86_64)
#
# @see     https://github.com/nnsuite/TAOS-CI
# @author  Geunsik Lim <geunsik.lim@samsung.com>
#
#


##
# @brief [MODULE] ${BOT_NAME}/pr-postbuild-bazel-ubuntu-wait-queue
function pr-postbuild-bazel-ubuntu-wait-queue() {
    echo -e "[DEBUG] Waiting CI trigger to run a bazel-based app actually."
    message="Trigger: wait queue. There are other build jobs and we need to wait for some minutes. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-bazel-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

##
# @brief [MODULE] ${BOT_NAME}/pr-postbuild-bazel-ubuntu-ready-queue
function pr-postbuild-bazel-ubuntu-ready-queue() {
    echo -e "[DEBUG] Readying CI trigger to run a bazel-based app actually."
    message="Trigger: ready queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-bazel-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

##
# @brief [MODULE] ${BOT_NAME}/pr-postbuild-bazel-ubuntu-run-queue
function pr-postbuild-bazel-ubuntu-run-queue() {
    echo -e "[DEBUG] Starting CI trigger to run a bazel-based app actually."
    message="Trigger: run queue. The commit number is $input_commit."
    cibot_report $TOKEN "pending" "${BOT_NAME}/pr-postbuild-bazel-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en
    echo "[DEBUG] locale information: start ---------------------------------------------"
    locale
    echo "[DEBUG] locale information: end   ---------------------------------------------"

    echo -e "#######################################################################"
    echo -e "[MODULE] ${BOT_NAME}/pr-postbuild-bazel-ubuntu: Starting ..."
    echo -e "[DEBUG] Checking dependencies of required command..."
    check_cmd_dep bazel
    check_cmd_dep git
    check_cmd_dep curl
    check_cmd_dep grep
    check_cmd_dep ps
    check_cmd_dep tail
    check_cmd_dep dot

    ########## Step 1/4: Set-up environment variables.
    declare -i result=0

    # [User Area] Define an each statement to download, build, and run source files.
    START_DOWNLOAD="git clone https://github.com/{your_account}/{download_repo}.git temp_repo"
    START_BUILDTEST="bazel build --cxxopt='-std=c++11' //src/main:your_test"
    START_RUNTEST="time ./bazel-bin/src/main/your_test | tee result.txt"
    TARGET_FOLDER="subdir/module/core"

    # setup Bazel build environment
    if [[ $(which bazel) -ne 0 ]]; then
        echo -e "Installing the Bazel package ..."
        sudo apt install curl gnupg
        curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
        sudo apt update -y
        echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
        sudo apt update && sudo apt install bazel
    fi

    ########## Step 2/4: Build source codes.
    # Put a timer in front of the build job to check a start time.
    time_start=$(date +"%s")

    # Check if a 'build' folder already exists.
    pushd $TARGET_FOLDER
    bazel --version
    bazel clean

    # Download pre-built files. If you need, you may modify the below statements
    if [[ ! -d ./third_party/lib ]]; then
        pwd
        echo -e "Oooops. ./third_party/lib/ folder does not exist."
        echo -e "Starting git clone command to download ./third_party/lib/ ...."
        echo -e "statement (download): $START_DOWNLOAD"
        eval $START_DOWNLOAD
        $result=$? 
        echo -e "[DEBUG] The result value of the download task is $result"
        if [[ $result -ne 0 ]]; then
            echo -e "[DEBUG] The download task is failed."
        fi
        cp -arfp temp_repo/third_party/* ./third_party/
        ln -s    temp_repo/RNNTModel     ./RNNTModel
    else
        echo -e "It's okay. ./third_party/lib folder does exist."
        pwd
    fi

    # Build a source code of the nnstreamer repository
    echo -e "Starting a buile task with bazel command ..."
    pwd
    echo -e "statement (build): $START_BUILDTEST"
    eval $START_BUILDTEST
    result=$?
    echo -e "[DEBUG] The result value of the build-test is $result"
    if [[ $result -ne 0 ]]; then
        echo -e "[DEBUG] The build test is failed."
    fi

    ########## Step 3/4: Execute a run-test

    # TODO: Fix to me. Describe a statement that you want to evaluate
    eval_data="음성파일입니다"

    # The number of test for repeated tests. To skip a run-test, specify "loop_num=0".
    loop_num=1
    
    if [[ $loop_num -ge 1 && $result -eq 0 ]]; then
        # Run an aging test to verify if the output result is correct or not.
        for (( count=1; count<=$loop_num; count++ )) ; do
            echo -e "------ Trying to do a run-test [$count/$loop_num] ------"
            pwd
            # Do a run-test
            time ls -al
            echo -e "statement (run): $START_RUNTEST"
            echo -e "## Expected result: '$eval_data'"
            echo -e "## Actual   result:"
            exec_start=$(date +"%s")
            date
            eval $START_RUNTEST
            result+=$?
            date
            exec_end=$(date +"%s")
            exec_diff=$(($exec_end-$exec_start))
            exec_cost="$(($exec_diff / 60))m $(($exec_diff % 60))s"

            echo -e "[DEBUG] Execution time: $exec_cost secs"
            echo -e "[DEBUG] The result value of the run-test is $result"
    
            if [[ "$(tail -n1 ./result.txt)" =~ "$eval_data" ]]; then
                echo -e "## PASSED. The execution result is correct. ##"
                result=0
            else
                echo -e "## FAILED. The execution result is incorrect. ##"
                result=1
            fi
        done
    else
        echo -e "###### Skipping a run-test [$count/$loop_num] ... ######"
    fi

    # Generate code flow graph
    (bazel query --notool_deps \
    --noimplicit_deps "deps(//src/main:your_test)" \
    --output graph) > result.dot
    result+=$?
    [[ $result -eq 0 ]] || echo -e "[DEBUG] 'bazel query' cmd to create result.dot is failed."

    dot -Tpng ./result.dot -o result.png
    result+=$?
    [[ $result -eq 0 ]] || echo -e "[DEBUG] 'dot' cmd to create result.png, is failed."

    # Archive a result file
    echo -e "[DEBUG] The repository location for this PR: ${dir_ci}/${dir_commit}/"
    cp ./result.txt ${dir_ci}/${dir_commit}/report/bazel-ubuntu-result.txt
    cp ./result.dot ${dir_ci}/${dir_commit}/report/bazel-ubuntu-result.dot
    cp ./result.png ${dir_ci}/${dir_commit}/report/bazel-ubuntu-result.png

    popd

    # Put a timer behind the build job to check an end time.
    time_end=$(date +"%s")
    time_diff=$(($time_end-$time_start))
    time_build_cost="$(($time_diff / 60))m $(($time_diff % 60))s"


    ########## Step 4/4: Report a execution result

    # Summarize a test result before doing final report.
    if [[ ${result} -ne 0 ]]; then
        echo -e "[DEBUG][FAILED] Oooops!!!!!! Bazel(Ubuntu) is failed after $time_build_cost."
        echo -e ""
        check_result="failure"
        global_check_result="failure"
    else
        echo -e "[DEBUG][PASSED] Successfully Bazel(Ubuntu) is passed in $time_build_cost."
        check_result="success"
    fi

    # Report a test result as a final step.
    echo -e "[DEBUG] report the execution result of Bazel(Ubuntu). The result value is ${result}. "
    if [[ $check_result == "success" ]]; then
        # Report a success.
        message="Okay. Bazel(Ubuntu, X86_64) Successful in $time_build_cost. Commit number is '$input_commit'."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-postbuild-bazel-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        # Report a failure.
        message="Oooops. Bazel(Ubuntu, X86_64) is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-postbuild-bazel-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        # comment a hint why a submitted PR is failed.
        message=":octocat: **cibot**: $user_id, Bazel(Ubuntu, X86_64) could not be completed. To find out the reasons, please go to ${CISERVER}/${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}

