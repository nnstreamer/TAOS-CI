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
# @file pr-format-indent.sh
# @brief Check the code formatting style with GNU indent
# @see      https://www.gnu.org/software/indent/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-indent
function pr-format-indent(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-indent: Check the code formatting style with GNU indent"

    check_cmd_dep indent

    # Note that you have to install up-to-date GNU intent package.
    INDENTFORMAT=NA
    INDENT_COMMAND="indent"

    which ${INDENT_COMMAND}
    if [[ $? -ne 0 ]]; then
        echo "Error: ${INDENT_COMMAND} is not available."
        echo "       Please install ${INDENT_COMMAND}."
        exit 1
    fi

    # One way to make sure you are following our coding style is to run your code
    # (remember, only the *.c files, not the headers) through GNU Indent
    FILES_IN_COMPILER=$(find $SRC_PATH/ -iname '*.cpp' -o -iname '*.c')
    FILES_TO_BE_TESTED=$(git ls-files $FILES_IN_COMPILER)

    echo "[DEBUG] TAOS/pr-format-indent: run"
    # ${INDENT_COMMAND} -i $FILES_TO_BE_TESTED
    indent \
      --braces-on-if-line \
      --case-brace-indentation0 \
      --case-indentation2 \
      --braces-after-struct-decl-line \
      --line-length80 \
      --no-tabs \
      --cuddle-else \
      --dont-line-up-parentheses \
      --continuation-indentation4 \
      --honour-newlines \
      --tab-size8 \
      --indent-level2 \
      $FILES_TO_BE_TESTED

    indent_format_file="indent-format.patch"
    git diff > ../report/${indent_format_file}
    PATCHFILE_SIZE=$(stat -c%s ../report/${indent_format_file})
    if [[ $PATCHFILE_SIZE -ne 0 ]]; then
        echo "[DEBUG] GNU indent is failed. Update your code to follow convention after reading ${indent_format_file}."
        check_result="failure"
        global_check_result="failure"
    else
        check_result="success"
    fi

    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A indent formatting style."
        message="Successfully, The commits are passed."
        cibot_report $TOKEN "success" "TAOS/pr-format-indent" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A indent formatting style."
        message="Oooops. The component you are submitting with incorrect indent-format style."
        cibot_report $TOKEN "failure" "TAOS/pr-format-indent" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi

}
