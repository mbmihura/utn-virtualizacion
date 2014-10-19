#!/bin/bash

# This script receives a host's IP and a path to a log files and continuously
# monitors the given host's status, writing it's status changes to the log file.
# Note, that if the provided log's path exist, the script will append the new 
# events.

HOST_IP=$1
LOG_FILE_PATH=$2
TIME=1

# Function to write to log using a fixed format.
log() {
	local MSG=$2
	echo "$(date "+%Y%m%d %T") $MSG" >> $LOG_FILE_PATH
}

# Handle signals
trap "echo; echo -e \"Stopping watchdog for host $HOST_IP (pid: $$)\"; exit" SIGHUP SIGINT SIGTERM

# Check if log file exist. If not, create a new file with current time and status 'Unknown'.
if [[ ! -f $LOG_FILE_PATH ]]; then
	log Unknown
fi

# Start infinite monitoring
while true; do
	#Hago un ping al host
	#chmod a+x check.sh $host
	#TODO bash checkHostStatus.sh $HOST_IP >/dev/null 2>&1
	ping -c 1 $HOST_IP > /dev/null #IMPROVE, Print to screen in errors.
	
	# Write current status to log file
	test $? -eq 0 && STATUS=OK || STATUS=NORESPONSE
	log $HOST_IP $STATUS
	sleep $TIME
done


