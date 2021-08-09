#!/usr/bin/env bash
## SPDX-License-Identifier: APACHE-2.0-only

## @file   out-of-pr-killer.sh
## @auther Geunsik Lim <geunsik.lim@samsung.com>
## @brief  Out-of-PR(OOP) Killer
##
## This module runs when there is no available queue to run a PR.
## It is to kill compulsorily the previous same PRs invoked by
## checker-pr-gateway.sh when the developers resend same PRs repeatedly.
## 


# --------------------------- Out-of-PR (OOP) killer: kill previous duplicated PRs  ----------------------------------

##
## @brief Run Out-of-PR(OOP) killer
function run_oop_killer(){
    # Specify dependent commands for this function.
    check_cmd_dep ps
    check_cmd_dep awk
    check_cmd_dep grep
    check_cmd_dep bc
    check_cmd_dep kill
    check_cmd_dep sleep
    check_cmd_dep rm

    # Run the OOP killer
    # Kill PRs that were previously invoked by checker-pr-gateway.sh with the same PR number.
    echo "[DEBUG] OOP Killer: Kill the existing same PRs that is previously invoked by checker-pr-gateway.sh.\n"
    ps aux | grep "^www-data.*bash \./checker-pr-gateway.sh" | while read line
    do
        victim_pr=`echo $line  | awk '{print $17}'`
        victim_date=`echo $line  | awk '{print $13}'`
        # Step 1: The victim pid1 is checker-pr-gateway.sh (It is a task distributor.)
        # Step 2: The victim pid2 is checker-pr-postbuild-async.sh (It is the postbuild group.)
        # Step 3:
        # a. The victim pid3_tizen:  "gbs" command for a Tizen build
        # b. The victim pid3_ubuntu: "pdebuild" command for a Ubuntu build
        victim_pid1=`ps -ef | grep bash | grep checker-pr-gateway.sh       | grep $input_pr | grep $victim_date | awk '{print $2}'`
        victim_pid2=`ps -ef | grep bash | grep checker-pr-postbuild-async.sh | grep $input_pr | grep $victim_date | awk '{print $2}'`
        victim_pid3_tizen=`ps -ef | grep python | grep gbs | grep "_pr_number $input_pr" | grep $victim_date | awk '{print $2}'`
        victim_pid3_ubuntu=`ps -ef | grep bash | grep pdebuild | grep "_pr_number $input_pr" | grep $victim_date | awk '{print $2}'`
        # Todo: NYI, Implement the OOP killer for Yocto build (devtool)
        victim_pid3_yocto=""
        victim_pid3_android=""
    
        # The OOP killer destroy the examination of out-of-date PRs when developers have resbumitted a PR repeatedly.
        if [[ ("$victim_pr" -eq "$input_pr") && (1 -eq "$(echo "$victim_date < $input_date" | bc)") ]]; then
            echo "[DEBUG] OOP Killer: Killing 'checker-pr-gateway.sh' process ($victim_pid1) ..."
            kill $victim_pid1

            echo "[DEBUG] OOP Killer: Killing 'checker-pr-postbuild-async.sh' process ($victim_pid2) ..."
            kill $victim_pid2

            echo "[DEBUG] OOP Killer/Tizen: victim_pr=$victim_pr, input_pr=$input_pr, victim_date=$victim_date, input_date=$input_date "
            echo "[DEBUG] OOP Killer/Tizen: killing PR $victim_pr (pid <$victim_pid1> <$victim_pid2> <$victim_pid3_tizen>)."
            kill $victim_pid3_tizen

            echo "[DEBUG] OOP Killer/Ubuntu: victim_pr=$victim_pr, input_pr=$input_pr, victim_date=$victim_date, input_date=$input_date "
            echo "[DEBUG] OOP Killer/Ubuntu: killing PR $victim_pr (pid <$victim_pid1> <$victim_pid2> <$victim_pid3_ubuntu>)."
            kill $victim_pid3_ubuntu

            # Sleep for 1 second to handle a situation that someone updates a PR repeatedly.
            sleep 1
            echo "[DEBUG] OOP Killer: removing the out-of-date ./${dir_worker}/${victim_pr}-${victim_date}-* folder"
            rm -rf ./${dir_worker}/${victim_pr}-${victim_date}-*
        fi
    done
}

