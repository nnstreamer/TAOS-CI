#!/usr/bin/env bash

## @file ./book-hard-copy-prj-generate.sh"
#  @brief pdf generator for auto-driving development manual
#  @date May-13-2018
#  @dependency: doxygen, make, unoconv, libreoffice, pdftk, pdfunite

src_path="`dirname \"$0\"`/../.."

# Generate original book with doxygen tags
function generate_original(){
doxygen ./ci/Doxyfile.prj
cd latex 
make  -j`nproc`
mv refman.pdf book-prj.pdf 
}

function generate_cover(){
# Generate cover book 
unoconv -f pdf --export=ExportFormFields=false ../ci/doc/book-hard-copy-cover1.odt 
string_time="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                         $(date)"
echo -e  "$string_time" > book-hard-copy-date.txt
libreoffice --convert-to "pdf" book-hard-copy-date.txt 
pdftk  ../ci/doc/book-hard-copy-cover1.pdf  stamp ./book-hard-copy-date.pdf  output book-hard-copy-stamped.pdf
}

function generate_final(){
# Generate final book
pdfunite book-hard-copy-stamped.pdf book-prj.pdf book.pdf
}

# Main function
pushd $src_path
generate_original
generate_cover
generate_final
popd
