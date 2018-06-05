#!/bin/bash
grep "Signed-off-by" .pr-body
exit $?
