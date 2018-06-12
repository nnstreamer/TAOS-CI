#!/usr/bin/env bash

##
# @file config-plugins-format.sh
# @brief add plugin modules for a github repository
#

##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.

echo "[MODULE] CI/pr-format-clang: Check the code formatting style with clang-format"
echo "Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-clang.sh
pr-format-clang

echo "[MODULE] CI/pr-format-exclusive-vio: Check issue #279. VIO commits should not touch non VIO files."
echo "Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-good/pr-format-exclusive-vio.sh
pr-format-exclusive-vio


##################################################################################################################
echo "[MODULE] plugins-ugly: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

