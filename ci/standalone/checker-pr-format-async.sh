#!/usr/bin/env bash

##
# Copyright 2018 The TAOS-CI Authors. All Rights Reserved.
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
# @file checker-pr-format-async.sh
# @brief It checks format rules whenever a PR is submitted.
# @see      https://github.sec.samsung.net/STAR/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @param arguments are received from CI manager
#  arg1: date(Ymdhms)
#  arg2: commit number
#  arg3: repository address of PR
#  arg4: branch name
#  arg5: PR number
#  arg6: delivery id
#
# @see variables to control the directories
#  $dir_ci directory is CI folder
#  $dir_worker   directory is PR worker folder
#  $dir_commit   directory is commit folder
#
# @modules:
# "[MODULE] TAOS/pr-format-file-size      Check the file size to not include big binary files"
# "[MODULE] TAOS/pr-format-newline        Check the illegal newline handlings in text files"
# "[MODULE] TAOS/pr-format-doxygen        Check documenting code using doxygen in text files"
# "[MODULE] TAOS/pr-format-cppcheck       Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck"
# "[MODULE] TAOS/pr-format-rpm-spec       Check the spec file with rpmlint"
# "[MODULE] TAOS/pr-format-nobody         Check the commit message body"
# "[MODULE] TAOS/pr-format-timestamp      Check the timestamp of the commit"
# "[MODULE] TAOS/pr-format-executable     Check executable bits for .cpp, .h, .hpp, .c, .caffemodel, .prototxt, .txt."
# "[MODULE] TAOS/pr-format-hardcoded-path Check prohibited hardcoded paths (/home/* for now)"
# "[MODULE] plugins-good                Plugin group that follow Apache license with good quality"
# "[MODULE] plugins-staging                Plugin group that does not have evaluation and aging test enough"
#

# --------------------------- Pre-setting module ----------------------------------------------------------------------

# arguments
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6

# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation from CI manager
source ./config/config-environment.sh
source ./common/cibot_rest_api.sh

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# @dependency
# git, which, grep, touch, find, wc, cat, basename, tail, clang-format-4.0, cppcheck, rpmlint, aha, stat, curl
# check if dependent packages are installed
source ./common/inspect_dependency.sh
check_package git
check_package which
check_package grep
check_package touch
check_package find
check_package wc
check_package cat
check_package basename
check_package tail
check_package clang-format-4.0
check_package cppcheck
check_package rpmlint
check_package aha
check_package stat
check_package curl
check_package ctags
echo "[DEBUG] Checked dependency packages.\n"

# get user ID from the input_repo string
set -- "${input_repo}"
IFS="\/"; declare -a Array=($*); unset IFS;
user_id="@${Array[3]}"

# Set folder name uniquely to run CI in different folder per a PR.
dir_worker="repo-workers/pr-format"

# Set project repo name
PRJ_REPO_OWNER=`echo $(basename "${input_repo%.*}")`

cd ..
export dir_ci=`pwd`

# create dir_work folder
if [[ ! -d $dir_worker ]]; then
    mkdir -p $dir_worker
fi
cd $dir_worker
export dir_worker=$dir_worker

# check if dir_commit folder exists, then, create dir_commit folder
# let's keep the existing result although the same target directory already exists.
cd $dir_ci
export dir_commit=${dir_worker}/${input_date}-${input_pr}-${input_commit}
# --------------------------- CI Trigger (queued) --------------------------------------------------------------------
message="Trigger: queued. The commit number is $input_commit."
cibot_pr_report $TOKEN "pending" "(INFO)TAOS/pr-format-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

# --------------------------- git-clone module: clone git repository -------------------------------------------------
echo "[DEBUG] Starting pr-format....\n"

# check if existing folder exists.
if [[ -d $dir_commit ]]; then
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
fi

# check if github project folder already exists
cd $dir_commit
if [[ -d ${PRJ_REPO_OWNER} ]]; then
    echo "[DEBUG] WARN: ${PRJ_REPO_OWNER} already exists and is not an empty directory."
    echo "[DEBUG] WARN: So removing the existing directory..."
    rm -rf ./${PRJ_REPO_OWNER}
fi

# create 'report' folder to archive log files.
mkdir ./report

# run "git clone" command to download git source
pwd
sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo
if [[ $? != 0 ]]; then
    echo "git clone --reference ${REFERENCE_REPOSITORY} $input_repo "
    echo "[DEBUG] ERROR: Oooops. 'git clone' command failed."
    exit 1
else
    echo "[DEBUG] 'git clone' command is successfully finished."
fi

# run "git branch" to use commits from PR branch
cd ./${PRJ_REPO_OWNER}
git checkout -b $input_branch origin/$input_branch
git branch

echo "Make sure commit all changes before running this checker."

# --------------------------- Jenkins module: start -----------------------------------------------------
# archive a patch file of latest commit with 'format-patch' option
# This *.patch file is used for nobody check.
git format-patch -1 $input_commit --output-directory ../report/

# declare default variables
# check_result variable can get three values such as success, skip, and failure.
# global_check_result variable can get two values such as success and failure.
check_result="success"
global_check_result="success"


echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-file-size: Check the file size to not include big binary files"

# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`

for current_file in ${FILELIST}; do
    FILESIZE=$(stat -c%s "$current_file")
    echo "[DEBUG] current file name is ($current_file). file size is \"$FILESIZE\". "
    # Add thousands separator in a number
    FILESIZE_NUM=`echo $FILESIZE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
    # check the files in case that there are files that exceed 5MB.
    if  [[ $FILESIZE -le ${filesize_limit}*1024*1024 ]]; then
        echo "[DEBUG] Passed. patch file name: $current_file. value is $FILESIZE_NUM."
        check_result="success"
    elif  [[ $current_file =~ "$SKIP_CI_PATHS_FORMAT" ]]; then
        echo "[DEBUG] Skipped because a patch file $current_file is located in $SKIP_CI_PATHS_FORMAT."
        echo "[DEBUG] The file size is $FILESIZE_NUM."
        check_result="success"
    else
        echo "[DEBUG] Failed. patch file name: $current_file. value is $FILESIZE_NUM."
        check_result="failure"
        global_check_result="failure"
        break
    fi
done


# get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
i_filename=$(basename $current_file)

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. File size."
    message="Successfully all files are passed without any issue of file size."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-filesize" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. File size."
    message="Oooops. File size checker is failed at $i_filename."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-filesize" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: '$user_id', Oooops. Note that you can not upload a big file that exceeds ${filesize_limit} Mbytes. The file name is ($current_file). The file size is \"$FILESIZE_NUM\". If you have to temporarily upload binary files unavoidably, please share this issue to all members after uploading the files in **/${SKIP_CI_PATHS_FORMAT}** folder."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-newline: Check the illegal newline handlings in text files"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for current_file in ${FILELIST}; do
    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $current_file )."

    newline_count=0
    if [[ `file $current_file | grep "ASCII text" | wc -l` -gt 0 ]]; then
        # in case of text files: *.c|*.h|*.cpp|*.py|*.md|*.xml|*.txt|*.launch|*.sh|*.php|*.html|*.json|*.spec|*.manifest|*.CODEOWNERS )
        echo "[DEBUG] ( $current_file ) file is a text file."
        num=$(( $num + 1 ))
        # fetch patch content of a specified file from  a commit.
        echo "[DEBUG] git show $current_file > ../report/${num}.patch "
        git show $current_file > ../report/${num}.patch
        # check if the last line of a patch file includes "\ No newline....." statement.
        newline_count=$(cat ../report/${num}.patch  | tail -1 | grep '^\\ No newline' | wc -l)
        if  [[ $newline_count == 0 ]]; then
            echo "[DEBUG] Newline checker is passed. patch file name: $current_file. The number of newlines is $newline_count."
            check_result="success"

        elif  [[ $current_file =~ "$SKIP_CI_PATHS_FORMAT" ]]; then
            echo "[DEBUG] Newline checker skipped because a patch file $current_file is located in the $SKIP_CI_PATHS_FORMAT."
            echo "[DEBUG] The file size is $FILESIZE_NUM."
            check_result="success"
        else
            echo "[DEBUG] Newline checker is failed. patch file name: $current_file. The number of newlines is $newline_count."
            touch ../report/newline-error-${num}.patch
            echo " There are ${newline_count} '\ No newline ...' statements in the ${num}.patch file." > ../report/newline-error-${num}.patch
            check_result="failure"
            global_check_result="failure"
            break
        fi
    fi
done

# get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
i_filename=$(basename $current_file)

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. No newline anomaly."
    message="Successfully all text files are passed without newline issue."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-newline" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A newline anomaly happened."
    message="Oooops. New line checker is failed at $i_filename."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-newline" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, There is a newline issue. The final line of a text file should have newline character. Please resubmit your PR after fixing end of line in $current_file."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-doxygen: Check documenting code using doxygen in text files"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for curr_file in ${FILELIST}; do
    # if a current file is located in $SKIP_CI_PATHS_FORMAT folder, let's skip the inspection process
    if [[ "$curr_file" =~ ($SKIP_CI_PATHS_FORMAT)$ ]]; then
        echo "[DEBUG] Doxygen checker skips the doxygen inspection because $curr_file is located in the \"$SKIP_CI_PATHS_FORMAT\"."
        continue
    fi

    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $curr_file ) . "
    if [[ `file $curr_file | grep "ASCII text" | wc -l` -gt 0 ]]; then
        # in case of source code files: *.c|*.h|*.cpp|*.py|*.sh|*.php )
        case $curr_file in
            # in case of C/C++ code
            *.c|*.h|*.cpp|*.hpp )
                echo "[DEBUG] ( $curr_file ) file is source code with the text format."
                doxygen_lang="doxygen-cncpp"
                # Append a doxgen rule step by step
                doxygen_basic_rules="@file @brief" # @file and @brief to inspect file
                doxygen_advanced_rules="@author @bug" # @author, @bug to inspect file, @brief for to inspect function
                check_result="success"

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
                        # ex) want to pass 143 not 14, 43, 1, 3, 4 
                        if [[ $structure_positions =~ " $idx " && $brief -eq 0 ]]; then # same as above.
                            echo "[ERROR] File name: $curr_file, $idx line, structure needs @brief tag "
                            check_result="failure"
                            global_check_result="failure"
                        fi

                        # Find brief tag in the comments between the codes.
                        if [[ $line =~  "@brief" ]]; then 
                            brief=1
                        elif [[ $line != *"*"*  && ( $line =~ ";" || $line =~ "}" ) ]]; then  # The tag you find is used in this line.
                            brief=0
                        fi
                        
                        # Check the beginning of the comment is '/*' beacuse doxygen can't recognize comment start with '/*'
                        if [[ $line =~ "/*" && $line != *"/**"* ]]; then
                            echo "[ERROR] File name: $curr_file, $idx line, the comment should begin with /**"
                            check_result="failure"
                            global_check_result="failure"
                        fi
                        
                        # Check the doxygen tag written in upper case beacuase doxygen can't use upper case tag. ex) @TODO
                        if [[ $line =~ "@"[A-Z] ]]; then
                            echo "[ERROR] File name: $curr_file, $idx line, The tag sholud be written in lower case."
                            check_result="failure"
                            global_check_result="failure"
                        fi

                    done < "$curr_file"
                fi

                if  [[ $check_result == "success" ]]; then
                    echo "[DEBUG] $doxygen_lang: passed. file name: $curr_file, All tags are found."
                fi
                ;;
            # in case of Python code
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
    message="$message http://github.sec.samsung.net/STAR/TAOS-CI/blob/tizen/ci/doc/doxygen-documentation.md"
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-cppcheck: Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck"
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
        # in case of source code files: *.c|*.cpp)
        case $i in
            # in case of C/C++ code
            *.c|*.cpp)
                echo "[DEBUG] ( $i ) file is source code with the text format."
                static_analysis_sw="cppcheck"
                static_analysis_rules="--std=posix"
                cppcheck_result="cppcheck_result.txt"
                # Check C/C++ file, enable all checks.
                $static_analysis_sw $static_analysis_rules $i 2> ../report/$cppcheck_result
                bug_line=`wc -l ../report/$cppcheck_result`
                if  [[ $bug_line -gt 0 ]]; then
                    echo "[DEBUG] $static_analysis_sw: failed. file name: $i, There are $bug_line bug(s)."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $static_analysis_sw: passed. file name: $i, There are $bug_line bug(s)."
                    check_result="success"
                fi
                ;;
            * )
                echo "[DEBUG] ( $i ) file can not be investigated by cppcheck (statid code analysis tool)."
                check_result="skip"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. static code analysis tool - cppcheck."
    message="Successfully source code(s) is written without dangerous coding constructs."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. static code analysis tool - cppcheck."
    message="Skipped. Your PR does not include c/c++ code(s)."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. static code analysis tool - cppcheck."
    message="Oooops. cppcheck is failed. Please, read $cppcheck_result for more details."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-cppcheck" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint in more detail
    message=":octocat: **cibot**: $user_id, **$i** includes bug(s). You must fix incorrect coding constructs in the source code before entering a review process."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi


echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-rpm-spec: Check the spec file with rpmlint"
spec_modified="false"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for i in ${FILELIST}; do
    if [[ $i =~ ^obsolete/.* ]]; then
        continue
    fi
    if [[ $i =~ ^external/.* ]]; then
        continue
    fi
    # Handle only spec file in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $i )."
    RPM_SPEC_REPORT_FILE="rpm-spec-check-result.html"
    touch ../report/${RPM_SPEC_REPORT_FILE}
    echo "RPM spec checker is skipped because there is no spec file (e.g., *.spec) in this PR."
    if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
        case $i in
            # in case of *.spec file
            *.spec )
                echo "[DEBUG] ( $i ) file is source code with the text format."
                rpmlint_result=`rpmlint $i | aha --line-fix > ../report/${RPM_SPEC_REPORT_FILE}`
                echo "[DEBUG] rpmlint result:\n $rpmlint_result"
                check_result="success"
                spec_modified="true"
                break
                ;;
            * )
                echo "[DEBUG] ( $i ) file is not source code with the text format."
                check_result="success"
                spec_modified="false"
                ;;
        esac
    fi
done

# If developer(s) modify *.spec file, let's report an investigation result that checks common errors in the file.
if [[ spec_modified == "true" ]]; then

    # inform PR submitter of a hint in more detail to fix incorrect *.spec file.
    # TODO: Improve the existing handling method in case that developers incorrectly write *.spec file.
    message=":octocat: **cibot**: [FYI] We inform $user_id of a check result of spec file with rpmlint. If there are some warning(s) or error(s) in your spec file, modify ${i} correctly after reading the report at ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${RPM_SPEC_REPORT_FILE}."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. rpm spec checker."
        message="Successfully rpm spec checker is done."
        cibot_pr_report $TOKEN "success" "TAOS/pr-format-rpm-spec" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. rpm spec checker."
        message="Oooops. The rpm spec checker is failed."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-format-rpm-spec" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    fi
else
    echo "[DEBUG] Skipped. rpm spec checker."
    message="Skipped. rpm spec checker is jumped because you did not modify a spec file."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-rpm-spec" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-nobody: Check the commit message body"
check_result="success"
echo "             #### No body check result ####            " > ../report/nobody-result.txt
for filename in ../report/000*.patch; do
    echo " * $filename " >> ../report/nobody-result.txt
    line_count=0
    body_count=0
    nobody_result=0
    # let's do the while-loop statement to read data line by line
    while IFS= read -r line; do
        #If the line starts with "Subject*" then set var to "yes".
        if [[ $line == Subject* ]] ; then
            printline="yes"
            # Just t make each line start very clear, remove in use.
            echo "============== commit body: start =====================" >> ../report/nobody-result.txt
            continue
        fi
        #If the line starts with "---*" then set var to "no".
        if [[ $line == ---* ]] ; then
            printline="no"
            # Just to make each line end very clear, remove in use.
            echo "============== commit body: end   =====================" >> ../report/nobody-result.txt
            break
        fi
        # If variable is yes, print the line.
        if [[ $printline == "yes" ]] ; then
            echo "[DEBUG] $line"   >> ../report/nobody-result.txt
            line_count=$(echo $line | wc -w)
            body_count=$(($body_count + $line_count))
        fi
    done < "$filename"

    # determine if a commit body exceeds 3 words (Signed-off-by line is already 3 words.)
    echo "[DEBUG] body count is $body_count"
    body_count_criteria=`echo "3+5"|bc`
    if  [[ $body_count -lt $body_count_criteria ]]; then
        echo "[DEBUG] commit body checker is FAILED. patch file name: $filename"
        echo "[DEBUG] current directory is `pwd`"
        check_result="failure"
        global_check_result="failure"
    else
        echo "[DEBUG] commit body checker is PASSED. patch file name: $filename"
        echo "[DEBUG] current directory is `pwd`"
        check_result="success"
    fi
done
if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. No newline abnormally."
    message="Successfully commit body includes +5 words."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-nobody" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A newline abnormally found."
    message="Oooops. Commit message body checker failed. You must write commit message (+5 words) as well as commit title."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-nobody" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
fi



echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-timestamp: Check the timestamp of the commit"
check_result="success"
TIMESTAMP=`git show --pretty="%ct" --no-notes -s`
TIMESTAMP_READ=`git show --pretty="%cD" --no-notes -s`
TIMESTAMP_BUF_3M=$(( $TIMESTAMP - 180 ))
# Let's "accept" 3 minutes of clock drift.
NOW=`date +%s`
NOW_READ=`date`

if [[ $TIMESTAMP_BUF_3M -gt $NOW ]]; then
    check_result="failure"
    global_check_reulst="failure"
elif [[ $TIMESTAMP -gt $NOW ]]; then
    check_result="failure"
    global_check_reulst="failure"
else
    check_result="success"
fi

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A timestamp."
    message="Successfully the commit has no timestamp error."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-timestamp" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A timestamp."
    message="Timestamp error: files are from the future: ${TIMESTAMP_READ} > (now) ${NOW_READ}."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-timestamp" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-executable: Check executable bits for .cpp, .c, .hpp, .h, .prototxt, .caffemodel, .txt., .init"
# Please add more types if you feel proper.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for X in $FILELIST; do
    echo "[DEBUG] exectuable checke - file name is \"$FILELIST\"."
    if [[ $X =~ \.cpp$ || $X =~ \.c$ || $X =~ \.hpp$ || $X =~ \.h$ || $X =~ \.prototxt$ || $X =~ \.caffemodel$ || $X =~ \.txt$ || $X =~ \.ini$ ]]; then
        if [[ -f "$X" && -x "$X" ]]; then
            # It is a text file (.cpp, .c, ...) and is executable. This is invalid!
            check_result="failure"
            global_check_result="failure"
            break
        else
            check_result="success"
        fi
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A executable bits."
    message="Successfully, The commits are passed."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-executable" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A executable bits."
    message="Oooops. The commit has an invalid executable file ${X}. Please turn the executable bits off."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-executable" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    message=":octocat: **cibot**: $user_id, Oooops. The commit has an invalid executable file. The file is **${X}**. Please turn the executable bits off. Run **chmod 644 file-name** command."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

echo "########################################################################################"
echo "[MODULE] TAOS/pr-format-hardcoded-path: Check prohibited hardcoded paths (/home/* for now)"
hardcoded_file="hardcoded-path.txt"
if [[ -f ../report/${hardcoded_file}.tmp ]]; then
    rm -f ../report/${hardcoded_file}.tmp
    touch ../report/${hardcoded_file}.tmp
fi
for X in `echo "${FILELIST}" | grep "$SRC_PATH/.*/" | sed -e "s|.*$SRC_PATH/\([a-zA-Z0-9_]*\)/.*|\1|" | sort -u`; do
    # README.md is added because grep waits for indefinite time if find gives you NULL.
    grep "\"\/home\/" `find $SRC_PATH/$X -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h"` README.md >> ../report/${hardcoded_file}.tmp
done
cat ../report/${hardcoded_file}.tmp | tr '\n' '\r' | sed -e "s|[^\r]*//[^\r]*\"/home/[^\r]*\r||g" | tr '\r' '\n' > ../report/${hardcoded_file}
rm -f ../report/${hardcoded_file}.tmp
VIOLATION=`wc -l < ../report/${hardcoded_file}`
if [[ $VIOLATION -gt 0 ]]
then
    check_result="failure"
    global_check_result="failure"
else
    check_result="success"
fi

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. A hardcoded paths."
    message="Successfully, The commits are passed."
    cibot_pr_report $TOKEN "success" "TAOS/pr-format-hardcoded-path" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo "[DEBUG] Failed. A hardcoded paths."
    message="Oooops. The component you are submitting has hardcoded paths that are not allowed in the source. Please do not hardcode paths."
    cibot_pr_report $TOKEN "failure" "TAOS/pr-format-hardcoded-path" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
fi


##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
echo "Current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh"
source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh

##################################################################################################################
# --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# report if all modules are successfully completed or not.
echo "[DEBUG] Varaible global_check_result is $global_check_result."
if [[ $global_check_result == "success" ]]; then
    # in case of success
    message="Successfully all format checkers are done."
    cibot_pr_report $TOKEN "success" "(INFO)TAOS/pr-format-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    echo "[DEBUG] cibot_pr_report $TOKEN success (INFO)TAOS/pr-format-all $message ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/ ${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of success content to encourage review process
    echo -e "[DEBUG] (INFO)TAOS/pr-format-all: All format modules are passed - it is ready to review!"
    echo -e "[DEBUG] :shipit: Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."

elif [[ $global_check_result == "failure" ]]; then
    # in case of failure
    message="Oooops. There is a failed format checker. Update your code correctly after reading error messages."
    cibot_pr_report $TOKEN "failure" "(INFO)TAOS/pr-format-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint to fix issues
    message=":octocat: **cibot**: $user_id, One of the format checkers is failed. If you want to get a hint to fix this issue, please go to ${REPOSITORY_WEB}/wiki/."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

else
    # in case that CI is broken
    message="Oooops. It seems that CI bot has bug(s). CI bot has to be fixed."
    cibot_pr_report $TOKEN "failure" "(INFO)TAOS/pr-format-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

fi

