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
# @file coverage-generator.sh
# @brief Auto-generate unit test coverage files
# @how to append this script to /etc/crontab
#       $ sudo vi /etc/crontab
#       30 * * * * www-data /var/www/html/nnstreamer/ci/gcov/coverage-generator.sh
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Sewon Oh <sewon.oh@samsung.com>
# @param    None
#

# Set-up environements
dirpath="$( cd "$( dirname "$0")" && pwd )"
build_root="${dirpath}/../../../"

# Include comman api
source $dirpath/../taos/common/api_collection.sh

# Check dependency
check_dependency gbs
check_dependency rpm2cpio
check_dependency cpio

# Build a RPM file to geneate a code coverage statistics with gcov/lcov.
gbs build -A x86_64 --define "testcoverage 1" -B $dirpath $build_root --clean

# Extract rpm to gcov_html folder
cp $dirpath/local/repos/tizen/x86_64/RPMS/nnstreamer-unittest-coverage* $dirpath
pushd $dirpath
rpm2cpio $dirpath/nnstreamer-unittest-coverage* | cpio -idvm 
mkdir -p ../gcov_html
mv -f usr/share/nnstreamer/unittest/result/* ../gcov_html
popd

# Remove unused folder. 
# Note that we have to use 'sudo' command  to remove these files 
# because 'gbs' command creates some files with "root' ID 
# via "sudo chroot" operation.
sudo rm -rf $dirpath/local
sudo rm -rf $dirpath/usr

