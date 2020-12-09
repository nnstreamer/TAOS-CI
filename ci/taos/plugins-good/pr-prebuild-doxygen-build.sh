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
# @file     pr-prebuild-doxygen-build.sh
# @brief    Check a doxygen grammar if a doxygen can normally generates source code
#
# Doxygen is the de facto standard tool for generating documentation from annotated C++
# sources, but it also supports other popular programming languages such as C, Objective-C,
# C#, PHP, Java, Python, IDL (Corba, Microsoft, and UNO/OpenOffice flavors), Fortran, VHDL,
# Tcl, and to some extent D.
#
# @see      http://www.doxygen.nl/
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @note
#  Note that module developer has to execute a self evaluaton if the plug-in module includes incorrect grammar(s).
#

# @brief [MODULE] ${BOT_NAME}/pr-prebuild-doxygen-build
function pr-prebuild-doxygen-build(){
echo -e "########################################################################################"
echo -e "[MODULE] ${BOT_NAME}/pr-prebuild-doxygen-build: Check a doxygen grammar if a doxygen can normally generates source code"
echo -e "[DEBUG] Current directory is `pwd`."

# Check if the below required commands are installed by server administrator
check_cmd_dep file
check_cmd_dep grep
check_cmd_dep cat
check_cmd_dep wc
check_cmd_dep doxygen

# Read file names that a contributor modified(e.g., added, moved, deleted, and updated) from a last commit.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`

# Inspect all files that contributor modifed.
for i in ${FILELIST}; do
    # skip obsolete folder
    if [[ $i =~ ^obsolete/.* ]]; then
        continue
    fi

    # skip external folder
    if [[ $i =~ ^external/.* ]]; then
        continue
    fi

    echo "[DEBUG] file name is ( $i )."
    # Handle only a source code sequentially in case that there are lots of files in one commit.
    if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
        case $i in
            # In case of source code
            *.c | *.cpp | *.cc | *.hh | *.h | *.hpp | *.py | *.sh | *.php | *.java)
                echo -e "[DEBUG] ( $i ) file is a source code with a ASCII text format."
                doxygen_analysis_sw="doxygen"
                doxygen_analysis_rules=" - "
                echo -e "[DEBUG] REFERENCE_REPOSITORY/ci/ is '${REFERENCE_REPOSITORY}/ci/'."
                doxygen_analysis_config="../../../ci/Doxyfile.prj"
                doxygen_check_result="doxygen_build_result.txt"

                # Doxygen Usage: ( cat ../Doxyfile.ci ; echo "INPUT=./webhook.php" ) | doxygen -
                ( cat $doxygen_analysis_config ; echo "INPUT=$i" ) | $doxygen_analysis_sw $doxygen_analysis_rules
                result=$?

                if  [[ $result != 0 ]]; then
                    echo -e "[DEBUG] $doxygen_analysis_sw: failed. file name: $i, There are incorrect doxygen tag(s)."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo -e "[DEBUG] $doxygen_analysis_sw: passed. file name: $i, There are not incorrect doxygen tag(s)."
                    check_result="success"
                fi
                ;;
            * )
                echo -e "[DEBUG] ( $i ) file can not be checked by doxygen software because it is not a source code."
                check_result="skip"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo -e "[DEBUG] Passed. doxygen build verifier - doxygen."
    message="Successfully source code(s) is written without a incorrect doxygen grammar."
    cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-doxygen-build" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

elif [[ $check_result == "skip" ]]; then
    echo -e "[DEBUG] Skipped. doxygen build verifier - doxygen."
    message="Skipped. Your PR does not include source code file(s) such as .c and .cpp."
    cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-doxygen-build" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

else
    echo -e "[DEBUG] Failed. doxygen build verifier - doxygen."
    message="Oooops. doxygen build verifier is failed. Please, read $doxygen_check_result for more details."
    cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-doxygen-build" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, It seems that **$i** includes incorrect doxygen tag(s). Please fix a invalid statement before starting a review process."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

}
