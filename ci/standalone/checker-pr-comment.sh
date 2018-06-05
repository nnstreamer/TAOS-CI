#!/usr/bin/env bash

## @file  checker-pr-comment.sh
## @brief Automatic PR commenter to announce information automatically whenever contributor submits a PR
## @param
##  arg1: PR number
##

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/botenv.sh

# check if input argument is correct. 
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please, use a correct PR number.\n"
    exit 1
fi

input_pr=$1

 # --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# execute automatic comment on new PR.

# inform PR submitter that they do not have to merge their own PR directly.
message="Thank you for submitting PR #${input_pr}. Note that you **don't must merge your own PR** firsthand. If your PR has +2 commits, run **'$ git format-patch --cover-letter -{number-of-commits}'** to get a template. Then, paste a content in your PR body."

/usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":octocat: **cibot**: $message \"}" \
     ${GITHUB_WEBHOOK_API}/issues/$input_pr/comments


# inform the developers of the webpage address in order that they can monitor the current status of their PR.
message="If you want to monitor the current build status of your PR, Please refer to ${CISERVER}/AuDri/ci/standalone/ci-server/monitor.php"

/usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":mag_right: **cibot**: $message \"}" \
     ${GITHUB_WEBHOOK_API}/issues/$input_pr/comments
