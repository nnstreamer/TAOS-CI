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
# @file pr-prebuild-doxygen-tag.sh
# @brief Check if source code includes required Doxygen tags
#
# This module is to check if a source code appropriately consists of required Doxygen tags.
# The execution result is reported with "${BOT_NAME}/pr-prebuild-doxygen-tag" context into status section
# of a GitHub PR webpage.
#
# @see      https://github.com/nnstreamer/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @author   Sewon Oh <sewon.oh@samsung.com>

##
# @brief [MODULE] ${BOT_NAME}/pr-prebuild-doxygen-tag
function pr-prebuild-doxygen-tag(){
    report_path=../report/doxygen_tag.txt

    echo "########################################################################################" >> $report_path
    echo "[MODULE] ${BOT_NAME}/pr-prebuild-doxygen-tag: Check if source code includes required Doxygen tags for Doxygen documentation." >> $report_path
    # Inspect all *.patch files that are fetched from a commit file
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    check_result="skip"
    latest_failed_file=""
    for curr_file in ${FILELIST}; do
        # if a current file is located in $SKIP_CI_PATHS_FORMAT folder, let's skip the inspection process
        if [[ "$curr_file" =~ ($SKIP_CI_PATHS_FORMAT)$ ]]; then
            echo "[DEBUG] Doxygen checker skips the Doxygen inspection because $curr_file is located in the \"$SKIP_CI_PATHS_FORMAT\"." >> $report_path
            continue
        fi

        echo "[DEBUG] The current file name is (${curr_file}). " >> $report_path
        # Handle only text files in case that there are lots of files in one commit.
        if [[ `file $curr_file | grep "ASCII text" | wc -l` -gt 0 ]]; then
            # In case of source code files: *.c|*.h|*.cpp|*.py|*.sh|*.php )
            case $curr_file in
                # In case of C/C++ code
                *.c|*.h|*.cc|*.hh|*.cpp|*.hpp )
                    echo "[DEBUG] ( $curr_file ) file is source code with the text format." >> $report_path
                    doxygen_lang="doxygen-cncpp"
                    # Append a doxgen rule step by step
                    doxygen_basic_rules="@file @brief" # @file and @brief to inspect file
                    doxygen_advanced_rules="@author @bug" # @author, @bug to inspect file, @brief for to inspect function

                    # When a current file is a source code,
                    # change a default value of $check_result from 'skip' to 'success'
                    if [[ $check_result == "skip" ]]; then
                        check_result="success"
                    fi

                    # Apply advanced doxygen rule if pr_doxygen_check_level=1 in config-environment.sh
                    if [[ $pr_doxygen_check_level == 1 ]]; then
                        doxygen_basic_rules="$doxygen_basic_rules $doxygen_advanced_rules"
                    fi

                    for word in $doxygen_basic_rules
                    do
                        # echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word." >> $report_path
                        doxygen_rule_compare_count=`cat ${curr_file} | grep "$word" | wc -l`
                        doxygen_rule_expect_count=1

                        # Doxygen_rule_compare_count: real number of Doxygen tags in a file
                        # Doxygen_rule_expect_count: required number of Doxygen tags
                        if [[ $doxygen_rule_compare_count -lt $doxygen_rule_expect_count ]]; then
                            echo "[ERROR] $doxygen_lang: failed. file name: $curr_file, $word tag is required at the top of file" >> $report_path
                            check_result="failure"
                            global_check_result="failure"
                            latest_failed_file=$curr_file
                        fi
                    done

                    # Checking tags for each function
                    if [[ $pr_doxygen_check_level == 1 ]]; then
                        declare -i idx=0
                        function_positions="" # Line number of functions.
                        structure_positions="" # Line number of structure.

                        local function_check_flag="f+p" # check document for function and prototype of the function

                        if [[ $pr_doxygen_check_skip_function_definition == 1 && $curr_file != *.h ]]; then
                            function_check_flag="p" # check document for only prototypes of the function for non-header file
                        fi

                        # Find line number of functions using ctags, and append them.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            temp=`echo $line | cut -d ' ' -f3` # line number of function place 3rd field when divided into ' ' >> $report_path
                            function_positions="$function_positions $temp "
                        done < <(ctags -x --c-kinds=$function_check_flag $curr_file) # "--c-kinds=f" mean find function

                        # Find line number of structure using ctags, and append them.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            temp=`echo $line | cut -d ' ' -f3` # line number of structure place 3rd field when divided into ' ' >> $report_path
                            structure_positions="$structure_positions $temp "
                        done < <(ctags -x --c-kinds=sc $curr_file) # "--c-kinds=sc" mean find 's'truct and 'c'lass

                        # Checking committed file line by line for detailed hints when missing Doxygen tags.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            idx+=1

                            # Check if a function has @brief tag or not.
                            # To pass correct line number not sub number, keep space " $idx ".
                            # ex) want to pass 143 not 14, 43, 1, 3, 4
                            if [[ $function_positions =~ " $idx " && $brief -eq 0 ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, `echo $line | cut -d ' ' -f1` function needs @brief tag " >> $report_path
                                check_result="failure"
                                global_check_result="failure"
                                latest_failed_file=$curr_file
                            fi

                            # Check if a structure has @brief tag or not.
                            # To pass correct line number not sub number, keep space " $idx ".
                            # For example, we want to pass 143 not 14, 43, 1, 3, and 4.
                            if [[ $structure_positions =~ " $idx " && $brief -eq 0 ]]; then # same as above.
                                echo "[ERROR] File name: $curr_file, $idx line, structure needs @brief tag " >> $report_path
                                check_result="failure"
                                global_check_result="failure"
                                latest_failed_file=$curr_file
                            fi

                            # Find brief or copydoc tag in the comments between the codes.
                            if [[ $line =~  "@brief" || $line =~ "@copydoc" ]]; then
                                brief=1
                            # Doxygen tags become zero in code section.
                            elif [[ $line != *"*"*  && ( $line =~ ";" || $line =~ "}" || $line =~ "#") ]]; then
                                brief=0
                            fi

                            # Check a comment statement that begins with '/*'.
                            # Note that doxygen does not recognize a comment  statement that start with '/*'.
                            # Let's skip the doxygen tag inspection such as "/**" in case of a single line comment.
                            if [[ $line =~ "/*" && $line != *"/**"*  && ( $line != *"*/"  || $line =~ "@" ) && ( $idx != 1 ) ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, Doxygen or multi line comments should begin with /**" >> $report_path
                                check_result="failure"
                                global_check_result="failure"
                                latest_failed_file=$curr_file
                            fi

                            # Check the doxygen tag written in upper case beacuase doxygen cannot use upper case tag such as '@TODO'.
			    # This is a simple (incorrect) method to detect.
			    # @todo it should be able to know if it is inside a comment or not!
                            if [[ $line =~ ^[\ \t]*\*[\t \t]*"@"[A-Z] ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, The doxygen tag sholud be written in lower case." >> $report_path
                                check_result="failure"
                                global_check_result="failure"
                                latest_failed_file=$curr_file
                            fi
                            if [[ $line =~ //[\ \t]*"@"[A-Z] ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, The doxygen tag sholud be written in lower case." >> $report_path
                                check_result="failure"
                                global_check_result="failure"
                                latest_failed_file=$curr_file
                            fi

                        done < "$curr_file"
                    fi
                    ;;
                # In case of Python code
                *.py )
                    echo "[DEBUG] ( $curr_file ) file is source code with the text format." >> $report_path
                    doxygen_lang="doxygen-python"
                    # Append a Doxgen rule step by step
                    doxygen_rules="@package @brief"
                    doxygen_rule_num=0
                    doxygen_rule_all=0

                    # When a current file is a source code,
                    # change a default value of $check_result from 'skip' to 'success'
                    if [[ $check_result == "skip" ]]; then
                        check_result="success"
                    fi

                    for word in $doxygen_rules
                    do
                        # echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word." >> $report_path
                        doxygen_rule_all=$(( doxygen_rule_all + 1 ))
                        doxygen_rule[$doxygen_rule_all]=`cat ${curr_file} | grep "$word" | wc -l`
                        doxygen_rule_num=$(( $doxygen_rule_num + ${doxygen_rule[$doxygen_rule_all]} ))
                    done
                    if  [[ $doxygen_rule_num -le 0 ]]; then
                        echo "[ERROR] $doxygen_lang: failed. file name: $curr_file, ($doxygen_rule_num)/$doxygen_rule_all tags are found." >> $report_path
                        check_result="failure"
                        global_check_result="failure"
                        latest_failed_file=$curr_file
                        break
                    else
                        echo "[DEBUG] $doxygen_lang: passed. file name: $curr_file, ($doxygen_rule_num)/$doxygen_rule_all tags are found." >> $report_path
                    fi
                    ;;
                * )
                    echo "[DEBUG] ( $curr_file ) file is not source code with the text format." >> $report_path
                    ;;
            esac
        fi
    done

    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. Doxygen documentation." >> $report_path
        message="Successfully the Doxygen checker is passed."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-doxygen-tag" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    elif [[ $check_result == "skip" ]]; then
        echo "[DEBUG] Skipped. Doxygen documentation" >> $report_path
        message="Skipped. Your PR does not include source code(s)."
        cibot_report $TOKEN "success" "${BOT_NAME}/pr-prebuild-doxygen-tag" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[ERROR] Failed. Doxygen documentation." >> $report_path
        message="Oooops. The Doxygen checker is failed. Please write a Doxygen document in your code."
        cibot_report $TOKEN "failure" "${BOT_NAME}/pr-prebuild-doxygen-tag" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM_LOCAL}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

        # inform a PR submitter of a hint message in more detail
        message=":octocat: **cibot**: $user_id, **$latest_failed_file** does not include Doxygen tags such as **$doxygen_basic_rules**. You must include the Doxygen tags in the source code."
        message="$message Please refer to a Doxygen manual at"
        message="$message http://github.com/nnstreamer/TAOS-CI/blob/main/ci/doc/doxygen-documentation.md"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

    fi
}

