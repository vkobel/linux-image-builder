#!/bin/sh
set -x

echo $tapname > /tmp/qlog
tapname=${1}
iface=wlp2s0
if [ -n "$tapname" ]; then
    ip tuntap add $tapname mode tap
    ip addr add 172.16.0.1/24 dev $tapname
    ip link set $tapname up
    iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i $tapname -o $iface -j ACCEPT
    exit 0
else
    echo "Error: no interface specified"
    exit 1
fi
