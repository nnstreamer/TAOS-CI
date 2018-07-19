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
# @brief Check if Linux system try to use SWAP space.
# -----------------------------------------------------------------------------------------


# email information
email_cmd="mailx"
email_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoon.moon@samsung.com sangjung.woo@samsung.com \
wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
sewon.oh@samsung.com kibeom.lee@samsung.com byoungo.kim@samsung.com "
email_subject="[aaci] Warning: Server starts using SWAP memory to avoid OOM."
email_message=" Hi,\n\n Ooops. The server starts using SWAP memory due to shortage of RAM space.\n\n $(free -h)\n\n For more details, visit https://github.sec.samsung.net/STAR/TAOS-Platform/issues/.\n\n $(date).\n from aaci.mooo.com.\n"




# send e-mail if a partitions is almost full.
function email_on_failure(){
    echo -e "$email_message" | $email_cmd -v -s  "$email_subject" $email_recipient
}

# run

source /etc/environment

SwapTotal=`awk '/SwapTotal:/ { print $2}' /proc/meminfo`
SwapFree=`awk '/SwapFree:/ { print $2}' /proc/meminfo`
echo -e "SwapTotal is $SwapTotal. SwapFree is $SwapFree"

if [[ $SwapFree -lt $SwapTotal ]]; then
    email_on_failure
    exit 4
else
    echo -e "Good. Linux kernel does not try to use SWAP space."
fi

# jenkins submit issue according "exit ***" value.
exit 0
