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


##
# @brief API to write comment to new pull request with curl
# @param
# arg1: token key
# arg2: message
# arg3: commit address
function cibot_comment(){
    # check if input argument is correct.
    if [[ $1 == "" || $2 == "" || $3 == "" ]]; then
        printf "[DEBUG] ERROR: Please, input correct arguments to run cibot_comment function.\n"
        exit 1
    fi

    # argeuments
    TOKEN="$1"
    MESSAGE="$2"
    COMMIT_ADDRESS="$3"

    echo -e "[DEBUG] Running the curl-based $FUNCNAME API to comment a hint."
    echo -e "[DEBUG] MESSAGE: $MESSAGE"
    echo -e "[DEBUG] COMMIT_ADDRESS: $COMMIT_ADDRESS"

    # keep the message that exceeds 140 characters in case of comment creation of issue and PR
    # In case that cibot create deployment statuses for a given PR:
    # A short description of the status. Maximum length of 140 characters. Default: ""
    # @see https://developer.github.com/v3/repos/deployments/
    TRIM_MESSAGE="$MESSAGE"

    # let's do PR report
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\"$TRIM_MESSAGE\"}" \
    $COMMIT_ADDRESS

    echo -e "[DEBUG] Return value of the curl webhook command is '$?'. If the value is 0, it means that webhook operation is normal."
    echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Not Found\", add a privileged user id at 'Setting - Collaborators'."
    echo -e "[DEBUG] Note: The privileged user id has to be appended by \"Write\" permission."
    echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Bad credentials\", try do it again with a correct token key."

}

##
# @brief API to change a status of the pull request with curl
# @param
# arg1: token number
# arg2: state
# arg3: context
# arg4: description
# arg5: target_url
# arg5: commit address
function cibot_report(){
    # check if input argument is correct.
    if [[ $1 == "" || $2 == ""  || $3 == ""  || $4 == ""  || $5 == "" || $6 == "" ]]; then
        printf "[DEBUG] ERROR: Please, input correct arguments to run cibot_report function.\n"
        exit 1
    fi
    # argeuments
    TOKEN="$1"
    STATE="$2"
    CONTEXT="$3"
    DESCRIPTION="$4"
    TARGET_URL="$5"
    COMMIT_ADDRESS="$6"

    echo -e "[DEBUG] Running the curl-based $FUNCNAME API to change the PR status."
    echo -e "[DEBUG] STATE: $STATE"
    echo -e "[DEBUG] CONTEXT: $CONTEXT"

    # trim the message that exceeds 140 characters in case of PR status change.
    # In case that cibot create deployment statuses for a given PR:
    # A short description of the status. Maximum length of 140 characters. Default: ""
    # @see https://developer.github.com/v3/repos/deployments/
    TRIM_DESCRIPTION=""
    msg_max=120
    num_chars=`echo $DESCRIPTION | wc -c`
    echo -e "[DEBUG] The length of a webhook message is \"$num_chars\"."
    echo -e "[DEBUG] The original DESCRIPTION is \"$DESCRIPTION\"."
    if [[ $num_chars -gt $msg_max ]]; then
        TRIM_DESCRIPTION="`echo $DESCRIPTION | cut -c 1-${msg_max}` ..."
    else
        TRIM_DESCRIPTION="$DESCRIPTION"
    fi
    echo -e "[DEBUG] The edited TRIM_DESCRIPTION is \"$TRIM_DESCRIPTION\"."

    # let's send PR report to change PR status
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"state\":\"$STATE\",\"context\":\"$CONTEXT\",\"description\":\"$TRIM_DESCRIPTION\",\"target_url\":\"$TARGET_URL\"}" \
    $COMMIT_ADDRESS

    echo -e "[DEBUG] -----------------------------------------------------------------------------"
    echo -e "[DEBUG] Return value of the curl webhook command is '$?'. If the value is 0, it means that webhook operation is normal."
    echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Not Found\", add a privileged user id at 'Setting - Collaborators'."
    echo -e "[DEBUG] Note: The privileged user id has to be appended by \"Write\" permission."
    echo -e "[DEBUG] Note: If webhook server replies \"message\": \"Bad credentials\", try do it again with a correct token key."
    echo -e "[DEBUG] -----------------------------------------------------------------------------"
}

##
# @brief API to move to a git repository folder that imported a specified branch name
# @param
# argument: none
function goto_repodir(){
    echo -e "[DEBUG] Let's move to a git repository folder."
    cd $dir_ci
    cd $dir_commit
    cd ./${PRJ_REPO_OWNER}
    echo -e "Current path: $(pwd)."
}

##
#  @brief check if a package is installed
#  @param
#   arg1: package name
function check_cmd_dep() {
    echo "Checking for $1..."
    which "$1" 2>/dev/null || {
      echo "Please install $1."
      # Inform a CI administrator of a hint in more detail
      message=":octocat: **cibot**: Oooops. The administrator of CI server must install a debian package to support '$1' command."
      cibot_comment $TOKEN "$message" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
      exit 1
    }
}

# check if dependent packages are installed to avoid an unexpected program error.
check_cmd_dep curl
check_cmd_dep cut
check_cmd_dep wc
