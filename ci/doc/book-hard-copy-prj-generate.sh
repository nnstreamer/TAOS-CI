#!/usr/bin/env bash

## @file ./book-hard-copy-prj-generate.sh"
#  @brief pdf generator for auto-driving development manual
#  @date May-13-2018

################# Do not modify the below statements ##################################

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

## @brief Display debug message
function display(){
    echo -e $1 $2
}

## @brief Generate original book with doxygen tags
function generate_original(){
    display "[DEBUG] current folder:" $(pwd)
    doxygen $REFERENCE_REPOSITORY/ci/Doxyfile.prj
    cd latex 
    make  -j`nproc`
    mv refman.pdf book-prj.pdf 
}

## @brief Generate cover book
function generate_cover(){
    display "[DEBUG] current folder:" $(pwd)
    unoconv -f pdf --export=ExportFormFields=false $REFERENCE_REPOSITORY/ci/doc/book-hard-copy-cover1.odt
    string_time="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                         $(date)"
    echo -e  "$string_time" > book-hard-copy-date.txt
    libreoffice --convert-to "pdf" book-hard-copy-date.txt 
    pdftk $REFERENCE_REPOSITORY/ci/doc/book-hard-copy-cover1.pdf  stamp book-hard-copy-date.pdf  output book-hard-copy-stamped.pdf
}

## @brief Generate final book
function generate_final(){
    display "[DEBUG] current folder:" $(pwd)
    pdfunite book-hard-copy-stamped.pdf book-prj.pdf book.pdf
    display "[DEBUG] PDF book file is generated in" $(pwd)
}

## @brief Main function
function main(){
    # fetch a project path from command
    display "[DEBUG] current folder:" $1
    prj_path="`dirname \"$1\"`/../.."

    # go to project path
    cd $prj_path
    display "[DEBUG] value of prj_path:" $prj_path
    display "[DEBUG] current folder:" $(pwd)
    # import configuraiotn file of CI
    source ./ci/taos/config/config-environment.sh

    # let's go to source folder
    # then, run entire procedure to generate doxygen-based pdf book
    pushd $SRC_PATH
    display "[DEBUG] current folder:" $(pwd)
    generate_original
    generate_cover
    generate_final
    display "[DEBUG] current folder:" $(pwd)
    popd

    # Move 'latex' and 'html' folder to project folder to keep only source code in $SRC_PATH directory.
    # Note that $SRC_PATH directory has to be used by various utilities.
    display "[DEBUG] current folder:" $1
    if [[ -d latex || -f latex ]]; echo "Oooops. latex folder/symbolic exists. Removing that..."; then rm -rf latex; fi
    if [[ -d html  || -f html  ]]; echo "Oooops. html  folder/symbolic exists. Removing that..."; then rm -rf html ; fi
    mv $SRC_PATH/latex .
    mv $SRC_PATH/html  .
}

## @dependency: doxygen, make, unoconv, libreoffice, pdftk, pdfunite
check_package doxygen
check_package make
check_package unoconv
check_package libreoffice
check_package pdftk
check_package pdfunite

# Start
# Note that the folder layout has to be maintained as follows.
# - /var/www/html/<prj_name>/
# - /var/www/html/ci  (Symbolic)
# - /var/www/html/<prc_name>/TAOS-CI/
# Then, run a script file with fulll path such as "/var/www/html/<prj_name>/ci/doc/book-hard-copy-prj-generate.sh"
# For example, $ /var/www/html/<prj_name>/ci/doc/book-hard-copy-prj-generate.sh

main $0
