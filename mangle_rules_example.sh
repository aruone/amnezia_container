/ip firewall mangle
add chain=prerouting protocol=udp port=25896,6969,6881-6889 action=accept comment="Torrents DIRECT (UDP)"
add chain=prerouting protocol=tcp port=25896,6969,6881-6889 action=accept comment="Torrents DIRECT (TCP)"
add chain=prerouting action=accept dst-address-list=DIRECT_TRAFFIC log=no log-prefix=""
add chain=prerouting dst-address-list=cloudflare action=mark-routing new-routing-mark=awg passthrough=yes comment="CLOUDFLARE TO AWG"
/ip firewall address-list
remove [find list="cloudflare"]
remove [find list="DIRECT_TRAFFIC"]
add list=cloudflare address=173.245.48.0/20
add list=cloudflare address=103.21.244.0/22
add list=cloudflare address=103.22.200.0/22
add list=cloudflare address=103.31.4.0/22
add list=cloudflare address=141.101.64.0/18
add list=cloudflare address=108.162.192.0/18
add list=cloudflare address=190.93.240.0/20
add list=cloudflare address=188.114.96.0/20
add list=cloudflare address=197.234.240.0/22
add list=cloudflare address=198.41.128.0/17
add list=cloudflare address=162.158.0.0/15
add list=cloudflare address=104.16.0.0/12
add list=cloudflare address=172.64.0.0/13
add list=cloudflare address=131.0.72.0/22
add list=cloudflare address=140.248.64.0/18
add list=DIRECT_TRAFFIC address=playstation.net
add list=DIRECT_TRAFFIC address=steamcommunity.com
add list=DIRECT_TRAFFIC address=capcomfighters.net