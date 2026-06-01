/* NPC DPI-C 总线回调 — C 重构版
 * Verilator 用 g++ 编译所有源文件（含 .c），需要 extern "C" 保证 DPI 函数为 C 链接。 */
#include <svdpi.h>
#include <stdint.h>
#include <stdlib.h>

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

#ifdef __cplusplus
}
#endif
