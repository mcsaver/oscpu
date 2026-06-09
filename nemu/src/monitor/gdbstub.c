/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "gdbstub.h"

#ifndef CONFIG_TARGET_AM

#include <isa.h>
#include <memory/paddr.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int gdbstub_port = 0;

void gdbstub_set_port(int port) {
  Assert(port > 0 && port <= 65535, "invalid --gdbstub port: %d", port);
  gdbstub_port = port;
}

bool gdbstub_is_enabled(void) {
  return gdbstub_port > 0;
}

const char *gdbstub_capability(void) {
  return "remote-readonly";
}

static int hex_value(int ch) {
  if (ch >= '0' && ch <= '9') return ch - '0';
  if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
  if (ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
  return -1;
}

static char hex_digit(uint8_t value) {
  static const char digits[] = "0123456789abcdef";
  return digits[value & 0xf];
}

static ssize_t write_all(int fd, const void *buf, size_t len) {
  const uint8_t *p = buf;
  size_t done = 0;
  while (done < len) {
    ssize_t n = write(fd, p + done, len - done);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return n;
    done += (size_t)n;
  }
  return (ssize_t)done;
}

static int read_byte(int fd) {
  uint8_t ch;
  for (;;) {
    ssize_t n = read(fd, &ch, 1);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return -1;
    return ch;
  }
}

static bool read_packet(int fd, char *payload, size_t payload_cap) {
  int ch;
  do {
    ch = read_byte(fd);
    if (ch < 0) return false;
  } while (ch != '$');

  uint8_t sum = 0;
  size_t len = 0;
  for (;;) {
    ch = read_byte(fd);
    if (ch < 0) return false;
    if (ch == '#') break;
    sum += (uint8_t)ch;
    if (len + 1 < payload_cap) {
      payload[len++] = (char)ch;
    }
  }
  payload[len] = '\0';

  int hi = read_byte(fd);
  int lo = read_byte(fd);
  int hv = hex_value(hi);
  int lv = hex_value(lo);
  if (hv < 0 || lv < 0 || (uint8_t)((hv << 4) | lv) != sum) {
    (void)write_all(fd, "-", 1);
    return false;
  }

  (void)write_all(fd, "+", 1);
  return true;
}

static bool send_packet(int fd, const char *payload) {
  uint8_t sum = 0;
  for (const char *p = payload; *p != '\0'; p++) {
    sum += (uint8_t)*p;
  }

  char trailer[4] = {'#', hex_digit(sum >> 4), hex_digit(sum), '\0'};
  if (write_all(fd, "$", 1) <= 0) return false;
  if (write_all(fd, payload, strlen(payload)) <= 0) return false;
  if (write_all(fd, trailer, 3) <= 0) return false;

  int ack = read_byte(fd);
  return ack == '+';
}

static void append_byte_hex(char *out, size_t cap, size_t *pos, uint8_t value) {
  if (*pos + 2 >= cap) return;
  out[(*pos)++] = hex_digit(value >> 4);
  out[(*pos)++] = hex_digit(value);
  out[*pos] = '\0';
}

static void append_word_le(char *out, size_t cap, size_t *pos, word_t value) {
  for (size_t i = 0; i < sizeof(word_t); i++) {
    append_byte_hex(out, cap, pos, (uint8_t)(value >> (i * 8)));
  }
}

static word_t gdbstub_reg_value(unsigned regno, bool *ok) {
  if (regno < 32) {
    *ok = true;
    return cpu.gpr[regno];
  }
  if (regno == 32) {
    *ok = true;
    return cpu.pc;
  }
  *ok = false;
  return 0;
}

static void handle_read_all_regs(char *out, size_t cap) {
  size_t pos = 0;
  for (unsigned i = 0; i < 32; i++) {
    append_word_le(out, cap, &pos, cpu.gpr[i]);
  }
  append_word_le(out, cap, &pos, cpu.pc);
}

static void handle_read_one_reg(const char *payload, char *out, size_t cap) {
  char *end = NULL;
  unsigned long regno = strtoul(payload + 1, &end, 16);
  bool ok = false;
  word_t value = gdbstub_reg_value((unsigned)regno, &ok);
  if (!ok || end == payload + 1 || *end != '\0') {
    out[0] = '\0';
    return;
  }
  size_t pos = 0;
  append_word_le(out, cap, &pos, value);
}

static void handle_read_memory(const char *payload, char *out, size_t cap) {
  char *end = NULL;
  uint64_t addr = strtoull(payload + 1, &end, 16);
  if (end == payload + 1 || *end != ',') {
    snprintf(out, cap, "E01");
    return;
  }
  uint64_t len = strtoull(end + 1, &end, 16);
  if (*end != '\0') {
    snprintf(out, cap, "E01");
    return;
  }
  if (len > 2048 || (len > 0 && addr > UINT64_MAX - len + 1)) {
    snprintf(out, cap, "E22");
    return;
  }

  paddr_t start = (paddr_t)addr;
  paddr_t last = (paddr_t)(addr + len - 1);
  if (len > 0 && (!in_pmem(start) || !in_pmem(last))) {
    snprintf(out, cap, "E14");
    return;
  }

  size_t pos = 0;
  uint8_t *base = len == 0 ? NULL : guest_to_host(start);
  for (uint64_t i = 0; i < len; i++) {
    append_byte_hex(out, cap, &pos, base[i]);
  }
}

static bool handle_packet(int fd, const char *payload) {
  char reply[8192];
  reply[0] = '\0';

  if (strcmp(payload, "?") == 0) {
    snprintf(reply, sizeof(reply), "S05");
  } else if (strcmp(payload, "qSupported") == 0 ||
             strncmp(payload, "qSupported:", 11) == 0) {
    snprintf(reply, sizeof(reply), "PacketSize=4000;qXfer:features:read-;swbreak-;hwbreak-");
  } else if (strcmp(payload, "qAttached") == 0) {
    snprintf(reply, sizeof(reply), "1");
  } else if (strcmp(payload, "qC") == 0) {
    snprintf(reply, sizeof(reply), "QC1");
  } else if (payload[0] == 'H') {
    snprintf(reply, sizeof(reply), "OK");
  } else if (strcmp(payload, "g") == 0) {
    handle_read_all_regs(reply, sizeof(reply));
  } else if (payload[0] == 'p') {
    handle_read_one_reg(payload, reply, sizeof(reply));
  } else if (payload[0] == 'm') {
    handle_read_memory(payload, reply, sizeof(reply));
  } else if (payload[0] == 'D') {
    (void)send_packet(fd, "OK");
    Log("GDB stub detached");
    return false;
  } else if (payload[0] == 'c') {
    // 当前基线只提供启动前调试握手；continue 后退出 stub，让 NEMU 回到原有 monitor/batch 流程。
    Log("GDB stub continue requested");
    return false;
  } else if (strcmp(payload, "vMustReplyEmpty") == 0 ||
             strncmp(payload, "qXfer:features:read:", 20) == 0) {
    reply[0] = '\0';
  } else {
    reply[0] = '\0';
  }

  return send_packet(fd, reply);
}

void gdbstub_wait_for_client_if_enabled(void) {
  if (!gdbstub_is_enabled()) {
    return;
  }

  int listen_fd = socket(AF_INET, SOCK_STREAM, 0);
  Assert(listen_fd >= 0, "Can not create gdbstub socket");

  int yes = 1;
  setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

  struct sockaddr_in addr = {};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons((uint16_t)gdbstub_port);
  int rc = bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr));
  Assert(rc == 0, "Can not bind gdbstub port %d", gdbstub_port);
  rc = listen(listen_fd, 1);
  Assert(rc == 0, "Can not listen on gdbstub port %d", gdbstub_port);

  Log("GDB stub listening on 127.0.0.1:%d (%s)", gdbstub_port, gdbstub_capability());
  int client_fd = accept(listen_fd, NULL, NULL);
  Assert(client_fd >= 0, "Can not accept gdbstub client");
  close(listen_fd);
  Log("GDB stub client connected");

  char payload[4096];
  while (read_packet(client_fd, payload, sizeof(payload))) {
    if (!handle_packet(client_fd, payload)) {
      break;
    }
  }

  close(client_fd);
}

#else

void gdbstub_set_port(int port) {
  (void)port;
}

bool gdbstub_is_enabled(void) {
  return false;
}

const char *gdbstub_capability(void) {
  return "unsupported";
}

void gdbstub_wait_for_client_if_enabled(void) {
}

#endif
