#!/bin/bash

set -e
MYSQL_PWD=qwerty123
ADMIN_USER=admin
ADMIN_PWD=admin
HOSTNAME_BASE=iyv
GUEST_IP_BASE=192.168.11.20

VM_ID=$1


if [[ VM_ID -eq "" ]]; then
    echo "Usage: ./guest-setup <VM_ID>"
    exit
fi


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

echo "Creating shared folder"
mkdir /home/$ADMIN_USER/shared

echo "Configuring network"

echo "#iface eth0 inet static" >> /etc/network/interfaces
echo "# address 192.168.10.X" >> /etc/network/interfaces
echo "# netmask 255.255.255.0" >> /etc/network/interfaces
echo "# broadcast 192.168.11.255" >> /etc/network/interfaces
echo "# network 192.168.11.0" >> /etc/network/interfaces
echo "# gateway 192.168.11.1" >> /etc/network/interfaces
echo "# dns-nameservers 192.168.11.1" >> /etc/network/interfaces
echo "# dns-search cpe.telecentro.com" >> /etc/network/interfaces
#resolvconf -u
sed '/awk/d' mi_fichero.txt
echo "${GUEST_IP_BASE}1 ${HOSTNAME_BASE}01" >> /etc/hosts
echo "${GUEST_IP_BASE}2 ${HOSTNAME_BASE}02" >> /etc/hosts
echo "${GUEST_IP_BASE}3 ${HOSTNAME_BASE}dr" >> /etc/hosts

echo "${GUEST_IP_BASE}1 ${HOSTNAME_BASE}-svc-db" >> /etc/hosts
echo "${GUEST_IP_BASE}2 ${HOSTNAME_BASE}-svc-app" >> /etc/hosts

echo "Network done. Please manually configure "IP Address, netmask, etc. at /etc/network/interfaces"
