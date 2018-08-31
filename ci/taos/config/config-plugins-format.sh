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
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>


##### Set environment for audit plugins
declare -i idx=-1

##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.

format_plugins[++idx]="pr-format-doxygen"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check a source code consists of required doxygen tags."
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

#format_plugins[++idx]="pr-format-indent"
# echo "${format_plugins[idx]} is starting."
# echo "[MODULE] TAOS/${format_plugins[idx]}: Check the code formatting style with GNU indent"
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
# source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh


#format_plugins[++idx]="pr-format-clang"
# echo "${format_plugins[idx]} is starting."
# echo "[MODULE] TAOS/${format_plugins[idx]}: Check the code formatting style with clang-format"
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
# source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

#format_plugins[++idx]="pr-format-exclusive-vio"
# echo "${format_plugins[idx]} is starting."
# echo "[MODULE] TAOS/${format_plugins[idx]}: Check issue #279. VIO commits should not touch non VIO files."
# echo "The current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
# source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-pylint"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the code formatting style with pylint"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-newline"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check if there is a newline issue in text files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-rpm-spec"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check if there is incorrect staements in *.spec file"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-file-size"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-cppcheck"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-nobody"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-timestamp"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-format-executable"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh

format_plugins[++idx]="pr-hardcoded-path"
echo "${format_plugins[idx]} is starting."
echo "[MODULE] TAOS/${format_plugins[idx]}: Check the file size to not include big binary files"
echo "The current path: $(pwd)."
echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh"
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-good/${format_plugins[idx]}.sh



##################################################################################################################
echo "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

