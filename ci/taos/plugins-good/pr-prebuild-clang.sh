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
# @file pr-prebuild-clang.sh
# @brief Check Check the code formatting style with clang-format
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @detail   Users may provide arguments with "clang_option" variable,
#           where multiple options may be given with a space, " ", as a
#           separator.
#           Available options are:
#             cxx-only : Audit C++ files only (*.cc, *.hh, *.H, *.cpp)

##
#  @brief [MODULE] ${BOT_NAME}/pr-prebuild-clang
function pr-prebuild-clang(){
    echo "########################################################################################"
    echo "[MODULE] pr-prebuild-clang: Check the code formatting style with clang-format"
    # Note that you have to install up-to-date clang-format package from llvm project.
    # The clang-format-6.0 package includes git-clang-format as well as clang-format.
    # The clang-format-6.0 is used in Ubuntu 18.04 by default.
    # It has been included by http://archive.ubuntu.com/ubuntu/ by default since Oct-25-2017.
    # $ sudo apt install clang-format-6.0
    # In case that we need to change clang-format with latest version, refer to https://apt.llvm.org
    CLANGFORMAT=NA
    CLANG_COMMAND="clang-format-6.0"

    which ${CLANG_COMMAND}
    if [[ $? -ne 0 ]]; then
        echo "Error: ${CLANG_COMMAND} is not available."
        echo "       Please install ${CLANG_COMMAND}."
        exit 1
    fi

    echo "[DEBUG] Path of a working directory: "
    pwd

    # investigate files that are affected by the incoming patch
    # TODO: get all diff since master?
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    AUDITLIST=""

    for i in ${FILELIST}; do
            AUDITLIST+=`echo $i | grep "\.h"`
            AUDITLIST+=`echo $i | grep "\.hpp"`
            AUDITLIST+=`echo $i | grep "\.hh"`
            AUDITLIST+=`echo $i | grep "\.H"`
            AUDITLIST+=`echo $i | grep "\.c"`
            AUDITLIST+=`echo $i | grep "\.cpp"`
            AUDITLIST+=`echo $i | grep "\.cc"`
            AUDITLIST+=`echo $i | grep "\.C"`
        AUDITLIST+=' '
    done
    echo "[DEBUG] Files of source code: $AUDITLIST"

    # import clang configuration file
    if [ ! -f ".clang-format" ]; then
	ln -sf ci/doc/.clang-format .clang-format
    fi

    # run clang format checker
    for i in ${AUDITLIST}; do
	${CLANG_COMMAND} -i $i
    done

    # save the result
    clang_format_file="clang-format.patch"
    search_target=""
    for option in ${clang_option}; do
        if [ "${option}" == "cxx-only" ]; then
            search_target="-- *.cc *.hh *.hpp *.cpp"
        fi
    done
    git diff ${search_target} > ../report/${clang_format_file}

    # Revert what clang-format did to the source tree
    git reset --hard

    # check a clang format rule with file size of patch file
    PATCHFILE_SIZE=$(stat -c%s ../report/${clang_format_file})
    if [[ $PATCHFILE_SIZE -ne 0 ]]; then
        echo "[DEBUG] a module of the prebuild group is failed. Update your code to follow convention after reading ${clang_format_file}."
        check_result="failure"
        global_check_result="failure"
    else
        check_result="success"
    fi

    # report the clang inspection result
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A clang-formatting style."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-clang" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A clang-formatting style."
        message="Oooops. The component you are submitting with incorrect clang-format style."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-clang" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi

}

