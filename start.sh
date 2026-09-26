#!/bin/bash

ip link del awg0 2>/dev/null

amneziawg-go awg0

ip addr add 10.66.66.2/32 dev awg0
ip -6 addr add fd42:42:42::2/128 dev awg0 2>/dev/null
ip link set mtu 1360 up dev awg0

grep -vE '^(Address|MTU|DNS|PostUp|PostDown|PreUp|PreDown|Table)' /etc/amnezia/awg0.conf > /tmp/clean.conf
awg setconf awg0 /tmp/clean.conf

ip route replace 144.31.239.192 via 172.17.0.1
ip route replace 0.0.0.0/1 dev awg0
ip route replace 128.0.0.0/1 dev awg0

iptables -t nat -A POSTROUTING -o awg0 -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "start.sh script finished"