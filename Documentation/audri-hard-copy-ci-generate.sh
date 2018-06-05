#!/usr/bin/env bash

## @file ./audri-hard-copy-ci-generate.sh"
#  @brief pdf generator for auto-driving CI book
#  @date May-13-2018
#  @dependency: doxygen, make



# Generate PDF-based CI manual with doxygen tags
function generate_ci_book(){
doxygen ../Doxyfile.ci
cd latex 
make  -j`nproc`
mv refman.pdf audri-ci.pdf
}

# Main function
pushd /var/www/html/AuDri-doxygen/ci/
generate_ci_book
popd
