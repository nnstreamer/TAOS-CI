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
# @file pr-format-doxygen.sh
# @brief Check if source code includes required doxygen tags
#
# This module is to check if a source code appropriately consists of required doxygen tags.
# The execution result is reported with "TAOS/pr-format-doxygen" context into status section
# of a github PR webpage.
#
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @author   Sewon Oh <sewon.oh@samsung.com>

##
# @brief [MODULE] TAOS/pr-format-doxygen
function pr-format-doxygen(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-doxygen: Check if source code includes required doxygen tags for doxygen documentation."
    # Inspect all *.patch files that are fetched from a commit file
    FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
    check_result="success"
    for curr_file in ${FILELIST}; do
        # if a current file is located in $SKIP_CI_PATHS_FORMAT folder, let's skip the inspection process
        if [[ "$curr_file" =~ ($SKIP_CI_PATHS_FORMAT)$ ]]; then
            echo "[DEBUG] Doxygen checker skips the doxygen inspection because $curr_file is located in the \"$SKIP_CI_PATHS_FORMAT\"."
            continue
        fi
    
        echo "[DEBUG] The current file name is (${curr_file}). "
        # Handle only text files in case that there are lots of files in one commit.
        if [[ `file $curr_file | grep "ASCII text" | wc -l` -gt 0 ]]; then
            # In case of source code files: *.c|*.h|*.cpp|*.py|*.sh|*.php )
            case $curr_file in
                # In case of C/C++ code
                *.c|*.h|*.cpp|*.hpp )
                    echo "[DEBUG] ( $curr_file ) file is source code with the text format."
                    doxygen_lang="doxygen-cncpp"
                    # Append a doxgen rule step by step
                    doxygen_basic_rules="@file @brief" # @file and @brief to inspect file
                    doxygen_advanced_rules="@author @bug" # @author, @bug to inspect file, @brief for to inspect function
    
                    # Apply advanced doxygen rule if pr_doxygen_check_level=1 in config-environment.sh
                    if [[ $pr_doxygen_check_level == 1 ]]; then
                        doxygen_basic_rules="$doxygen_basic_rules $doxygen_advanced_rules"
                    fi
    
                    for word in $doxygen_basic_rules
                    do
                        # echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word."
                        doxygen_rule_compare_count=`cat ${curr_file} | grep "$word" | wc -l`
                        doxygen_rule_expect_count=1
    
                        # Doxygen_rule_compare_count: real number of doxygen tag in file
                        # Doxygen_rule_expect_count: required number of doxygen tag
                        if [[ $doxygen_rule_compare_count -lt $doxygen_rule_expect_count ]]; then
                            echo "[ERROR] $doxygen_lang: failed. file name: $curr_file, $word tag is required at the top of file"
                            check_result="failure"
                            global_check_result="failure"
                        fi
                    done
    
                    # Checking tags for each function
                    if [[ $pr_doxygen_check_level == 1 ]]; then
                        declare -i idx=0
                        function_positions="" # Line number of functions.
                        structure_positions="" # Line number of structure.
    
                        # Find line number of functions using ctags, and append them.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            temp=`echo $line | cut -d ' ' -f3` # line number of function place 3rd field when divided into ' '
                            function_positions="$function_positions $temp "
                        done < <(ctags -x --c-kinds=f $curr_file) # "--c-kinds=f" mean find function
    
                        # Find line number of structure using ctags, and append them.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            temp=`echo $line | cut -d ' ' -f3` # line number of structure place 3rd field when divided into ' '
                            structure_positions="$structure_positions $temp "
                        done < <(ctags -x --c-kinds=sc $curr_file) # "--c-kinds=sc" mean find 's'truct and 'c'lass
    
                        # Checking commited file line by line for detailed hints when missing doxygen tags.
                        while IFS='' read -r line || [[ -n "$line" ]]; do
                            idx+=1
    
                            # Check if a function has @brief tag or not.
                            # To pass correct line number not sub number, keep space " $idx ".
                            # ex) want to pass 143 not 14, 43, 1, 3, 4
                            if [[ $function_positions =~ " $idx " && $brief -eq 0 ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, `echo $line | cut -d ' ' -f1` function needs @brief tag "
                                check_result="failure"
                                global_check_result="failure"
                            fi
    
                            # Check if a structure has @brief tag or not.
                            # To pass correct line number not sub number, keep space " $idx ".
                            # For example, we want to pass 143 not 14, 43, 1, 3, and 4.
                            if [[ $structure_positions =~ " $idx " && $brief -eq 0 ]]; then # same as above.
                                echo "[ERROR] File name: $curr_file, $idx line, structure needs @brief tag "
                                check_result="failure"
                                global_check_result="failure"
                            fi
    
                            # Find brief tag in the comments between the codes.
                            if [[ $line =~  "@brief" ]]; then
                                brief=1
                            # Doxygen tags become zero in code section.
                            elif [[ $line != *"*"*  && ( $line =~ ";" || $line =~ "}" || $line =~ "#") ]]; then
                                brief=0
                            fi
    
                            # Check a comment statement that begins with '/*'.
                            # Note that doxygen does not recognize a comment  statement that start with '/*'.
                            # Let's skip the doxygen tag inspection such as "/**" in case of a single line comment.
                            if [[ $line =~ "/*" && $line != *"/**"*  && ( $line != *"*/"  || $line =~ "@" ) ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, Doxygen or multi line comments should begin with /**"
                                check_result="failure"
                                global_check_result="failure"
                            fi
    
                            # Check the doxygen tag written in upper case beacuase doxygen cannot use upper case tag such as '@TODO'.
                            if [[ $line =~ "@"[A-Z] ]]; then
                                echo "[ERROR] File name: $curr_file, $idx line, The doxygen tag sholud be written in lower case."
                                check_result="failure"
                                global_check_result="failure"
                            fi
    
                        done < "$curr_file"
                    fi
                    ;;
                # In case of Python code
                *.py )
                    echo "[DEBUG] ( $curr_file ) file is source code with the text format."
                    doxygen_lang="doxygen-python"
                    # Append a doxgen rule step by step
                    doxygen_rules="@package @brief"
                    doxygen_rule_num=0
                    doxygen_rule_all=0
                    for word in $doxygen_rules
                    do
                        # echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word."
                        doxygen_rule_all=$(( doxygen_rule_all + 1 ))
                        doxygen_rule[$doxygen_rule_all]=`cat ${curr_file} | grep "$word" | wc -l`
                        doxygen_rule_num=$(( $doxygen_rule_num + ${doxygen_rule[$doxygen_rule_all]} ))
                    done
                    if  [[ $doxygen_rule_num -le 0 ]]; then
                        echo "[ERROR] $doxygen_lang: failed. file name: $curr_file, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                        check_result="failure"
                        global_check_result="failure"
                        break
                    else
                        echo "[DEBUG] $doxygen_lang: passed. file name: $curr_file, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                        check_result="success"
                    fi
                    ;;
                * )
                    echo "[DEBUG] ( $curr_file ) file is not source code with the text format."
                    check_result="success"
                    ;;
            esac
        fi
    done
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. doxygen documentation."
        message="Successfully source code(s) includes doxygen document correctly."
        cibot_pr_report $TOKEN "success" "TAOS/pr-format-doxygen" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[ERROR] Failed. doxygen documentation."
        message="Oooops. The doxygen checker is failed. Please, write doxygen document in your code."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-format-doxygen" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    
        # inform PR submitter of a hint in more detail
        message=":octocat: **cibot**: $user_id, **$i** does not include doxygen tags such as $doxygen_basic_rules. You must include the doxygen tags in the source code at least."
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    
        message=":octocat: **cibot**: $user_id, You wrote code with incorrect doxygen statements. Please check a doxygen rule at"
        message="$message http://github.com/nnsuite/TAOS-CI/blob/tizen/ci/doc/doxygen-documentation.md"
        cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    fi
}

