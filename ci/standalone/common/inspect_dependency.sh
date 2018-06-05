#!/usr/bin/env bash

##
# @file  checker-issue-comment.sh
# @brief issue facility to comment automatically whenever issue happens .
# @param
#  arg1: issue number
#

##
#  @brief check if a pcakge is installed
#  @param
#   arg1: package name
function check_package() {
    echo "Checking for $1..."
    which "$1" 2>/dev/null || {
      echo "Please install $1."
      exit 1
    }
}
