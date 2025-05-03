#!/usr/bin/env bash
set -e

function net::bridge::create() {
	local name=$1
	# Create a bridge
	ip link add "${name}" type bridge
	# Bring up the bridge
	ip link set "${name}" up
	# enable vlan filtering
	ip link set dev "${name}" type bridge vlan_filtering 1
}

function net::namespace:create() {
	local serial=$1
	local master=$2
	local vid=$3

	local name="vm${serial}"
	local addr="192.168.0.${serial}/24"

	# Create a new VM
	ip netns add "${name}"

	# Create a veth pair
	ip link add "${name}" type veth peer name eth0 netns "${name}"

	# Bring up the interfaces
	ip link set "${name}" up
	ip netns exec "${name}" ip link set eth0 up

	# Assign an IP address to the interface in the namespace
	ip netns exec "${name}" ip addr add "${addr}" dev eth0

	# add to the bridge
	ip link set "${name}" master "${master}"

	# configure vlan tagging
	bridge vlan add dev "${name}" vid "${vid}" pvid untagged
}

net::bridge::create "br0"
net::namespace:create 1 "br0" 10
net::namespace:create 2 "br0" 10
net::namespace:create 3 "br0" 20

# Test the connectivity
# example output:
#
#     # container 1 and 2 are in the same VLAN
#     $ ip netns exec cnt1 ping -I eth0 192.168.0.2 -c 1
#     PING 192.168.0.2 (192.168.0.2) from 192.168.0.1 eth0: 56(84) bytes of data.
#     64 bytes from 192.168.0.2: icmp_seq=1 ttl=64 time=0.217 ms
#
#     --- 192.168.0.2 ping statistics ---
#     1 packets transmitted, 1 received, 0% packet loss, time 0ms
#     rtt min/avg/max/mdev = 0.217/0.217/0.217/0.000 ms
#
#     # container 1 and 3 are in different VLANs
#     $ ip netns exec cnt1 ping -I eth0 192.168.0.3 -c 1
#     PING 192.168.0.3 (192.168.0.3) from 192.168.0.1 eth0: 56(84) bytes of data.
#
#     --- 192.168.0.3 ping statistics ---
#     1 packets transmitted, 0 received, 100% packet loss, time 0ms
