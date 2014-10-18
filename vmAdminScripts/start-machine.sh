#!/bin/bash

source utils.sh

if ! is_numeric $1; then
  echo "Invalid VM Number $1."
  echo "Usage: ./start-machine <vm-number>"
fi

VM_NUMBER=$1
VM_NAME=${cfg_vms[(${VM_NUMBER} - 1)]}

echo "Will now start VM $VM_NAME"

vboxmanage startvm $VM_NAME
echo "TODO: Failback here"
