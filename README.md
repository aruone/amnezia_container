```shell
podman machine start
podman build --no-cache --platform linux/arm64 -t my-amnezia .
podman save --format docker-archive -o amnezia_mikrotik.tar localhost/my-amnezia
```


Load container into mikrotik (example):
/file add type=directory name=flash/awg_conf
/container/mounts/add src=flash/awg_conf/awg_mikrotik_client.conf dst=/etc/amnezia/awg0.conf list=awg0 read-only=yes
/file add type=directory name=flash/awg_root
/container add file=tmp1/amnezia_mikrotik.tar root-dir=flash/awg_root start-on-boot=yes interface=veth2 mountlists=awg0 shm-size=160MiB

Set routing
/routing table add name=awg fib
/ip route add dst-address=0.0.0.0/0 gateway=172.17.0.3 routing-table=awg
/ip firewall address-list
    add list=VPS address=<your vpn server>
/ip/firewall/mangle
    add chain=prerouting action=accept dst-address=192.168.88.0/24 
    add chain=prerouting action=accept dst-address-list=VPS log=no log-prefix="" 
    add chain=prerouting action=mark-routing new-routing-mark=awg passthrough=yes src-address=192.168.88.0/24 log=no log-prefix=""

/tool fetch url="https://antifilter.network/download/iprange.lst" mode=https output=none
/ip firewall address-list remove [find list=ru_direct]
:foreach i in=[:to-array [file get flash/ipv4-aggregated.txt contents]] do={
:if ([:len $i] > 0) do={ /ip firewall address-list add list=ru_direct address=$i }
}
