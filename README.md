```shell
podman machine start
podman build --no-cache --platform linux/arm64 -t my-amnezia .
podman save --format docker-archive -o amnezia_mikrotik.tar localhost/my-amnezia
```

Load container into mikrotik (example):
/file add type=directory name=flash/awg_root
/container add file=tmp1/amnezia_mikrotik.tar root-dir=flash/awg_root start-on-boot=yes interface=veth1 mountlists=awg0 shm-size=128MiB

Set routing
/routing table add name=awg fib
/ip route add dst-address=0.0.0.0/0 gateway=172.17.0.2 routing-table=awg
/ip firewall mangle add chain=prerouting src-address=192.168.88.0/24 dst-address=!192.168.88.0/24 action=mark-routing new-routing-mark=awg passthrough=yes comment="AWG GLOBAL SWITCH"