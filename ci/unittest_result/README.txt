

 Gtest-based UnitTest Report
===============================

This section describes how to get the report file after running the unit-tests based on Gtest.
The below statements show how to run this auto-unittest script at specified time every day.
The auto-unittet.sch is written by the Tizen gbs and Google Gtest.
* https://source.tizen.org/documentation/reference/git-build-system/usage/gbs-build
* https://github.com/google/googletest

## Example
$ sudo vi /etc/crontab
30 7 * * * www-data /var/www/html/nnstreamer/ci/taos/auto-unittest.sh


## Repot
The result files are archived into the ./ci/unittest_result/ folder.
