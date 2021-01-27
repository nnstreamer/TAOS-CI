#!/usr/bin/env bash

# This is to create the taos-ci documents (https://taos-ci.github.io/).
# Our documentation uses hotdoc, you should usually refer to here: http://hotdoc.github.io/ .
# Run this script on the root path of the TAOS-CI.

echo "Generate TAOS-CI documents"

deps_file_path="$(pwd)/ci/doc/TAOS-CI.deps"

echo "TAOS-CI version: $v"
echo "Dependencies file path: $deps_file_path"

hotdoc run -i index.md -o ci/doc/TAOS-CI-doc --sitemap=ci/doc/hotdoc/sitemap.txt --deps-file-dest=$deps_file_path \
           --html-extra-theme=ci/doc/hotdoc/theme/extra --project-name=TAOS-CI --project-version=0.0.0
