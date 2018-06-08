#!/usr/bin/env bash

## @file  checker-issue-comment.sh
## @brief issue facility to comment automatically whenever issue happens .
## @param
##  arg1: issue number
##

# --------------------------- Pre-setting module --------------------------------------------------------
source ./config/config-environment.sh

# check if input argument is correct. 
if [[ $1 == "" ]]; then
    printf "[DEBUG] ERROR: Please, use a correct issue number.\n"
    exit 1
fi

# --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# execute automatic comment on new issue.
/usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"body":":octocat: **cibot**: Thank you for posting issue #'$1'. The person in charge will reply soon."}' \
     ${GITHUB_WEBHOOK_API}/issues/$1/comments
