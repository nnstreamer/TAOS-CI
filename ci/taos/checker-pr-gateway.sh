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
#  $dir_ci directory is CI folder
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
export dir_commit=${dir_worker}/${input_date}-${input_pr}-${input_commit}

# Remove it if there are existing folders
if [[ -d $dir_commit ]]; then
    echo -e "[DEBUG] 'mkdir' command is failed because $dir_commit directory already exists."
    echo -e "[DEBUG] So removing the existing directory..."
    rm -rf ./${dir_commit}
fi

# Create a commit folder
cd $dir_ci
mkdir -p $dir_commit

# --------------------------- Run a checker: format ---------------------------------------
cd $dir_ci
echo -e "[DEBUG] dir_commit is $dir_commit. This folder is created." | tee    $log_file_format
echo -e "[DEBUG] current path: $(pwd)."                              | tee -a $log_file_format
# Save a log file to debug a format cheker
log_file_format="${dir_ci}/${dir_commit}/checker-pr-format.log"
echo -e "[DEBUG] ./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6 "    | tee -a $log_file_format
echo -e "[DEBUG] Starting a format checker...            "           | tee -a $log_file_format
# Run format checker
pushd ./taos/
./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6                       | tee -a $log_file_format
popd
echo -e "[DEBUG] Running..."                                         | tee -a $log_file_format
echo -e "[DEBUG] Completed."                                         | tee -a $log_file_format

# --------------------------- Run a checker: audit ----------------------------------------
cd $dir_ci
echo -e "[DEBUG] dir_commit is $dir_commit. This folder is created." | tee    $log_file_audit
echo -e "[DEBUG] current path: $(pwd)."                              | tee -a $log_file_audit
# Save a log file to debug a audit checker
log_file_audit="${dir_ci}/${dir_commit}/checker-pr-audit.log"
echo -e "[DEBUG] ./checker-pr-audit-async.sh $1 $2 $3 $4 $5 $6 "     | tee -a $log_file_audit
echo -e "[DEBUG] Starting a audit checker...             "           | tee -a $log_file_audit
# Run audit checker
pushd ./taos/
./checker-pr-audit-async.sh $1 $2 $3 $4 $5 $6                        | tee -a $log_file_audit
popd
echo -e "[DEBUG] Running..."                                         | tee -a $log_file_audit
echo -e "[DEBUG] Completed."                                         | tee -a $log_file_audit
