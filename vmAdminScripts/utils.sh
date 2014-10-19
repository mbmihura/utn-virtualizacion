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

function is_ready_vm {

  local VM_NUMBER=$1
  local VM_IP=${cfg_vm_ips[(${VM_NUMBER} - 1)]}

  nc -z $VM_IP 22 >> /dev/null
  return $?
}

function is_active_dr {

  is_active_vm 3
  return $?
}

function wait_until_running {

    local VM_NUMBER=$1
    local LOOP_COUNTER=1


    while ! is_ready_vm $VM_NUMBER;do

      LOOP_COUNTER=$loop_counter+1
      if [[ $LOOP_COUNTER -gt 20 ]]; then
        echo "Machine $VM_NUMBER would not start."
        return 1
      fi
      printf "."
      sleep 5

    done

    return $?

}

function execute_in_vm {
  local VM_NUMBER=$1
  local SCRIPT=$2
  local VM_USER=$cfg_admin_user
  local VM_IP=${cfg_vm_ips[($VM_NUMBER - 1)]}

  local CMD="ssh -n ${VM_USER}@$VM_IP $SCRIPT >> /dev/null 2> /dev/null"
#  echo "Executing $CMD"
  $CMD >> /dev/null

  return $?
}

function execute_in_vm_sudo {

  execute_in_vm $1 "sudo $2"

  return $?
}

function machine_runs {

  local MACHINE=$1
  local FEATURE=$2
  local FILE=$3

  if [[ -n $FILE ]];then
      DIPOSITION_FILE=$FILE;
  else
      DIPOSITION_FILE=$cfg_disposition_file;
  fi

  cat $DIPOSITION_FILE | grep $MACHINE | grep $FEATURE >> /dev/null
  return $?
}

function prepare_db_for_app {

  local APP_TO_PREPARE=$1

  where_is_feature db
  local VM_WITH_DB=$?
  local VM_WITH_APP_SUFFIX=${cfg_vm_suffixes[($APP_TO_PREPARE - 1)]}
  execute_in_vm_sudo $VM_WITH_DB "mysql -u root -pqwerty123 -e \"update wordpress.wp_options set option_value='http://iyv$VM_WITH_APP_SUFFIX/wordpress' where option_name in ('siteurl', 'home')\""

}

function start_feature {

  local VM_NUMBER=$1
  local FEATURE=$2

  if [[ $FEATURE == "db" ]]; then
    local SERVICE=mysql;
  else
    local SERVICE=apache2;
    prepare_db_for_app $VM_NUMBER
  fi

  execute_in_vm_sudo $VM_NUMBER "service $SERVICE start"

}

function machine_should_run {

    local MACHINE=$1
    local FEATURE=$2
    local DR_MACHINE_NUMBER=3

    if machine_runs $MACHINE $FEATURE $cfg_orig_disposition_file; then
      return 0;
    fi

    if machine_runs $DR_MACHINE_NUMBER $FEATURE; then
      return 0;
    fi

    return 1
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

function where_is_feature {

    local FEATURE=$1

    local VM_NUMBER=$(awk "/${FEATURE}/{ print NR; exit }" $cfg_disposition_file)
    return $VM_NUMBER

}

function move_app {

  local APP_FROM=$1
  local APP_TO=$2

  execute_in_vm_sudo $APP_FROM "service apache2 stop"

  prepare_db_for_app $APP_TO

  execute_in_vm_sudo $APP_TO "service apache2 start"
  return 0
}

function remove_feature_from_disposition {

  local MACHINE_FROM=$1
  local FEATURE=$2

  local NEW_DISPOSITION=vm$MACHINE_FROM

  for possible_feature in ${cfg_features[@]}
  do
    if [[ $possible_feature == $FEATURE ]] || ! machine_runs $MACHINE_FROM $possible_feature;
    then
      NEW_DISPOSITION="$NEW_DISPOSITION -"
    else
      NEW_DISPOSITION="$NEW_DISPOSITION $possible_feature"
    fi
  done

  sed -i "/vm$MACHINE_FROM/c\\$NEW_DISPOSITION" $cfg_disposition_file

}

function add_feature_from_disposition {

  local MACHINE_FROM=$1
  local FEATURE=$2

  local NEW_DISPOSITION=vm$MACHINE_FROM

  for possible_feature in ${cfg_features[@]}
  do
    if machine_runs $MACHINE_FROM $possible_feature || [[ $possible_feature == $FEATURE ]];
    then
      NEW_DISPOSITION="$NEW_DISPOSITION $possible_feature"
    else
      NEW_DISPOSITION="$NEW_DISPOSITION -"
    fi
  done

  sed -i "/vm$MACHINE_FROM/c\\$NEW_DISPOSITION" $cfg_disposition_file

}



function set_hosts_resolution {

  local FEATURE=$1
  local FEATURE_TO=$2
  local FEATURE_TO_IP=${cfg_vm_ip_numbers[(${FEATURE_TO} - 1)]}

  for vm_number in 1 2; do
    execute_in_vm_sudo $vm_number "sed -i \"/${cfg_host_svc_prefix}$FEATURE/c\\$FEATURE_TO_IP\t${cfg_host_svc_prefix}$FEATURE\" /etc/hosts"
  done
}

function set_hosts_resolution_all_features {

  local VM_NUMBER=$1

  for possible_feature in ${cfg_features[@]};
  do
    where_is_feature $possible_feature
    local VM_NUMBER_CURR_FEATURE=$?
    local VM_IP_CURR_FEATURE=${cfg_vm_ip_numbers[(${VM_NUMBER_CURR_FEATURE} - 1)]}

    execute_in_vm_sudo $VM_NUMBER "sed -i \"/${cfg_host_svc_prefix}$possible_feature/c\\$VM_IP_CURR_FEATURE\t${cfg_host_svc_prefix}$possible_feature\" /etc/hosts"
  done

}

function move_feature {

  local FEATURE_FROM=$1
  local FEATURE_TO=$2
  local FEATURE=$3
  local FEATURE_TO_IP=${cfg_vm_ip_numbers[(${FEATURE_TO} - 1)]}


# Call function to move feature from one machine to another dynamically.
  eval "move_$FEATURE $FEATURE_FROM $FEATURE_TO"

# Reflect changes in features tracking file
  remove_feature_from_disposition $FEATURE_FROM $FEATURE
  add_feature_from_disposition $FEATURE_TO $FEATURE

# Alter /etc/hosts file to that db and app can comunicate transparently
  set_hosts_resolution $FEATURE $FEATURE_TO

}

function bring_in_feature {

    local MY_VM=$1
    local FEATURE=$2

    where_is_feature $FEATURE
    local VM_WITH_FEATURE=$?

    if [[ $MY_VM -ne  $VM_WITH_FEATURE ]]; then
        move_feature $VM_WITH_FEATURE $MY_VM $FEATURE;
    fi

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

  local VM_FROM=$1

  echo "Starting DR"
  bash start-machine.sh 3 >> /dev/null
  echo "Started!"

  echo "Now moving feature db to DR."
  move_feature $VM_FROM 3 db;
  echo "Moved!"
  echo "Now moving feature app to DR."
  move_feature $VM_FROM 3 app;
  echo "Moved!"
  echo "Updating hosts resolution file."
  set_hosts_resolution_all_features 3

}

function stop_vm {

  local VM_NUMBER=$1

  execute_in_vm_sudo $VM_NUMBER "poweroff"

}
