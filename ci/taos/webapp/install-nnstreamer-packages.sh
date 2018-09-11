#!/usr/bin/env bash


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
# @file install-nnstreamer-packages.sh
# @brief This script is to install packages that are required to run nnstreamer modules.
#
# We assume that you use Ubuntu 16.04 x86_64 distribution.

echo -e "########## for CI-server: Setting-up a package repository of TensorFlow"
# If you do not use Version 16.04, you have to modify /etc/apt/sources.list.d/nnstreamer.list file appropriately. 
sudo apt -y install software-properties-common
yes "" | sudo add-apt-repository ppa:nnstreamer/ppa
sudo apt -y update

echo -e "########## for CI-server: Installing base packages to check example apps of NNstreamer"
# fetch a project path from command
echo -e "[DEBUG] current folder:" $0
prj_path="`dirname \"$0\"`/../../.."

# go to project path
pushd $prj_path
echo -e  "[DEBUG] value of prj_path:" $prj_path
echo -e  "[DEBUG] current folder:" $(pwd)

# Note that mk-build-deps needs a equivs package.
sudo apt -y install devscripts equivs > /dev/null
echo -e "[DEBUG] Installing dependent packages by reading debian/control file."
sudo mk-build-deps --install debian/control > /dev/null
popd

echo -e "########## for CI-system: Installing base packages for "
sudo apt -y install rpmlint ctags sudo

echo -e "[DEBUG] Required packages are successfully installed...."
