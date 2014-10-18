source .machines-config

function is_numeric {

  re='^[0-9]+$'
  if [[ $1 =~ $re ]] ; then
    return 0
  else
    return 1
  fi
}

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

  is_active_vm 3
  return $?
}

function execute_in_vm {
  local VM_NUMBER=$1
  local SCRIPT=$2
  local VM_USER=$cfg_admin_user
  local VM_IP=${cfg_vm_ips[($VM_NUMBER - 1)]}

  local CMD="ssh -n ${VM_USER}@$VM_IP $SCRIPT"
  echo "Executing $CMD"
  $CMD

  return $?
}

function execute_in_vm_sudo {

  execute_in_vm $1 "sudo $2"

  return $?
}

function machine_runs {

  local MACHINE=$1
  local FEATURE=$2

  cat $cfg_disposition_file | grep $MACHINE | grep $FEATURE

  return $?
}


function move_db {

  local DB_FROM=$1
  local DB_TO=$2

  local IP_FROM=${cfg_vm_ips[($DB_FROM - 1)]}
  local IP_TO=${cfg_vm_ips[($DB_TO - 1)]}

  execute_in_vm_sudo $DB_FROM "service mysql stop"
  execute_in_vm_sudo $DB_TO "service mysql stop"
  execute_in_vm_sudo $DB_TO "rm -rf /var/lib/mysql/*; rm -rf share/*"
  execute_in_vm_sudo $DB_FROM "scp -r -i .ssh/id_dsa /var/lib/mysql admin@$IP_TO:share/"
  execute_in_vm_sudo $DB_TO "cp -r share/mysql/. /var/lib/mysql"
  execute_in_vm_sudo $DB_TO "chown -R mysql:mysql /var/lib/mysql"
  execute_in_vm_sudo $DB_TO "service mysql start"

}

function move_app {

  local DB_FROM=$1
  local DB_TO=$2

  echo 'Stop web app in machine $DB_FROM'
  #execute_in_vm_sudo $DB_FROM "apagar la app"

  return 0
}

function remove_feature_from_disposition {

  local MACHINE_FROM=$1
  local FEATURE=$2

  local NEW_DISPOSITION=vm$MACHINE_FROM

  for possible_feature in $cfg_features
  do
    if machine_runs $MACHINE_FROM $possible_feature && [[ $possible_feature -ne $FEATURE ]]
    then
      NEW_DISPOSITION="$NEW_DISPOSITION $possible_feature"
    else
      NEW_DISPOSITION="$NEW_DISPOSITION -"
    fi
  done

  sed -i "/vm$MACHINE_FROM/c\\$NEW_DISPOSITION" $cfg_disposition_file

}

function add_feature_from_disposition {

  local MACHINE_FROM=$1
  local FEATURE=$2

  local NEW_DISPOSITION=vm$MACHINE_FROM

  for possible_feature in $cfg_features
  do
    if machine_runs $MACHINE_FROM $possible_feature || [[ $possible_feature -eq $FEATURE ]]
    then
      NEW_DISPOSITION="$NEW_DISPOSITION $possible_feature"
    else
      NEW_DISPOSITION="$NEW_DISPOSITION -"
    fi
  done

  sed -i "/vm$MACHINE_FROM/c\\$NEW_DISPOSITION" $cfg_disposition_file

}

function move_feature {

  local FEATURE_FROM=$1
  local FEATURE_TO=$2
  local FEATURE=$3

# Call function to move feature from one machine to another dynamically.
  eval "move_$FEATURE $FEATURE_FROM $FEATURE_TO"

# Reflect changes in features tracking file
  remove_feature_from_disposition $FEATURE_FROM $FEATURE
  add_feature_from_disposition $FEATURE_TO $FEATURE

}

function fail_over_to {

  local VM_TO=$1
  local VM_FROM=$2

  if machine_runs $VM_FROM db; then
    move_feature $VM_FROM $VM_TO db;
  fi

  if machine_runs $VM_FROM app; then
    move_feature $VM_FROM $VM_TO app;
  fi

  return 1
}

function fail_over_to_dr {

   return 1
}
