#!/bin/bash

if [[ -z "$1" ]]; then
	TIME=5
	echo "Using default time interval 5 seconds."
else
	TIME=$1
fi

setsid ./iyv-watchdog.sh -h iyv01 -l logs/iyv01.log -t $TIME >/dev/null 2>&1 < /dev/null &
setsid ./iyv-watchdog.sh -h iyv02 -l logs/iyv02.log -t $TIME >/dev/null 2>&1 < /dev/null &
setsid ./iyv-watchdog.sh -h iyvdr -l logs/iyvdr.log -t $TIME >/dev/null 2>&1 < /dev/null &
setsid ./iyv-watchdog.sh -l logs/db-iyv.log -s db -t $TIME >/dev/null 2>&1 < /dev/null &
setsid ./iyv-watchdog.sh -l logs/app-iyv.log -s app -t $TIME >/dev/null 2>&1 < /dev/null &
