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
# @file   checker-issue-comment.sh
# @brief  An issue facility to comment automatically whenever issue happens .
# @see    https://github.com/nnstreamer/TAOS-CI
# @author Geunsik Lim <geunsik.lim@samsung.com>
# @param
#  arg1: issue number
#

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/config-environment.sh
source ./common/api_collection.sh

# Check if an input argument is correct.
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please use a correct issue number.\n"
    exit 1
fi

input_issue=$1

# --------------------------- Report module: submit a check result to a github website --------------
# Submit an appropriate reply automatically whenever new issue is created.

message=":octocat: **cibot**: Thank you for posting issue #$input_issue. The person in charge will reply soon."
cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_issue/comments"

