#!/usr/bin/env bash

# github webhook api address
GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/STAR/on-device-api"
# GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/STAR/nnstreamer"
# GITHUB_WEBHOOK_API="https://github.sec.samsung.net/api/v3/repos/STAR/TAOS-CI"

TOKEN="01eec554abcaae8755c06c2b06f5d6bb84d4b4a5" # git.bot.sec id

# input commit number. For example,  input_commit is 6967adfe5fea652b9959c58110fc8d7f280c8a43
input_commit=$1

if [[ $1 == "" ]]; then
    echo "Oooops. Run '$0 <COMMIT_NUMBER>'"
fi

#CONTEXT="TAOS/pr-format-clang"
#CONTEXT="TAOS/pr-format-doxygen"
#CONTEXT="TAOS/pr-format-newline"
#CONTEXT="TAOS/pr-format-filesize"
#CONTEXT="TAOS/pr-format-indent"
#CONTEXT="TAOS/pr-format-indent"
CONTEXT="(INFO)TAOS/pr-format-all"
#CONTEXT="TAOS/pr-audit-build-tizen"
#CONTEXT="TAOS/pr-audit-build-ubuntu"
#CONTEXT="TAOS/pr-audit-build-smp"
#CONTEXT="(INFO)TAOS/pr-audit-all"


# send a PR status message into a commit of a PR
/usr/bin/curl -H "Content-Type: application/json" \
 -H "Authorization: token "$TOKEN"  " \
 --data "{\"state\":\"success\",\"context\":\"$CONTEXT\",\"description\":\"Successfully done. It is just a test message.\",\"target_url\":\"http://aaci.mooo.com/\"}" \
 ${GITHUB_WEBHOOK_API}/statuses/$input_commit

echo -e "[DEBUG] Return value of the curl webhook command is '$?'. If the value is 0, it means that webhook operation is normal."
echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Not Found\", add a privileged user id at 'Setting - Collaborators'."
echo -e "[DEBUG] Note: The privileged user id has to be appended by \"Write\" permission."
echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Bad credentials\", try do it again with a correct token key."

