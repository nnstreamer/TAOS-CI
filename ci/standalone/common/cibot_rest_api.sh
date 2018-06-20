#!/usr/bin/env bash

##
# @file  cibot_rest_api.sh
# @brief issue & PR facility to comment automatically some messages

##
# @brief automatic comment facility
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
    
    echo -e "[DEBUG] Running the curl-based commenting procedure."
    echo -e "[DEBUG] TOKEN: $TOKEN"
    echo -e "[DEBUG] MESSAGE: $MESSAGE"
    echo -e "[DEBUG] COMMIT_ADDRESS: $COMMIT_ADDRESS"
    
    # let's do PR report
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\"$MESSAGE\"}" \
    $COMMIT_ADDRESS
}

##
# @brief automatic comment facility
# @param
# arg1: token number
# arg2: state
# arg3: context
# arg4: description
# arg5: target_url
# arg5: commit address
function cibot_pr_report(){
    # check if input argument is correct.
    if [[ $1 == "" || $2 == ""  || $3 == ""  || $4 == ""  || $5 == "" || $6 == "" ]]; then
        printf "[DEBUG] ERROR: Please, input correct arguments to run cibot_pr_report function.\n"
        exit 1
    fi
    # argeuments
    TOKEN="$1"
    STATE="$2"
    CONTEXT="$3"
    DESCRIPTION="$4"
    TARGET_URL="$5"
    COMMIT_ADDRESS="$6"
    
    echo -e "[DEBUG] Running the curl-based PR report procedure."
    
    # let's do PR report
    /usr/bin/curl -H "Content-Type: application/json" \
    -H "Authorization: token "$TOKEN"  " \
    --data "{\"state\":\"$STATE\",\"context\":\"$CONTEXT\",\"description\":\"$DESCRIPTION\",\"target_url\":\"$TARGET_URL\"}" \
    $COMMIT_ADDRESS
}
