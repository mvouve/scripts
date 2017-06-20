#!/usr/bin/env bash

#Download server files
wget marcvouve.com/files/filter-api.tar.gz
#untar Server files (
tar -zxvf filter-api.tar.gz
apt install -y libpqxx-dev postgresql daemon
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres'"
./VPNBuddyFilter
nohup ./vpnbuddyapi &
