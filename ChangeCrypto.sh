#!/bin/bash
#Configure StrongSwan
mv /etc/ipsec.conf /etc/ipsec.conf.original
cat <<EOT >> /etc/ipsec.conf
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    ike=$1-sha1-modp1024,3des-sha1-modp1024!
    esp=$1-sha1,3des-sha1!
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$1
    leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightdns=8.8.8.8,8.8.4.4
    rightsourceip=10.10.10.0/24
    rightsendcert=never
    eap_identity=%identity 
EOT
ipsec reload