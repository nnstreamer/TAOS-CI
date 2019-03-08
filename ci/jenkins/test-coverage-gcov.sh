#!/usr/bin/env bash

##
# Copyright (c) 2018 Samsung Electronics Co., Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# set-up configruation variables.
mkdir -p /var/www/html/<prj_name>/gcov
pushd /var/www/html/<prj_name>/gcov

rm -Rf unittest_old

# download nnstream-unittest-coverar.rpm files.
mv index.html index_reference.html
wget http://download.tizen.org/live/devel:/AIC:/Tizen:/5.0:/nnsuite/unittest/x86_64/
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

wget http://download.tizen.org/live/devel:/AIC:/Tizen:/5.0:/nnsuite/unittest/x86_64/$FILENAME

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
