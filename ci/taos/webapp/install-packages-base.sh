#!/usr/bin/env bash

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

##
# @file       install-packages-base.sh
# @brief      This script is to install packages that are required to run all modules.
# @dependency apt
# @see        https://github.com/nnsuite/TAOS-CI

##
# @brief Check if packages are installed normally.
function func-pack-fail(){
        echo -e "[DEBUG] It's failed. Oooops. The return value is $?."
        echo -e "[DEBUG] Please run this script again after fixing this issue."
        echo -e "[DEBUG] Note that you have to install all pcakges as a prerequiste."
        echo -e "[DEBUG] Stopping this script..."
        exit 1
}

echo -e "\n\n\n##########  for CI-server: Installing Apache and PHP packages for webhook handler"
sudo apt -y install bash php curl || func-pack-fail
sudo apt -y install apache2 || func-pack-fail
sudo apt -y install php php-cgi libapache2-mod-php php-common php-pear php-mbstring || func-pack-fail
sudo a2enconf php7.0-cgi
sudo systemctl restart apache2

echo -e "\n\n\n########## for CI-system: Installing packages for web-based monitoring"
sudo apt -y install procps htop || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing packages for modules"
sudo apt -y install grep debianutils || func-pack-fail
sudo apt -y install sed coreutils aha git || func-pack-fail
sudo apt -y install findutils cppcheck || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing packages for gcov/lcov"
sudo apt -y install lcov || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing clang-format"
echo -e "[DEBUG] You have to install clang-format-4.0 (official version) to check C++ formatting."
if [[ -f /etc/apt/sources.list.d/clang.list ]]; then
    sudo echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main" > /etc/apt/sources.list.d/clang.list
    sudo apt -y update
    sudo apt -y install clang-format-4.0 || func-pack-fail
fi

echo -e "\n\n\n########## for CI-system: Installing packages for doxygen book"
sudo apt -y install texlive-latex-base texlive-latex-extra || func-pack-fail
sudo apt -y install graphviz doxygen latex-xcolor || func-pack-fail
sudo apt -y install unoconv pdftk poppler-utils || func-pack-fail
sudo apt -y install libreoffice evince || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing packages for SLOCcount"
sudo apt -y install sloccount || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing packages for aspell"
sudo apt -y install aspell || func-pack-fail

echo -e "\n\n\n########## for CI-system: Installing packages for spellcheck"
sudo apt -y install spellcheck || func-pack-fail

echo -e "\n\n\n########## for CI-system: Setting-up a build environment of Tizen package (.rpm)"
if [[ ! -f /etc/apt/sources.list.d/tizen.list ]]; then
    sudo echo "deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ / " > /etc/apt/sources.list.d/tizen.list
    sudo apt -y update
    sudo apt -y install mic gbs || func-pack-fail
fi

echo -e "\n\n\n########## for CI-system: Setting-up a build environment of Ubuntu package (.deb)"
echo -e "[DEBUG] Note that you have to write ~/.pbuilderrc file"
sudo apt -y install pbuilder debootstrap devscripts || func-pack-fail


echo -e "\n\n\n########## for CI-system: Setting-up a build environment of Yocto package (.deb)"
echo -e "[DEBUG] Note that you have to install Extensible SDK (eSDK) directly"
sudo apt -y install gawk wget git-core diffstat unzip texinfo gcc-multilib || func-pack-fail
sudo apt -y install build-essential chrpath socat libsdl1.2-dev xterm || func-pack-fail

echo -e "\n\n\n########## Execution Result"
echo -e "[DEBUG] It's okay. All packages are successfully installed...."
echo -e "[DEBUG] Then, install the TAOS-CI software as a next step."


