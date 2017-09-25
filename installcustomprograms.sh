#!/usr/bin/env bash

#Download server files
wget marcvouve.com/files/filter-api.tar.gz
#untar Server files (
tar -zxvf filter-api.tar.gz
apt install -y libpqxx-dev postgresql daemon
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres'"
systemctl enable postgresql
systemctl start postgresql

mv vpnbuddyapi /usr/sbin/vpnbuddyapi
mv VPNBuddyFilter /usr/sbin/VPNBuddyFilter
mv geoip /usr/sbin/geoip/
mv vpnbuddy /etc/init.d/vpnbuddy

systemctl enable vpnbuddy
systemctl start vpnbuddy

# Finish dropping everything from the firewall and save.
iptables -P INPUT DROP
iptables -P OUTPUT DROP
netfilter-persistent save
netfilter-persistent reload
