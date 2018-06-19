#!/usr/bin/env bash

# set-up configruation variables.
mkdir -p /var/www/html/<prj_name>/gcov
pushd /var/www/html/<prj_name>/gcov

rm -Rf unittest_old
USERNAME=git.bot.sec
PASSWORD=npuxxxx

# download nnstream-unittest-coverar.rpm files.
mv index.html index_reference.html
wget http://$USERNAME:$PASSWORD@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/TAOS/unittest/x86_64/
FILENAME=`grep "nnstreamer-unittest-coverage.*\.rpm" index.html | sed "s|.*\(nnstreamer-unittest-.*\)\.rpm.*|\1.rpm|"`

echo $FILENAME

# check if file does exist.
FILENAMELEN=${#FILENAME}

if [ "$FILENAMELEN" -lt 1 ]
then
  echo "nnstreamer-unittest-coverage*.rpm does not exist!"
  exit 0
fi

# delete the existing rpm files
rm -f nnstreamer-unittest-coverage*.rpm.*
rm -f nnstreamer-unittest-coverage*.rpm

# download latest rpm file.
rm -Rf rpmextract
mkdir -p rpmextract

wget http://$USERNAME:$PASSWORD@10.113.136.32/download_trbs/newlive/Tizen:/5.0:/TAOS/unittest/x86_64/$FILENAME

# decompress latest rpm file.
pushd rpmextract
rpm2cpio ../$FILENAME | cpio -idmv
popd
rm -Rf nnstreamer-*

# move unit test files to ./unittest/ folder.
mv unittest unittest_old
mkdir -p unittest
mv -f rpmextract/usr/share/nnstreamer/unittest/result/* .
ls -la

# end of line.
