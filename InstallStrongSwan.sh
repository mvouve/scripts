#!/bin/bash
#script version of: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt update
apt-get -y install strongswan strongswan-plugin-eap-mschapv2 moreutils iptables-persistent
#Make key directory
mkdir vpn-certs
cd vpn-certs
#generate keys
echo "Generating Keys"
#Certificate Authority
ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem
chmod 600 server-root-key.pem
ipsec pki --self --ca --lifetime 3650 \
--in server-root-key.pem \
--type rsa --dn "C=CAN, O=$4, CN=$4 CA" \
--outform pem > server-root-ca.pem

# Private Key
ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem
ipsec pki --pub --in vpn-server-key.pem \
--type rsa | ipsec pki --issue --lifetime 1825 \
--cacert server-root-ca.pem \
--cakey server-root-key.pem \
--dn "C=CAN, O=$4, CN=$1" \
--san $1 \
--flag serverAuth --flag ikeIntermediate \
--outform pem > vpn-server-cert.pem
cp ./vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
cp ./vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem
chown root /etc/ipsec.d/private/vpn-server-key.pem
chgrp root /etc/ipsec.d/private/vpn-server-key.pem
chmod 600 /etc/ipsec.d/private/vpn-server-key.pem
cp /etc/ipsec.conf /etc/ipsec.conf.original


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
    ike=aes256-sha1-modp1024,3des-sha1-modp1024!
    esp=aes256-sha1,3des-sha1!
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
mv /etc/ipsec.secrets /etc/ipsec.secrets.original
cat <<EOT >> /etc/ipsec.secrets
$1 : RSA "/etc/ipsec.d/private/vpn-server-key.pem"
$2 %any% : EAP $3
EOT
ipsec reload
#IPTables
ufw disable
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -Z

# Don't close the SSH session!
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow all loopback connections
#iptables -A INPUT -i lo -j ACCEPT

# Allow IPSec connections
#iptables -A INPUT -p udp --dport  500 -j ACCEPT
#iptables -A INPUT -p udp --dport 4500 -j ACCEPT

# Forward ESP traffic
#iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.0/24 -j ACCEPT
#iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT


# Allow VPN to accept traffic from the internet on behalf of the Client
#iptables -t nat -A POSTROUTING -s $1 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
#iptables -t nat -A POSTROUTING -s $1 -o eth0 -j MASQUERADE
#iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

# for ISAKMP (handling of security associations)
iptables -A INPUT -p udp --dport 500 --j ACCEPT
# for NAT-T (handling of IPsec between natted devices)
iptables -A INPUT -p udp --dport 4500 --j ACCEPT
# for ESP payload (the encrypted data packets)
iptables -A INPUT -p esp -j ACCEPT
# for the routing of packets on the server
iptables -t nat -A POSTROUTING -j SNAT --to-source $1 -o eth0

# Drop everything else
#iptables -A INPUT -j DROP
#iptables -A FORWARD -j DROP
netfilter-persistent save
netfilter-persistent reload

# Edit Sysctl.conf
mv sysctl.conf sysctl.conf.orig
echo "net.ipv4.ip_forward = 1" |  tee /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" |  tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" |  tee -a /etc/sysctl.conf

echo "done"
