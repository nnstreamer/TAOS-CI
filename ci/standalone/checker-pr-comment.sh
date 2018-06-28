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

if [[ $pr_comment_notice == 1 ]]; then
    # inform PR submitter of a rule to pass the CI process
    message="Thank you for submitting PR #${input_pr}. Your PR has to pass all verificiation processes of cibot before getting a review process from reviewers. We recommend that you read instruction manual in `Documentation folder`. If you want to monitor the progress status of your PR in detail, visit ${CISERVER}."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_self_merge == 1 ]]; then
    # inform PR submitter that they do not have to merge their own PR directly.
    message="Note that **you do not have to merge your own PR** directly."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_many_commit == 1 ]]; then
    # infrom PR submitter of how to submit a PR that include lots of commits.
    message="If you have to submit +2 commits per PR, paste the output in your PR body after running `$ git format-patch --cover-letter -{number-of-commits}`."
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

if [[ $pr_comment_pr_monitor == 1 ]]; then
    # inform PR submitter of the webpage address in order that they can monitor the current status of their PR.
    message="If you want to monitor the current build status of your PR, Please refer to ${CISERVER}/${PRJ_REPO_UPSTREAM}/ci/standalone/ci-server/monitor.php"
    cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
fi

