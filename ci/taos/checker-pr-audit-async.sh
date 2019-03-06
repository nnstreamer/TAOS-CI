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
# @file checker-pr-audit-async.sh
# @brief It executes a build test whenever a PR is submitted.
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @dependency: gbs, tee, curl, grep, wc, cat, sed, awk, basename
# @param arguments are received by ci bot
#  arg1: date(YmdHisu)
#  arg2: commit number
#  arg3: repository address of PR
#  arg4: branch name
#  arg5: PR number
#  arg6: delivery id
#
# @see directory variables
#  $dir_ci       directory for webhooks (Absolute path)
#  $dir_worker   directory for PR workers
#  $dir_commit   directory for commits
#
# @modules:
# [MODULE] TAOS/pr-audit-build-tizen-x86_64     Check if 'gbs build -A x86_64' can be successfully passed.
# [MODULE] TAOS/pr-audit-build-tizen-armv7l     Check if 'gbs build -A armv7l' can be successfully passed.
# [MODULE] TAOS/pr-audit-build-ubuntu           Check if 'pdebuild' can be successfully passed.
# [MODULE] TAOS/pr-audit-build-yocto              Check if 'devtool' can be successfully passed.
# [MODULE] plugins-base                         Plugin group that consist of a well-maintained modules
# [MODULE] plugins-good                         Plugin group that follow Apache license with good quality
# [MODULE] plugins-staging                      Plugin group that does not have evaluation and aging test enough

# --------------------------- Pre-setting module ----------------------------------------------------------------------
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6

# Note that the server administrator has to specify appropriate variables after installing required packages.
source ./config/config-server-administrator.sh

# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation from cibot.php
source ./config/config-environment.sh

# Check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# Import global variables
source ./common/global-variable.sh

# Check if dependent packages are installed
source ./common/api_collection.sh
check_dependency gbs
check_dependency tee
check_dependency curl
check_dependency grep
check_dependency wc
check_dependency cat
check_dependency sed
check_dependency awk
check_dependency basename
echo "[DEBUG] Checked dependency packages.\n"

# Include a PR scheduler module to handle a run-queue and wait-queue while running a build tasks
source ./common/pr-scheduler.sh

# Include a Out-of-PR(OOP) killer to handle lots of duplicated same PRs with LRU approach
source ./common/out-of-pr-killer.sh

# Get user ID from the input_repo string
set -- "${input_repo}"
IFS="\/"; declare -a Array=($*); unset IFS;
user_id="@${Array[3]}"

# Set folder name uniquely to run CI in different folder per a PR.
dir_worker="repo-workers/pr-checker"

# Set project repo name of contributor
PRJ_REPO_OWNER=`echo $(basename "${input_repo%.*}")`

cd ..
export dir_ci=`pwd`

# Create dir_work folder
if [[ ! -d $dir_worker ]]; then
    mkdir -p $dir_worker
fi
cd $dir_worker
export dir_worker=$dir_worker

# Check if dir_commit folder exists, then, create dir_commit folder
# let's keep the existing result although the same target directory already exists.
cd $dir_ci
export dir_commit=${dir_worker}/${input_pr}-${input_date}-${input_commit}

# Out-of-Pr (OOP) killer:
# Stop compulsorily the previous same PRs invoked by checker-pr-gateway.sh
# when the developers try to send a lot of same PRs repeatedly.
run_oop_killer

# --------------------------- CI Trigger (wait queue) -----------------------------------------------------------------

if [[ $pr_comment_pr_updated == 1 ]]; then
    # Inform all developers of their activity whenever PR submitter resubmit their PR after applying comments of reviews
    message=":dart: **cibot**: $user_id has updated the pull request."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

# Load the configuraiton file that user defined to build selectively.
echo "[MODULE] plugins-base: Plugin group that does have well-maintained features as a base module."
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo "[MODULE] plugins-staging: Plugin group that does not has evaluation and aging test enough"

echo "[DEBUG] The current directory: $(pwd)"
source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-audit.sh 2>> ../audit_module_error.log
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-audit.sh"

# Create new context name to monitor progress status of a checker
message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
cibot_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    echo -e "[DEBUG] -----------------------------"
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] wait queue: Job is queued to run 'gbs build -A $arch (for Tizen)' command."
            ${plugin}-wait-queue $arch
        done
    else
        echo "[DEBUG] wait queue: Job is queue to run $plugin"
        ${plugin}-wait-queue
    fi
done


# --------------------------- audit module: start -----------------------------------------------------

echo "[DEBUG] The current directory: $(pwd)"
echo -e "[DEBUG] Starting an audit checker...."
echo -e "[DEBUG] dir_ci is '$dir_ci'" 
echo -e "[DEBUG] dir_worker is '$dir_worker'" 
echo -e "[DEBUG] dir_commit is '$dir_commit'"

echo -e "[DEBUG] Let's move to a git repository folder."
cd $dir_ci
cd $dir_commit
cd ./${PRJ_REPO_OWNER}
echo "[DEBUG] The current directory: $(pwd)"

echo -e "[MODULE] Exception Handling: Let's skip CI-Build/UnitTest in case of no buildable files. "

# Check if PR-build can be skipped.
# BUILD_MODE is created in order that developers can do debugging easily in console after adding new CI facility.
#
# Note that ../report/build_log_${input_pr}_output.txt includes both stdout(1) and stderr(2) in case of BUILD_MODE=1.
# BUILD_MODE=0 : run "gbs build" command without generating debugging information.
# BUILD_MODE=1 : run "gbs build" command with generation of debugging contents.
# BUILD_MODE=99: skip "gbs build" procedures to do debugging of another CI function.
FILELIST=`git show --pretty="format:" --name-only --diff-filter=AMRC`
BUILD_MODE=99
for file in $FILELIST
do
    if [[ "$file" =~ ($SKIP_CI_PATHS_AUDIT)$ ]]; then
        echo "[DEBUG] $file may be skipped."
    else
        echo "[DEBUG] $file cannot be skipped."
        BUILD_MODE=0
        break
    fi
done


# Declare default variables
check_result="success"
global_check_result="success"

if [[ -d $REPOCACHE ]]; then
    echo "[DEBUG] repocache, $REPOCACHE already exists. Good"
    # TODO: periodically delete the contents of REPOCACHE. (e.g., every Sunday?)
else
    echo "[DEBUG] repocache, $REPOCACHE does not exists. Create one"
    # Delete if it's a file.
    rm -f $REPOCACHE
    mkdir -p $REPOCACHE
fi
echo "[DEBUG] Link to the RPM repo cache to accelerate GBS start up"
mkdir -p ./GBS-ROOT/local/
pushd ./GBS-ROOT/local
ln -s $REPOCACHE cache
popd


# --------------------------- CI Trigger (ready queue) --------------------------------------------------------

# Note that package build results in the unexpected build failure due to some reasons such as server issue,
# changes of build environment, and high overload of run queeue. So We need to provide ready queue to inform
# users of current status of a pull request.

message="Trigger: wait queue. The commit number is $input_commit."
cibot_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    echo -e "[DEBUG] -----------------------------"
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] ready queue: Job is started to run 'gbs build -A $arch (for Tizen)' command."
            ${plugin}-ready-queue $arch
        done
    else
        echo "[DEBUG] ready queue: Job is started to run $plugin"
        ${plugin}-ready-queue
    fi
done


# --------------------------- CI Trigger (run queue) --------------------------------------------------------

# Note that  major job is run qeue amon the queues while executing the audit checker. So we have to notify
# if the current status of pull reqeust is building or not.

message="Trigger: run queue. The commit number is $input_commit."
cibot_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    # Run the pull request scheduler: manage queues to minimize overhead possibility of the server
    # due to (1) too many PRs and (2) the low-end server equipment.
    # The 'pr_sched_runqueue' function is located in 'common' folder.
    pr_sched_runqueue "The $plugin plugin module"

    echo -e "-----------------------------"
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] run queue: Compiling the source code to Tizen $arch RPM package."
            ${plugin}-run-queue $arch
        done
    else
        echo "[DEBUG] run queue: Running the '$plugin' module"
        ${plugin}-run-queue
    fi
done

if [[ ${BUILD_TEST_FAIL} -eq 1 ]]; then
    # Comment a hint on failed PR to author.
    message=":octocat: **cibot**: $user_id, A builder checker could not be completed because one of the checkers is not completed. In order to find out a reason, please go to ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

# --------------------------- Report module: generate a log file and check other conditions --------------------------

# Save webhook information for debugging
echo ""
echo "[DEBUG] Start time       : ${input_date}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Commit number    : ${input_commit}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Repository       : ${input_repo}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Branch name      : ${input_branch}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] PR number        : ${input_pr}"          >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] X-GitHub-Delivery: ${input_delivery_id}" >> ../report/build_log_${input_pr}_output.txt

# Optimize size of log file (e.g., from 20MB to 1MB)
# remove unnecessary contents that are created by resource checker
__log_size_filter="/]]$\|for.*req_build.*in\|for.*}'\|']'$\|found=\|basename\|search_res\|local.*'target=/ d"
sed "${__log_size_filter}" ../report/build_log_${input_pr}_output.txt > ../report/build_log_${input_pr}_output_tmp.txt
rm -f  ../report/build_log_${input_pr}_output.txt
mv ../report/build_log_${input_pr}_output_tmp.txt ../report/build_log_${input_pr}_output.txt
ls -al

# Inform developers of the warning message in case that the log file exceeds 10MB.
echo "[DEBUG] Check if the log file size exceeds 10MB."

FILESIZE=$(stat -c%s "../report/build_log_${input_pr}_output.txt")
if  [[ $FILESIZE -le 10*1024*1024 ]]; then
    echo "[DEBUG] Passed. The file size of build_log_${input_pr}_output.txt is $FILESIZE bytes."
    check_result="success"
else
    echo "[DEBUG] Failed. The file size of build_log_${input_pr}_output.txt is $FILESIZE bytes."
    check_result="failure"
    break
fi

# Add thousands separator in a number
FILESIZE_NUM=`echo $FILESIZE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
if [[ $check_result == "success" ]]; then
    echo "[DEBUG] Good job. the log file does not exceed 10MB. The file size of build_log_${input_pr}_output.txt is $FILESIZE_NUM bytes."
else
    # inform PR submitter of a hint in more detail
    message=":fire: **cibot**: $user_id, Oooops. The log file exceeds 10MB due to incorrect commit(s). The file size of build_log_${input_pr}_output.txt is **$FILESIZE_NUM** bytes    . Please resubmit after updating your PR to reduce the file size of build_log_${input_pr}_output.txt."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

# --------------------------- Report module: submit  global check result -----------------------------------------------
# Report if all modules are successfully completed or not.
echo "[DEBUG] Send a total report with global_check_result variable. global_check_result is ${global_check_result}. "

if [[ $global_check_result == "success" ]]; then
    # The global check is succeeded.
    message="Successfully all audit modules are passed. Commit number is $input_commit."
    cibot_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    # If contributors want later, let's inform developers of CI test result to go to a review process as a final step before merging a PR
    echo "[DEBUG] All audit modules are passed - it is ready to review! :shipit:. Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."

elif [[ $global_check_result == "failure" ]]; then
    # The global check is failed.
    message="Oooops. One of the audits is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
    cibot_report $TOKEN "failure" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
else
    # The global check is failed due to CI error.
    message="CI Error. There is a bug in CI script. Please contact the CI administrator."
    cibot_report $TOKEN "error" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    echo -e "[DEBUG] It seems that this script has a bug. Please check value of \$global_check_result."
fi

# --------------------------- Cleaner:  Remove unnecessary directories --------------------
# If you have to remove unnecessary directory or files as a final step
# Please append a command below. 
echo "[DEBUG] The current directory: $(pwd)."


