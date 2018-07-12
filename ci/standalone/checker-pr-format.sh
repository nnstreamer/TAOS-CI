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
# @file     checker-pr-format.sh
# @brief    It checks format rules whenever a PR is submitted.
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

# --------------------------- Pre-setting module --------------------------------------------------------------
# Arguments
input_date=$1
input_commit=$2
input_repo=$3
input_branch=$4
input_pr=$5
input_delivery_id=$6

# Note the "source ./config/config-environment.sh" file can be called in another script
# instead of in this file in order to support asynchronous operation from CI manager
source ./config/config-environment.sh

# @dependency: tee
# Check if dependent packages are installed
source ./common/api_collection.sh
check_package tee
echo "[DEBUG] Checked dependency packages.\n"

# Check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    echo -e "[DEBUG] ERROR: Please, input correct arguments."
    exit 1
fi

# Set folder name uniquely to run CI in different folder per a PR.
cd ..
export dir_ci=`pwd`

# Check if dir_commit folder exists, then, create dir_commit folder
# Let's keep the existing result although the same target directory already exists.
cd $dir_ci
dir_worker="repo-workers/pr-format"
export dir_worker=$dir_worker
export dir_commit=${dir_worker}/${input_date}-${input_pr}-${input_commit}

# Remove existing folders
if [[ -d $dir_commit ]]; then
    echo -e "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
    echo -e "[DEBUG] WARN: So removing the existing directory..."
    rm -rf ./${dir_commit}
fi


# Save a log file for debugging
mkdir -p $dir_commit
log_file="${dir_ci}/${dir_commit}/checker-pr-format.log"
echo -e "[DEBUG] dir_commit is $dir_commit. This folder is created."              | tee    $log_file
echo -e "[DEBUG] Initializing...                          "                       | tee -a $log_file
echo -e "[DEBUG] ./checker-pr-format.sh $1 $2 $3 $4 $5 $6 "                       | tee -a $log_file

# --------------------------- Run module ----------------------------------------------------------------------
echo -e "[DEBUG] Current path: $(pwd)."                                           | tee -a $log_file
echo -e "[DEBUG] ./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6 | tee $log_file " | tee -a $log_file
echo -e "[DEBUG] Starting asynchronously...                                     " | tee -a $log_file
cd ./standalone/
./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6                                    | tee -a $log_file
echo -e "[DEBUG] Running                                                        " | tee -a $log_file
echo -e "[DEBUG] ......                                                         " | tee -a $log_file
echo -e "[DEBUG] Completed"                                                       | tee -a $log_file
