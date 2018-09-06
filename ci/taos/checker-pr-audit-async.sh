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
#  $dir_ci       directory for webhooks
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

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

# check if dependent packages are installed
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

# get user ID from the input_repo string
set -- "${input_repo}"
IFS="\/"; declare -a Array=($*); unset IFS;
user_id="@${Array[3]}"

# Set folder name uniquely to run CI in different folder per a PR.
dir_worker="repo-workers/pr-audit"

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
export dir_commit=${dir_worker}/${input_date}-${input_pr}-${input_commit}

# --------------------------- Out-of-commit (OOC) killer: kill duplicated PR request ----------------------------------

# kill PIDs that were previously invoked by checker-pr-audit.sh with the same PR number.
echo "[DEBUG] Starting killing activity to kill previously invoked checker-pr-audit.sh with the same PR number.\n"
ps aux | grep "^www-data.*bash \./checker-pr-audit.sh" | while read line
do
    victim_pr=`echo $line  | awk '{print $17}'`
    victim_date=`echo $line  | awk '{print $13}'`
    # Info: pid1 is checker-pr-audit.sh, pid2 is checker-pr-audit-async.sh, and pid3 is "gbs build" command.
    victim_pid1=`ps -ef | grep bash | grep checker-pr-audit.sh       | grep $input_pr | grep $victim_date | awk '{print $2}'`
    victim_pid2=`ps -ef | grep bash | grep checker-pr-audit-async.sh | grep $input_pr | grep $victim_date | awk '{print $2}'`
    victim_pid3=`ps -ef | grep python | grep gbs | grep "_pr_number $input_pr" | grep $victim_date | awk '{print $2}'`

    # The process killer allows to kill only task(s) in case that there are running lots of tasks with same PR number.
    if [[ ("$victim_pr" -eq "$input_pr") && (1 -eq "$(echo "$victim_date < $input_date" | bc)") ]]; then
        echo "[DEBUG] victim_pr=$victim_pr, input_pr=$input_pr, victim_date=$victim_date, input_date=$input_date "
        echo "[DEBUG] killing PR $victim_pr (pid <$victim_pid1> <$victim_pid2> <$victim_pid3>)."
        kill $victim_pid1
        kill $victim_pid2
        kill $victim_pid3
        sleep 1
        # Handle a possibility that someone updates a single PR multiple times within 1 second.
        echo "[DEBUG] removing the ./${dir_worker}/${victim_date}-${victim_pr}-* folder"
        rm -rf ./${dir_worker}/${victim_date}-${victim_pr}-*
    fi
done

# --------------------------- CI Trigger (wait queue) -----------------------------------------------------------------

if [[ $pr_comment_pr_updated == 1 ]]; then
    # inform all developers of their activity whenever PR submitter resubmit their PR after applying comments of reviews
    message=":dart: **cibot**: $user_id has updated the pull request."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

# load the configuraiton file that user defined to build selectively.
echo "[MODULE] plugins-base: Plugin group that does have well-maintained features as a base module."
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
echo "[MODULE] plugins-staging: Plugin group that does not has evaluation and aging test enough"
echo "Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-audit.sh 2>> ../audit_module_error.log
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/config/config-plugins-audit.sh"

# create new context name to monitor progress status of a checker
message="Trigger: wait queue. There are other build jobs and we need to wait.. The commit number is $input_commit."
cibot_pr_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] Job is queued to run 'gbs build -A $arch(for Tizen)' command."
            ${plugin}-wait-queue $arch
        done
    else
        echo "[DEBUG] Job is queue to run $plugin"
        ${plugin}-wait-queue
    fi
done



# --------------------------- git-clone module: clone git repository -------------------------------------------------
echo "[DEBUG] Starting pr-audit....\n"

# check if existing folder already exists
if [[ -d $dir_commit ]]; then
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
else
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory does not exists."
fi

# check if github project folder already exists
pwd
cd $dir_commit
if [[ -d ${PRJ_REPO_OWNER} ]]; then
    echo "[DEBUG] WARN: ${PRJ_REPO_OWNER} already exists and is not an empty directory."
    echo "[DEBUG] WARN: Removing the existing directory..."
    rm -rf ./${PRJ_REPO_OWNER}
fi

# create 'report' folder to archive log files.
mkdir ./report

# run "git clone" command to download git source
# options of 'sudo' command: 
# 1) The -H (HOME) option sets the HOME environment variable to the home directory of the target user (root by default)
# as specified in passwd. By default, sudo does not modify HOME.
# 2) The -u (user) option causes sudo to run the specified command as a user other than root. To specify a uid instead of a username, use #uid.
pwd
sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo
if [[ $? != 0 ]]; then
    echo "[DEBUG] ERROR: 'git clone' command is failed because of incorrect setting of CI server."
    echo "[DEBUG] Please check /var/www/ permission, /var/www/html/.netrc, and /var/www/html/.gbs.conf."
    echo "[DEBUG] current id: $(id)"
    echo "[DEBUG] current path: $(pwd)"
    echo "[DEBUG] $ sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo"
    exit 1
fi

# run "git branch" to use commits from PR branch
cd ./${PRJ_REPO_OWNER}
git checkout -b $input_branch origin/$input_branch
git branch

# --------------------------- audit module: start -----------------------------------------------------

echo "[MODULE] Exception Handling: Let's skip CI-Build/UnitTest in case of no buildable files. "

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


# declare default variables
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

# --------------------------- Commit scheduler: manage hardware resource in case of too many PRs ----------------------

# Let's accommodate upto 8 gbs tasks (one is "grep" process) to maintain a available system resource of the build server.
# Job queue: Fairness or FCFS is not guaranteed.
# $RANDOM is an internal bash function (not a constant) - http://tldp.org/LDP/abs/html/randomvar.html
# To enhance a job queue, refer to http://hackthology.com/a-job-queue-in-bash.html

# Commit scheduler for Tizen build (gbs)
JOBS_PR=8
while [ `ps aux | grep "sudo.*gbs build" | wc -l` -gt $JOBS_PR ]
do
    WAITTIME=$(( ( RANDOM % 20 ) + 20 ))
    sleep $WAITTIME
done

# Todo: Commit scheduler for Ubuntu build (pdebuild)
# Todo: Commit scheduler for Yocto  build (devtool)

# --------------------------- CI Trigger (ready queue) --------------------------------------------------------

# Note that package build results in the unexpected build failure due to some reasons such as server issue,
# changes of build environment, and high overload of run queeue. So We need to provide ready queue to inform
# users of current status of a pull request.

message="Trigger: wait queue. The commit number is $input_commit."
cibot_pr_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] Job is started to run 'gbs build -A $arch(for Tizen)' command."
            ${plugin}-ready-queue $arch
        done
    else
        echo "[DEBUG] Job is started to run $plugin"
        ${plugin}-ready-queue
    fi
done


# --------------------------- CI Trigger (run queue) --------------------------------------------------------

# Note that  major job is run qeue amon the queues while executing the audit checker. So we have to notify
# if the current status of pull reqeust is building or not.

message="Trigger: run queue. The commit number is $input_commit."
cibot_pr_report $TOKEN "pending" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

for plugin in ${audit_plugins[*]}
do
    if [[ ${plugin} == "pr-audit-build-tizen" ]]; then
        for arch in $pr_build_arch_type
        do
            echo "[DEBUG] Compiling the source code to Tizen $arch RPM package."
            ${plugin}-run-queue $arch
        done
    else
        echo "[DEBUG] run queue: Running the '$plugin' module"
        ${plugin}-run-queue
    fi
done

# --------------------------- Report module: generate a log file and checke other conditions --------------------------

# save webhook information for debugging
echo ""
echo "[DEBUG] Start time       : ${input_date}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Commit number    : ${input_commit}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Repository       : ${input_repo}"        >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] Branch name      : ${input_branch}"      >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] PR number        : ${input_pr}"          >> ../report/build_log_${input_pr}_output.txt
echo "[DEBUG] X-GitHub-Delivery: ${input_delivery_id}" >> ../report/build_log_${input_pr}_output.txt

# optimize size of log file (e.g., from 20MB to 1MB)
# remove unnecessary contents that are created by resource checker
__log_size_filter="/]]$\|for.*req_build.*in\|for.*}'\|']'$\|found=\|basename\|search_res\|local.*'target=/ d"
sed "${__log_size_filter}" ../report/build_log_${input_pr}_output.txt > ../report/build_log_${input_pr}_output_tmp.txt
rm -f  ../report/build_log_${input_pr}_output.txt
mv ../report/build_log_${input_pr}_output_tmp.txt ../report/build_log_${input_pr}_output.txt
ls -al

# inform developers of the warning message in case that the log file exceeds 10MB.
echo "Check if the log file size exceeds 10MB."

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
# report if all modules are successfully completed or not.
echo "send a total report with global_check_result variable. global_check_result is ${global_check_result}. "

if [[ $global_check_result == "success" ]]; then
    # The global check is succeeded.
    message="Successfully all audit modules are passed. Commit number is $input_commit."
    cibot_pr_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

    # If contributors want later, let's inform developers of CI test result to go to a review process as a final step before merging a PR
    echo "[DEBUG] All audit modules are passed - it is ready to review! :shipit:. Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."

elif [[ $global_check_result == "failure" ]]; then
    # The global check is failed.
    message="Oooops. One of the audits is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
    cibot_pr_report $TOKEN "failure" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
else
    # The global check is failed due to CI error.
    message="CI Error. There is a bug in CI script. Please contact the CI administrator."
    cibot_pr_report $TOKEN "error" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    echo -e "[DEBUG] It seems that this script has a bug. Please check value of \$global_check_result."
fi

# --------------------------- Cleaner: remove ./GBS-ROOT/ folder to keep available storage space --------------------
# let's do not keep the ./GBS-ROOT/ folder because it needs a storage space more than 9GB on average.
sleep 3

if [[ -d GBS-ROOT ]]; then
    echo "Removing ./GBS-ROOT/ folder."
    sudo rm -rf ./GBS-ROOT/
    if [[ $? -ne 0 ]]; then
            echo "[DEBUG][FAILED] Oooops!!!!!! ./GBS-ROOT folder is not removed."
    else
            echo "[DEBUG][PASSED] Successfully ./GBS-ROOT folder is removed."
    fi
fi
pwd
