/* NPC DPI-C 总线回调 — C 重构版
 * Verilator 用 g++ 编译所有源文件（含 .c），需要 extern "C" 保证 DPI 函数为 C 链接。 */
#include <svdpi.h>
#include <stdint.h>

#include "cpu/difftest.h"
#include "memory/paddr.h"
#include "monitor/log.h"
#include "utils.h"

#ifdef __cplusplus
extern "C" {
#endif

void npc_ifetch(uint32_t addr, uint32_t *data, svBit *error) {
  if (data == NULL || error == NULL) return;
  *data = 0;
  *error = 0;
  if ((addr & 0x1u) != 0) { *error = 1; return; }
  if (!npc_paddr_read(addr, data, NPC_BUS_IFETCH)) { *error = 1; }
}

void npc_mem_read(uint32_t addr, uint32_t *data, svBit *error) {
  if (data == NULL || error == NULL) return;
  *data = 0;
  *error = 0;
  if ((addr & 0x3u) != 0) { *error = 1; return; }
  if (!npc_paddr_read(addr, data, NPC_BUS_LOAD)) { *error = 1; }
}

void npc_mem_write(uint32_t addr, uint32_t data, uint32_t mask, svBit *error) {
  if (error == NULL) return;
  *error = 0;
  mask &= 0xfu;
  if ((addr & 0x3u) != 0) { *error = 1; return; }
  if (mask == 0) return;
  if (!npc_paddr_write(addr, data, mask, NPC_BUS_STORE)) { *error = 1; }
}

void npc_uart_event(uint32_t is_write, uint32_t tx_valid, uint32_t tx_data) {
  (void)is_write;
  npc_difftest_skip_ref();
  if (tx_valid) {
    npc_log_putchar((char)(tx_data & 0xffu));
  }
}

#ifdef __cplusplus
}
#endif
