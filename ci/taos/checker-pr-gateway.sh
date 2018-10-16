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
# @brief    It clones a github repository with "git clone" command  whenever a PR is submitted.
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
#
# Arguments
date=$1
commit=$2
repo=$3
branch=$4
pr_no=$5
delivery_id=$6

result=0
cmd="./checker-pr-format.sh $date $commit $repo $branch $pr_no $delivery_id > /dev/null 2>/dev/null &"
$cmd
result=$?
echo -e "[DEBUG] checker: checker-pr-format.sh is done asynchronously. The variable result is $result."
echo -e "[DEBUG] It means that checker-pr-format.sh is still running now."
echo -e "[DEBUG] ./checker-pr-format.sh $date $commit $repo $branch $pr_no $delivery_id"

result=0
cmd="./checker-pr-audit.sh $date $commit $repo $branch $pr_no $delivery_id > /dev/null 2>/dev/null &"
$cmd
result=$?
echo -e "[DEBUG] checker: checker-pr-audit.sh is done asynchronously. The variable result is $result."
echo -e "[DEBUG] It means that checker-pr-audit.sh is still running now."
echo -e "[DEBUG] ./checker-pr-audit.sh $date $commit $repo $branch $pr_no $delivery_id"
