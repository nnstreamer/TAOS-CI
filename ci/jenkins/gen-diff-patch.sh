#!/bin/bash
DIFF_COMMITS=`git log --graph --oneline origin/dev_algo..HEAD | wc -l`
git format-patch -$DIFF_COMMITS
