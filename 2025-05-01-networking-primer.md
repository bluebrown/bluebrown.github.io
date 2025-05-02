# Networking Primer

## Network Data Flow

The following describes the data flow through a typical network
interface:

1. **Medium (Cable/Wireless):** The physical medium over which data
   travels, e.g., Ethernet cables or Wi-Fi signals.
2. **Adapter (Network Adapter, optional):** Converts data for
   compatibility with the physical medium, e.g., USB-to-Ethernet
   adapters.
3. **NIC (Network Interface Card):**
   - **PHY (Physical Layer):** Modulates and demodulates signals into
     electrical, optical, or wireless forms suitable for the medium.
   - **MAC (Media Access Control):** Handles framing, addressing, access
     control, and error detection on the medium.
4. **DMA (Direct Memory Access, commonly used):** Transfers data between
hardware and system memory without CPU intervention.
5. **Driver:** Software that communicates with the NIC and may offload
tasks (e.g., checksum calculations) to the hardware for optimization.
6. **OS Buffer:** Temporary memory in the operating system for storing
incoming and outgoing packets. This operates in **kernel space**, often
using structures like `struct sk_buff` in Linux.
7. **OS Network Stack:** Handles network protocols and tasks such as:
   - **ARP (Address Resolution Protocol):** Maps IP addresses to MAC
     addresses.
   - **TCP/IP or UDP:** Manages communication protocols and flow
     control.
   - **Fragmentation/Reassembly:** Splits or reassembles packets for
     efficient transmission.
8. **Network Interface:** Exposed to userland applications through APIs
like sockets for sending and receiving data.

> [!NOTE]
>
> - **Kernel Space:** Layers such as the NIC, driver, OS buffer, and
>   network stack operate in privileged kernel mode.
> - **User Space:** Applications interact with the network stack via the
>   **Network Interface**, typically using socket APIs.
> - **Raw Sockets:** Allow userland programs to bypass the network stack
>   for custom packet construction, often used for diagnostics or
>   specialized applications. These usually require elevated privileges.

## Networking Devices and Concepts

### Switch (Layer 2)

- Operates at the **Data Link Layer (Layer 2)** of the OSI model.
- Forwards packets based on **MAC addresses**.
- Uses a **MAC address table (CAM table)** to map MAC addresses to
  switch ports.
- Connects devices in a **Local Area Network (LAN)** and enables
  efficient communication within the same Layer 2 domain.

### Router (Layer 3)

- Operates at the **Network Layer (Layer 3)** of the OSI model.
- Routes packets between subnets or networks using **IP addresses** and
  routing tables.
- Connects multiple networks to enable communication between them,
  ensuring proper delivery across Layer 3 boundaries.

### Bridge Drivers (Software Bridges)

- **Functionality:** Software bridges join multiple network interfaces
  into a single Layer 2 network, enabling communication without
  requiring a router.
- **Common Use Cases:**
  - Virtualization environments to connect virtual machines or
    containers.
  - Extending Layer 2 domains across network interfaces.
- **How They Work:** Forward Ethernet frames between interfaces based on
  MAC addresses.
- **Bypassing Routers:** Allows devices on different interfaces to
  communicate directly without needing Layer 3 routing.

Example of creating a software bridge in Linux:

```bash
ip link add name br0 type bridge
ip link set dev eth0 master br0
ip link set dev eth1 master br0
ip link set dev br0 up 
```

> [!NOTE]  
> Software bridges are a versatile tool in modern networking and are
> commonly used in virtualization and containerized environments.

> [!TIP]  
> Switches can also be used in conjunction with software bridges for more
> complex setups, such as VLAN management.

## Layer 2 vs. Layer 3

Understanding the distinction between **Layer 2 (Data Link Layer)** and
**Layer 3 (Network Layer)** is crucial for networking design and
troubleshooting.

### Layer 2 (Data Link Layer)

- Operates using **MAC addresses** to forward packets within the same
  broadcast domain.
- Devices communicate directly using **ARP (Address Resolution
  Protocol)** to map IP addresses to MAC addresses.
- **Limitations:** Layer 2 cannot forward packets outside the LAN
  without special extensions like VLAN bridging or tunneling.

> [!NOTE]  
> ARP resolves IP addresses to MAC addresses for Layer 2 communication.
> Once resolved, only MAC addresses are used for data transmission.

### Layer 3 (Network Layer)

- Operates using **IP addresses** to route packets between different
  networks or subnets.
- When a destination IP is outside the LAN:
  - Sends the packet to the **default gateway** (usually a router).
  - The router determines the best path to the destination network.

#### Key Workflow: IP Lookup

1. **Within the same LAN:**
   - Use ARP to resolve the destination IP to a MAC address and send the
     packet directly over Layer 2.
2. **Outside the LAN:**
   - Forward the packet to the router (default gateway) for routing to
     the destination network.

> [!NOTE]
> Technologies like **Layer 2 Tunneling Protocol (L2TP)** or VLAN
> bridging can extend Layer 2 connectivity across different networks,
> bypassing the need for a router in specific setups.

---

## TAP Devices

TAP (Terminal Access Point) devices are **virtual network interfaces**
that simulate a physical Layer 2 connection. They are commonly used in
virtualization, testing, or coding exercises.

- TAP devices handle Ethernet frames and expose them to userland
  programs, behaving like a NIC but existing entirely in software.
- Programs can directly read and write Ethernet frames to the TAP
  interface.

Example of creating a TAP device in Linux:

```bash
ip tuntap add dev tap0 mode tap 
ip addr add 192.0.0.1/24 dev
tap0 ip link set dev tap0 up 
```

> [!NOTE]
> Ensure the `tuntap` kernel module is loaded using `modprobe tun`
> before creating TAP devices.

## Resources

- [LearnCisco: Ethernet Protocol](https://www.learncisco.net/courses/icnd-1/building-a-network/ethernet-protocol.html)
- [LearnCisco: TCP/IP Internet Layer](https://www.learncisco.net/courses/icnd-1/building-a-network/tcpip-internet-layer.html)
- [Red Hat: Introduction to Linux Interfaces](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking)
- [Linux Kernel Docs: TUN/TAP](https://docs.kernel.org/networking/tuntap.html)
- [GitHub: iproute2](https://github.com/iproute2/iproute2/blob/main/ip/iptuntap.c#L48)
- [StackOverflow: Managing Network Interfaces](https://stackoverflow.com/questions/5858655/linux-programmatically-up-down-an-interface-kernel#5859449)
- [StackOverflow: IFF_UP vs IFF_RUNNING](https://stackoverflow.com/questions/11679514/what-is-the-difference-between-iff-up-and-iff-running)
- [VLAN Tagging](https://networkengineering.stackexchange.com/questions/6483/why-and-how-are-ethernet-vlans-tagged)
