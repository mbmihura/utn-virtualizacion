#!/bin/bash

set -e
MYSQL_PWD=qwerty123

echo "Installing base packages"
apt-get install -y openssl openssh-server curl git htop
restart ssh

echo "Cloning GIT repository"
git clone https://github.com/mbmihura/utn-virtualizacion

echo "Installing DB Engine"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PWD"
apt-get install -y mysql-server
[[ `netstat -tap | grep mysql | wc -l` -lt 1 ]] && echo "DB Installation Failed" || echo "DB Installation succeeded. Root password is: $MYSQL_PWD"

