// NEMU Ubuntu virtio-net guest-check 的最小 ICMP probe。
// rootfs 不要求预装 ping；host 侧交叉编译后注入 guest，用 raw socket
// 直接验证 NEMU hostless ARP/ICMP responder 的 TX/RX 数据路径。

#define _GNU_SOURCE

#include <arpa/inet.h>
#include <errno.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

static uint16_t icmp_checksum(const void *data, size_t len) {
  const uint8_t *p = data;
  uint32_t sum = 0;
  while (len >= 2) {
    sum += ((uint16_t)p[0] << 8) | p[1];
    p += 2;
    len -= 2;
  }
  if (len != 0) {
    sum += (uint16_t)p[0] << 8;
  }
  while ((sum >> 16) != 0) {
    sum = (sum & 0xffffu) + (sum >> 16);
  }
  return (uint16_t)~sum;
}

static int fail_errno(const char *stage) {
  printf("__NEMU_ICMP_PROBE_FAIL__:%s:%s\n", stage, strerror(errno));
  return 1;
}

static int fail_msg(const char *stage, const char *msg) {
  printf("__NEMU_ICMP_PROBE_FAIL__:%s:%s\n", stage, msg);
  return 1;
}

int main(int argc, char **argv) {
  const char *dst_text = argc > 1 ? argv[1] : "10.0.2.2";
  int fd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
  if (fd < 0) {
    return fail_errno("socket");
  }

  struct timeval timeout = {
    .tv_sec = 5,
    .tv_usec = 0,
  };
  if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) != 0) {
    close(fd);
    return fail_errno("setsockopt-timeout");
  }

  struct sockaddr_in dst;
  memset(&dst, 0, sizeof(dst));
  dst.sin_family = AF_INET;
  if (inet_pton(AF_INET, dst_text, &dst.sin_addr) != 1) {
    close(fd);
    return fail_msg("inet-pton", "bad-destination");
  }

  struct {
    struct icmphdr icmp;
    uint8_t payload[24];
  } packet;
  memset(&packet, 0, sizeof(packet));
  const char payload[] = "nemu-virtio-net-icmp";
  const size_t payload_len = sizeof(payload) - 1;
  memcpy(packet.payload, payload, payload_len);
  packet.icmp.type = ICMP_ECHO;
  packet.icmp.code = 0;
  packet.icmp.un.echo.id = htons((uint16_t)getpid());
  packet.icmp.un.echo.sequence = htons(1);
  const size_t packet_len = sizeof(packet.icmp) + payload_len;
  packet.icmp.checksum = icmp_checksum(&packet, packet_len);

  printf("__NEMU_ICMP_PROBE_TX__:%s\n", dst_text);
  fflush(stdout);
  ssize_t sent = sendto(fd, &packet, packet_len, 0,
      (struct sockaddr *)&dst, sizeof(dst));
  if (sent != (ssize_t)packet_len) {
    close(fd);
    return sent < 0 ? fail_errno("sendto") : fail_msg("sendto", "short-write");
  }

  while (true) {
    uint8_t buf[2048];
    struct sockaddr_in src;
    socklen_t src_len = sizeof(src);
    ssize_t got = recvfrom(fd, buf, sizeof(buf), 0,
        (struct sockaddr *)&src, &src_len);
    if (got < 0) {
      if (errno == EINTR) continue;
      close(fd);
      return fail_errno("recvfrom");
    }
    if ((size_t)got < sizeof(struct iphdr) + sizeof(struct icmphdr)) {
      continue;
    }

    struct iphdr ip;
    memcpy(&ip, buf, sizeof(ip));
    size_t ihl = (size_t)ip.ihl * 4u;
    if (ip.version != 4 || ihl < sizeof(struct iphdr) ||
        (size_t)got < ihl + sizeof(struct icmphdr) ||
        ip.protocol != IPPROTO_ICMP ||
        ip.saddr != dst.sin_addr.s_addr) {
      continue;
    }

    struct icmphdr reply;
    memcpy(&reply, buf + ihl, sizeof(reply));
    if (reply.type == ICMP_ECHOREPLY &&
        reply.code == 0 &&
        reply.un.echo.id == packet.icmp.un.echo.id &&
        reply.un.echo.sequence == packet.icmp.un.echo.sequence) {
      char src_text[INET_ADDRSTRLEN] = {};
      inet_ntop(AF_INET, &ip.saddr, src_text, sizeof(src_text));
      printf("__NEMU_ICMP_PROBE_RX__:%s\n", src_text);
      printf("__NEMU_ICMP_PROBE_PASS__:icmp-echo\n");
      close(fd);
      return 0;
    }
  }
}
