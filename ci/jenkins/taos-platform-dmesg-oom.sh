#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------
# @author Geunsik Lim <geunsik.lim@samsung.com>
# @brief Check if Linux system generates Out-of-Memory issue.
# -----------------------------------------------------------------------------------------


#--------- user configuraiton ---------------
#filter="^"
filter="Out of memory"

# email information
email_cmd="mailx"
email_recipient="geunsik.lim@samsung.com myungjoo.ham@samsung.com jijoon.moon@samsung.com sangjung.woo@samsung.com \
wook16.song@samsung.com jy1210.jung@samsung.com jinhyuck83.park@samsung.com hello.ahn@samsung.com \
sewon.oh@samsung.com kibeom.lee@samsung.com byoungo.kim@samsung.com "
email_subject="[aaci] Warning: Server starts using SWAP memory to avoid OOM."
email_message=" Hi,\n\n Ooops. The server starts using SWAP memory due to shortage of RAM space.\n\n $(free -h)\n\n For more details, visit https://github.sec.samsung.net/STAR/TAOS-Platform/issues/.\n\n $(date).\n from aaci.mooo.com.\n"

# send e-mail if a partitions is almost full.
function email_on_failure(){
    echo -e "$email_message" | $email_cmd -v -s  "$email_subject" $email_recipient
}

# run

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
    email_on_failure
    exit 4
else
    exit 0
fi
