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
# @file pr-audit-build-ubuntu.sh
# @brief Build package with pbuilder/pdebuild to verify build validation on Ubuntu distribution
# @see      https://wiki.ubuntu.com/PbuilderHowto
# @see      https://github.com/nnsuite/TAOS-CI
# @author   Geunsik Lim <geunsik.lim@samsung.com>
# @requirement
# First install the required packages.
# $ sudo apt install pbuilder debootstrap devscripts
# Then, create tarball that will contain your chroot environment to build package.
#
# $ vi ~/.pbuilderrc
# # man 5 pbuilderrc
# DISTRIBUTION=xenial
# OTHERMIRROR="deb http://archive.ubuntu.com/ubuntu xenial universe multiverse"
# $ sudo ln -s  ~/.pbuilderrc /root/.pbuilderrc
# ( or $ sudo ln -s  ~/.pbuilderrc /.pbuilderrc)
# $ sudo pbuilder create
# $ ls -al /var/cache/pbuilder/base.tgz

# @brief [MODULE] TAOS/pr-audit-build-ubuntu-trigger-queue
function pr-audit-build-ubuntu-trigger-queue(){
    message="Trigger: queued. There are other build jobs and we need to wait.. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-audit-build-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-ubuntu-trigger-run
function pr-audit-build-ubuntu-trigger-run(){
    echo "[DEBUG] Starting CI trigger to run 'pdebuild (for Ubuntu)' command actually."
    message="Trigger: running. The commit number is $input_commit."
    cibot_pr_report $TOKEN "pending" "TAOS/pr-audit-build-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
}

# @brief [MODULE] TAOS/pr-audit-build-ubuntu
function pr-audit-build-ubuntu(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-audit-build-ubuntu: check build process for Ubuntu distribution"

    # check if dependent packages are installed
    # the required packages are pbuilder(pdebuild), debootstrap(debootstrap), and devscripts(debuild)
    check_dependency sudo
    check_dependency curl
    check_dependency pdebuild
    check_dependency debootstrap
    check_dependency debuild

    echo "[DEBUG] starting TAOS/pr-audit-build-ubuntu facility"

    # BUILD_MODE=0 : run "pdebuild" command without generating debugging information.
    # BUILD_MODE=1 : run "pdebuild" command with a debug file.
    # BUILD_MODE=99: skip "pdebuild" procedures
    BUILD_MODE=$BUILD_MODE_UBUNTU

    # build package
    if [[ $BUILD_MODE == 99 ]]; then
        # skip build procedure
        echo -e "BUILD_MODE = 99"
        echo -e "Skipping 'pdebuild' procedure temporarily."
        $result=999
    else
        # build package with pdebuild
        # Note that you have to set no-password condition after running 'visudo' command.
        # www-data    ALL=(ALL) NOPASSWD:ALL
        echo -e "[DEBUG] current folder is $(pwd)."

        # if ./GBS-ROOT/ folder exists, let's remove this folder for pdebuild.
        if [[ -d GBS-ROOT ]]; then
            echo -e "Removing ./GBS-ROOT/ folder."
            sudo rm -rf ./GBS-ROOT/
            if [[ $? -ne 0 ]]; then
                    echo -e "[DEBUG][FAILED] Oooops!!!!!! ./GBS-ROOT folder is not removed."
            else
                    echo -e "[DEBUG][PASSED] Successfully ./GBS-ROOT folder is removed."
            fi
        fi

        # It extracts the chroot, invoke "apt-get update" and "apt-get dist-upgrade" inside the chroot,
        # and then recreate the base.tgz (the base tar-ball)
        # Caution: we recommend that you append the below statement into /etc/crontab to avoid a traffic jam
        # such as a busy waiting situation in case of too many PRs.
        # echo -e "[DEBUG] starting 'pdebuild update' command."
        # sudo pbuilder update  --override-config

        echo -e "[DEBUG] starting 'pdebuild --use-pdebuild-internal' command."
        # --use-pdebuild-internal runs "debian/rules clean"inside the chroot
        # http://pbuilder-docs.readthedocs.io/en/latest/usage.html
        # example: sudo -Hu www-data pdebuild
        pdebuild  --use-pdebuild-internal 2> ../report/build_log_${input_pr}_ubuntu_error.txt 1> ../report/build_log_${input_pr}_ubuntu_output.txt
    fi

    result=$?
    echo "[DEBUG] The variable result value is $result."

    # report execution result
    # let's do the build procedure of or skip the build procedure according to $BUILD_MODE
    if [[ $BUILD_MODE == 99 ]]; then
        # Do not run "pdebuild" command in order to skip unnecessary examination if there are no buildable files.
        echo -e "BUILD_MODE == 99"
        echo -e "[DEBUG] Let's skip the pdebuild procedure because there is not source code. All files may be skipped."
        echo -e "[DEBUG] So, we stop remained all tasks at this time."

        message="Skipped pdebuild procedure. No buildable files found. Commit number is $input_commit."
        cibot_pr_report $TOKEN "success" "TAOS/pr-audit-build-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        message="Skipped pdebuild procedure. Successfully all audit modules are passed. Commit number is $input_commit."
        cibot_pr_report $TOKEN "success" "(INFO)TAOS/pr-audit-all" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

        echo -e "[DEBUG] pdebuild procedure is skipped - it is ready to review! :shipit: Note that CI bot has two sub-bots such as TAOS/pr-audit-all and TAOS/pr-format-all."
    else
        echo -e "BUILD_MODE != 99"
        echo -e "[DEBUG] The return value of pdebuild command is $result."
        # Let's check if build procedure is normally done.
        if [[ $result -eq 0 ]]; then
                echo -e "[DEBUG][PASSED] Successfully Ubunu build checker is passed. Return value is ($result)."
                check_result="success"
        else
                echo -e "[DEBUG][FAILED] Oooops!!!!!! Ubuntu build checker is failed. Return value is ($result)."
                check_result="failure"
                global_check_result="failure"
        fi

        # Let's report build result of source code
        if [[ $check_result == "success" ]]; then
            message="Successfully  Ubuntu build checker is passed. Commit number is '$input_commit'."
            cibot_pr_report $TOKEN "success" "TAOS/pr-audit-build-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
        else
            message="Oooops. Ubuntu  build checker is failed. Resubmit the PR after fixing correctly. Commit number is $input_commit."
            cibot_pr_report $TOKEN "failure" "TAOS/pr-audit-build-ubuntu" "$message" "${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/" "$GITHUB_WEBHOOK_API/statuses/$input_commit"

            # comment a hint on failed PR to author.
            message=":octocat: **cibot**: $user_id, Oooops. A Ubuntu builder checker could not be completed. To get a hint, please go to ${CISERVER}${PRJ_REPO_UPSTREAM}/ci/${dir_commit}/."
            cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
        fi
    fi
 
}
