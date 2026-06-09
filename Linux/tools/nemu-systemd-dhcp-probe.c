// NEMU Ubuntu virtio-net guest-check 的最小 DHCP probe。
// rootfs 不要求预装 dhclient/systemd-networkd 配置；host 侧交叉编译后注入
// guest，用 AF_PACKET 原始以太网帧验证无 IPv4 地址状态下的
// DISCOVER/OFFER 与 REQUEST/ACK 往返。

#define _GNU_SOURCE

#include <arpa/inet.h>
#include <errno.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define DHCP_CLIENT_PORT 68
#define DHCP_SERVER_PORT 67
#define DHCP_BOOTREQUEST 1
#define DHCP_BOOTREPLY 2
#define DHCP_HTYPE_ETHERNET 1
#define DHCP_MAGIC_COOKIE 0x63825363u
#define DHCP_FIXED_LEN 240
#define DHCP_OPT_PAD 0
#define DHCP_OPT_REQUESTED_IP 50
#define DHCP_OPT_MSG_TYPE 53
#define DHCP_OPT_SERVER_ID 54
#define DHCP_OPT_PARAM_REQUEST 55
#define DHCP_OPT_END 255
#define DHCPDISCOVER 1
#define DHCPOFFER 2
#define DHCPREQUEST 3
#define DHCPACK 5
#define DHCP_FRAME_MAX 576

static const uint8_t broadcast_mac[6] = {
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
};

static void put_be16(uint8_t *p, uint16_t value) {
  p[0] = value >> 8;
  p[1] = value & 0xffu;
}

static void put_be32(uint8_t *p, uint32_t value) {
  p[0] = value >> 24;
  p[1] = (value >> 16) & 0xffu;
  p[2] = (value >> 8) & 0xffu;
  p[3] = value & 0xffu;
}

static uint16_t get_be16(const uint8_t *p) {
  return ((uint16_t)p[0] << 8) | p[1];
}

static uint32_t get_be32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | p[3];
}

static uint16_t checksum16(const uint8_t *data, size_t len) {
  uint32_t sum = 0;
  while (len >= 2) {
    sum += get_be16(data);
    data += 2;
    len -= 2;
  }
  if (len != 0) {
    sum += (uint16_t)data[0] << 8;
  }
  while ((sum >> 16) != 0) {
    sum = (sum & 0xffffu) + (sum >> 16);
  }
  return (uint16_t)~sum;
}

static int fail_errno(const char *stage) {
  printf("__NEMU_DHCP_PROBE_FAIL__:%s:%s\n", stage, strerror(errno));
  return 1;
}

static int fail_msg(const char *stage, const char *msg) {
  printf("__NEMU_DHCP_PROBE_FAIL__:%s:%s\n", stage, msg);
  return 1;
}

static int get_iface_info(int fd, const char *ifname, int *ifindex,
    uint8_t mac[6]) {
  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", ifname);
  if (ioctl(fd, SIOCGIFINDEX, &ifr) != 0) {
    return -1;
  }
  *ifindex = ifr.ifr_ifindex;

  memset(&ifr, 0, sizeof(ifr));
  snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", ifname);
  if (ioctl(fd, SIOCGIFHWADDR, &ifr) != 0) {
    return -1;
  }
  memcpy(mac, ifr.ifr_hwaddr.sa_data, 6);
  return 0;
}

static size_t put_opt(uint8_t *opts, size_t off, uint8_t code,
    const uint8_t *value, uint8_t len) {
  opts[off++] = code;
  opts[off++] = len;
  memcpy(opts + off, value, len);
  return off + len;
}

static size_t make_dhcp_payload(uint8_t *dhcp, size_t cap, uint8_t msg_type,
    uint32_t xid, const uint8_t mac[6], uint32_t requested_ip,
    uint32_t server_id) {
  if (cap < 320) return 0;
  memset(dhcp, 0, cap);
  dhcp[0] = DHCP_BOOTREQUEST;
  dhcp[1] = DHCP_HTYPE_ETHERNET;
  dhcp[2] = 6;
  put_be32(dhcp + 4, xid);
  put_be16(dhcp + 10, 0x8000);
  memcpy(dhcp + 28, mac, 6);
  put_be32(dhcp + 236, DHCP_MAGIC_COOKIE);

  uint8_t *opts = dhcp + DHCP_FIXED_LEN;
  size_t off = 0;
  off = put_opt(opts, off, DHCP_OPT_MSG_TYPE, &msg_type, 1);
  if (requested_ip != 0) {
    uint8_t ip_opt[4];
    put_be32(ip_opt, requested_ip);
    off = put_opt(opts, off, DHCP_OPT_REQUESTED_IP, ip_opt, sizeof(ip_opt));
  }
  if (server_id != 0) {
    uint8_t server_opt[4];
    put_be32(server_opt, server_id);
    off = put_opt(opts, off, DHCP_OPT_SERVER_ID, server_opt, sizeof(server_opt));
  }
  const uint8_t params[] = {1, 3, 6, 51, 54};
  off = put_opt(opts, off, DHCP_OPT_PARAM_REQUEST, params, sizeof(params));
  opts[off++] = DHCP_OPT_END;
  return DHCP_FIXED_LEN + off;
}

static size_t make_dhcp_frame(uint8_t *frame, size_t cap, uint8_t msg_type,
    uint32_t xid, const uint8_t mac[6], uint32_t requested_ip,
    uint32_t server_id) {
  if (cap < DHCP_FRAME_MAX) return 0;
  memset(frame, 0, cap);
  memcpy(frame, broadcast_mac, 6);
  memcpy(frame + 6, mac, 6);
  put_be16(frame + 12, ETH_P_IP);

  uint8_t *ip = frame + 14;
  ip[0] = 0x45;
  ip[8] = 64;
  ip[9] = IPPROTO_UDP;
  memset(ip + 12, 0, 4);
  memset(ip + 16, 0xff, 4);

  uint8_t *udp = ip + 20;
  put_be16(udp, DHCP_CLIENT_PORT);
  put_be16(udp + 2, DHCP_SERVER_PORT);

  uint8_t *dhcp = udp + 8;
  size_t dhcp_len = make_dhcp_payload(dhcp, cap - 14 - 20 - 8,
      msg_type, xid, mac, requested_ip, server_id);
  if (dhcp_len == 0) return 0;
  size_t udp_len = 8 + dhcp_len;
  size_t ip_len = 20 + udp_len;
  put_be16(ip + 2, (uint16_t)ip_len);
  put_be16(ip + 10, 0);
  put_be16(ip + 10, checksum16(ip, 20));
  put_be16(udp + 4, (uint16_t)udp_len);
  put_be16(udp + 6, 0);
  return 14 + ip_len;
}

static bool find_option(const uint8_t *opts, size_t len, uint8_t target,
    const uint8_t **value, uint8_t *value_len) {
  size_t off = 0;
  while (off < len) {
    uint8_t code = opts[off++];
    if (code == DHCP_OPT_END) break;
    if (code == DHCP_OPT_PAD) continue;
    if (off >= len) return false;
    uint8_t opt_len = opts[off++];
    if (off + opt_len > len) return false;
    if (code == target) {
      *value = opts + off;
      *value_len = opt_len;
      return true;
    }
    off += opt_len;
  }
  return false;
}

static int recv_dhcp_reply(int fd, uint32_t xid, uint8_t expect_type,
    uint32_t *yiaddr, uint32_t *server_id) {
  while (true) {
    uint8_t frame[2048];
    ssize_t got = recv(fd, frame, sizeof(frame), 0);
    if (got < 0) {
      if (errno == EINTR) continue;
      return fail_errno("recv");
    }
    if (got < 14 + 20 + 8 + DHCP_FIXED_LEN ||
        get_be16(frame + 12) != ETH_P_IP) {
      continue;
    }
    const uint8_t *ip = frame + 14;
    size_t ihl = (size_t)(ip[0] & 0x0f) * 4u;
    if ((ip[0] >> 4) != 4 || ihl < 20 || ip[9] != IPPROTO_UDP ||
        (size_t)got < 14 + ihl + 8 + DHCP_FIXED_LEN) {
      continue;
    }
    const uint8_t *udp = ip + ihl;
    if (get_be16(udp) != DHCP_SERVER_PORT ||
        get_be16(udp + 2) != DHCP_CLIENT_PORT) {
      continue;
    }
    const uint8_t *dhcp = udp + 8;
    size_t udp_len = get_be16(udp + 4);
    if (udp_len < 8 + DHCP_FIXED_LEN ||
        dhcp[0] != DHCP_BOOTREPLY ||
        get_be32(dhcp + 4) != xid ||
        get_be32(dhcp + 236) != DHCP_MAGIC_COOKIE) {
      continue;
    }

    const uint8_t *msg_value = NULL;
    uint8_t msg_len = 0;
    if (!find_option(dhcp + DHCP_FIXED_LEN, udp_len - 8 - DHCP_FIXED_LEN,
          DHCP_OPT_MSG_TYPE, &msg_value, &msg_len) ||
        msg_len != 1 || msg_value[0] != expect_type) {
      continue;
    }

    const uint8_t *server_value = NULL;
    uint8_t server_len = 0;
    if (!find_option(dhcp + DHCP_FIXED_LEN, udp_len - 8 - DHCP_FIXED_LEN,
          DHCP_OPT_SERVER_ID, &server_value, &server_len) ||
        server_len != 4) {
      return fail_msg("server-id", "missing");
    }
    *yiaddr = get_be32(dhcp + 16);
    *server_id = get_be32(server_value);
    return 0;
  }
}

static int send_dhcp_frame(int fd, int ifindex, const uint8_t *frame,
    size_t frame_len) {
  struct sockaddr_ll dst;
  memset(&dst, 0, sizeof(dst));
  dst.sll_family = AF_PACKET;
  dst.sll_protocol = htons(ETH_P_IP);
  dst.sll_ifindex = ifindex;
  dst.sll_halen = 6;
  memcpy(dst.sll_addr, broadcast_mac, 6);
  ssize_t sent = sendto(fd, frame, frame_len, 0,
      (struct sockaddr *)&dst, sizeof(dst));
  if (sent != (ssize_t)frame_len) {
    return sent < 0 ? fail_errno("sendto") : fail_msg("sendto", "short-write");
  }
  return 0;
}

int main(int argc, char **argv) {
  const char *ifname = argc > 1 ? argv[1] : "eth0";
  int fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_IP));
  if (fd < 0) return fail_errno("socket");

  struct timeval timeout = {
    .tv_sec = 5,
    .tv_usec = 0,
  };
  if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) != 0) {
    close(fd);
    return fail_errno("setsockopt-timeout");
  }

  int ifindex = 0;
  uint8_t mac[6];
  if (get_iface_info(fd, ifname, &ifindex, mac) != 0) {
    close(fd);
    return fail_errno("iface-info");
  }

  struct sockaddr_ll bind_addr;
  memset(&bind_addr, 0, sizeof(bind_addr));
  bind_addr.sll_family = AF_PACKET;
  bind_addr.sll_protocol = htons(ETH_P_IP);
  bind_addr.sll_ifindex = ifindex;
  if (bind(fd, (struct sockaddr *)&bind_addr, sizeof(bind_addr)) != 0) {
    close(fd);
    return fail_errno("bind");
  }

  uint32_t xid = 0x4e454d55u;
  uint8_t frame[DHCP_FRAME_MAX];
  size_t frame_len = make_dhcp_frame(frame, sizeof(frame),
      DHCPDISCOVER, xid, mac, 0, 0);
  if (frame_len == 0) {
    close(fd);
    return fail_msg("discover", "packet-build");
  }

  printf("__NEMU_DHCP_PROBE_TX__:discover:%s\n", ifname);
  fflush(stdout);
  int rc = send_dhcp_frame(fd, ifindex, frame, frame_len);
  if (rc != 0) {
    close(fd);
    return rc;
  }

  uint32_t offered_ip = 0;
  uint32_t server_id = 0;
  rc = recv_dhcp_reply(fd, xid, DHCPOFFER, &offered_ip, &server_id);
  if (rc != 0) {
    close(fd);
    return rc;
  }
  struct in_addr offered_addr = {.s_addr = htonl(offered_ip)};
  struct in_addr server_addr = {.s_addr = htonl(server_id)};
  char offered_text[INET_ADDRSTRLEN] = {};
  char server_text[INET_ADDRSTRLEN] = {};
  inet_ntop(AF_INET, &offered_addr, offered_text, sizeof(offered_text));
  inet_ntop(AF_INET, &server_addr, server_text, sizeof(server_text));
  printf("__NEMU_DHCP_PROBE_OFFER__:%s:%s\n", offered_text, server_text);

  frame_len = make_dhcp_frame(frame, sizeof(frame),
      DHCPREQUEST, xid, mac, offered_ip, server_id);
  if (frame_len == 0) {
    close(fd);
    return fail_msg("request", "packet-build");
  }
  printf("__NEMU_DHCP_PROBE_TX__:request:%s\n", ifname);
  fflush(stdout);
  rc = send_dhcp_frame(fd, ifindex, frame, frame_len);
  if (rc != 0) {
    close(fd);
    return rc;
  }

  uint32_t ack_ip = 0;
  uint32_t ack_server = 0;
  rc = recv_dhcp_reply(fd, xid, DHCPACK, &ack_ip, &ack_server);
  if (rc != 0) {
    close(fd);
    return rc;
  }
  struct in_addr ack_addr = {.s_addr = htonl(ack_ip)};
  struct in_addr ack_server_addr = {.s_addr = htonl(ack_server)};
  char ack_text[INET_ADDRSTRLEN] = {};
  char ack_server_text[INET_ADDRSTRLEN] = {};
  inet_ntop(AF_INET, &ack_addr, ack_text, sizeof(ack_text));
  inet_ntop(AF_INET, &ack_server_addr, ack_server_text, sizeof(ack_server_text));
  printf("__NEMU_DHCP_PROBE_ACK__:%s:%s\n", ack_text, ack_server_text);

  if (ack_ip != offered_ip || ack_server != server_id) {
    close(fd);
    return fail_msg("ack", "mismatch");
  }

  printf("__NEMU_DHCP_PROBE_PASS__:dhcp-lease\n");
  close(fd);
  return 0;
}
