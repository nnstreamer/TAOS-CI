#!/usr/bin/env bash

## @file   book-doxygen-publish.sh
#  @brief  The PDF generator for a Doxygen-based developer manual
#  @date   May-13-2018
#  @author Geunsik Lim <geunsik.lim@samsung.com>

################# Do not modify the below statements ##################################

##
#  @brief check if a pcakge is installed
#  @param
#   arg1: package name
function check_dep_cmd() {
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
    rm -f $REFERENCE_REPOSITORY/ci/doxybook/.~lock.book-cover-design.pdf
    unoconv -f pdf --export=ExportFormFields=false $REFERENCE_REPOSITORY/ci/doxybook/book-cover-design.odt
    mv $REFERENCE_REPOSITORY/ci/doxybook/book-cover-design.pdf ./
    string_time="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                         $(date)"
    echo -e  "$string_time" > book-cover-date.txt
    libreoffice --convert-to "pdf" book-cover-date.txt 
    pdftk book-cover-design.pdf stamp book-cover-date.pdf output book-cover-stamped.pdf
}

## @brief Generate final book
function generate_final(){
    display "[DEBUG] current folder:" $(pwd)
    pdfunite book-cover-stamped.pdf book-prj.pdf book.pdf
    display "[DEBUG] PDF book file is generated in" $(pwd)
}

## @brief Clean unnecessary files
function generate_clean(){
    display "[DEBUG] current folder:" $(pwd)
    # if  latex and html foler are exists in the GitHub projct folder, remove them.
    if [[ -d latex || -f latex ]]; echo "Oooops. latex folder/symbolic exists. Removing that..."; then rm -rf latex; fi
    if [[ -d html  || -f html  ]]; echo "Oooops. html  folder/symbolic exists. Removing that..."; then rm -rf html ; fi

    # In order to keep the only source files in $SRC_PATH directory,
    # let's move the latex and html folder to the GitHub project folder
    # Note that $SRC_PATH directory has to be used by various utilities.
    mv $SRC_PATH/latex .
    mv $SRC_PATH/html  .
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

    # clean unnecessary files
    generate_clean

    echo -e "The Doxygen-based publication procedure is completed."
}

## @dependency: doxygen, make, unoconv, libreoffice, pdftk, pdfunite
check_dep_cmd doxygen
check_dep_cmd make
check_dep_cmd unoconv
check_dep_cmd libreoffice
check_dep_cmd pdftk
check_dep_cmd pdfunite

# Start
# Note that the you must keep the folder structure to generate the doxygen-based pdf book as follows.
# - /var/www/html/<prj_name>/
# - /var/www/html/ci  (Symbolic)
# - /var/www/html/<prj_name>/TAOS-CI/
# Then, run a script file with fulll path such as "/var/www/html/<prj_name>/ci/doxybook/book-doxygen-publish.sh"
# For example, $ /var/www/html/<prj_name>/ci/doxybook/book-doxygen-publish.sh

main $0
