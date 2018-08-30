#!/usr/bin/env bash

##
# @file install-nnstreamer-packages.sh
# @brief This script is to install packages that are required to run nnstreamer modules.
#
# We assume that you use Ubuntu 16.04 x86_64 distribution.
# If you do not use Version 16.04, you have to modify /etc/apt/sources.list.d/nnstreamer.list file appropriately. 


echo -e "########## Installing base packages for Gstreamer"
sudo apt -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libglib2.0-dev
sudo apt -y install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good

echo -e "########## Installing base packages to test nnstreamer apps"
sudo apt -y install rpmlint ctags sudo
sudo apt -y install cmake make

sudo apt -y install python-gi python3-gi
sudo apt -y install python-gst-1.0 python3-gst-1.0
sudo apt -y install python-gst-1.0-dbg python3-gst-1.0-dbg

echo -e "########## Setting-up tensorflow build environment"
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:nnstreamer/ppa
sudo apt -y update
sudo apt -y install tensorflow-dev tensorflow-lite-dev

echo -e "[DEBUG] Completed...."

