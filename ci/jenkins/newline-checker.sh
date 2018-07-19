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

./gen-diff-patch.sh

# investigate generated all *.patch files
for i in *.patch; do
	# FIXME: Handle in case that there are multiple files in one commit.
	cat $i | grep '^\\ No newline' > /dev/null
	if  [[ $? == 0 ]]; then
		echo "[DEBUG] Failed. patch file name: $i"
		echo "[DEBUG] current directory is `pwd`"
		newline_pass=0
	else
		echo "[DEBUG] Passed. patch file name: $i"
		echo "[DEBUG] current directory is `pwd`"
		newline_pass=1
	fi
	# Binary handling: Let's do not check "No newline" statement in case of *.bin files
	bin_num=$(cat $i | grep "diff --git" | grep ".bin" | wc -l)
	if  [[ $bin_num > 0 ]]; then
		newline_pass=1
	fi
done

if [[ $newline_pass == 0 ]]; then
	exit 1
fi
