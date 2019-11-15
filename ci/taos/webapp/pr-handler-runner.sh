#!/usr/bin/env bash


source ../config/config-environment.sh
source ../common/api_collection.sh

# TODO: Enhance the security of the handler.

# if # of arguments is 2, run the comment handler
args=$#
echo -e "[DEBUG] The number of arguments is $args."
echo -e "[DEBUG] command is ($0 $1 $2 $3 $4.)"
if [[ $args == 2 ]]; then
    echo -e "[DEBUG] setting parameters for the PR comment handler..."
    input_msg_comment="$1"
    input_pr="$2"
    echo -e "[DEBUG] *Token           : ******"
    echo -e "[DEBUG] *Message(report) : $input_msg_report"
    echo -e "[DEBUG] *Message(comment): $input_msg_comment"
    echo -e "[DEBUG] *API   : $GITHUB_WEBHOOK_API"
    echo -e "[DEBUG] *PR    : $input_pr"
# if # of arguments is 4, run the report handler
elif [[ $args == 4 ]]; then
    echo -e "[DEBUG] setting parameters for the PR report handler..."
    input_status="$1"
    input_cimodule="$2"
    input_msg_report="$3"
    input_commit="$4"
    echo -e "[DEBUG] *Token           : ******"
    echo -e "[DEBUG] *Status: $input_status"
    echo -e "[DEBUG] *CI module: $input_cimodule"
    echo -e "[DEBUG] *Message(report) : $input_msg_report"
    echo -e "[DEBUG] *Message(comment): $input_msg_comment"
    echo -e "[DEBUG] *CI Server: $CISERVER"
    echo -e "[DEBUG] *API   : $GITHUB_WEBHOOK_API"
    echo -e "[DEBUG] *commit: $input_commit"
else
    echo -e "Ooops. Please check the number of the arguments."
fi



if [[ $input_msg_report ]]; then
    echo -e '[DEBUG] cibot_report $TOKEN "$input_status" "$input_cimodule" "$input_msg_report" "$CISERVER" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"'
    cibot_report $TOKEN "$input_status" "$input_cimodule" "$input_msg_report" "$CISERVER" "${GITHUB_WEBHOOK_API}/statuses/$input_commit"
else
    echo -e "[WARN] The system does not run the cibot_report() because the variable input_msg_report is empty."
fi

if [[ $input_msg_comment ]]; then
    cibot_comment $TOKEN "$input_msg_comment" "$GITHUB_WEBHOOK_API/issues/$input_pr/comments"
else
    echo -e "[WARN] The system does not run the cibot_comment() because the variable input_msg_comment is empty."
fi
