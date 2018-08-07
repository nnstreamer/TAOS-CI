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

# -----------------------------------------------------------------------------------------
# @author Geunsik Lim <geunsik.lim@samsung.com>
# @brief Check if Linux system reports system errors.
# -----------------------------------------------------------------------------------------


#--------- user configuraiton ---------------
#filter="^"
filter="error"

# email information
email_cmd="mailx"
email_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoon.moon@samsung.com sangjung.woo@samsung.com \
wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
sewon.oh@samsung.com kibeom.lee@samsung.com byoungo.kim@samsung.com "
email_subject="[aaci] Warning: Server starts using SWAP memory to avoid OOM."
email_message=" Hi,\n\n Ooops. The server starts using SWAP memory due to shortage of RAM space.\n\n $(free -h)\n\n For more details, visit a github issue webpage.\n\n $(date).\n from Jenkins system.\n"

# send e-mail if a partitions is almost full.
function email_on_failure(){
    echo -e "$email_message" | $email_cmd -v -s  "$email_subject" $email_recipient
}

# run
#--------- do not modify from this line -----
data=`dmesg | tail -n 50`
error_num=`echo -n "$data" | grep -c "$filter" `
as_start_criteria=5

echo -e "---------------"
echo -e "1. Filtering message: \"$filter\" "
echo -e "2. # of errors: $error_num"
echo -e "3. dmesg data:"
echo -e "  . . . Omission . . . "
echo -e "$data"
echo -e "---------------"

if [[ $error_num -gt $as_start_criteria ]]; then
    email_on_failure
    exit 4
else
    exit 0
fi


