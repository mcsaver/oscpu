/* NPC DPI-C 总线回调 — C 重构版
 * Verilator 用 g++ 编译所有源文件（含 .c），需要 extern "C" 保证 DPI 函数为 C 链接。 */
#include <svdpi.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cpu/difftest.h"
#include "memory/paddr.h"
#include "monitor/log.h"
#include "utils.h"

#ifdef __cplusplus
extern "C" {
#endif

static bool g_uart_tx_trace_inited = false;
static bool g_uart_tx_trace_enabled = false;
static uint64_t g_uart_tx_trace_min_commit = 0;
static uint64_t g_uart_tx_trace_limit = 128;
static uint64_t g_uart_tx_trace_count = 0;
static bool g_uart_access_trace_enabled = false;
static uint64_t g_uart_access_trace_min_commit = 0;
static uint64_t g_uart_access_trace_limit = 256;
static uint64_t g_uart_access_trace_count = 0;
static bool g_irq_trace_enabled = false;
static uint64_t g_irq_trace_min_commit = 0;
static uint64_t g_irq_trace_limit = 128;
static uint64_t g_irq_trace_count = 0;
static bool g_uart_rx_inited = false;
static bool g_uart_rx_trace_enabled = false;
static uint64_t g_uart_rx_trace_min_commit = 0;
static uint64_t g_uart_rx_trace_limit = 128;
static uint64_t g_uart_rx_trace_count = 0;
static uint64_t g_uart_rx_cycle_gap = 0;
static uint64_t g_uart_rx_next_cycle = 0;
static uint8_t *g_uart_rx_buf = NULL;
static size_t g_uart_rx_len = 0;
static size_t g_uart_rx_pos = 0;
static bool g_uart_rx_wait_logged = false;
static bool g_uart_rx_wait_release_logged = false;

static void append_uart_rx_bytes(const uint8_t *data, size_t len) {
  if (data == NULL || len == 0) return;
  if (len > ((size_t)-1) - g_uart_rx_len) {
    LogBothTag("uart-rx", "input too large, drop len=%llu",
               (unsigned long long)len);
    return;
  }
  uint8_t *next =
      (uint8_t *)realloc(g_uart_rx_buf, g_uart_rx_len + len);
  if (next == NULL) {
    LogBothTag("uart-rx", "failed to allocate len=%llu",
               (unsigned long long)(g_uart_rx_len + len));
    return;
  }
  memcpy(next + g_uart_rx_len, data, len);
  g_uart_rx_buf = next;
  g_uart_rx_len += len;
}

static size_t append_uart_rx_file(const char *path) {
  if (path == NULL || path[0] == '\0') return 0;

  FILE *fp = fopen(path, "rb");
  if (fp == NULL) {
    LogBothTag("uart-rx", "failed to open NPC_UART_RX_FILE=%s", path);
    return 0;
  }

  if (fseek(fp, 0, SEEK_END) != 0) {
    fclose(fp);
    LogBothTag("uart-rx", "failed to seek NPC_UART_RX_FILE=%s", path);
    return 0;
  }
  long file_len_l = ftell(fp);
  if (file_len_l <= 0) {
    fclose(fp);
    return 0;
  }
  rewind(fp);

  size_t file_len = (size_t)file_len_l;
  uint8_t *tmp = (uint8_t *)malloc(file_len);
  if (tmp == NULL) {
    fclose(fp);
    LogBothTag("uart-rx", "failed to allocate file len=%llu path=%s",
               (unsigned long long)file_len, path);
    return 0;
  }

  size_t got = fread(tmp, 1, file_len, fp);
  fclose(fp);
  append_uart_rx_bytes(tmp, got);
  free(tmp);
  return got;
}

static void init_uart_rx_source(void) {
  if (g_uart_rx_inited) return;
  g_uart_rx_inited = true;

  const char *trace_s = getenv("NPC_UART_RX_TRACE");
  g_uart_rx_trace_enabled =
      trace_s != NULL && trace_s[0] != '\0' && trace_s[0] != '0';
  const char *min_commit_s = getenv("NPC_UART_RX_TRACE_MIN_COMMIT");
  if (min_commit_s && min_commit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(min_commit_s, &end, 0);
    if (end != min_commit_s) g_uart_rx_trace_min_commit = value;
  }
  const char *limit_s = getenv("NPC_UART_RX_TRACE_LIMIT");
  if (limit_s && limit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(limit_s, &end, 0);
    if (end != limit_s) g_uart_rx_trace_limit = value;
  }
  const char *cycle_gap_s = getenv("NPC_UART_RX_CYCLE_GAP");
  if (cycle_gap_s && cycle_gap_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(cycle_gap_s, &end, 0);
    if (end != cycle_gap_s) g_uart_rx_cycle_gap = value;
  }

  size_t file_bytes = append_uart_rx_file(getenv("NPC_UART_RX_FILE"));
  const char *text = getenv("NPC_UART_RX_TEXT");
  size_t text_bytes = 0;
  if (text != NULL && text[0] != '\0') {
    text_bytes = strlen(text);
    append_uart_rx_bytes((const uint8_t *)text, text_bytes);
  }

  if (g_uart_rx_len > 0 || g_uart_rx_trace_enabled) {
    LogBothTag("uart-rx",
               "loaded bytes=%llu file_bytes=%llu text_bytes=%llu "
               "trace=%u min_commit=%llu limit=%llu cycle_gap=%llu "
               "wait='%s'",
               (unsigned long long)g_uart_rx_len,
               (unsigned long long)file_bytes,
               (unsigned long long)text_bytes,
               g_uart_rx_trace_enabled ? 1u : 0u,
               (unsigned long long)g_uart_rx_trace_min_commit,
               (unsigned long long)g_uart_rx_trace_limit,
               (unsigned long long)g_uart_rx_cycle_gap,
               npc_uart_rx_wait_text());
  }
}

static void maybe_trace_uart_rx(uint32_t rx_data) {
  if (!g_uart_rx_trace_enabled) return;
  if (npc_stats()->commits < g_uart_rx_trace_min_commit) return;
  if (g_uart_rx_trace_limit > 0 &&
      g_uart_rx_trace_count >= g_uart_rx_trace_limit) {
    return;
  }

  uint32_t ch = rx_data & 0xffu;
  char printable = (ch >= 0x20u && ch <= 0x7eu) ? (char)ch : '.';
  LogBothTag("uart-rx",
             "pop=%llu cycle=%llu commit=%llu data=0x%02x char='%c'",
             (unsigned long long)(g_uart_rx_trace_count + 1),
             (unsigned long long)npc_stats()->cycles,
             (unsigned long long)npc_stats()->commits,
             ch, printable);
  g_uart_rx_trace_count++;
}

static void init_uart_tx_trace(void) {
  if (g_uart_tx_trace_inited) return;
  g_uart_tx_trace_inited = true;

  const char *trace_s = getenv("NPC_UART_TX_TRACE");
  g_uart_tx_trace_enabled =
      trace_s != NULL && trace_s[0] != '\0' && trace_s[0] != '0';
  const char *min_commit_s = getenv("NPC_UART_TX_TRACE_MIN_COMMIT");
  if (min_commit_s && min_commit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(min_commit_s, &end, 0);
    if (end != min_commit_s) g_uart_tx_trace_min_commit = value;
  }
  const char *limit_s = getenv("NPC_UART_TX_TRACE_LIMIT");
  if (limit_s && limit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(limit_s, &end, 0);
    if (end != limit_s) g_uart_tx_trace_limit = value;
  }
  const char *access_trace_s = getenv("NPC_UART_ACCESS_TRACE");
  g_uart_access_trace_enabled =
      access_trace_s != NULL && access_trace_s[0] != '\0' &&
      access_trace_s[0] != '0';
  const char *access_min_commit_s =
      getenv("NPC_UART_ACCESS_TRACE_MIN_COMMIT");
  if (access_min_commit_s && access_min_commit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(access_min_commit_s, &end, 0);
    if (end != access_min_commit_s) {
      g_uart_access_trace_min_commit = value;
    }
  }
  const char *access_limit_s = getenv("NPC_UART_ACCESS_TRACE_LIMIT");
  if (access_limit_s && access_limit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(access_limit_s, &end, 0);
    if (end != access_limit_s) g_uart_access_trace_limit = value;
  }
  const char *irq_trace_s = getenv("NPC_IRQ_TRACE");
  g_irq_trace_enabled =
      irq_trace_s != NULL && irq_trace_s[0] != '\0' &&
      irq_trace_s[0] != '0';
  const char *irq_min_commit_s = getenv("NPC_IRQ_TRACE_MIN_COMMIT");
  if (irq_min_commit_s && irq_min_commit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(irq_min_commit_s, &end, 0);
    if (end != irq_min_commit_s) g_irq_trace_min_commit = value;
  }
  const char *irq_limit_s = getenv("NPC_IRQ_TRACE_LIMIT");
  if (irq_limit_s && irq_limit_s[0] != '\0') {
    char *end = NULL;
    uint64_t value = strtoull(irq_limit_s, &end, 0);
    if (end != irq_limit_s) g_irq_trace_limit = value;
  }
  if (g_uart_tx_trace_enabled) {
    LogBothTag("uart-trace",
               "enabled min_commit=%llu limit=%llu",
               (unsigned long long)g_uart_tx_trace_min_commit,
               (unsigned long long)g_uart_tx_trace_limit);
  }
  if (g_uart_access_trace_enabled) {
    LogBothTag("uart-access",
               "enabled min_commit=%llu limit=%llu",
               (unsigned long long)g_uart_access_trace_min_commit,
               (unsigned long long)g_uart_access_trace_limit);
  }
  if (g_irq_trace_enabled) {
    LogBothTag("irq-trace",
               "enabled min_commit=%llu limit=%llu",
               (unsigned long long)g_irq_trace_min_commit,
               (unsigned long long)g_irq_trace_limit);
  }
}

static void maybe_trace_uart_tx(uint32_t tx_data) {
  init_uart_tx_trace();
  if (!g_uart_tx_trace_enabled) return;
  if (npc_stats()->commits < g_uart_tx_trace_min_commit) return;
  if (g_uart_tx_trace_limit > 0 &&
      g_uart_tx_trace_count >= g_uart_tx_trace_limit) {
    return;
  }

  uint32_t ch = tx_data & 0xffu;
  char printable = (ch >= 0x20u && ch <= 0x7eu) ? (char)ch : '.';
  LogBothTag("uart-trace",
             "tx=%llu cycle=%llu commit=%llu data=0x%02x char='%c'",
             (unsigned long long)(g_uart_tx_trace_count + 1),
             (unsigned long long)npc_stats()->cycles,
             (unsigned long long)npc_stats()->commits,
             ch, printable);
  g_uart_tx_trace_count++;
}

static void maybe_trace_uart_access(uint32_t is_write, uint32_t tx_valid,
                                    uint32_t tx_data, uint32_t access_addr,
                                    uint64_t access_wdata,
                                    uint32_t access_wstrb,
                                    uint64_t access_rdata) {
  init_uart_tx_trace();
  if (!g_uart_access_trace_enabled) return;
  if (npc_stats()->commits < g_uart_access_trace_min_commit) return;
  if (g_uart_access_trace_limit > 0 &&
      g_uart_access_trace_count >= g_uart_access_trace_limit) {
    return;
  }

  uint32_t ch = tx_data & 0xffu;
  char printable = (ch >= 0x20u && ch <= 0x7eu) ? (char)ch : '.';
  LogBothTag("uart-access",
             "access=%llu cycle=%llu commit=%llu %s addr=0x%03x "
             "wdata=0x%016llx wstrb=0x%x rdata=0x%016llx "
             "tx_valid=%u tx_data=0x%02x char='%c'",
             (unsigned long long)(g_uart_access_trace_count + 1),
             (unsigned long long)npc_stats()->cycles,
             (unsigned long long)npc_stats()->commits,
             is_write ? "write" : "read", access_addr & 0xfffu,
             (unsigned long long)access_wdata, access_wstrb,
             (unsigned long long)access_rdata, tx_valid ? 1u : 0u,
             ch, printable);
  g_uart_access_trace_count++;
}

void npc_ifetch(npc_paddr_t addr, npc_word_t *data, svBit *error) {
  if (data == NULL || error == NULL) return;
  *data = 0;
  *error = 0;
  if ((addr & 0x1u) != 0) { *error = 1; return; }
  if (!npc_paddr_read(addr, data, NPC_BUS_IFETCH)) { *error = 1; }
}

void npc_mem_read(npc_paddr_t addr, npc_word_t *data, svBit *error) {
  if (data == NULL || error == NULL) return;
  *data = 0;
  *error = 0;
  if ((addr & 0x7u) != 0) { *error = 1; return; }
  if (!npc_paddr_read(addr, data, NPC_BUS_LOAD)) { *error = 1; }
}

void npc_mem_write(npc_paddr_t addr, npc_word_t data, npc_word_t mask, svBit *error) {
  if (error == NULL) return;
  *error = 0;
  mask &= 0xffu;
  if ((addr & 0x7u) != 0) { *error = 1; return; }
  if (mask == 0) return;
  if (!npc_paddr_write(addr, data, mask, NPC_BUS_STORE)) { *error = 1; }
}

void npc_irq_event(uint32_t uart_irq, uint32_t plic_irq) {
  init_uart_tx_trace();
  if (!g_irq_trace_enabled) return;
  if (npc_stats()->commits < g_irq_trace_min_commit) return;
  if (g_irq_trace_limit > 0 && g_irq_trace_count >= g_irq_trace_limit) {
    return;
  }

  LogBothTag("irq-trace",
             "event=%llu cycle=%llu commit=%llu uart_irq=%u plic_irq=%u",
             (unsigned long long)(g_irq_trace_count + 1),
             (unsigned long long)npc_stats()->cycles,
             (unsigned long long)npc_stats()->commits,
             uart_irq ? 1u : 0u,
             plic_irq ? 1u : 0u);
  g_irq_trace_count++;
}

void npc_uart_event(uint32_t is_write, uint32_t tx_valid, uint32_t tx_data,
                    uint32_t access_addr, uint64_t access_wdata,
                    uint32_t access_wstrb, uint64_t access_rdata) {
  (void)is_write;
  maybe_trace_uart_access(is_write, tx_valid, tx_data, access_addr,
                          access_wdata, access_wstrb, access_rdata);
  npc_difftest_skip_ref();
  if (tx_valid) {
    maybe_trace_uart_tx(tx_data);
    npc_log_putchar((char)(tx_data & 0xffu));
  }
}

int npc_uart_rx_pop(uint32_t *data) {
  if (data == NULL) return 0;
  init_uart_rx_source();
  if (!npc_uart_rx_wait_satisfied()) {
    if (!g_uart_rx_wait_logged && g_uart_rx_len > 0) {
      LogBothTag("uart-rx",
                 "waiting for guest output pattern='%s' before releasing "
                 "bytes=%llu",
                 npc_uart_rx_wait_text(),
                 (unsigned long long)g_uart_rx_len);
      g_uart_rx_wait_logged = true;
    }
    *data = 0;
    return 0;
  }
  if (!g_uart_rx_wait_release_logged && g_uart_rx_wait_logged) {
    LogBothTag("uart-rx",
               "wait pattern matched; releasing input at cycle=%llu "
               "commit=%llu",
               (unsigned long long)npc_stats()->cycles,
               (unsigned long long)npc_stats()->commits);
    g_uart_rx_wait_release_logged = true;
  }
  if (g_uart_rx_pos >= g_uart_rx_len) {
    *data = 0;
    return 0;
  }
  if (g_uart_rx_cycle_gap > 0 &&
      npc_stats()->cycles < g_uart_rx_next_cycle) {
    *data = 0;
    return 0;
  }

  uint32_t ch = g_uart_rx_buf[g_uart_rx_pos++];
  *data = ch;
  if (g_uart_rx_cycle_gap > 0) {
    g_uart_rx_next_cycle = npc_stats()->cycles + g_uart_rx_cycle_gap;
  }
  maybe_trace_uart_rx(ch);
  return 1;
}

#ifdef __cplusplus
}
#endif
