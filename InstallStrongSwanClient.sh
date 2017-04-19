#!/bin/bash

mv /etc/ipsec.conf /etc/ipsec.conf.original
cat <<EOT >> /etc/ipsec.conf
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn %default
    auto=add

    # key and renewal settings 
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1    
    keyexchange=ikev2

    # various keepalive settings
    dpdaction=clear
    dpddelay=300s

	rightcert=/etc/ipsec.d/certs/vpn-server-cert.pem
	right=$1
	rightsubnet=10.10.10.0/24
EOT

mv /etc/ipsec.secrets /etc/ipsec.secrets.original
cat <<EOT >> /etc/ipsec.secrets
$2 %any% : EAP $3
EOT

ipsec reload