#!/bin/bash

source .machines-config

VM_NUMBER=$1
VM_NAME=${cfg_vms[(${VM_NUMBER} - 1)]}

echo "Will start VM $VM_NAME"
CMD="vboxmanage startvm $VM_NAME"
echo $CMD
$CMD
echo "TODO: Failback here"
