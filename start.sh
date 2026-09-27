#!/bin/bash
set -e

sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip link del awg0 2>/dev/null || true

if ! ip link add dev awg0 type amneziawg 2>/dev/null; then
    echo "Kernel module dynamic creation failed, starting amneziawg-go..."
    amneziawg-go awg0 >/dev/null 2>&1
fi

ip addr add 10.66.66.2/32 dev awg0
ip -6 addr add fd42:42:42::2/128 dev awg0 2>/dev/null || true
ip link set mtu 1360 up dev awg0

grep -vE '^(Address|MTU|DNS|PostUp|PostDown|PreUp|PreDown|Table)' /etc/amnezia/awg0.conf > /tmp/clean.conf
awg setconf awg0 /tmp/clean.conf

MAIN_IFACE=$(ip route | awk '/default/ {print $5}')
GATEWAY=$(ip route | awk '/default/ {print $3}')

ip route replace 192.168.0.0/16 via $GATEWAY dev $MAIN_IFACE 2>/dev/null || true
ip route replace 10.0.0.0/8 via $GATEWAY dev $MAIN_IFACE 2>/dev/null || true
ip route replace 172.16.0.0/12 via $GATEWAY dev $MAIN_IFACE 2>/dev/null || true

ip route replace 144.31.239.192 via $GATEWAY dev $MAIN_IFACE

ip route replace 0.0.0.0/1 dev awg0
ip route replace 128.0.0.0/1 dev awg0

iptables -t nat -A POSTROUTING -o awg0 -j MASQUERADE
iptables -A FORWARD -i $MAIN_IFACE -o awg0 -j ACCEPT
iptables -A FORWARD -i awg0 -o $MAIN_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "AmneziaWG status: UP on $MAIN_IFACE via $GATEWAY!"

if [ -d /post_scripts ]; then
    for script in $(find /post_scripts -type f); do
        echo "executing ${script}"
        bash ${script}
    done
fi

trap "ip link del awg0 2>/dev/null; exit 0" SIGTERM SIGINT
sleep infinity & wait
