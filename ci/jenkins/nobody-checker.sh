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

for filename in *.patch; do
	line_count=0
	body_count=0
	nobody_result=0
	#While loop to read line by line
	while IFS= read -r line; do
		#If the line starts with "Subject*" then set var to "yes".
		if [[ $line == Subject* ]] ; then
			printline="yes"
			# Just t make each line start very clear, remove in use.
			echo "----------------------->>"
			continue
		fi
		#If the line starts with "---*" then set var to "no".
		if [[ $line == ---* ]] ; then
			printline="no"
			# Just to make each line end very clear, remove in use.
			echo "-----------------------<<"
			break
		fi
		# If variable is yes, print the line.
		if [[ $printline == "yes" ]] ; then
			echo "[DEBUG] $line"
			line_count=$(echo $line | wc -w)
			body_count=$(($body_count + $line_count))
		fi
	done < "$filename"

	# determine if a commit body exceeds 4 words (Signed-off-by already is 4 words.)
	echo "[DEBUG] body count is $body_count"
	body_count_criteria=`echo "4+4"|bc`
	if  [[ $body_count -le $body_count_criteria ]]; then
		echo "[DEBUG] commit body checker is FAILED. patch file name: $filename"
		echo "[DEBUG] current directory is `pwd`"
		nobody_result=0
		exit 1
	else
		echo "[DEBUG] commit body checker is PASSED. patch file name: $filename"
		echo "[DEBUG] current directory is `pwd`"
		nobody_result=1
	fi
done
