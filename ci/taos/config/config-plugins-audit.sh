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
# @file     config-plugins-audit.sh
# @brief    Configuraiton file to maintain audit modules (after completing a build procedure)
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>

##### Set environment for audit plugins
declare -i idx=-1

###### plugins-base ###############################################################################################
echo "[MODULE] plugins-base: Plugin group is a well-maintained collection of plugin modules."
# Please append your plugin modules here.

audit_plugins[++idx]="pr-audit-build-tizen"
echo "[DEBUG] The default BUILD_MODE of ${audit_plugins[idx]} is declared with 99 (SKIP MODE) by default in plugins-base folder."
echo "[DEBUG] ${audit_plugins[idx]} is started."
echo "[DEBUG] TAOS/${audit_plugins[idx]}: Check if Tizen rpm package is successfully generated."
echo "[DEBUG] Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-base/${audit_plugins[idx]}.sh


audit_plugins[++idx]="pr-audit-build-ubuntu"
echo "[DEBUG] The default BUILD_MODE of ${audit_plugins[idx]} is declared with 99 (SKIP MODE) by default in plugins-base folder."
echo "[DEBUG] ${audit_plugins[idx]} is started."
echo "[DEBUG] TAOS/${audit_plugins[idx]}: Check if Ubuntu deb package is successfully generated."
echo "[DEBUG] Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-base/${audit_plugins[idx]}.sh


audit_plugins[++idx]="pr-audit-build-yocto"
echo "[DEBUG] The default BUILD_MODE of ${audit_plugins[idx]} is declared with 99 (SKIP MODE) by default in plugins-base folder."
echo "[DEBUG] ${audit_plugins[idx]} is started."
echo "[DEBUG] TAOS/${audit_plugins[idx]}: Check if YOCTO deb package is successfully generated."
echo "[DEBUG] Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/taos/plugins-base/${audit_plugins[idx]}.sh



###### plugins-good ###############################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.






###### plugins-staging ################################################################################################
echo "[MODULE] plugins-staging: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

# module_name="pr-audit-resource"
# echo "[DEBUG] $module_name is started."
# echo "[DEBUG] TAOS/$module_name: Check if there are not-installed resource files."
# echo "[DEBUG] Current path: $(pwd)."
# source ${REFERENCE_REPOSITORY}/ci/taos/plugins-staging/$module_name.sh
# $module_name
# echo "[DEBUG] $module_name is done."

# audit_plugins[++idx]="pr-nnstreamer-ubuntu-apptest"
# echo "[DEBUG] TAOS/${audit_plugins[idx]}: Check nnstreamer sample app"
# echo "[DEBUG] ${audit_plugins[idx]} is started."
# echo "[DEBUG] Current path: $(pwd)."
# source ${REFERENCE_REPOSITORY}/ci/taos/plugins-staging/${audit_plugins[idx]}.sh

