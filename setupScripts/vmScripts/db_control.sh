#/bin/bash

case $1 in
  stop )
    service mysql stop
  ;;
  start )
    service mysql start
  ;;
esac
