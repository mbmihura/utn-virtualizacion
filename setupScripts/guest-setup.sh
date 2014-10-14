#!/bin/bash

set -e
MYSQL_PWD=qwerty123
ADMIN_USER=admin
ADMIN_PWD=admin

echo "Installing base packages"
apt-get install -y openssl openssh-server curl git htop mcrypt whois sshpass
apt-get update
apt-get install -y dkms build-essential linux-headers-generic linux-headers-$(uname -r)
restart ssh

echo "Creating admin user"
useradd $ADMIN_USER -d /home/admin -m -p $(mkpasswd $ADMIN_PWD)
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "Installing DB Engine"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PWD"
apt-get install -y mysql-server
[[ `netstat -tap | grep mysql | wc -l` -lt 1 ]] && echo "DB Installation Failed" || echo "DB Installation succeeded. Root password is: $MYSQL_PWD" && exit 1
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$MYSQL_PWD' WITH GRANT OPTION;"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO root@'localhost' IDENTIFIED BY '$MYSQL_PWD' WITH GRANT OPTION; flush privileges;"
