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
# @file config-plugins-format.sh
# @brief add plugin modules for a github repository
# @see      https://github.sec.samsung.net/STAR/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.

module_name="pr-format-doxygen"
echo "$module_name is starting."
echo "[MODULE] TAOS/$module_name: Check a source code consists of required doxygen tags."
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh"
source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh
$module_name
echo "$module_name is done."

module_name="pr-format-indent"
# echo "$module_name is starting."
# echo "[MODULE] TAOS/$module_name: Check the code formatting style with GNU indent"
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh
# $module_name
# echo "$module_name is done."

module_name="pr-format-clang"
# echo "$module_name is starting."
# echo "[MODULE] TAOS/$module_name: Check the code formatting style with clang-format"
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh
# $module_name
# echo "$module_name is done."

module_name="pr-format-exclusive-vio"
# echo "$module_name is starting."
# echo "[MODULE] TAOS/$module_name: Check issue #279. VIO commits should not touch non VIO files."
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh
# $module_name
# echo "pr-format-exclusive-io is done."

module_name="pr-format-pylint"
echo "$module_name is starting."
echo "[MODULE] TAOS/$module_name: Check the code formatting style with pylint"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh"
source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/$module_name.sh
$module_name
echo "$module_name is done."


##################################################################################################################
echo "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

