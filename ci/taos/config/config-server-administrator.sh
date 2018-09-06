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
# @file config-server-administrator.sh
# @brief configuration file to declare contents that a server administrator installed.
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
#

########### Caution: If you are not server administrator, do not modify this file #################

# Note that administrator of a server has to specify the location of eSDK at first.
# In order to know how to install eSDK, please read plugins-base/pr-audit-build-yocto.sh file.
# It is environment variables that are imported from eSDK to use devtool command.
# - YOCTO_ESDK_DIR="/var/www"
# - YOCTO_ESDK_NAME="kairos_sdk" or YOCTO_ESDK_NAME="poky_sdk"
# In general, root path of Yocto eSDK is declated in $YOCTO_ESDK_DIR/$YOCTO_ESDK_NAME/ folder.

YOCTO_ESDK_DIR="/var/www/"
YOCTO_ESDK_NAME=""

