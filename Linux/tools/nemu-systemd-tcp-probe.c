// NEMU Ubuntu virtio-net guest-check 的最小 TCP/HTTP probe。
// 通过普通 TCP socket 验证 guest TCP 栈、ARP、virtio-net TX/RX 与 NEMU
// hostless responder，而不是声明已经具备 TAP/NAT/外网能力。

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

#define TCP_PROBE_BUF_SIZE 512
#define TCP_PROBE_MAX_LOOPS 64

static int fail_errno(const char *stage) {
  printf("__NEMU_TCP_PROBE_FAIL__:%s:%s\n", stage, strerror(errno));
  return 1;
}

static int fail_msg(const char *stage, const char *msg) {
  printf("__NEMU_TCP_PROBE_FAIL__:%s:%s\n", stage, msg);
  return 1;
}

static int send_all(int fd, const char *buf, size_t len) {
  size_t done = 0;
  while (done < len) {
    ssize_t n = send(fd, buf + done, len - done, 0);
    if (n < 0) {
      if (errno == EINTR) continue;
      return -1;
    }
    if (n == 0) return 0;
    done += (size_t)n;
  }
  return 1;
}

static int tcp_probe_once(const char *ifname, const char *server_text,
    const struct in_addr *server_addr, uint16_t port, const char *path,
    unsigned int iter, unsigned int loops) {
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) return fail_errno("socket");

  struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
  if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) != 0 ||
      setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv)) != 0) {
    close(fd);
    return fail_errno("setsockopt-timeout");
  }
  if (ifname[0] != '\0' &&
      setsockopt(fd, SOL_SOCKET, SO_BINDTODEVICE, ifname, strlen(ifname) + 1) != 0) {
    close(fd);
    return fail_errno("bind-device");
  }

  struct sockaddr_in dst;
  memset(&dst, 0, sizeof(dst));
  dst.sin_family = AF_INET;
  dst.sin_port = htons(port);
  dst.sin_addr = *server_addr;

  printf("__NEMU_TCP_PROBE_ITER__:%u/%u\n", iter, loops);
  printf("__NEMU_TCP_PROBE_CONNECT__:%s:%u:%u/%u\n",
      server_text, port, iter, loops);
  if (connect(fd, (const struct sockaddr *)&dst, sizeof(dst)) != 0) {
    close(fd);
    return fail_errno("connect");
  }

  char request[160];
  int request_len = snprintf(request, sizeof(request),
      "GET %s HTTP/1.0\r\nHost: nemu.local\r\nConnection: close\r\n\r\n", path);
  if (request_len <= 0 || (size_t)request_len >= sizeof(request)) {
    close(fd);
    return fail_msg("request", "too-long");
  }

  printf("__NEMU_TCP_PROBE_TX__:GET:%s:%u/%u\n", path, iter, loops);
  int send_rc = send_all(fd, request, (size_t)request_len);
  if (send_rc <= 0) {
    close(fd);
    return send_rc < 0 ? fail_errno("send") : fail_msg("send", "short-send");
  }

  char reply[TCP_PROBE_BUF_SIZE];
  size_t used = 0;
  while (used + 1 < sizeof(reply)) {
    ssize_t got = recv(fd, reply + used, sizeof(reply) - 1 - used, 0);
    if (got < 0) {
      if (errno == EINTR) continue;
      close(fd);
      return fail_errno("recv");
    }
    if (got == 0) break;
    used += (size_t)got;
    reply[used] = '\0';
    if (strstr(reply, "\r\n\r\n") != NULL) break;
  }
  reply[used] = '\0';

  if (strstr(reply, "HTTP/1.0 204 No Content") == NULL) {
    close(fd);
    return fail_msg("reply", "missing-http-204");
  }

  printf("__NEMU_TCP_PROBE_RX__:HTTP/1.0 204 No Content:%u/%u\n",
      iter, loops);
  close(fd);
  return 0;
}

int main(int argc, char **argv) {
  const char *ifname = argc > 1 ? argv[1] : "eth0";
  const char *server_text = argc > 2 ? argv[2] : "10.0.2.2";
  uint16_t port = argc > 3 ? (uint16_t)strtoul(argv[3], NULL, 0) : 80;
  const char *path = argc > 4 ? argv[4] : "/nemu-health";
  unsigned long loops_ul = argc > 5 ? strtoul(argv[5], NULL, 0) : 1;

  struct in_addr server_addr;
  if (inet_pton(AF_INET, server_text, &server_addr) != 1) {
    return fail_msg("inet-pton", "bad-server");
  }
  if (port == 0) {
    return fail_msg("port", "bad-port");
  }
  if (loops_ul == 0 || loops_ul > TCP_PROBE_MAX_LOOPS) {
    return fail_msg("loops", "bad-loop-count");
  }

  unsigned int loops = (unsigned int)loops_ul;
  printf("__NEMU_TCP_PROBE_BURST__:%u\n", loops);
  for (unsigned int i = 1; i <= loops; i++) {
    int rc = tcp_probe_once(ifname, server_text, &server_addr, port, path, i, loops);
    if (rc != 0) return rc;
  }

  printf("__NEMU_TCP_PROBE_PASS__:tcp-http:%u\n", loops);
  return 0;
}
