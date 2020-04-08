#!/bin/sh
set -x

tapname=${1}
iface=wlp2s0

if [ -n "$tapname" ]; then
    ip link del dev $tapname
    iptables -t nat -D POSTROUTING -o $iface -j MASQUERADE
    iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -D FORWARD -i $tapname -o $iface -j ACCEPT
    exit 0
else
    echo "Error: no interface specified"
    exit 1
fi
