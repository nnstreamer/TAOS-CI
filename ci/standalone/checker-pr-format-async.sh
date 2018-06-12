#!/usr/bin/env bash

##
# @file checker-pr-format-async.sh
# @brief It checks format rules whenever a PR is submitted.
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
# "[MODULE] CI/pr-format-file-size      Check the file size to not include big binary files"
# "[MODULE] CI/pr-format-newline        Check the illegal newline handlings in text files"
# "[MODULE] CI/pr-format-doxygen        Check documenting code using doxygen in text files"
# "[MODULE] CI/pr-format-cppcheck       Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck"
# "[MODULE] CI/pr-format-pylint         Check dangerous coding constructs in source codes (*.py) with pylint"
# "[MODULE] CI/pr-format-rpm-spec       Check the spec file with rpmlint"
# "[MODULE] CI/pr-format-nobody         Check the commit message body"
# "[MODULE] CI/pr-format-timestamp      Check the timestamp of the commit"
# "[MODULE] CI/pr-format-executable     Check executable bits for .cpp, .h, .hpp, .c, .caffemodel, .prototxt, .txt."
# "[MODULE] CI/pr-format-hardcoded-path Check prohibited hardcoded paths (/home/* for now)"
# "[MODULE] plugins-good                Plugin group that follow Apache license with good quality"
# "[MODULE] plugins-ugly                Plugin group that does not have evaluation and aging test enough"
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

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# @dependency
# git, which, grep, touch, find, wc, cat, basename, tail, clang-format-4.0, cppcheck, rpmlint, aha, stat
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
# --------------------------- CI Trigger ----------------------------------------------------------------------
/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data '{"state":"pending","context":"(INFO)CI/pr-format-all","description":"Triggered. The commit number is '$input_commit'","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
${GITHUB_WEBHOOK_API}/statuses/$input_commit

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
echo "[MODULE] CI/pr-format-file-size: Check the file size to not include big binary files"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for i in ${FILELIST}; do
    # check the files in case that there are files that exceed 5MB.
    echo "[DEBUG] file name is ( $i ) . "
        echo "[DEBUG] ( $i ) file is a text file."
        FILESIZE=$(stat -c%s "$i")
        # Add thousands separator in a number
        FILESIZE_NUM=`echo $FILESIZE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
        if  [[ $FILESIZE -le 5*1024*1024 ]]; then
            echo "[DEBUG] Passed. patch file name: $i. value is $FILESIZE_NUM."
            check_result="success"
        else
            echo "[DEBUG] Failed. patch file name: $i. value is $FILESIZE_NUM."
            check_result="failure"
            global_check_result="failure"
            break
        fi
done

# get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
i_filename=$(basename $i)

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. File size."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-format-filesize","description":"Successfully all files are passed without any issue of file size.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. File size."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"CI/pr-format-filesize","description":"Oooops. File size checker is failed at '$i_filename'","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"body":":octocat: **cibot**: '$user_id', It seems that there are big files that exceed 5MB in your PR. Please resubmit your PR after reducing '$i' size."}' \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-newline: Check the illegal newline handlings in text files"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for i in ${FILELIST}; do
    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $i )."
    newline_count=0
    if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
        # in case of text files: *.c|*.h|*.cpp|*.py|*.md|*.xml|*.txt|*.launch|*.sh|*.php|*.html|*.json|*.spec|*.manifest|*.CODEOWNERS )
        echo "[DEBUG] ( $i ) file is a text file."
        num=$(( $num + 1 ))
        # fetch patch content of a specified file from  a commit.
        echo "[DEBUG] git show $i > ../report/${num}.patch "
        git show $i > ../report/${num}.patch
        # check if the last line of a patch file includes "\ No newline....." statement.
        newline_count=$(cat ../report/${num}.patch  | tail -1 | grep '^\\ No newline' | wc -l)
        if  [[ $newline_count == 0 ]]; then
            echo "[DEBUG] Newline checker is passed. patch file name: $i. The number of newlines is $newline_count."
            check_result="success"
        else
            echo "[DEBUG] Newline checker is failed. patch file name: $i. The number of newlines is $newline_count."
            touch ../report/newline-error-${num}.patch
            echo " There are ${newline_count} '\ No newline ...' statements in the ${num}.patch file." > ../report/newline-error-${num}.patch
            check_result="failure"
            global_check_result="failure"
            break
        fi
    fi
done

# get just a file name from a path to avoid length limitation (e.g., max 140 characters) of 'description' tag
i_filename=$(basename $i)

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. No newline anomaly."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-format-newline","description":"Successfully all text files are passed without newline issue.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. A newline anomaly happened."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"CI/pr-format-newline","description":"Oooops. New line checker is failed at '$i_filename'","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"body":":octocat: **cibot**: '$user_id', There is a newline issue. The final line of a text file should have newline character. Please resubmit your PR after fixing end of line in '$i'."}' \
     ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-doxygen: Check documenting code using doxygen in text files"
# investigate generated all *.patch files
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for i in ${FILELIST}; do
    if [[ $i =~ ^obsolete/.* ]]; then
        continue
    fi
    if [[ $i =~ ^external/.* ]]; then
        continue
    fi
    # Handle only text files in case that there are lots of files in one commit.
    echo "[DEBUG] file name is ( $i ) . "
    if [[ `file $i | grep "ASCII text" | wc -l` -gt 0 ]]; then
        # in case of source code files: *.c|*.h|*.cpp|*.py|*.sh|*.php )
        case $i in
            # in case of C/C++ code
            *.c|*.h|*.cpp|*.hpp )
                echo "[DEBUG] ( $i ) file is  source code with the text format."
                doxygen_lang="doxygen-cncpp"
                # Append a doxgen rule step by step
                doxygen_rules="@file @brief"
                doxygen_rule_num=0
                doxygen_rule_all=0
                for word in $doxygen_rules
                do
                    echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word."
                    doxygen_rule_all=$(( doxygen_rule_all + 1 ))
                    doxygen_rule[$doxygen_rule_all]=`cat ${i} | grep "$word" | wc -l`
                    doxygen_rule_num=$(( $doxygen_rule_num + ${doxygen_rule[$doxygen_rule_all]} ))
                done
                if  [[ $doxygen_rule_num -le 0 ]]; then
                    echo "[DEBUG] $doxygen_lang: failed. file name: $i, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $doxygen_lang: passed. file name: $i, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                    check_result="success"
                fi
                ;;
            # in case of Python code
            *.py )
                echo "[DEBUG] ( $i ) file is  source code with the text format."
                doxygen_lang="doxygen-python"
                # Append a doxgen rule step by step
                doxygen_rules="@package @brief"
                doxygen_rule_num=0
                doxygen_rule_all=0
                for word in $doxygen_rules
                do
                    echo "[DEBUG] $doxygen_lang: doxygen tag for current $doxygen_lang code is $word."
                    doxygen_rule_all=$(( doxygen_rule_all + 1 ))
                    doxygen_rule[$doxygen_rule_all]=`cat ${i} | grep "$word" | wc -l`
                    doxygen_rule_num=$(( $doxygen_rule_num + ${doxygen_rule[$doxygen_rule_all]} ))
                done
                if  [[ $doxygen_rule_num -le 0 ]]; then
                    echo "[DEBUG] $doxygen_lang: failed. file name: $i, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                    check_result="failure"
                    global_check_result="failure"
                    break
                else
                    echo "[DEBUG] $doxygen_lang: passed. file name: $i, ($doxygen_rule_num)/$doxygen_rule_all tags are found."
                    check_result="success"
                fi
                ;;
            * )
                echo "[DEBUG] ( $i ) file is not source code with the text format."
                check_result="success"
                ;;
        esac
    fi
done

if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Passed. doxygen documentation."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-format-doxygen","description":"Successfully source code(s) includes doxygen document correctly.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. doxygen documentation."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"CI/pr-format-doxygen","description":"Oooops. The doxygen checker is failed. Please, write doxygen document in your code.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"body\":\":octocat: **cibot**: $user_id, **$i** does not include doxygen tags such as $doxygen_rules. You must include the doxygen tags in the source code at least. \"}" \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-cppcheck: Check dangerous coding constructs in source codes (*.c, *.cpp) with cppcheck"
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-cppcheck\",\"description\":\"Successfully source code(s) is written without dangerous coding constructs.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. static code analysis tool - cppcheck."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-cppcheck\",\"description\":\"Skipped. Your PR does not include c/c++ code(s).\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. static code analysis tool - cppcheck."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"failure\",\"context\":\"CI/pr-format-cppcheck\",\"description\":\"Oooops. cppcheck is failed. Please, read '$cppcheck_result' for more details.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"body\":\":octocat: **cibot**: $user_id, **$i** includes bug(s). You must fix incorrect coding constructs in the source code before entering a review process. \"}" \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi


echo "########################################################################################"
echo "[MODULE] CI/pr-format-pylint: Check dangerous coding constructs in source codes (*.py) with pylint"
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
                # Check C/C++ file, enable all checks.
                if [[ ! -e ~/.pylintrc ]]; then
                    $py_analysis_sw --generate-rcfile > ~/.pylintrc
                fi
                $py_analysis_sw $py_analysis_rules  > ../report/${py_check_result}
                line_count=`wc -l $cppcheck_result`
                # TODO: apply strict rule with pass/failure instead of report when developers understand investigation result of pylint.
                if  [[ $line_count -lt 0 ]]; then
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-pylint\",\"description\":\"Successfully source code(s) is written without dangerous coding constructs.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"body\":\":octocat: **cibot**: $user_id, We generate a report if there are dangerous coding constructs in your code. Please read ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${py_check_result}.\"}" \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

elif [[ $check_result == "skip" ]]; then
    echo "[DEBUG] Skipped. static code analysis tool - pylint."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-pylint\",\"description\":\"Skipped. Your PR does not include python code(s).\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

else
    echo "[DEBUG] Failed. static code analysis tool - pylint."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"failure\",\"context\":\"CI/pr-format-pylint\",\"description\":\"Oooops. cppcheck is failed. Please, read '$py_check_result' for more details.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint in more detail
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"body\":\":octocat: **cibot**: $user_id, It seems that **$i** includes bug(s). You must fix incorrect coding constructs in the source code before entering a review process. \"}" \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-rpm-spec: Check the spec file with rpmlint"
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
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"body\":\":octocat: **cibot**: [FYI] We inform $user_id of a check result of spec file with rpmlint. If there are some warning(s) or error(s) in your spec file, modify ${i} correctly after reading the report at ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${RPM_SPEC_REPORT_FILE} \"}" \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. rpm spec checker."
        /usr/bin/curl -H "Content-Type: application/json" \
         -H "Authorization: token "$TOKEN"  " \
         --data '{"state":"success","context":"CI/pr-format-rpm-spec","description":"Successfully rpm spec checker is done.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
         ${GITHUB_WEBHOOK_API}/statuses/$input_commit
    else
        echo "[DEBUG] Failed. rpm spec checker."
        /usr/bin/curl -H "Content-Type: application/json" \
         -H "Authorization: token "$TOKEN"  " \
         --data '{"state":"failure","context":"CI/pr-format-rpm-spec","description":"Oooops. The rpm spec checker is failed.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
         ${GITHUB_WEBHOOK_API}/statuses/$input_commit
    fi
else
    echo "[DEBUG] Skipped. rpm spec checker."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-format-rpm-spec","description":"Skipped. rpm spec checker is jumped because you did not modify a spec file.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-nobody: Check the commit message body"
check_result="success"
for filename in ../report/000*.patch; do
    line_count=0
    body_count=0
    nobody_result=0
    #While loop to read line by line
    while IFS= read -r line; do
        #If the line starts with "Subject*" then set var to "yes".
        if [[ $line == Subject* ]] ; then
            printline="yes"
            # Just t make each line start very clear, remove in use.
            echo "----------------------->>"
            continue
        fi
        #If the line starts with "---*" then set var to "no".
        if [[ $line == ---* ]] ; then
            printline="no"
            # Just to make each line end very clear, remove in use.
            echo "-----------------------<<"
            break
        fi
        # If variable is yes, print the line.
        if [[ $printline == "yes" ]] ; then
            echo "[DEBUG] $line"
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-format-nobody","description":"Successfully commit body includes +5 words.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. A newline abnormally found."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"CI/pr-format-nobody","description":"Oooops. Commit message body checker failed. You must write commit message (+5 words) as well as commit title.","target_url":"'${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
fi



echo "########################################################################################"
echo "[MODULE] CI/pr-format-timestamp: Check the timestamp of the commit"
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-timestamp\",\"description\":\"Successfully the commit has no timestamp error.\",\"target_url\":\"$CISERVER\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. A timestamp."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"failure\",\"context\":\"CI/pr-format-timestamp\",\"description\":\"Timestamp error: files are from the future: ${TIMESTAMP_READ} > (now) ${NOW_READ}.\",\"target_url\":\"$CISERVER\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-executable: Check executable bits for .cpp, .h, .hpp, .c, .caffemodel, .prototxt, .txt."
# Please add more types if you feel proper.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
for X in $FILELIST; do
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-executable\",\"description\":\"Successfully, The commits are passed.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/ \"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. A executable bits."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"failure\",\"context\":\"CI/pr-format-executable\",\"description\":\"Oooops. The commit has an invalid executable: ${X}. Please turn the executable bits off.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
fi

echo "########################################################################################"
echo "[MODULE] CI/pr-format-hardcoded-path: Check prohibited hardcoded paths (/home/* for now)"
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
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"success\",\"context\":\"CI/pr-format-hardcoded-path\",\"description\":\"Successfully, The commits are passed.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
else
    echo "[DEBUG] Failed. A hardcoded paths."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"state\":\"failure\",\"context\":\"CI/pr-format-hardcoded-path\",\"description\":\"Oooops. The component you are submitting has hardcoded paths that are not allowed in the source. Please do not hardcode paths.\",\"target_url\":\"${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/report/${hardcoded_file}\"}" \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
fi


##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo "[MODULE] plugins-ugly: Plugin group that does not have evaluation and aging test enough"
echo "Current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh"
source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh

##################################################################################################################
# --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# report if all modules are successfully completed or not.

if [[ $global_check_result == "success" ]]; then
    # in case of success
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"(INFO)CI/pr-format-all","description":"Successfully all format checkers are done. Note that CI bot has two sub-bots such as CI/pr-audit-all and CI/pr-format-all.","target_url":"'$CISERVER${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of success content to encourage review process
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"body":":octocat: **cibot**: :+1: **(INFO)CI/pr-format-all**: All format modules are passed - it is ready to review! :shipit: Note that CI bot has two sub-bots such as CI/pr-audit-all and CI/pr-format-all."}' \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

elif [[ $global_check_result == "failure" ]]; then
    # in case of failure
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"(INFO)CI/pr-format-all","description":"Oooops. There is a failed format checker. Update your code correctly after reading error messages.","target_url":"'$CISERVER${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

    # inform PR submitter of a hint to fix issues
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data '{"body":":octocat: **cibot**: '$user_id', One of the format checkers is failed. If you want to get a hint to fix this issue, please go to '${REPOSITORY_WEB}/wiki/CI-System-for-continuous-integration'."}' \
    ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments

else
    # in case that CI is broken
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"error","context":"(INFO)CI/pr-format-all","description":"Oooops. It seems that CI bot has bug(s). CI bot has to be fixed.","target_url":"'$CISERVER${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit

fi

