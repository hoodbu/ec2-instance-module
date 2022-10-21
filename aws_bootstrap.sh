#!/bin/bash
sudo hostnamectl set-hostname ${name}
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo echo ubuntu:${password} | /usr/sbin/chpasswd
sudo apt update -y
sudo apt upgrade -y
sudo apt-get -y install traceroute unzip build-essential git gcc hping3 apache2 net-tools
sudo apt autoremove

sudo /etc/init.d/ssh restart
sudo echo "<html><h1>Prosimo is awesome</h1></html>" > /var/www/html/index.html 

git clone https://github.com/Microsoft/ntttcp-for-linux
cd ntttcp-for-linux/src
make; make install
cp ntttcp /usr/local/bin/

wget https://github.com/microsoft/ethr/releases/latest/download/ethr_linux.zip
unzip ethr_linux.zip -d /home/ubuntu/