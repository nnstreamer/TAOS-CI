#!/usr/bin/env bash

## @file ./audri-hard-copy-ros-generate.sh"
#  @brief pdf generator for auto-driving development manual
#  @date May-13-2018
#  @dependency: doxygen, make, unoconv, libreoffice, pdftk, pdfunite


# Generate original book with doxygen tags
function generate_original(){
doxygen ../Doxyfile.ros 
cd latex 
make  -j`nproc`
mv refman.pdf audri-ros.pdf 
}

function generate_cover(){
# Generate cover book 
unoconv -f pdf --export=ExportFormFields=false ../../Documentation/audri-hard-copy-cover1.odt 
string_time="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                         $(date)"
echo -e  "$string_time" > audri-hard-copy-date.txt
libreoffice --convert-to "pdf" audri-hard-copy-date.txt 
pdftk  ../../Documentation/audri-hard-copy-cover1.pdf  stamp ./audri-hard-copy-date.pdf  output audri-hard-copy-stamped.pdf
}

function generate_final(){
# Generate final book
pdfunite audri-hard-copy-stamped.pdf audri-ros.pdf audri.pdf
}

# Main function
pushd /var/www/html/AuDri-doxygen/ROS/ 
generate_original
generate_cover
generate_final
popd
