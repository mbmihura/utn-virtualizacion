#!/bin/bash

source utils.sh

if ! is_numeric $1; then
  echo "Invalid VM Number $1.";
  echo "Usage: ./stop-machine <vm-number>";
fi


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
  echo "Trying to fail-over to $VM_NAME"
  fail_over_to $OTHER_VM $VM_NUMBER
else
  fail_over_to_dr $VM_NUMBER;
fi

execute_in_vm_sudo $VM_NUMBER poweroff
echo "Stopped!"
