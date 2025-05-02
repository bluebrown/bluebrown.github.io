$ ip netns exec vlan10 ip link set lo up
$ ip netns exec vlan10 ip route add default dev veth10

brdige is showing this

$ bridge vlan show
port              vlan-id
veth10-br         1 PVID Egress Untagged
br0               1 PVID Egress Untagged
veth20-br         1 PVID Egress Untagged

all untagged should be good. full bridge mode.

inm host ns all links are up 

$ ip -br link
veth10-br@if7    UP             8e:37:3c:8c:59:6c <BROADCAST,MULTICAST,UP,LOWER_UP>
br0              UP             02:db:03:ed:2d:eb <BROADCAST,MULTICAST,UP,LOWER_UP>
veth20-br@if12   UP             26:ac:21:42:7e:b5 <BROADCAST,MULTICAST,UP,LOWER_UP>

in the netns as well

$ ip netns exec vlan10 ip -br link
veth10@if6       UP             fe:82:b9:a9:2a:83 <BROADCAST,MULTICAST,UP,LOWER_UP>

$ ip netns exec vlan20 ip -br link
veth20@if11      UP             16:bc:f1:c0:81:c0 <BROADCAST,MULTICAST,UP,LOWER_UP>

$ ip netns exec vlan10 ip -br addr
veth10@if6       UP             192.168.10.42/24 fe80::fc82:b9ff:fea9:2a83/64

$ ip netns exec vlan20 ip -br addr
veth20@if11      UP             192.168.20.42/24 fe80::14bc:f1ff:fec0:81c0/64


on the host ns they dont have addrs. I think they dont need. As fas as i understand
the subinterface on the bridge will get addr later when doing ip routing. but not sure

$ ip -br addr show
veth10-br@if7    UP             fe80::8c37:3cff:fe8c:596c/64
br0              UP             fe80::db:3ff:feed:2deb/64
veth20-br@if12   UP             fe80::24ac:21ff:fe42:7eb5/64


$ tcpdump -i br0
18:17:36.312166 IP 192.168.20.42 > 192.168.10.42: ICMP echo request, id 41292, seq 1, length 64
18:17:37.368530 IP 192.168.20.42 > 192.168.10.42: ICMP echo request, id 41292, seq 2, length 64
18:17:38.408534 IP 192.168.20.42 > 192.168.10.42: ICMP echo request, id 41292, seq 3, length 64
18:17:41.368419 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28
18:17:42.408485 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28
18:17:43.448406 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28

$ ip netns exec vlan20 sysctl net.ipv4.conf.veth20.arp_ignore
net.ipv4.conf.veth20.arp_ignore = 0

$ bridge fdb
33:33:00:00:00:01 dev eth0 self permanent
01:00:5e:00:00:01 dev eth0 self permanent
33:33:ff:13:b8:3b dev eth0 self permanent
8e:37:3c:8c:59:6c dev veth10-br vlan 1 master br0 permanent
8e:37:3c:8c:59:6c dev veth10-br master br0 permanent
33:33:00:00:00:01 dev veth10-br self permanent
01:00:5e:00:00:01 dev veth10-br self permanent
33:33:ff:8c:59:6c dev veth10-br self permanent
33:33:00:00:00:01 dev br0 self permanent
01:00:5e:00:00:6a dev br0 self permanent
33:33:00:00:00:6a dev br0 self permanent
01:00:5e:00:00:01 dev br0 self permanent
33:33:ff:ed:2d:eb dev br0 self permanent
02:db:03:ed:2d:eb dev br0 vlan 1 master br0 permanent
02:db:03:ed:2d:eb dev br0 master br0 permanent
26:ac:21:42:7e:b5 dev veth20-br vlan 1 master br0 permanent
26:ac:21:42:7e:b5 dev veth20-br master br0 permanent
33:33:00:00:00:01 dev veth20-br self permanent
01:00:5e:00:00:01 dev veth20-br self permanent
33:33:ff:42:7e:b5 dev veth20-br self permanent

$ ip netns exec vlan10 tcpdump -i veth10 -nn arp
18:27:29.276492 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28
18:27:30.328932 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28
18:27:31.368467 ARP, Request who-has 192.168.10.42 tell 192.168.20.42, length 28

# in another terminal
$ ip netns exec vlan20 ping -c 3 192.168.10.42 -I veth20
PING 192.168.10.42 (192.168.10.42) from 192.168.20.42 veth20: 56(84) bytes of data.
--- 192.168.10.42 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2092ms

$ ip netns exec vlan10 ip neigh
192.168.20.42 dev veth10 lladdr 16:bc:f1:c0:81:c0 STALE

sudo ip netns exec vlan20 ip neigh
192.168.10.42 dev veth20 FAILED




