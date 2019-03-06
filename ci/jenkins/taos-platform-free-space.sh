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
# @brief Check if your hard disk is nearly full.
# @description
# This script is a simple test to check a disk space.
# If a mounted partition is under certain quota(10GB), alert us via 1) email.
# -----------------------------------------------------------------------------------------

#------------------------------- configuration area ---------------------------------------
# partions to monitor disk free space
# /dev/sdc1 / (14GB, Ubuntu OS)
# /dev/sdb1 /var/www (04TB, CI partition)
mounted_folders="/ /var/www"

# email information
email_cmd="mailx"
email_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoon.moon@samsung.com sangjung.woo@samsung.com \
wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
sewon.oh@samsung.com kibeom.lee@samsung.com byoungo.kim@samsung.com "
email_subject="[aaci] Critical:  Your hard disk is nearly full.".
email_message=" Hi,\n\n Ooops. Your specified partitions ($mounted_folders) are almost full.\n\n $(df -h)\n\n For more details, visit a github issue webapge.\n\n $(date).\n from Jenkins system.\n"
PART_QUOTA_GB=10

#------------------------------- code area -----------------------------------------------
# check package dependency
function check_package() {
    echo "Checking for $1..."
    which "$1" 2>/dev/null || {
      echo "Please install $1."
      exit 1
    }
}

# send e-mail if a partitions is almost full.
function email_on_failure(){
    echo -e "$email_message" | $email_cmd -v -s  "$email_subject" $email_recipient
}

# check dependency
check_package mailx
check_package df

# run

source /etc/environment

for dir in $mounted_folders; do
    PART_FREE_MB=`df -m --output=avail "$dir" | tail -n1` # df -m not df -h
    PART_FREE_GB=$(($PART_FREE_MB/1024))
    if [[ $PART_FREE_GB -lt $PART_QUOTA_GB ]]; then
        echo "[DEBUG] Oops. '$dir' is almost full. The available space is $PART_FREE_GB Gbytes."
        email_on_failure
        exit 4
    else
        echo "[DEBUG] Okay. '$dir' is not full. The available space is $PART_FREE_GB Gbytes."
    fi
done

# jenkins submit issue according "exit ***" value.
exit 0
