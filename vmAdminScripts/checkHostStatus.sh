#!/bin/bash

host=$1

if [ -z "$host" ]
then
	>&2 echo usage: checkIpStatus [-ip ]
	exit 1
fi

n=$(ping -c 1 $host 1>&1)
# TODO improve this
case $? in
	0) echo host is alive.;;
	1) echo No reply.;;
	#2) echo $OTHER_ERROR;;
esac