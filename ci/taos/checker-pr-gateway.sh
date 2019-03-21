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
# @file     checker-pr-gateway.sh
# @brief    A PR gateway to control two PR checkers such as format and audit
# First of all, it clones a github repository with "git clone" command 
# when a contributor submits a PR. Then, it run format and audit checker sequentially.
# 
# @see      https://github.com/nnsuite/TAOS-CI
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
#  $dir_ci directory is CI folder (Absolute path)
#  $dir_worker   directory is PR worker folder
#  $dir_commit   directory is commit folder

# ---------------------------------------------------------------

# Arguments
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6


# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation.
source ./config/config-environment.sh
pwd

# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    echo -e "[ERROR] Oooops. We can not run $0 due to incorrect arguments."
    echo -e "[ERROR] Unexpectedly $0 Stopped."
    exit 1
fi

# Load API library
source ./common/api_collection.sh

# Check if dependent packages are installed
echo -e "[DEBUG] Checking dependent commands...\n"
check_dependency tee
check_dependency rm

# Set folder name uniquely to run CI in different folder per a PR.
cd ..
export dir_ci=`pwd`

# Check if dir_commit folder exists, then, create dir_commit folder
# Let's keep the existing result although the same target directory already exists.
cd $dir_ci
dir_worker="repo-workers/pr-checker"
export dir_worker=$dir_worker
export dir_commit=${dir_worker}/${input_pr}-${input_date}-${input_commit}

# Check if a same commit folder already exists
if [[ -d $dir_commit ]]; then
    echo -e "[DEBUG] 'mkdir' command is failed because $dir_commit directory already exists."
    echo -e "[DEBUG] So removing the existing directory..."
    rm -rf ./${dir_commit}
fi

# Create a commit folder
cd $dir_ci
mkdir -p $dir_commit
echo "[DEBUG] $dir_commit folder is created."

# --------------------------- git-clone module: clone a git repository ----------------------
echo "[DEBUG] Starting 'git clone' command to get a git repository...."

# Set project repo name of contributor
PRJ_REPO_OWNER=`echo $(basename "${input_repo%.*}")`

# Check if a git repository already exists
cd $dir_commit
if [[ -d ${PRJ_REPO_OWNER} ]]; then
    echo -e "[DEBUG] ${PRJ_REPO_OWNER} already exists and is not an empty directory."
    echo -e "[DEBUG] Removing the existing directory..."
    rm -rf ./${PRJ_REPO_OWNER}
fi

# create 'report' folder to archive log files.
pwd
mkdir ./report
echo -e "[DEBUG] The 'report' folder is created."

# run "git clone" command to download git source
# options of 'sudo' command: 
# 1) The -H (HOME) option sets the HOME environment variable to the home directory of the target user (root by default)
# as specified in passwd. By default, sudo does not modify HOME.
# 2) The -u (user) option causes sudo to run the specified command as a user other than root. To specify a uid instead of a username, use #uid.
pwd
run_git_clone="sudo -Hu www-data git clone --reference ${REFERENCE_REPOSITORY} $input_repo"
echo -e "[DEBUG] $run_git_clone"
$run_git_clone
if [[ $? != 0 ]]; then
    echo "[DEBUG] ERROR: 'git clone' command is failed because of incorrect setting of CI server."
    echo "[DEBUG] Please check /var/www/ permission, /var/www/html/.netrc, and /var/www/html/.gbs.conf."
    echo "[DEBUG] current id: $(id)"
    echo "[DEBUG] current path: $(pwd)"
    echo "[DEBUG] $run_git_clone"
    exit 1
fi

# run "git branch" to use commits from PR branch
echo -e "[DEBUG] PRJ_REPO_OWNER is ./${PRJ_REPO_OWNER}"
cd ./${PRJ_REPO_OWNER}
checkout_branch="git checkout -b $input_branch origin/$input_branch"
echo -e "[DEBUG] $checkout_branch"
$checkout_branch
git branch
pwd


# @brief checker runner to run the checkers based on the dependency policy
# Run the first group, then depending on the dependency policy, run the remaining groups
# @param arguments received by the function
#  arg1: list of checkers (like format, audit, etc)
#  arg2: list of checker's name
#  arg3: list of checker's log file
#  arg@: all remaining arguments are to be passed to the checkers (common for all the checkers)
function run_all_checkers(){
  local -n checker_cmd_list=$1
  local -n name_list=$2
  local -n logfile_list=$3
  local checker_args=${@:4}

  local num_checkers=${#checker_cmd_list[@]}
  for (( i=0; i<$num_checkers; i++ )); do
    local logfile=${logfile_list[$i]}

    cd $dir_ci
    echo -e "[DEBUG] dir_commit is $dir_commit. This folder is created." | tee    $logfile
    echo -e "[DEBUG] current path: $(pwd)."                              | tee -a $logfile
    # Save a log file to debug the cheker
    echo -e "[DEBUG] ${checker_cmd_list[$i]} $checker_args "             | tee -a $logfile
    echo -e "[DEBUG] Starting a ${name_list[$i]} checker... "            | tee -a $logfile
    # Run checker
    pushd ./taos/
    ${checker_cmd_list[$i]} $checker_args                                | tee -a $logfile &
    local pid=$!
    popd
    echo -e "[DEBUG] Running..."                                         | tee -a $logfile

    # if the dependency between groups is to be enforced and current group fails, skip remaining groups
    if [[ $dep_policy_between_groups == 1 ]]; then
      wait $pid
      if [[ $? != 0 ]]; then
        break
      fi
    fi
  done
}

# --------------------------- Create and run checkers -------------------------------------
# Create an empty list for the checkers to be run with the corresponding elements
# The order of the checkers in the list creates a dependency between them determining the order in which they will run
# 1) Checker itself to be run
# 2) Name of the checker
# 3) Log file to log the output of the checker
declare -a checker_cmd_list
declare -a checker_name_list
declare -a checker_logfile_list

# Ready a checker: format
checker_cmd_list+=("./checker-pr-format-async.sh")
checker_name_list+=("format")
checker_logfile_list+=("${dir_ci}/${dir_commit}/checker-pr-format.log")
echo -e "[DEBUG] Added ${checker_name_list[-1]} checker"

# Ready a checker: audit
checker_cmd_list+=("./checker-pr-audit-async.sh")
checker_name_list+=("audit")
checker_logfile_list+=("${dir_ci}/${dir_commit}/checker-pr-audit.log")
echo -e "[DEBUG] Added ${checker_name_list[-1]} checker"

# Run all the checkers
echo -e "[DEBUG] Running all checkers"
run_all_checkers checker_cmd_list checker_name_list checker_logfile_list $1 $2 $3 $4 $5 $6
echo -e "[DEBUG] Completed all checkers"
