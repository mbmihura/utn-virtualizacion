#/bin/bash

if [[ `netstat -tap | grep mysql | wc -l` -lt 1 ]]
  then echo "MySQL is running."
  else exit "MySQL is NOT running."
fi
