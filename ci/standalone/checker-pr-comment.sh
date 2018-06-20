#!/usr/bin/env bash

## @file  checker-pr-comment.sh
## @brief Automatic PR commenter to announce information automatically whenever contributor submits a PR
## @param
##  arg1: PR number
##

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/config-environment.sh
source ./common/cibot_rest_api.sh

# check if input argument is correct. 
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please, use a correct PR number.\n"
    exit 1
fi

input_pr=$1

 # --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# execute automatic comment to handle new PR that include commits more than 2.

# inform PR submitter that they do not have to merge their own PR directly.
# message="Thank you for submitting PR #${input_pr}. Note that you **are not allowed to merge your own PR** directly. If your PR has +2 commits, run **'$ git format-patch --cover-letter -{number-of-commits}'** to get a template. Then, paste a content in your PR body."
# cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"


# inform the developers of the webpage address in order that they can monitor the current status of their PR.
message="If you want to monitor the current build status of your PR, Please refer to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/standalone/ci-server/monitor.php"
cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"

