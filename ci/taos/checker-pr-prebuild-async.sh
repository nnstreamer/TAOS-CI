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
# @file    checker-pr-prebuild-async.sh
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
#  $dir_ci       directory is CI folder (Absolute path)
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

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# @dependency
# git, which, grep, touch, find, wc, cat, basename, tail, clang-format-4.0, cppcheck, rpmlint, aha, stat, curl
# check if dependent packages are installed
source ./common/api_collection.sh
check_cmd_dep git
check_cmd_dep which
check_cmd_dep grep
check_cmd_dep touch
check_cmd_dep find
check_cmd_dep wc
check_cmd_dep cat
check_cmd_dep basename
check_cmd_dep tail
check_cmd_dep clang-format-4.0
check_cmd_dep cppcheck
check_cmd_dep rpmlint
check_cmd_dep aha
check_cmd_dep stat
check_cmd_dep curl
check_cmd_dep ctags
echo -e "[DEBUG] Checked dependency packages.\n"

# get user ID from the input_repo string
set -- "${input_repo}"
IFS="\/"; declare -a Array=($*); unset IFS;
user_id="@${Array[3]}"

# Set folder name uniquely to run CI in different folder per a PR.
dir_worker="repo-workers/pr-checker"

# Set project repo name of contributor
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
export dir_commit=${dir_worker}/${input_pr}-${input_date}-${input_commit}
# --------------------------- CI Trigger (queued) --------------------------------------------------------------------
message="Trigger: queued. The commit number is $input_commit."
cibot_report $TOKEN "pending" "(INFO)${BOT_NAME}/pr-prebuild-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"



# --------------------------- CI module: start -----------------------------------------------------
pwd
echo -e "[DEBUG] Starting a module of prebuild group ..."
echo -e "[DEBUG] dir_ci is '$dir_ci'" 
echo -e "[DEBUG] dir_worker is '$dir_worker'" 
echo -e "[DEBUG] dir_commit is '$dir_commit'" 

echo -e "[DEBUG] Let's move to a git repository folder."
cd $dir_ci
cd $dir_commit
cd ./${PRJ_REPO_OWNER}
echo -e "Current path: $(pwd)."

# archive a patch file of latest commit with 'format-patch' option
# This *.patch file is used for nobody check.
run_git_format_patch="git format-patch -1 $input_commit --output-directory ../report/"
echo -e "[DEBUG] $run_git_format_patch"
$run_git_format_patch
ls ../report -al

# declare default variables
# check_result variable can get three values such as success, skip, and failure.
# global_check_result variable can get two values such as success and failure.
check_result="success"
global_check_result="success"


# Plug-in folders
##################################################################################################################
echo -e "[MODULE] plugins-base: it is a well-maintained collection of CI plugins as a essential plugin."
echo -e "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo -e "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
echo -e " "
echo -e "Current path: $(pwd)."
echo -e "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-prebuild.sh"

# If there are incorrect statements in a configuration file of the prebuild group, Let's report it.
source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-prebuild.sh 2>> ../pr-plugins-prebuild_error.txt


for plugin in ${prebuild_plugins[*]}
do
    echo -e "[DEBUG] -----------------------------"
    echo -e "[DEBUG] run queue: Running the '${plugin}' module"
    ${plugin}
done

##################################################################################################################

exit_code=0
# --------------------- Report module: submit webhook API for global check result to github website --------------
# report if all modules are successfully completed or not.
echo -e "[DEBUG] Varaible global_check_result is $global_check_result."
if [[ $global_check_result == "success" ]]; then
    # in case of success
    message="Successfully all modules of the prebuild group are done."
    cibot_report $TOKEN "success" "(INFO)${BOT_NAME}/pr-prebuild-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    echo -e "[DEBUG] cibot_report $TOKEN success (INFO)${BOT_NAME}/pr-prebuild-all $message ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/ ${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of success content to encourage review process
    echo -e "[DEBUG] (INFO)${BOT_NAME}/pr-prebuild-all: All modules of the prebuld group are passed - it is ready to review!"
    echo -e "[DEBUG] :shipit: Note that CI bot has two sub-bots such as ${BOT_NAME}/pr-postbuild-all and ${BOT_NAME}/pr-prebuild-all."

elif [[ $global_check_result == "failure" ]]; then
    # in case of failure
    message="Oooops. There is a failed module of the prebuild group. Update your code correctly after reading error messages."
    cibot_report $TOKEN "failure" "(INFO)${BOT_NAME}/pr-prebuild-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"

    # inform PR submitter of a hint to fix issues
    message=":octocat: **cibot**: $user_id, One of the module of prebuild group is failed. If you want to get a hint to fix this issue, please go to ${REPOSITORY_WEB}/wiki/."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
    exit_code=1

else
    # in case that CI is broken
    message="Oooops. It seems that CI bot has bug(s). CI bot has to be fixed."
    cibot_report $TOKEN "failure" "(INFO)${BOT_NAME}/pr-prebuild-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
    exit_code=1

fi

# Return with exit code
exit $exit_code
