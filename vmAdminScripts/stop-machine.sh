#!/bin/bash

source .machines-config

VM_NUMBER=$1
VM_NAME=${cfg_vms[(${VM_NUMBER} - 1)]}
VM_IP=${cfg_vm_ips[(${VM_NUMBER} - 1)]}
POWEROFF_SCRIPT="echo $cfg_admin_passwd | sudo -S poweroff"
VM_USER=$cfg_admin_user

echo "Now powering off machine $VM_NAME"

CMD="sshpass -p$cfg_admin_passwd ssh -n -f ${VM_USER}@$VM_IP $POWEROFF_SCRIPT"
echo $CMD

$CMD
