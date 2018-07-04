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
# @file config-plugins-format.sh
# @brief add plugin modules for a github repository
#

##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.

# echo "pr-format-indent is starting."
# echo "[MODULE] TAOS/pr-format-indent: Check the code formatting style with GNU indent"
# echo "Current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-indent.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-indent.sh
# pr-format-indent
# echo "pr-format-indent is done."

# echo "pr-format-clang is starting."
# echo "[MODULE] TAOS/pr-format-clang: Check the code formatting style with clang-format"
# echo "Current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-clang.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-clang.sh
# pr-format-clang
# echo "pr-format-clang is done."

# echo "pr-format-exclusive-io is starting."
# echo "[MODULE] TAOS/pr-format-exclusive-vio: Check issue #279. VIO commits should not touch non VIO files."
# echo "Current path: $(pwd)."
# echo "[DEBUG] source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-exclusive-vio.sh"
# source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-exclusive-vio.sh
# pr-format-exclusive-vio
# echo "pr-format-exclusive-io is done."


##################################################################################################################
echo "[MODULE] plugins-ugly: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

