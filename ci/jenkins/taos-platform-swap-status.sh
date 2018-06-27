#!/usr/bin/env bash

SwapTotal=`awk '/SwapTotal:/ { print $2}' /proc/meminfo`
SwapFree=`awk '/SwapFree:/ { print $2}' /proc/meminfo`

echo -e "SwapTotal is $SwapTotal. SwapFree is $SwapFree"

if [[ $SwapFree -lt $SwapTotal ]]; then
    data="Ooops. Linux kernel starts using SWAP space due to avoid Out-of-Memory(OOM)"
    echo $data
    free -h
    subject="[$JOB_NAME] $BUILD_DISPLAY_NAME:  Linux kernel starts using SWAP memory."
    message=`echo $data`
    message+=`echo -e "\n \n \n \n"`
    message+=`free -h`
    message+=`echo -e "\n \n \n------------------------------------------- \n \n \n"`
    message+=`cat /proc/meminfo`
    message+=`top -b -n 1  -o VIRT`
    echo "$subject"
    echo "$message"
    echo "$message" | mail -s "$subject" geunsik.lim@samsung.com
    exit 4
else
    data="Good. Linux kernel is not using SWAP space."
    echo $data
    exit 0

fi
