# Networking Primer

Networking connects devices to enable communication by utilizing
physical links—either point-to-point connections (e.g., between two
devices) or shared mediums (e.g., wireless or Ethernet networks). These
physical links form the "roads" on which data travels. However, the
global connectivity we experience today depends on a **logical network**
layered on top of this physical foundation.

The logical network uses protocols like Ethernet and IP to define rules
for addressing and communication. Data travels in packets, structured
units that cross boundaries called broadcast domains. A broadcast domain
is a segment of the network where devices can directly communicate by
broadcasting messages, such as ARP requests ("Who has this IP?").

When data crosses into another network, it leaves its broadcast domain
and enters another. At each boundary, data is **re-encapsulated** at the
Data Link Layer (Layer 2) for the next hop, while the Network Layer
(Layer 3) information (e.g., IP address) remains unchanged. This ensures
data can traverse multiple physical and logical networks to reach its
destination.

## Networking Layers

To understand how networking operates, it is essential to grasp the
**OSI Model**, a conceptual framework that organizes networking into
seven layers. Each layer has specific responsibilities, and together
they enable seamless communication between devices.

### Data Link Layer (Layer 2)

The Data Link Layer is responsible for local communication within the
same physical or logical network (e.g., Ethernet switching). It
encapsulates data into **frames** with MAC addresses for source and
destination.

A single packet from the Network Layer may be fragmented into multiple
frames at this layer, depending on the Maximum Transmission Unit (MTU)
of the physical medium. For example, if a packet is larger than the MTU
(e.g., 1500 bytes for Ethernet), it will be split into smaller frames,
each transmitted separately.

> [!TIP]  
> Mismatched MTU settings can lead to packet fragmentation or dropped
> packets. Configuring consistent MTU sizes across devices is crucial
> for avoiding these issues.

```console
Frame: 00:1A:2B:3C:4D:5E -> FF:FF:FF:FF:FF:FF | EtherType: 0x0800 | Payload: [DATA]
```

### Network Layer (Layer 3)

The Network Layer enables communication across different networks using
logical addressing (IP addresses). It encapsulates data into **packets**
with source and destination IP addresses.

```console
Packet: Source IP: 192.168.1.10 -> Destination IP: 192.168.1.20
```

### Transport Layer (Layer 4)

The Transport Layer ensures reliable communication through protocols
like TCP (connection-oriented) and UDP (connectionless). It encapsulates
data into **segments** (TCP) or **datagrams** (UDP) for delivery between
applications.

At this layer, a single application message (e.g., an HTTP request) can
be divided into multiple packets for delivery. For example:

- In TCP, large chunks of data are split into multiple packets to ensure
  reliable delivery, with each packet numbered for sequencing and
  acknowledgment.
- In UDP, data is also split into packets, but without guarantees for
  sequencing or delivery.

```console
Source Port: 443, Destination Port: 12345, Sequence: 1001, ACK: 2001
```

### How Layers Work Together

Data from a higher layer (e.g., an application) is sequentially
encapsulated as it passes through lower layers. At the receiving end,
the process is reversed (decapsulation). For example:

1. A large file download may begin as a single request at the
   Application Layer.
2. The Transport Layer splits it into multiple packets for delivery.
3. The Network Layer routes each packet to its destination.
4. The Data Link Layer fragments these packets further into frames for
   transmission over the physical medium.

## Addressing Mechanisms in Networking

Addressing is critical for identifying devices and enabling
communication. Networking employs two primary types of addresses:

### MAC Addresses (Physical Layer)

MAC addresses are unique hardware identifiers assigned to network
interfaces. They are used for local communication within the same
broadcast domain.

Example: `00:1A:2B:3C:4D:5E`

### IP Addresses (Logical Layer)

IP addresses are software-configurable and used for communication across
networks. They consist of network and host portions, defined by a
**subnet mask** or **CIDR notation**.

Example: `192.168.1.1/24`

### ARP (Address Resolution Protocol)

ARP resolves IP addresses to MAC addresses for communication within a
subnet.

```console
Who has 192.168.1.10? Tell 192.168.1.1
Response: 192.168.1.10 is at 00:1A:2B:3C:4D:5E
```

## Subnets and Broadcast Domains

Subnets and broadcast domains define how devices communicate within and
across networks.

### Subnets and Isolation

A subnet is a logically segmented portion of a network, defined by a
subnet mask or CIDR notation. For example, `192.168.1.0/24` covers IPs
`192.168.1.1` to `192.168.1.254`. Devices in the same subnet communicate
directly using MAC addresses, while devices in different subnets require
a router to forward traffic.

### Physical and Logical Independence

Physical and logical network configurations do not always align. For
example, multiple subnets can coexist on the same physical switch,
ensuring devices in different subnets cannot communicate directly via
MAC addresses. Conversely, technologies like VXLAN (Virtual Extensible
LAN) enable devices to communicate across different physical hosts by
encapsulating Layer 2 frames over Layer 3 networks. This flexibility is
a hallmark of modern scalable network designs.

### Unicast, Multicast, and Broadcast

Networking uses three primary communication methods depending on the
target audience for data:

- **Unicast**: Data is sent from one sender to a single specific
  receiver. Most internet traffic, such as HTTP requests, is unicast.

  ```console
  Unicast: Source IP: 192.168.1.10 -> Destination IP: 192.168.1.20
  ```

- **Multicast**: Data is sent from one sender to multiple specific
  receivers who have opted to join the multicast group. Common in video
  streaming and conferencing applications.

  ```console
  Multicast: Source IP: 192.168.1.10 -> Multicast Group: 224.0.0.1
  ```

- **Broadcast**: Data is sent from one sender to all devices in the
  broadcast domain. Used for discovery protocols like ARP.

  ```console
  Broadcast: Source IP: 192.168.1.10 -> Destination MAC: FF:FF:FF:FF:FF:FF
  ```

Understanding these methods is essential for designing and
troubleshooting networks, as each has specific use cases and
limitations.

### VLANs and VXLANs in Practice

VLANs isolate traffic within the same physical switch, while VXLANs
extend that isolation across multiple switches and even data centers. In
multi-tenant environments like cloud data centers, these technologies
ensure secure and scalable network segmentation.

```bash
# Example: Creating a VXLAN interface in Linux
ip link add vxlan0 type vxlan id 42 dev eth0 dstport 4789
bridge fdb add 00:11:22:33:44:55 dev vxlan0 dst 192.168.1.100
```

## From Wire to Userland

### The Network Interface Card (NIC)

The NIC translates data between physical signals (e.g., electrical,
optical) and packet data for the operating system. For example, it
receives an Ethernet frame, strips the header, and passes it to the
kernel network stack.

### Packet Journey

1. NIC receives a frame.
2. Frame processed at Layer 2 (Data Link).
3. IP packet extracted and processed at Layer 3 (Network).
4. TCP/UDP segment processed at Layer 4 (Transport).
5. Payload delivered to user-space application.

## Network Troubleshooting Basics

Understanding network troubleshooting tools is essential for diagnosing
issues. Common tools include:

- `ping`: Tests reachability of a host.
- `traceroute`: Traces the path packets take to a destination.
- `tcpdump`: Captures and analyzes network traffic.
- `netstat`: Displays active connections and listening ports.
- `nslookup` or `dig`: Resolves DNS queries.

```bash
# Example: Capturing traffic on interface eth0
tcpdump -i eth0 port 80
```

## Roles of Common Devices

### Switch

A switch connects multiple devices in a network via point-to-point
connections. Operating at Layer 2 (Data Link), it forwards frames based
on MAC addresses.

### Router

A router connects multiple networks and determines the best path for
data using routing protocols. It operates at Layer 3 (Network) and
forwards packets based on IP addresses.

### Firewall

A firewall monitors and controls traffic based on security rules. It
operates at multiple layers, commonly Layer 3 (Network) and Layer 4
(Transport).

## Hands-On Labs

### Using Linux Bridge Driver as a Layer 2 Switch

Create a bridge interface:

```bash
ip link add name br0 type bridge
ip link set dev eth1 master br0
ip link set dev eth2 master br0
ip link set dev br0 up
ip link set dev eth1 up
ip link set dev eth2 up
```

### Using Linux as a Layer 3 Router

Enable IP forwarding:

```bash
echo 1 | tee /proc/sys/net/ipv4/ip_forward
```

Configure a route:

```bash
ip route add 10.0.0.0/24 via 192.168.1.1
```

### Using Linux as a Layer 4 Firewall

Basic iptables setup to block all incoming traffic except SSH:

```bash
iptables -P INPUT DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -P OUTPUT ACCEPT
```

## Conclusion

Networking is a complex yet fascinating field that underpins modern
communication. By understanding the layers, addressing mechanisms, and
troubleshooting techniques, you can navigate the intricacies of
networking with confidence. This primer serves as a foundation for
further exploration into advanced topics like routing protocols, network
security, and cloud networking.
