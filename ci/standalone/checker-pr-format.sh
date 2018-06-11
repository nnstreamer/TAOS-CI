#!/usr/bin/env bash

##
# @file checker-pr-format.sh
# @brief It checks format rules whenever a PR is submitted.
# @dependency: tee
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

# check if dependent packages are installed
source ./common/inspect_dependency.sh
check_package tee


# check if input argument is correct.
if [[ $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
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
    echo "[DEBUG] WARN: mkdir command is failed because $dir_commit directory already exists."
    echo "[DEBUG] WARN: So removing the existing directory..."
    rm -rf ./${dir_commit}
fi
mkdir -p $dir_commit

# Save a log file for debugging
log_file="${dir_ci}/${dir_commit}/checker-pr-format-async.log"
echo -e "[DEBUG] Initializing...                          "                       | tee    $log_file
echo -e "[DEBUG] ./checker-pr-format.sh $1 $2 $3 $4 $5 $6 "                       | tee -a $log_file

# --------------------------- Run module ----------------------------------------------------------------------
echo -e "[DEBUG] current path: $(pwd)."                                           | tee -a $log_file
cd ./standalone/
./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6                                    | tee -a $log_file
echo -e "[DEBUG] ./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6 | tee $log_file " | tee -a $log_file
echo -e "[DEBUG] Starting asynchronously...                                     " | tee -a $log_file
echo -e "[DEBUG]                                                                " | tee -a $log_file
echo -e "[DEBUG] ./checker-pr-format-async.sh $1 $2 $3 $4 $5 $6 | tee $log_file " | tee -a $log_file
echo -e "[DEBUG] Completed ......."                                               | tee -a $log_file
