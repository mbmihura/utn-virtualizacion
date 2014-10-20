#!/bin/bash

source utils.sh

# This script receives a host's IP and a path to a log files and continuously
# monitors the given host's status, writing it's status changes to the log file.
# Note, that if the provided log's path exist, the script will append the new
# events.

LOG_FILE_PATH=logs/default.log
TIME=1
WATCHDOG_METHOD=watch_host
hflag=false
VERBOSE=false

usage() { printf "Usage: $0 -h <hostname>\n\t [-s <db|app>] <<if you want to monitor a feature>>\n\t [-l <log-file-path>] <<You totally should specify a file>>\n\t [-t <time-interval>] <<Allows to control the frequence of monitoring>>\n\t [-v] <<Only if you want to see how the monitoring is done>>\n" 1>&2; exit 1; }

while getopts ":h:s:l:t:v" o; do
    case "${o}" in
        h)
					HOST_IP=${OPTARG};hflag=true
					;;
				s)
					SERVICE=${OPTARG}
					WATCHDOG_METHOD=watch_service
					;;
				l)
					LOG_FILE_PATH=${OPTARG}
					;;
				t)
					TIME=${OPTARG}
					;;
				v)
					VERBOSE=true
					;;
        *)
          usage
          ;;
    esac
done
shift $((OPTIND-1))

# Flag "h" (hostname) is mandatory when not wathing a service!
if [[ $WATCHDOG_METHOD == watch_host ]] && ! $hflag; then
	echo "Specify the host to watch (-h <host>)."
  usage
fi

# Function to write to log using a fixed format.
log() {
	local MSG=$2
	if $VERBOSE; then local VERVOSE_MSG=" | CMD:[$3]"; else local VERVOSE_MSG="";fi

	echo "$(date "+%Y%m%d %T") ${MSG}${VERVOSE_MSG}" >> $LOG_FILE_PATH
}

log_start() {

	if [[ ! -z $SERVICE ]]; then
		LOG_FOR=$SERVICE
    HOST_TXT="HOST:(varies)"
	else
		LOG_FOR=machine
    HOST_TXT="HOST:$HOST_IP"
	fi

	echo "<<<[PID:$$] LOG SESSION START AT $(date "+%Y%m%d %T"). $HOST_TXT. SERVICE:$LOG_FOR.>>>" >> $LOG_FILE_PATH
}

# Hosts monitor
watch_host() {

	ping -c 1 -w 3 $HOST_IP > /dev/null #IMPROVE, Print to screen in errors.

	# Write current status to log file
	test $? -eq 0 && STATUS=OK || STATUS=NORESPONSE
	log $HOST_IP $STATUS "ping -c 1 -w 5 $HOST_IP"
	sleep $TIME

	return 0

}

# Features monitor (like db/app)
watch_service() {

	where_is_feature $SERVICE
	local VM_NUMBER=$?
	local VM_IP=${cfg_vm_ips[(${VM_NUMBER} - 1)]}
	if [[ $SERVICE == db ]]; then local SVC_PORT=mysql; else local SVC_PORT=http;fi

	nc -vz -w 3 $VM_IP $SVC_PORT >> /dev/null 2> /dev/null

	test $? -eq 0 && STATUS=OK || STATUS=NORESPONSE
	log $VM_IP $STATUS "nc -vz $VM_IP $SVC_PORT"
	sleep $TIME

	return 0

}

# Handle signals
trap "echo; echo -e \"Stopping watchdog for host $HOST_IP (pid: $$)\"; exit" SIGHUP SIGINT SIGTERM

# Check if log file exist. If not, create a new file with current time and status 'Unknown'.
if [[ ! -f $LOG_FILE_PATH ]]; then
	log Unknown
fi

log_start

# Start infinite monitoring
while true; do

	eval $WATCHDOG_METHOD

done
