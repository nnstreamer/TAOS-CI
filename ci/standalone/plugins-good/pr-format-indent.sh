#!/usr/bin/env bash

##
# @file pr-format-indent.sh
# @brief Check the code formatting style with GNU indent
#  
# https://www.gnu.org/software/indent/

# @brief [MODULE] TAOS/pr-format-indent
function pr-format-indent(){
    echo "########################################################################################"
    echo "[MODULE] TAOS/pr-format-indent: Check the code formatting style with GNU indent"
    # Note that you have to install up-to-date GNU intent package.
    INDENTFORMAT=NA
    INDENT_COMMAND="indent"
    
    which ${INDENT_COMMAND}
    if [[ $? -ne 0 ]]; then
        echo "Error: ${INDENT_COMMAND} is not available."
        echo "       Please install ${INDENT_COMMAND}."
        exit 1
    fi
   
    # One way to make sure you are following our coding style is to run your code
    # (remember, only the *.c files, not the headers) through GNU Indent 
    FILES_IN_COMPILER=$(find $SRC_PATH/ -iname '*.cpp' -o -iname '*.c')
    FILES_TO_BE_TESTED=$(git ls-files $FILES_IN_COMPILER)
    
    echo "[DEBUG] TAOS/pr-format-indent: run"
    # ${INDENT_COMMAND} -i $FILES_TO_BE_TESTED
    indent \
      --braces-on-if-line \
      --case-brace-indentation0 \
      --case-indentation2 \
      --braces-after-struct-decl-line \
      --line-length80 \
      --no-tabs \
      --cuddle-else \
      --dont-line-up-parentheses \
      --continuation-indentation4 \
      --honour-newlines \
      --tab-size8 \
      --indent-level2 \
      $FILES_TO_BE_TESTED

    indent_format_file="indent-format.patch"
    git diff > ../report/${indent_format_file}
    PATCHFILE_SIZE=$(stat -c%s ../report/${indent_format_file})
    if [[ $PATCHFILE_SIZE -ne 0 ]]; then
            echo "[DEBUG] GNU indent is failed. Update your code to follow convention after reading ${indent_format_file}."
            check_result="failure"
            global_check_result="failure"
    else
            check_result="success"
    fi
    
    if [[ $check_result == "success" ]]; then
        echo "[DEBUG] Passed. A indent formatting style."
        message="Successfully, The commits are passed."
        cibot_pr_report $TOKEN "success" "TAOS/pr-format-indent" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    else
        echo "[DEBUG] Failed. A indent formatting style."
        message="Oooops. The component you are submitting with incorrect indent-format style."
        cibot_pr_report $TOKEN "failure" "TAOS/pr-format-indent" "$message" "$REPOSITORY_WEB/pull/$input_pr/commits/$input_commit" "$GITHUB_WEBHOOK_API/statuses/$input_commit"
    fi
}
