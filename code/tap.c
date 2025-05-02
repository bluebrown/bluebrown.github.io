#include <arpa/inet.h>
#include <fcntl.h>
#include <linux/if.h>
#include <linux/if_ether.h>
#include <linux/if_tun.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

// device must be created first, with:
//   ip tuntap add dev tap0 mode tap
//   ip link set dev tap0 up
//   ip addr add 192.168.0.10/24 dev tap0
int open_sesame(const char *dev) {
  int fd = open("/dev/net/tun", O_RDWR);
  if (fd < 0) {
    perror("open /dev/net/tun");
    return -1;
  }

  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));

  ifr.ifr_flags = IFF_TAP | IFF_NO_PI; // TAP device, no packet info

  strncpy(ifr.ifr_name, dev, IFNAMSIZ);

  if (ioctl(fd, TUNSETIFF, &ifr) < 0) {
    perror("ioctl TUNSETIFF");
    close(fd);
    return -1;
  }

  return fd;
}

void print_eth(const char *buf, int n) {

  struct ethhdr *eth = (struct ethhdr *)buf;

  char *mac_fmt = "%-14s %02x:%02x:%02x:%02x:%02x:%02x\n";

  printf(mac_fmt, "Source:", eth->h_source[0], eth->h_source[1],
         eth->h_source[2], eth->h_source[3], eth->h_source[4],
         eth->h_source[5]);

  printf(mac_fmt, "Destination:", eth->h_dest[0], eth->h_dest[1],
         eth->h_dest[2], eth->h_dest[3], eth->h_dest[4], eth->h_dest[5]);

  printf("%-14s", "Ethertype:");
  switch (ntohs(eth->h_proto)) {
  case ETH_P_IP:
    printf(" IPv4\n");
    break;
  case ETH_P_IPV6:
    printf(" IPv6\n");
    break;
  case ETH_P_ARP:
    printf(" ARP\n");
    break;
  default:
    printf(" 0x%04x\n", ntohs(eth->h_proto));
  }

  int len = n - sizeof(struct ethhdr);
  printf("Payload (%d bytes):\n  ", len);
  for (int i = 0; i < len; i++) {
    if (i % 16 == 0 && i != 0)
      printf("\n  ");
    printf("%02x ", (unsigned char)buf[i]);
  }

  printf("\n\n");
}

int main() {
  int tap = open_sesame("tap0");
  if (tap < 0)
    return 1;

  char buf[2048];
  while (1) {
    int n = read(tap, buf, sizeof(buf));
    if (n < 0) {
      perror("read");
      close(tap);
      return 1;
    }
    printf("Received %d bytes:\n", n);
    print_eth(buf, n);
  }

  close(tap);
  return 0;
}
