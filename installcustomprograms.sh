#!/usr/bin/env bash

#Download server files
wget marcvouve.com/files/VPNBuddyServer.tar.gz
#untar Server files (
tar -zxvf VPNBuddyServer.tar.gz
apt install -y libpqxx-dev postgresql daemon
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres'"
nohup ./vpnbuddyapi
./VPNBuddyFilter