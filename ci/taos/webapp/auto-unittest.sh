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
# @file auto-unittest.sh
# @brief Auto-generate unit test result
# @how to append this script to /etc/crontab
#       $ sudo vi /etc/crontab
#       30 * * * * www-data /var/www/html/nnstreamer/ci/taos/webapp/auto-unittest.sh
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Sewon Oh <sewon.oh@samsung.com>
# @param    None
#

# Set-up environements
dirpath="$( cd "$( dirname "$0")" && pwd )"
build_root="${dirpath}/../../../"
arch_type="x86_64 armv7l"
echo -e "[DEBUG] dirpath : $dirpath"
echo -e "[DEBUG] build_root : $build_root"

# Include comman api
source $dirpath/../common/api_collection.sh

# Check dependency
check_dependency gbs

# Create result folder
pushd ${build_root}
if [[ -d Documentation/unittest_result ]]; then
    rm -rf Documentation/unittest_result/*
else
    mkdir -p Documentation/unittest_result
fi

for arch in $arch_type
do
    # Gbs build for unit test
    # Unit test for ${arch}
    gbs build -A ${arch} --overwrite --clean > temp.txt

    # Parsing result 
    test_flag=0
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line =~  "./unittest_common" || $line =~ "./testAll.sh" ]]; then
            test_flag=1
        fi

        if [[ $line =~ "popd" ]]; then
            test_flag=0
        fi

        if [[ $test_flag -eq 1 ]]; then
            echo "$line" >> result.txt
        fi
    done < temp.txt

    mv result.txt Documentation/unittest_result/unit_test_result_${arch}.txt
done

rm temp.txt
popd

