#!/bin/bash

source utils.sh

if ! is_numeric $1; then
  echo "Invalid VM Number $1."
  echo "Usage: ./start-machine <vm-number>"
fi

VM_NUMBER=$1
VM_NAME=${cfg_vms[(${VM_NUMBER} - 1)]}



echo "Will now start VM $VM_NAME"

vboxmanage startvm $VM_NAME >> /dev/null

wait_until_running $VM_NUMBER
if [[ $? -ne 0 ]]; then
  echo "Aborting."
  exit;
fi
echo "Started!"

for possible_feature in $cfg_features
do
  if machine_should_run $VM_NUMBER $possible_feature && ! machine_runs $VM_NUMBER $possible_feature;
  then
    echo "Trying to fail-back $possible_feature to $VM_NAME."
    bring_in_feature $VM_NUMBER $possible_feature
    echo "Done."
  fi
done
