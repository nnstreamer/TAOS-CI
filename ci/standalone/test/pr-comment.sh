#!/usr/bin/env bash

GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/STAR/AuDri"
TOKEN="01eec554abcaae8755c06c2b06f5d6bb84d4b4a5" # git.bot.sec id
input_pr=$1

if [[ $1 == "" ]]; then
    echo "Oooops. Run '$0 <PR_NUMBER>'"
fi

# write a comment message into a PR
/usr/bin/curl -H "Content-Type: application/json" \
 -H "Authorization: token "$TOKEN"  " \
 --data "{\"body\":\":octocat: **cibot**: :+1: This PR looks great - It is just a test message.\"}" \
 ${GITHUB_WEBHOOK_API}/issues/${input_pr}/comments


