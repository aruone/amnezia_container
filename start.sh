#!/bin/bash

mkdir -p /etc/amnezia
awg-quick up /etc/amnezia/awg0.conf
trap "awg-quick down /etc/amnezia/awg0.conf; exit 0" SIGTERM SIGINT
sleep infinity & wait
