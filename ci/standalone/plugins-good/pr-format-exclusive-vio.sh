#!/usr/bin/env bash

##
# @file pr-format-exclusive-vio.sh
# @brief Check the issue #279 (VIO commits should be exclusive)
#

##
# @brief [MODULE] CI/pr-format-exclusive-vio
#
# Check issue #279. VIO commits should not touch non VIO files.
#
function pr-format-exclusive-vio(){
    echo "##################################################################################################"
    echo "[DEBUG] Starting pr-format-exclusive-vio function to investigate if a VIO commit is not exclusive."
    FILELIST=`git show --pretty="format:" --name-only`
    VIO_DIRECTORY="ROS/.*VIO/"
    CHECKVIO=0
    CHECKNONVIO=0
    for X in $FILELIST; do
        if [[ $X =~ ^$VIO_DIRECTORY ]]; then
            CHECKVIO=1
        else
            CHECKNONVIO=1
        fi
    done
    if [[ "$CHECKVIO" -eq 1 && "$CHECKNONVIO" -eq 1 ]]; then
        global_check_result="failure"
        echo "[DEBUG] Failed. A VIO commit is not exclusive."
        message="Oooops. This commit has VIO files and non-VIO files at the same time, violating issue #279."
        cibot_pr_report $TOKEN "failure" "CI/pr-format-exclusive-vio" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Passed. No violation of issue #279."
        message="Successfully, The commits are passed."
        cibot_pr_report $TOKEN "success" "CI/pr-format-exclusive-vio" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi
}
