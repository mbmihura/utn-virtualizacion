#!/bin/bash

source utils.sh

VM_NUMBER=$1
VM_NAME=${cfg_vms[(${VM_NUMBER} - 1)]}


if ! is_active_vm $VM_NUMBER;
then
  echo "VM $VM_NAME has been already powered off or is not reachable"
  exit
fi

echo "Now powering off machine $VM_NAME"


# Try to fail over to other VM
OTHER_VM=$(if [ $VM_NUMBER -eq 1 ]; then echo 2; else echo 1; fi)
if is_active_vm $OTHER_VM;
then
  fail_over_to $OTHER_VM
else
  fail_over_to_dr;
fi

execute_in_vm_sudo $VM_NUMBER poweroff
