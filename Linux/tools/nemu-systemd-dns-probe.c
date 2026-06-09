// NEMU Ubuntu virtio-net guest-check 的最小 DNS probe。
// DHCP 已把 DNS server 指向 10.0.2.2；本 probe 通过真实 UDP socket
// 验证 guest IPv4/ARP/UDP/DNS 路径，而不是声明已有外网/NAT。

#include <arpa/inet.h>
#include <errno.h>
#include <net/if.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

#define DNS_SERVER_PORT 53
#define DNS_HEADER_LEN 12
#define DNS_QTYPE_A 1
#define DNS_QCLASS_IN 1
#define DNS_BUF_SIZE 512

static uint16_t get_be16(const uint8_t *p) {
  return ((uint16_t)p[0] << 8) | p[1];
}

static uint32_t get_be32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | p[3];
}

static void put_be16(uint8_t *p, uint16_t value) {
  p[0] = value >> 8;
  p[1] = value & 0xffu;
}

static int fail_errno(const char *stage) {
  printf("__NEMU_DNS_PROBE_FAIL__:%s:%s\n", stage, strerror(errno));
  return 1;
}

static int fail_msg(const char *stage, const char *msg) {
  printf("__NEMU_DNS_PROBE_FAIL__:%s:%s\n", stage, msg);
  return 1;
}

static size_t append_qname(uint8_t *buf, size_t off, size_t cap,
    const char *name) {
  const char *p = name;
  while (*p != '\0') {
    const char *dot = strchr(p, '.');
    size_t label_len = dot != NULL ? (size_t)(dot - p) : strlen(p);
    if (label_len == 0 || label_len > 63 || off + 1 + label_len >= cap) {
      return 0;
    }
    buf[off++] = (uint8_t)label_len;
    memcpy(buf + off, p, label_len);
    off += label_len;
    if (dot == NULL) break;
    p = dot + 1;
  }
  if (off >= cap) return 0;
  buf[off++] = 0;
  return off;
}

static size_t make_dns_query(uint8_t *buf, size_t cap, uint16_t id,
    const char *name) {
  if (cap < DNS_HEADER_LEN) return 0;
  memset(buf, 0, cap);
  put_be16(buf, id);
  put_be16(buf + 2, 0x0100u);
  put_be16(buf + 4, 1);
  size_t off = append_qname(buf, DNS_HEADER_LEN, cap, name);
  if (off == 0 || off + 4 > cap) return 0;
  put_be16(buf + off, DNS_QTYPE_A);
  put_be16(buf + off + 2, DNS_QCLASS_IN);
  return off + 4;
}

static int skip_name(const uint8_t *buf, size_t len, size_t *off) {
  size_t p = *off;
  while (p < len) {
    uint8_t label_len = buf[p++];
    if ((label_len & 0xc0u) == 0xc0u) {
      if (p >= len) return 0;
      p++;
      *off = p;
      return 1;
    }
    if ((label_len & 0xc0u) != 0 || p + label_len > len) {
      return 0;
    }
    if (label_len == 0) {
      *off = p;
      return 1;
    }
    p += label_len;
  }
  return 0;
}

static int find_a_answer(const uint8_t *buf, size_t len, uint16_t id,
    uint32_t expected_ip) {
  if (len < DNS_HEADER_LEN || get_be16(buf) != id) return 0;
  uint16_t flags = get_be16(buf + 2);
  if ((flags & 0x8000u) == 0 || (flags & 0x000fu) != 0) return 0;
  uint16_t qdcount = get_be16(buf + 4);
  uint16_t ancount = get_be16(buf + 6);
  size_t off = DNS_HEADER_LEN;
  for (uint16_t i = 0; i < qdcount; i++) {
    if (!skip_name(buf, len, &off) || off + 4 > len) return 0;
    off += 4;
  }
  for (uint16_t i = 0; i < ancount; i++) {
    if (!skip_name(buf, len, &off) || off + 10 > len) return 0;
    uint16_t type = get_be16(buf + off);
    uint16_t qclass = get_be16(buf + off + 2);
    uint16_t rdlen = get_be16(buf + off + 8);
    off += 10;
    if (off + rdlen > len) return 0;
    if (type == DNS_QTYPE_A && qclass == DNS_QCLASS_IN &&
        rdlen == 4 && get_be32(buf + off) == expected_ip) {
      return 1;
    }
    off += rdlen;
  }
  return 0;
}

int main(int argc, char **argv) {
  const char *ifname = argc > 1 ? argv[1] : "eth0";
  const char *server_text = argc > 2 ? argv[2] : "10.0.2.2";
  const char *query_name = argc > 3 ? argv[3] : "nemu.local";

  struct in_addr server_addr;
  if (inet_pton(AF_INET, server_text, &server_addr) != 1) {
    return fail_msg("inet-pton", "bad-server");
  }

  int fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (fd < 0) return fail_errno("socket");

  struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
  if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) != 0) {
    close(fd);
    return fail_errno("setsockopt-timeout");
  }
  if (ifname[0] != '\0' &&
      setsockopt(fd, SOL_SOCKET, SO_BINDTODEVICE, ifname, strlen(ifname) + 1) != 0) {
    close(fd);
    return fail_errno("bind-device");
  }

  uint8_t query[DNS_BUF_SIZE];
  uint16_t id = (uint16_t)(((uint32_t)getpid() ^ 0x4e44u) & 0xffffu);
  size_t query_len = make_dns_query(query, sizeof(query), id, query_name);
  if (query_len == 0) {
    close(fd);
    return fail_msg("make-query", "bad-query-name");
  }

  struct sockaddr_in dst;
  memset(&dst, 0, sizeof(dst));
  dst.sin_family = AF_INET;
  dst.sin_port = htons(DNS_SERVER_PORT);
  dst.sin_addr = server_addr;

  printf("__NEMU_DNS_PROBE_TX__:%s:%s\n", query_name, server_text);
  ssize_t sent = sendto(fd, query, query_len, 0,
      (const struct sockaddr *)&dst, sizeof(dst));
  if (sent < 0 || (size_t)sent != query_len) {
    close(fd);
    return sent < 0 ? fail_errno("sendto") : fail_msg("sendto", "short-send");
  }

  uint8_t reply[DNS_BUF_SIZE];
  ssize_t got = recv(fd, reply, sizeof(reply), 0);
  if (got < 0) {
    close(fd);
    return fail_errno("recv");
  }

  if (!find_a_answer(reply, (size_t)got, id, ntohl(server_addr.s_addr))) {
    close(fd);
    return fail_msg("answer", "missing-a-record");
  }

  printf("__NEMU_DNS_PROBE_RX__:%s:%s\n", query_name, server_text);
  printf("__NEMU_DNS_PROBE_PASS__:dns-a\n");
  close(fd);
  return 0;
}
