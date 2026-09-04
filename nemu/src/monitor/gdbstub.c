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

#include <cpu/cpu.h>
#include <isa.h>
#include <memory/paddr.h>
#include <utils.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int gdbstub_port = 0;
bool gdbstub_runtime_enabled = false;
static int gdbstub_client_fd = -1;
// no-ack 是单个 GDB remote 连接的协商状态，不能跨连接继承。
static bool gdbstub_no_ack_mode = false;

#define GDBSTUB_MAX_BREAKPOINTS 32
#define GDBSTUB_POINT_SW_BREAK 0
#define GDBSTUB_POINT_HW_BREAK 1
#define GDBSTUB_POINT_WRITE_WATCH 2
#define GDBSTUB_POINT_READ_WATCH 3
#define GDBSTUB_POINT_ACCESS_WATCH 4

typedef struct {
  bool used;
  uint8_t type;
  vaddr_t addr;
  uint32_t kind;
} GdbstubBreakpoint;

static GdbstubBreakpoint gdbstub_breakpoints[GDBSTUB_MAX_BREAKPOINTS];

void gdbstub_set_port(int port) {
  Assert(port > 0 && port <= 65535, "invalid --gdbstub port: %d", port);
  gdbstub_port = port;
  gdbstub_runtime_enabled = true;
}

bool gdbstub_is_enabled(void) {
  return gdbstub_port > 0;
}

const char *gdbstub_capability(void) {
  return "remote-startup-rw-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack";
}

static void gdbstub_clear_breakpoints(void) {
  memset(gdbstub_breakpoints, 0, sizeof(gdbstub_breakpoints));
}

bool gdbstub_breakpoint_hit(vaddr_t pc) {
  if (!gdbstub_is_enabled()) {
    return false;
  }

  for (size_t i = 0; i < GDBSTUB_MAX_BREAKPOINTS; i++) {
    if (gdbstub_breakpoints[i].used &&
        (gdbstub_breakpoints[i].type == GDBSTUB_POINT_SW_BREAK ||
         gdbstub_breakpoints[i].type == GDBSTUB_POINT_HW_BREAK) &&
        gdbstub_breakpoints[i].addr == pc) {
      return true;
    }
  }
  return false;
}

static const char *gdbstub_point_type_name(uint8_t type) {
  switch (type) {
    case GDBSTUB_POINT_SW_BREAK: return "software breakpoint";
    case GDBSTUB_POINT_HW_BREAK: return "hardware breakpoint";
    case GDBSTUB_POINT_WRITE_WATCH: return "write watchpoint";
    case GDBSTUB_POINT_READ_WATCH: return "read watchpoint";
    case GDBSTUB_POINT_ACCESS_WATCH: return "access watchpoint";
    default: return "unknown point";
  }
}

static bool gdbstub_range_overlap(vaddr_t a_start, uint64_t a_len,
    vaddr_t b_start, uint64_t b_len) {
  if (a_len == 0 || b_len == 0) {
    return false;
  }
  uint64_t a0 = (uint64_t)a_start;
  uint64_t b0 = (uint64_t)b_start;
  uint64_t a1 = a0 + a_len;
  uint64_t b1 = b0 + b_len;
  if (a1 < a0) a1 = UINT64_MAX;
  if (b1 < b0) b1 = UINT64_MAX;
  return a0 < b1 && b0 < a1;
}

void gdbstub_watchpoint_after_access(vaddr_t addr, int len, bool is_write) {
  if (!gdbstub_is_enabled() || len <= 0 || nemu_state.state != NEMU_RUNNING) {
    return;
  }

  for (size_t i = 0; i < GDBSTUB_MAX_BREAKPOINTS; i++) {
    GdbstubBreakpoint *bp = &gdbstub_breakpoints[i];
    if (!bp->used) {
      continue;
    }
    bool kind_match =
      bp->type == GDBSTUB_POINT_ACCESS_WATCH ||
      (is_write && bp->type == GDBSTUB_POINT_WRITE_WATCH) ||
      (!is_write && bp->type == GDBSTUB_POINT_READ_WATCH);
    if (!kind_match) {
      continue;
    }
    if (!gdbstub_range_overlap(addr, (uint64_t)len, bp->addr, bp->kind)) {
      continue;
    }

    // GDB watchpoint 是数据访问后的 stop reply 基线：先让当前 load/store 完成，
    // 再停在下一条 PC，便于长跑 Ubuntu 中观察触发现场且避免改写取指路径。
    Log("GDB stub %s hit at addr = " FMT_WORD " len=%d pc=" FMT_WORD,
        gdbstub_point_type_name(bp->type), (word_t)addr, len, cpu.pc);
    nemu_state.state = NEMU_STOP;
    return;
  }
}

bool gdbstub_async_stop_requested(void) {
  if (gdbstub_client_fd < 0) {
    return false;
  }

  uint8_t ch = 0;
  ssize_t n;
  do {
    n = recv(gdbstub_client_fd, &ch, 1, MSG_DONTWAIT);
  } while (n < 0 && errno == EINTR);

  if (n < 0) {
    return errno != EAGAIN && errno != EWOULDBLOCK;
  }
  if (n == 0) {
    Log("GDB stub client disconnected during guest execution");
    return true;
  }

  // GDB remote 的运行中暂停是裸 0x03 字节，不带 RSP packet framing。
  // 在 CPU TB 边界轮询它，可以长跑 Ubuntu 时停机调试，同时不把 socket 读阻塞塞进热路径。
  if (ch == 0x03) {
    Log("GDB stub async interrupt requested");
    return true;
  }

  Log("GDB stub ignored unexpected async byte 0x%02x during guest execution", ch);
  return false;
}

static const char gdbstub_target_xml[] =
  "<?xml version=\"1.0\"?>\n"
  "<!DOCTYPE target SYSTEM \"gdb-target.dtd\">\n"
  "<target>\n"
  "  <architecture>riscv:rv64</architecture>\n"
  "  <feature name=\"org.gnu.gdb.riscv.cpu\">\n"
  "    <reg name=\"zero\" bitsize=\"64\" type=\"int\" regnum=\"0\"/>\n"
  "    <reg name=\"ra\" bitsize=\"64\" type=\"code_ptr\" regnum=\"1\"/>\n"
  "    <reg name=\"sp\" bitsize=\"64\" type=\"data_ptr\" regnum=\"2\"/>\n"
  "    <reg name=\"gp\" bitsize=\"64\" type=\"data_ptr\" regnum=\"3\"/>\n"
  "    <reg name=\"tp\" bitsize=\"64\" type=\"data_ptr\" regnum=\"4\"/>\n"
  "    <reg name=\"t0\" bitsize=\"64\" type=\"int\" regnum=\"5\"/>\n"
  "    <reg name=\"t1\" bitsize=\"64\" type=\"int\" regnum=\"6\"/>\n"
  "    <reg name=\"t2\" bitsize=\"64\" type=\"int\" regnum=\"7\"/>\n"
  "    <reg name=\"fp\" bitsize=\"64\" type=\"data_ptr\" regnum=\"8\"/>\n"
  "    <reg name=\"s1\" bitsize=\"64\" type=\"int\" regnum=\"9\"/>\n"
  "    <reg name=\"a0\" bitsize=\"64\" type=\"int\" regnum=\"10\"/>\n"
  "    <reg name=\"a1\" bitsize=\"64\" type=\"int\" regnum=\"11\"/>\n"
  "    <reg name=\"a2\" bitsize=\"64\" type=\"int\" regnum=\"12\"/>\n"
  "    <reg name=\"a3\" bitsize=\"64\" type=\"int\" regnum=\"13\"/>\n"
  "    <reg name=\"a4\" bitsize=\"64\" type=\"int\" regnum=\"14\"/>\n"
  "    <reg name=\"a5\" bitsize=\"64\" type=\"int\" regnum=\"15\"/>\n"
  "    <reg name=\"a6\" bitsize=\"64\" type=\"int\" regnum=\"16\"/>\n"
  "    <reg name=\"a7\" bitsize=\"64\" type=\"int\" regnum=\"17\"/>\n"
  "    <reg name=\"s2\" bitsize=\"64\" type=\"int\" regnum=\"18\"/>\n"
  "    <reg name=\"s3\" bitsize=\"64\" type=\"int\" regnum=\"19\"/>\n"
  "    <reg name=\"s4\" bitsize=\"64\" type=\"int\" regnum=\"20\"/>\n"
  "    <reg name=\"s5\" bitsize=\"64\" type=\"int\" regnum=\"21\"/>\n"
  "    <reg name=\"s6\" bitsize=\"64\" type=\"int\" regnum=\"22\"/>\n"
  "    <reg name=\"s7\" bitsize=\"64\" type=\"int\" regnum=\"23\"/>\n"
  "    <reg name=\"s8\" bitsize=\"64\" type=\"int\" regnum=\"24\"/>\n"
  "    <reg name=\"s9\" bitsize=\"64\" type=\"int\" regnum=\"25\"/>\n"
  "    <reg name=\"s10\" bitsize=\"64\" type=\"int\" regnum=\"26\"/>\n"
  "    <reg name=\"s11\" bitsize=\"64\" type=\"int\" regnum=\"27\"/>\n"
  "    <reg name=\"t3\" bitsize=\"64\" type=\"int\" regnum=\"28\"/>\n"
  "    <reg name=\"t4\" bitsize=\"64\" type=\"int\" regnum=\"29\"/>\n"
  "    <reg name=\"t5\" bitsize=\"64\" type=\"int\" regnum=\"30\"/>\n"
  "    <reg name=\"t6\" bitsize=\"64\" type=\"int\" regnum=\"31\"/>\n"
  "    <reg name=\"pc\" bitsize=\"64\" type=\"code_ptr\" regnum=\"32\"/>\n"
  "  </feature>\n"
  "</target>\n";

static size_t gdbstub_memory_map_xml(char *out, size_t cap) {
  int n = snprintf(out, cap,
      "<?xml version=\"1.0\"?>\n"
      "<!DOCTYPE memory-map PUBLIC \"+//IDN gnu.org//DTD GDB Memory Map V1.0//EN\" "
      "\"http://sourceware.org/gdb/gdb-memory-map.dtd\">\n"
      "<memory-map>\n"
      "  <memory type=\"ram\" start=\"0x%llx\" length=\"0x%llx\"/>\n"
      "</memory-map>\n",
      (unsigned long long)CONFIG_MBASE,
      (unsigned long long)CONFIG_MSIZE);
  if (n < 0) {
    if (cap > 0) out[0] = '\0';
    return 0;
  }
  if ((size_t)n >= cap) {
    return cap > 0 ? cap - 1 : 0;
  }
  return (size_t)n;
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
    if (!gdbstub_no_ack_mode) {
      (void)write_all(fd, "-", 1);
    }
    return false;
  }

  if (!gdbstub_no_ack_mode) {
    (void)write_all(fd, "+", 1);
  }
  return true;
}

static bool send_packet(int fd, const char *payload) {
  uint8_t sum = 0;
  for (const char *p = payload; *p != '\0'; p++) {
    sum += (uint8_t)*p;
  }

  char trailer[4] = {'#', hex_digit(sum >> 4), hex_digit(sum), '\0'};
  size_t payload_len = strlen(payload);
  if (write_all(fd, "$", 1) <= 0) return false;
  if (payload_len > 0 && write_all(fd, payload, payload_len) <= 0) return false;
  if (write_all(fd, trailer, 3) <= 0) return false;

  if (gdbstub_no_ack_mode) {
    return true;
  }
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

static void append_ascii_hex(char *out, size_t cap, size_t *pos, const char *text) {
  for (const char *p = text; *p != '\0'; p++) {
    append_byte_hex(out, cap, pos, (uint8_t)*p);
  }
}

static bool parse_byte_hex(const char *hex, uint8_t *value) {
  int hi = hex_value((unsigned char)hex[0]);
  int lo = hex_value((unsigned char)hex[1]);
  if (hi < 0 || lo < 0) {
    return false;
  }
  *value = (uint8_t)((hi << 4) | lo);
  return true;
}

static bool parse_word_le_hex(const char *hex, word_t *value) {
  word_t result = 0;
  for (size_t i = 0; i < sizeof(word_t); i++) {
    uint8_t byte = 0;
    if (!parse_byte_hex(hex + i * 2, &byte)) {
      return false;
    }
    result |= (word_t)byte << (i * 8);
  }
  *value = result;
  return true;
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

static void handle_write_one_reg(const char *payload, char *out, size_t cap) {
  char *end = NULL;
  unsigned long regno = strtoul(payload + 1, &end, 16);
  if (end == payload + 1 || *end != '=') {
    snprintf(out, cap, "E01");
    return;
  }

  const char *hex = end + 1;
  if (strlen(hex) != sizeof(word_t) * 2) {
    snprintf(out, cap, "E22");
    return;
  }

  word_t value = 0;
  if (!parse_word_le_hex(hex, &value)) {
    snprintf(out, cap, "E01");
    return;
  }

  if (regno < 32) {
    if (regno != 0) {
      cpu.gpr[regno] = value;
    }
    snprintf(out, cap, "OK");
    return;
  }
  if (regno == 32) {
    cpu.pc = value;
    snprintf(out, cap, "OK");
    return;
  }

  snprintf(out, cap, "E14");
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

static void handle_write_memory(const char *payload, char *out, size_t cap) {
  char *end = NULL;
  uint64_t addr = strtoull(payload + 1, &end, 16);
  if (end == payload + 1 || *end != ',') {
    snprintf(out, cap, "E01");
    return;
  }
  uint64_t len = strtoull(end + 1, &end, 16);
  if (*end != ':') {
    snprintf(out, cap, "E01");
    return;
  }
  const char *hex = end + 1;
  if (len > 2048 || (len > 0 && addr > UINT64_MAX - len + 1) ||
      strlen(hex) != len * 2) {
    snprintf(out, cap, "E22");
    return;
  }

  paddr_t start = (paddr_t)addr;
  paddr_t last = (paddr_t)(addr + len - 1);
  if (len > 0 && (!in_pmem(start) || !in_pmem(last))) {
    snprintf(out, cap, "E14");
    return;
  }

  uint8_t *base = len == 0 ? NULL : guest_to_host(start);
  for (uint64_t i = 0; i < len; i++) {
    uint8_t byte = 0;
    if (!parse_byte_hex(hex + i * 2, &byte)) {
      snprintf(out, cap, "E01");
      return;
    }
    base[i] = byte;
  }
  snprintf(out, cap, "OK");
}

static void handle_qxfer_buffer_read(const char *spec, const char *buf,
    size_t buf_len, char *out, size_t cap) {
  char *end = NULL;
  uint64_t offset = strtoull(spec, &end, 16);
  if (end == spec || *end != ',') {
    snprintf(out, cap, "E01");
    return;
  }
  const char *len_start = end + 1;
  uint64_t len = strtoull(len_start, &end, 16);
  if (end == len_start || *end != '\0') {
    snprintf(out, cap, "E01");
    return;
  }

  if (offset >= buf_len || len == 0) {
    snprintf(out, cap, "l");
    return;
  }

  size_t max_chunk = cap > 2 ? cap - 2 : 0;
  size_t remaining = buf_len - (size_t)offset;
  size_t chunk = len < remaining ? (size_t)len : remaining;
  if (chunk > max_chunk) {
    chunk = max_chunk;
  }

  out[0] = chunk < remaining ? 'm' : 'l';
  memcpy(out + 1, buf + offset, chunk);
  out[chunk + 1] = '\0';
}

static void handle_qxfer_features_read(const char *payload, char *out, size_t cap) {
  const char prefix[] = "qXfer:features:read:";
  const char target_annex[] = "target.xml";
  const char *annex = payload + sizeof(prefix) - 1;
  const char *spec = strchr(annex, ':');
  if (spec == NULL) {
    out[0] = '\0';
    return;
  }

  size_t annex_len = (size_t)(spec - annex);
  if (annex_len != sizeof(target_annex) - 1 ||
      strncmp(annex, target_annex, annex_len) != 0) {
    out[0] = '\0';
    return;
  }

  handle_qxfer_buffer_read(spec + 1, gdbstub_target_xml,
      sizeof(gdbstub_target_xml) - 1, out, cap);
}

static void handle_qxfer_memory_map_read(const char *payload, char *out, size_t cap) {
  const char prefix[] = "qXfer:memory-map:read:";
  const char *annex = payload + sizeof(prefix) - 1;
  const char *spec = strchr(annex, ':');
  if (spec == NULL) {
    out[0] = '\0';
    return;
  }
  if (spec != annex) {
    out[0] = '\0';
    return;
  }

  char xml[512];
  size_t xml_len = gdbstub_memory_map_xml(xml, sizeof(xml));
  handle_qxfer_buffer_read(spec + 1, xml, xml_len, out, cap);
}

static void handle_breakpoint_packet(const char *payload, char *out, size_t cap) {
  bool insert = payload[0] == 'Z';
  if ((payload[1] < '0' || payload[1] > '4') || payload[2] != ',') {
    out[0] = '\0';
    return;
  }
  uint8_t type = (uint8_t)(payload[1] - '0');
  const char *type_name = gdbstub_point_type_name(type);

  char *end = NULL;
  uint64_t addr = strtoull(payload + 3, &end, 16);
  if (end == payload + 3 || *end != ',') {
    snprintf(out, cap, "E01");
    return;
  }
  const char *kind_start = end + 1;
  uint64_t kind = strtoull(kind_start, &end, 16);
  if (end == kind_start || *end != '\0') {
    snprintf(out, cap, "E01");
    return;
  }
  if (kind == 0 || kind > 4096) {
    snprintf(out, cap, "E22");
    return;
  }

  if (insert) {
    for (size_t i = 0; i < GDBSTUB_MAX_BREAKPOINTS; i++) {
      if (gdbstub_breakpoints[i].used && gdbstub_breakpoints[i].type == type &&
          gdbstub_breakpoints[i].addr == (vaddr_t)addr) {
        snprintf(out, cap, "OK");
        return;
      }
    }

    for (size_t i = 0; i < GDBSTUB_MAX_BREAKPOINTS; i++) {
      if (!gdbstub_breakpoints[i].used) {
        gdbstub_breakpoints[i].used = true;
        gdbstub_breakpoints[i].type = type;
        gdbstub_breakpoints[i].addr = (vaddr_t)addr;
        gdbstub_breakpoints[i].kind = (uint32_t)kind;
        Log("GDB stub inserted %s at " FMT_WORD " kind=%u",
            type_name, (word_t)addr, (uint32_t)kind);
        snprintf(out, cap, "OK");
        return;
      }
    }

    snprintf(out, cap, "E22");
    return;
  }

  for (size_t i = 0; i < GDBSTUB_MAX_BREAKPOINTS; i++) {
    if (gdbstub_breakpoints[i].used && gdbstub_breakpoints[i].type == type &&
        gdbstub_breakpoints[i].addr == (vaddr_t)addr) {
      gdbstub_breakpoints[i].used = false;
      Log("GDB stub removed %s at " FMT_WORD, type_name, (word_t)addr);
      break;
    }
  }
  snprintf(out, cap, "OK");
}

static bool thread_part_matches_single_hart(const char *start, size_t len) {
  if (len == 0) {
    return true;
  }
  if (len == 1 && (start[0] == '0' || start[0] == '1')) {
    return true;
  }
  if (len == 2 && start[0] == '-' && start[1] == '1') {
    return true;
  }
  return false;
}

static bool thread_spec_matches_single_hart(const char *start, size_t len) {
  if (thread_part_matches_single_hart(start, len)) {
    return true;
  }

  if (len > 1 && start[0] == 'p') {
    const char *dot = memchr(start, '.', len);
    if (dot == NULL) {
      return thread_part_matches_single_hart(start + 1, len - 1);
    }
    size_t pid_len = (size_t)(dot - start - 1);
    size_t tid_len = len - pid_len - 2;
    return thread_part_matches_single_hart(start + 1, pid_len) &&
           thread_part_matches_single_hart(dot + 1, tid_len);
  }

  return false;
}

static void handle_thread_info_packet(const char *payload, char *out, size_t cap) {
  if (strcmp(payload, "qfThreadInfo") == 0) {
    snprintf(out, cap, "m1");
  } else if (strcmp(payload, "qsThreadInfo") == 0) {
    snprintf(out, cap, "l");
  } else if (strncmp(payload, "qThreadExtraInfo,", 17) == 0) {
    const char *thread = payload + 17;
    if (thread_spec_matches_single_hart(thread, strlen(thread))) {
      size_t pos = 0;
      append_ascii_hex(out, cap, &pos, "NEMU single hart");
    } else {
      out[0] = '\0';
    }
  } else if (payload[0] == 'T') {
    const char *thread = payload + 1;
    if (thread_spec_matches_single_hart(thread, strlen(thread))) {
      snprintf(out, cap, "OK");
    } else {
      snprintf(out, cap, "E01");
    }
  } else {
    out[0] = '\0';
  }
}

static bool parse_optional_exec_addr(const char *payload, word_t *addr) {
  if (payload[1] == '\0') {
    return true;
  }

  char *end = NULL;
  uint64_t value = strtoull(payload + 1, &end, 16);
  if (end == payload + 1 || *end != '\0') {
    return false;
  }
  *addr = (word_t)value;
  return true;
}

static void format_exec_stop_reply(char *out, size_t cap) {
  switch (atomic_load(&nemu_state.state)) {
    case NEMU_STOP:
      snprintf(out, cap, "S05");
      break;
    case NEMU_END:
      snprintf(out, cap, "W%02x", nemu_state.halt_ret & 0xff);
      break;
    case NEMU_ABORT:
      snprintf(out, cap, "X09");
      break;
    case NEMU_QUIT:
      snprintf(out, cap, "W00");
      break;
    case NEMU_REBOOT:
      snprintf(out, cap, "W%02x", NEMU_REBOOT_EXIT_STATUS);
      break;
    default:
      snprintf(out, cap, "S05");
      break;
  }
}

static bool exec_reply_is_terminal(const char *reply) {
  return reply[0] == 'W' || reply[0] == 'X';
}

static void handle_single_step(const char *payload, char *out, size_t cap) {
  word_t addr = cpu.pc;
  if (!parse_optional_exec_addr(payload, &addr)) {
    snprintf(out, cap, "E01");
    return;
  }
  cpu.pc = addr;

  cpu_exec(1);
  format_exec_stop_reply(out, cap);
}

static void handle_continue(const char *payload, char *out, size_t cap) {
  word_t addr = cpu.pc;
  if (!parse_optional_exec_addr(payload, &addr)) {
    snprintf(out, cap, "E01");
    return;
  }
  cpu.pc = addr;

  Log("GDB stub continue requested");
  cpu_exec(UINT64_MAX);
  format_exec_stop_reply(out, cap);
}

static bool send_exec_reply(int fd, const char *reply) {
  bool ok = send_packet(fd, reply);
  return ok && !exec_reply_is_terminal(reply);
}

typedef enum {
  GDBSTUB_VCONT_NO_MATCH,
  GDBSTUB_VCONT_CONT,
  GDBSTUB_VCONT_STEP,
  GDBSTUB_VCONT_MALFORMED,
} GdbstubVcontAction;

static GdbstubVcontAction parse_vcont_segment(const char *segment, size_t len) {
  if (len == 0) {
    return GDBSTUB_VCONT_MALFORMED;
  }

  char kind = segment[0];
  if (kind != 'c' && kind != 's' && kind != 'C' && kind != 'S') {
    return GDBSTUB_VCONT_NO_MATCH;
  }

  size_t pos = 1;
  if (kind == 'C' || kind == 'S') {
    size_t signal_start = pos;
    while (pos < len && segment[pos] != ':') {
      if (hex_value((unsigned char)segment[pos]) < 0) {
        return GDBSTUB_VCONT_MALFORMED;
      }
      pos++;
    }
    if (pos == signal_start) {
      return GDBSTUB_VCONT_MALFORMED;
    }
  }

  if (pos < len) {
    if (segment[pos] != ':') {
      return GDBSTUB_VCONT_MALFORMED;
    }
    pos++;
    if (!thread_spec_matches_single_hart(segment + pos, len - pos)) {
      return GDBSTUB_VCONT_NO_MATCH;
    }
  }

  return (kind == 'c' || kind == 'C') ? GDBSTUB_VCONT_CONT : GDBSTUB_VCONT_STEP;
}

static bool handle_vcont_packet(int fd, const char *payload) {
  char reply[8192];

  if (strcmp(payload, "vCont?") == 0) {
    return send_packet(fd, "vCont;c;s");
  }
  if (strncmp(payload, "vCont;", 6) != 0) {
    return send_packet(fd, "");
  }

  // 目前 NEMU 只暴露单 hart，vCont 只把匹配当前 hart 的 c/s 映射到既有同步执行路径。
  const char *segment = payload + 6;
  while (*segment != '\0') {
    const char *end = strchr(segment, ';');
    size_t len = end == NULL ? strlen(segment) : (size_t)(end - segment);
    GdbstubVcontAction action = parse_vcont_segment(segment, len);
    if (action == GDBSTUB_VCONT_MALFORMED) {
      return send_packet(fd, "E01");
    }
    if (action == GDBSTUB_VCONT_CONT) {
      handle_continue("c", reply, sizeof(reply));
      return send_exec_reply(fd, reply);
    }
    if (action == GDBSTUB_VCONT_STEP) {
      handle_single_step("s", reply, sizeof(reply));
      return send_exec_reply(fd, reply);
    }
    if (end == NULL) {
      break;
    }
    segment = end + 1;
  }

  return send_packet(fd, "E01");
}

static bool handle_packet(int fd, const char *payload) {
  char reply[8192];
  reply[0] = '\0';

  if (strcmp(payload, "?") == 0) {
    snprintf(reply, sizeof(reply), "S05");
  } else if (strcmp(payload, "qSupported") == 0 ||
             strncmp(payload, "qSupported:", 11) == 0) {
    snprintf(reply, sizeof(reply),
             "PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+");
  } else if (strcmp(payload, "QStartNoAckMode") == 0) {
    bool ok = send_packet(fd, "OK");
    if (ok) {
      gdbstub_no_ack_mode = true;
      Log("GDB stub no-ack mode enabled");
    }
    return ok;
  } else if (strcmp(payload, "qAttached") == 0) {
    snprintf(reply, sizeof(reply), "1");
  } else if (strcmp(payload, "qC") == 0) {
    snprintf(reply, sizeof(reply), "QC1");
  } else if (strcmp(payload, "qfThreadInfo") == 0 ||
             strcmp(payload, "qsThreadInfo") == 0 ||
             strncmp(payload, "qThreadExtraInfo,", 17) == 0 ||
             payload[0] == 'T') {
    handle_thread_info_packet(payload, reply, sizeof(reply));
  } else if (payload[0] == 'H') {
    snprintf(reply, sizeof(reply), "OK");
  } else if (strcmp(payload, "g") == 0) {
    handle_read_all_regs(reply, sizeof(reply));
  } else if (payload[0] == 'p') {
    handle_read_one_reg(payload, reply, sizeof(reply));
  } else if (payload[0] == 'P') {
    handle_write_one_reg(payload, reply, sizeof(reply));
  } else if (payload[0] == 'm') {
    handle_read_memory(payload, reply, sizeof(reply));
  } else if (payload[0] == 'M') {
    handle_write_memory(payload, reply, sizeof(reply));
  } else if (payload[0] == 's') {
    handle_single_step(payload, reply, sizeof(reply));
    return send_exec_reply(fd, reply);
  } else if (payload[0] == 'Z' || payload[0] == 'z') {
    handle_breakpoint_packet(payload, reply, sizeof(reply));
  } else if (payload[0] == 'D') {
    gdbstub_clear_breakpoints();
    (void)send_packet(fd, "OK");
    Log("GDB stub detached");
    return false;
  } else if (payload[0] == 'c') {
    handle_continue(payload, reply, sizeof(reply));
    return send_exec_reply(fd, reply);
  } else if (strncmp(payload, "vCont", 5) == 0) {
    return handle_vcont_packet(fd, payload);
  } else if (strncmp(payload, "qXfer:features:read:", 20) == 0) {
    handle_qxfer_features_read(payload, reply, sizeof(reply));
  } else if (strncmp(payload, "qXfer:memory-map:read:", 22) == 0) {
    handle_qxfer_memory_map_read(payload, reply, sizeof(reply));
  } else if (strcmp(payload, "vMustReplyEmpty") == 0) {
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

  gdbstub_clear_breakpoints();
  gdbstub_no_ack_mode = false;
  Log("GDB stub listening on 127.0.0.1:%d (%s)", gdbstub_port, gdbstub_capability());
  int client_fd = accept(listen_fd, NULL, NULL);
  Assert(client_fd >= 0, "Can not accept gdbstub client");
  close(listen_fd);
  Log("GDB stub client connected");
  gdbstub_client_fd = client_fd;

  char payload[4096];
  while (read_packet(client_fd, payload, sizeof(payload))) {
    if (!handle_packet(client_fd, payload)) {
      break;
    }
  }

  gdbstub_client_fd = -1;
  gdbstub_no_ack_mode = false;
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

bool gdbstub_breakpoint_hit(vaddr_t pc) {
  (void)pc;
  return false;
}

void gdbstub_watchpoint_after_access(vaddr_t addr, int len, bool is_write) {
  (void)addr;
  (void)len;
  (void)is_write;
}

bool gdbstub_async_stop_requested(void) {
  return false;
}

#endif
