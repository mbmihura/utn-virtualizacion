#!/bin/bash

server=$1
user=$2
keyPath=$3

echo $server $user $keyPath

# Valiate params:
if [ -z "$server" ] || [ -z "$user" ] || [ -z "$keyPath" ] # TODO use getopts?
then
	echo "usage 'connectToNode -server -user -path_to_KeyFile'"
	return 0
fi

# Connect to node:
ssh $user@$server

# TODO use asymetric keys auth.