#!/usr/bin/env bash

##
# @file config-plugins-audit.sh
# @brief add plugin modules for a github repository
#

##################################################################################################################
echo "[MODULE] plugins-good: Plugin group that follow Apache license with good quality"
# Please append your plugin modules here.


##################################################################################################################
echo "[MODULE] plugins-ugly: Plugin group that does not have evaluation and aging test enough"
# Please append your plugin modules here.

echo "[DEBUG] pr-audit-resource is starting."
echo "[MODULE] CI/pr-audit-resource: Check if there are not-installed resource files."
echo "Current path: $(pwd)."
source ${REFERENCE_REPOSITORY}/ci/standalone/plugins-ugly/pr-audit-resource.sh
pr-audit-resource
echo "[DEBUG] pr-audit-resource is done."

