#!/bin/bash

source .machines-config

function host_reachable {

  local HOST_IP=$1
  ping -c 1 -w 5 $HOST_IP 2>&1 >/dev/null ;

  if [[ $? -eq 0 ]]; then return 0; else return 1; fi
}


function is_active_vm {
  local VM_NUMBER=$1
  local VM_IP=${cfg_vm_ips[(${VM_NUMBER} - 1)]}

  host_reachable $VM_IP
  return $?
}

function is_active_dr {

  host_reachable $cfg_dr_ip
  return $?
}

function execute_in_vm {
  local VM_NUMBER=$1
  local SCRIPT=$2
  local VM_USER=$cfg_admin_user
  local VM_IP=${cfg_vm_ips[($VM_NUMBER - 1)]}

  local CMD="sshpass -p$cfg_admin_passwd ssh -n -f ${VM_USER}@$VM_IP $SCRIPT"
  echo "Executing $CMD"
  $CMD

  return $?
}

function execute_in_vm_sudo {

  execute_in_vm $1 "echo $cfg_admin_passwd | sudo -p \"\" -S $2"

  return $?
}

function fail_over_to {

  return 1
}


function fail_over_to_dr {

  return 1
}
