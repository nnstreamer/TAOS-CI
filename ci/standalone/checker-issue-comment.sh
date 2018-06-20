#!/usr/bin/env bash

## @file  checker-issue-comment.sh
## @brief issue facility to comment automatically whenever issue happens .
## @param
##  arg1: issue number
##

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/config-environment.sh
source ./common/cibot_rest_api.sh

# check if input argument is correct. 
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please, use a correct issue number.\n"
    exit 1
fi

input_issue=$1

# --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# execute automatic comment on new issue.

message=":octocat: **cibot**: Thank you for posting issue #$input_issue. The person in charge will reply soon."
cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_issue/comments"

