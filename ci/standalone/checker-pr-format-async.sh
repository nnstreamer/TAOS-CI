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
# @file    checker-pr-format-async.sh
# @brief   It checks format rules whenever a PR is submitted.
# @see     https://github.com/nnsuite/TAOS-CI
# @author  Geunsik Lim <geunsik.lim@samsung.com>
# @param   arguments are received from CI manager
#  arg1:   date(Ymdhms)
#  arg2:   commit number
#  arg3:   repository address of PR
#  arg4:   branch name
#  arg5:   PR number
#  arg6:   delivery id
#
# @see variables to control the directories
#  $dir_ci       directory is CI folder
#  $dir_worker   directory is PR worker folder
#  $dir_commit   directory is commit folder
#
# @modules:
# "[MODULE] plugins-base:        A well-maintained collection of CI plugins as a essential plugin"
# "[MODULE] plugins-good:        Plugin group that follow Apache license with good quality"
# "[MODULE] plugins-staging:     Plugin group that does not have evaluation and aging test enough"

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
source ./common/api_collection.sh

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# @dependency
# git, which, grep, touch, find, wc, cat, basename, tail, clang-format-4.0, cppcheck, rpmlint, aha, stat, curl
# check if dependent packages are installed
source ./common/api_collection.sh
check_dependency git
check_dependency which
check_dependency grep
check_dependency touch
check_dependency find
check_dependency wc
check_dependency cat
check_dependency basename
check_dependency tail
check_dependency clang-format-4.0
check_dependency cppcheck
check_dependency rpmlint
check_dependency aha
check_dependency stat
check_dependency curl
check_dependency ctags
echo -e "[DEBUG] Checked dependency packages.\n"

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
echo -e "[DEBUG] Starting pr-format....\n"

# check if existing folder exists.
if [[ -d $dir_commit ]]; then
    echo -e "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
fi

# check if github project folder already exists
cd $dir_commit
if [[ -d ${PRJ_REPO_OWNER} ]]; then
    echo -e "[DEBUG] WARN: ${PRJ_REPO_OWNER} already exists and is not an empty directory."
    echo -e "[DEBUG] WARN: So removing the existing directory..."
    rm -rf ./${PRJ_REPO_OWNER}
fi

# create 'report' folder to archive log files.
mkdir ./report

# run "git clone" command to download git source
pwd
sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo
if [[ $? != 0 ]]; then
    echo -e "git clone --reference ${REFERENCE_REPOSITORY} $input_repo "
    echo -e "[DEBUG] ERROR: Oooops. 'git clone' command failed."
    exit 1
else
    echo -e "[DEBUG] 'git clone' command is successfully finished."
fi

# run "git branch" to use commits from PR branch
cd ./${PRJ_REPO_OWNER}
git checkout -b $input_branch origin/$input_branch
git branch

echo -e "Make sure commit all changes before running this checker."

# --------------------------- Jenkins module: start -----------------------------------------------------
# archive a patch file of latest commit with 'format-patch' option
# This *.patch file is used for nobody check.
git format-patch -1 $input_commit --output-directory ../report/

# declare default variables
# check_result variable can get three values such as success, skip, and failure.
# global_check_result variable can get two values such as success and failure.
check_result="success"
global_check_result="success"


# Plug-in folders
##################################################################################################################
echo -e "[MODULE] plugins-base: it is a well-maintained collection of CI plugins as a essential plugin.
echo -e "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo -e "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
echo -e " "
echo -e "Current path: $(pwd)."
echo -e "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh"
source ${REFERENCE_REPOSITORY}/ci/standalone/config/config-plugins-format.sh

##################################################################################################################


# --------------------- Report module: submit webhook API for global check result to github website --------------
# report if all modules are successfully completed or not.
echo -e "[DEBUG] Varaible global_check_result is $global_check_result."
if [[ $global_check_result == "success" ]]; then
    # in case of success
    message="Successfully all format checkers are done."
    cibot_pr_report $TOKEN "success" "(INFO)TAOS/pr-format-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    echo -e "[DEBUG] cibot_pr_report $TOKEN success (INFO)TAOS/pr-format-all $message ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/ ${GITHUB_WEBHOOK_API}/statuses/$input_commit"

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

