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
# @brief Check if SPIN-OBS server generates build error.
# @description
# This script does a simple test to check a build error of SPIN-OBS server
# -----------------------------------------------------------------------------------------

#------------------------------- configuration area ---------------------------------------
OBS_SERVER="http://10.113.136.201/project/show/Tizen:5.0:TAOS"
OBS_SERVER_ERR_PKGS="http://10.113.136.201/project/monitor/Tizen:5.0:TAOS?blocked=0&building=0&dispatching=0&finished=0&scheduled=0&signing=0&succeeded=0"

# email information
email_cmd="mailx"
#email_recipient="geunsik.lim@samsung.com"
email_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoon.moon@samsung.com sangjung.woo@samsung.com \
wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
sewon.oh@samsung.com "

#------------------------------- code area -----------------------------------------------
# check package dependency
function check_package() {
    echo "Checking for $1..."
    which "$1" 2>/dev/null || {
      echo "Please install $1."
      exit 1
    }
}

# send e-mail if a build error happens.
function email_on_failure(){
    # fecth package list
    report_file=`curl -o obs-packages.txt http://10.113.136.201/project/monitor/Tizen:5.0:TAOS?blocked=0&building=0&dispatching=0&finished=0&scheduled=0&signing=0&succeeded=0`
    if [[ $? == 0 ]]; then
        echo "Successfully downloaded"
    else
        echo "Ooops. no downloaded."
    fi
    pack_list=`cat ./obs-packages.txt | grep "failed</a></td>" | cut -d "\"" -f 4`
    
    # make subject and message to send email
    email_subject="[aaci] Urgent: SPIN-OBS server generates build error"
    
    email_message="Hi,\n\n \
    Ooops. The  below $1 packages generates a build error.\n\n \
    [Package list]:\n $pack_list\n\n \
    If you want to see a package name in more detail,\n \
    please visit ${OBS_SERVER_ERR_PKGS}.\n\n \
    $(date)\n from aaci.mooo.com\n"
    
    # send email with mailx command
    echo -e "$email_message" | $email_cmd -v -s "$email_subject" $email_recipient
}

# check dependency
check_package curl
check_package cat
check_package grep
check_package sed
check_package cut

# run

source /etc/environment

build_err_msg=`curl -o obs.txt  $OBS_SERVER ; cat obs.txt | grep "build error"`
echo -e "[DEBUG] The raw message of build error is (\"$build_err_msg\")."
if [[ $build_err_msg == "" ]]; then
    exit 0
fi

build_err_num=`echo "$build_err_msg" | sed "s/>/|/g" | cut -d "|" -f 2 | cut -d " " -f1`
echo -e "[DEBUG] The value of the variable build_err_num is $build_err_num ."

if [[ !$build_err_num == "" && $build_err_num -lt 1 ]]; then
    echo -e "[DEBUG] Okay. There is no build error in $OBS_SERVER."
else
    echo -e "[DEBUG] Oops. There are build error(s) in $OBS_SERVER."
    email_on_failure $build_err_num
    exit 4
fi

# jenkins submit issue according "exit ***" value.
exit 0

