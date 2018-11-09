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
# @file  api_collection.sh
# @brief API collection to send webhook messages to a github server and to manage comment functions
# --------------------------- Pull-Request scheduler: control a server overhead due to too many PRs -----------

# Control gbs tasks (use -gt operator because one is "grep" process) to maintain an available system resource
# Job queue: Fairness or FCFS is not guaranteed.
# $RANDOM is an internal bash function (not a constant) - http://tldp.org/LDP/abs/html/randomvar.html
# To enhance a job queue, refer to http://hackthology.com/a-job-queue-in-bash.html
# The default RUN Queue is declared in the configuration file

# Todo: how to avoid a PR hang situation while running build tasks in AWS instance
# a. This routine need to be executed in front of the Ubuntu build as well as this location
# b. Make module files in common folder for maintenance consistently

declare -g current_jobs_all=0

##
# @brief Calculate the number of running jobs currently
# @param None
function check_running_jobs(){
    current_jobs_tizen_cmd="ps aux | grep \"sudo.*gbs build\" | wc -l"
    current_jobs_ubuntu_cmd="ps aux | grep \"sudo.*pbuilder\" | wc -l"
    current_jobs_yocto_cmd="" # NYI

    # Append "-2" to subtract that two 'grep' values are counted
    current_jobs_all="$(( $(eval "$current_jobs_tizen_cmd") + $(eval "$current_jobs_ubuntu_cmd") - 2 ))"
}

##
# @brief PR scheduler handle run-queue and wait-queue to keep the available system sources
# @param
#  arg1  location that we execute this module
function pr_sched_runqueue(){
    check_running_jobs
    # if running jobs exceed the maxium number of the run-queue, go to wait-queue.
    while [ $current_jobs_all -gt $RUN_QUEUE_PR_JOBS ]; do
        WAITTIME=$(( ( RANDOM % 10 ) + 50 ))
        echo -e "[DEBUG] Platfomr package builder: The PID $$ is sleeping for $WAITTIME seconds."
        echo -e "[DEBUG] # of running jobs is $current_jobs_all. # of maxium run queues is $RUN_QUEUE_PR_JOBS."
        echo -e "[DEBUG] The location of this function is $1."
        sleep $WAITTIME
        check_running_jobs
    done

}

