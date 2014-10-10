#!/bin/bash

# Execute once after creating the VM that will be used as VM1, VM2 y DR
# Requires open ssh server to be installed in host (use: sudo apt-get install openssh-server)
# Add keys
HOST=10.0.0.129
ADMIN_USER=usera

ssh-keygen -t dsa
ssh-copy-id $ADMIN_USER@$HOST

#connecto to host to test ssh
ssh $ADMIN_USER@$HOST

