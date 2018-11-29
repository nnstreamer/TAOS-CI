#!/usr/bin/env bash

# Specify a folder name to archive packages files (e.g., .rpm, .deb)
PACK_BIN_FOLDER="binary_repository"

# Specify a default locale policy.
# We recommend that you use a locale setting which supports UTF-8.
# Case study:
# 1) Yocto: "devtool add/build" command is not executed because it is written by a UTF-8 library.
# 2) Download: A log message is broken while downloading a file with no locale setting 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

