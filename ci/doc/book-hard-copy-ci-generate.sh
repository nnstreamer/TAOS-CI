#!/usr/bin/env bash

## @file ./book-hard-copy-ci-generate.sh"
#  @brief pdf generator for auto-driving CI book
#  @date May-13-2018
#  @dependency: doxygen, make

$ci_path="$(pwd)/../.."

##
# @brief  Generate PDF-based CI manual with doxygen tags
#
function generate_ci_book(){
doxygen ../Doxyfile.ci
cd latex 
make  -j`nproc`
mv refman.pdf book-ci.pdf
}

# Main function
pushd $ci_path
generate_ci_book
popd
