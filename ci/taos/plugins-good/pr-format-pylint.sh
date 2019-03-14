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
# @file pr-format-pylint.sh
# @brief Check the code formatting style with GNU pylint
# @see      https://www.pylint.org/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

# @brief [MODULE] TAOS/pr-format-pylint
function pr-format-pylint(){
echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-pylint: Check dangerous coding constructs in source codes (*.py) with pylint"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for i in ${FILELIST}; do
    # skip obsolete folder
    if [[ $i =~ ^obsolete/.* ]]; then
        continue
    fi
    # skip external folder
    if [[ $i =~ ^external/.* ]]; then
        continue
    fi
    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $i )."
    if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
        # in case of source code files: *.py)
        case $i in
            # in case of python code
            *.py)
                echo "[DEBUG] ( $i ) file is source code with the text format."
                py_analysis_sw="pylint"
                py_analysis_rules=" --reports=y "
                py_check_result="pylint_result.txt"

                if [[ ! -e ~/.pylintrc ]]; then
                    $py_analysis_sw --generate-rcfile > ~/.pylintrc
                fi

                # Check Python files
                $py_analysis_sw $py_analysis_rules $i > ../report/${py_check_result}
                line_count=$((`cat $py_check_result | grep W: | wc -l` + \
                    `cat $py_check_result | grep C: | wc -l` + \
                    `cat $py_check_result | grep E: | wc -l` + \
                    `cat $py_check_result | grep R: | wc -l`))

                # TODO: apply strict rule with pass/failure instead of report when developers understand investigation result of pylint.
                if  [[ $line_count -gt 0 ]]; then
                    echo "[DEBUG] $py_analysis_sw: failed. file name: $i, There are $line_count bug(s)."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $py_analysis_sw: passed. file name: $i, There are $line_count bug(s)."
                    check_result="success"
                fi
                ;;
            * )
                echo "[DEBUG] ( $i ) file can not be investigated by pylint (statid code analysis tool)."
                check_result="skip"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. static code analysis tool - pylint."
    message="Successfully source code(s) is written without dangerous coding constructs."
    cibot_report $TOKEN "success" "TAOS/pr-format-pylint" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message="We generate a report if there are dangerous coding constructs in your code. Please read ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${py_check_result}."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. static code analysis tool - pylint."
    message="Skipped. Your PR does not include python code(s)."
    cibot_report $TOKEN "success" "TAOS/pr-format-pylint" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

else
    echo "[DEBUG] Failed. static code analysis tool - pylint."
    message="Oooops. cppcheck is failed. Please, read $py_check_result for more details."
    cibot_report $TOKEN "failure" "TAOS/pr-format-pylint" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, It seems that **$i** includes bug(s). You must fix incorrect coding constructs in the source code before entering a review process."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

}
