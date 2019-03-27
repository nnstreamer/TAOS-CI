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
# @file     coverage-generator.sh
# @brief    Auto-generate unit test coverage files
# @author   Sewon Oh <sewon.oh@samsung.com>
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @note
#  How to append this script to /etc/crontab
#  $ sudo vi /etc/crontab
#  30 * * * * www-data /var/www/html/nnstreamer/ci/gcov/coverage-generator.sh
# @see      https://github.com/nnsuite/TAOS-CI
# @param    None

# Calculate the gcov and git directory from this file that include a absolute path
gcov_dir="$( cd "$( dirname "$0")" && pwd )"
cd $gcov_dir
cd ../../
git_dir="$(pwd)"
cd -
echo -e "[DEBUG] gcov_dir is '$gcov_dir'"
echo -e "[DEBUG] git_dir is '$git_dir'"

# Include the comman api
source $git_dir/ci/taos/common/api_collection.sh

# Check dependency
check_dependency gbs
check_dependency rpm2cpio
check_dependency cpio

pushd $git_dir
# Generate a code coverage statistics with gcov/lcov.
# Note that the gbs command requires a 'sudo' command to get a 'root' privilege
echo -e "[DEBUG] The current folder is '$(pwd)'."
echo -e "[DEBUG] Running 'gbs' command to generate a rpm file."
gbs build -A x86_64 --clean --define "testcoverage 1" --define "unit_test 1" -B $gcov_dir
result=$?
if [[ $result != 0 ]]; then
    echo -e "[DEBUG] Ooops. 'gbs build' command is failed."
    echo -e "[DEBUG] Stopping this task..."
    exit 1
fi

# Decompress the rpm file to  a gcov_html folder
cd $gcov_dir/
echo -e "[DEBUG] Copying generated rpm files to $gcov_dir folder."
cp $gcov_dir/local/repos/tizen/x86_64/RPMS/nnstreamer-unittest-coverage* $gcov_dir
echo -e "[DEBUG] Decompressing the rpm files in $gcov_dir folder."
rpm2cpio $gcov_dir/nnstreamer-unittest-coverage* | cpio -idumv
echo -e "[DEBUG] Removing the rpm files in $gcov_dir folder."
if [[ -d ../gcov_html ]]; then
    rm -rf ../gcov_html
fi
mkdir -p ../gcov_html
mv -f usr/share/nnstreamer/unittest/result/* ../gcov_html
if [[ -f ../gcov_html/index.html ]]; then
    ../badge/gen_badge.py codecoverage ../gcov_html/index.html ../badge/codecoverage.svg
fi
cd -

# Remove unused folder. 
# Note that we have to use 'sudo' command  to remove these files 
# because 'gbs' command creates some files with "sudo chroot" operation.
sudo rm -rf $gcov_dir/nnstreamer-unittest-coverage*
sudo rm -rf $gcov_dir/local
sudo rm -rf $gcov_dir/usr

echo -e "[DEBUG] The current folder is '$(pwd)'."
echo -e "[DEBUG] The test coverage is executed."
popd
