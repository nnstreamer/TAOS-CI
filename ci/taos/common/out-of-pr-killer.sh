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
# @file   out-of-pr-killer.sh
# @brief  Out-of-PR((OOP) Killer
#
# This facility is to stop compulsorily the previous same PRs invoked by
# checker-pr-gateway.sh when the developers try to send a lot of same PRs
# repeatedly.
# 


# --------------------------- Out-of-PR (OOP) killer: kill previous same PRs  ----------------------------------

##
# @brief Run out-of-pr killer
function run_oop_killer(){
    # Kill PRs that were previously invoked by checker-pr-gateway.sh with the same PR number.
    echo "[DEBUG] Starting killing activity to kill previously invoked checker-pr-gateway.sh with the same PR number.\n"
    ps aux | grep "^www-data.*bash \./checker-pr-gateway.sh" | while read line
    do
        victim_pr=`echo $line  | awk '{print $17}'`
        victim_date=`echo $line  | awk '{print $13}'`
        # Info: pid1 is checker-pr-gateway.sh, pid2 is checker-pr-audit-async.sh, and pid3 is "gbs build" command.
        victim_pid1=`ps -ef | grep bash | grep checker-pr-gateway.sh       | grep $input_pr | grep $victim_date | awk '{print $2}'`
        victim_pid2=`ps -ef | grep bash | grep checker-pr-audit-async.sh | grep $input_pr | grep $victim_date | awk '{print $2}'`
        victim_pid3=`ps -ef | grep python | grep gbs | grep "_pr_number $input_pr" | grep $victim_date | awk '{print $2}'`
    
        # The process killer allows to kill only task(s) in case that there are running lots of tasks with same PR number.
        if [[ ("$victim_pr" -eq "$input_pr") && (1 -eq "$(echo "$victim_date < $input_date" | bc)") ]]; then
            echo "[DEBUG] victim_pr=$victim_pr, input_pr=$input_pr, victim_date=$victim_date, input_date=$input_date "
            echo "[DEBUG] killing PR $victim_pr (pid <$victim_pid1> <$victim_pid2> <$victim_pid3>)."
            kill $victim_pid1
            kill $victim_pid2
            kill $victim_pid3
            sleep 1
            # Handle a possibility that someone updates a single PR multiple times within 1 second.
            echo "[DEBUG] removing the ./${dir_worker}/${victim_pr}-${victim_date}-* folder"
            rm -rf ./${dir_worker}/${victim_pr}-${victim_date}-*
        fi
    done

    # Todo: NYI, Implement the OOP killer for Ubuntu build (pdebuild)
    # Todo: NYI, Implement the OOP killer for Yocto  build (devtool)
}

