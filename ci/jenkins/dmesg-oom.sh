#!/usr/bin/env bash
#--------- user configuraiton ---------------
#filter="^"
filter="Out of memory"

#--------- do not modify from this line -----
data=`dmesg | tail -n 200`
error_num=`echo -n "$data" | grep -c "$filter" `
echo -e "---------------"
echo -e "1. filtering message: \"$filter\" "
echo -e "2. Report webaddress: https://github.sec.samsung.net/ "
echo -e "3. The number of errors: $error_num"
echo -e "4. dmesg data:"
echo -e "  . . . Omission . . . "
echo -e "$data"
echo -e "---------------"

if [[ $error_num -gt 0 ]]; then
    exit 4
else
    exit 0
fi


