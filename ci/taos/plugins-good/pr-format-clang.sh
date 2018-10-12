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
# @file pr-format-clang.sh
# @brief Check Check the code formatting style with clang-format
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

##
#  @brief [MODULE] TAOS/pr-format-clang
function pr-format-clang(){
    echo "########################################################################################"
    echo "[MODULE] pr-format-clang: Check the code formatting style with clang-format"
    # Note that you have to install up-to-date clang-format package from llvm project.
    # The clang-format-4.0 package includes git-clang-format as well as clang-format.
    # It has been included by http://archive.ubuntu.com/ubuntu/ by default since Oct-25-2017.
    # $ sudo apt install clang-format-4.0
    # In case that we need to change clang-format with latest version, refer to https://apt.llvm.org
    CLANGFORMAT=NA
    CLANG_COMMAND="clang-format-4.0"

    which ${CLANG_COMMAND}
    if [[ $? -ne 0 ]]; then
        echo "Error: ${CLANG_COMMAND} is not available."
        echo "       Please install ${CLANG_COMMAND}."
        exit 1
    fi

    echo "[DEBUG] Path of a working directory: "
    pwd

    # define file type of source code
    FILES_IN_COMPILER=`find $SRC_PATH/ -iname '*.h' -o -iname '*.cpp' -o -iname '*.c' -o -iname '*.hpp'`
    if [[ $? != 0 ]] ; then
        echo "[DEBUG] Oooops. Please check $SRC_PATH in configuraton file is vaild or not."
    fi

    echo "[DEBUG] Files of source code: $FILES_IN_COMPILER "

    # define file format to be tested by clang command.
    FILES_TO_BE_TESTED=$(git ls-files $FILES_IN_COMPILER)
    echo "[DEBUG] Files to be tested: $FILES_TO_BE_TESTED"

    # import clang configuration file
    ln -sf ci/doc/.clang-format .clang-format

    # run clang format checker
    ${CLANG_COMMAND} -i $FILES_TO_BE_TESTED

    # save the result
    clang_format_file="clang-format.patch"
    git diff > ../report/${clang_format_file}

    # check a clang format rule with file size of patch file
    PATCHFILE_SIZE=$(stat -c%s ../report/${clang_format_file})
    if [[ $PATCHFILE_SIZE -ne 0 ]]; then
            echo "[DEBUG] Format checker is failed. Update your code to follow convention after reading ${clang_format_file}."
            check_result="failure"
            global_check_result="failure"
    else
            check_result="success"
    fi

    # report the clang inspection result
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A clang-formatting style."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "TAOS/pr-format-clang" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A clang-formatting style."
        message="Oooops. The component you are submitting with incorrect clang-format style."
        cibot_report $TOKEN "failure" "TAOS/pr-format-clang" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
fi



}

