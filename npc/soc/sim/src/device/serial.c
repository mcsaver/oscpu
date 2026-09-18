/* NPC 串口设备
 * 学习 NEMU 的 IO/设备分层：每个设备独立成文件，
 * 在 init 中通过 npc_add_mmio_map() 自行注册到 MMIO 总线。
 * 设备行为（回调）与 IO 基础设施（map.c）彻底解耦。 */
#include "device/map.h"
#include "monitor/log.h"
#include "utils.h"

#include <stdint.h>

/* ---- MMIO 回调 ---- */
static uint32_t serial_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque; (void)error;
  if (offset == 4) return 0x00006000u; /* LSR THRE/TEMT */
  return 0;
}

static void serial_write_cb(void *opaque, uint32_t offset, uint32_t data,
                             uint32_t mask, bool *error) {
  (void)opaque; (void)error;
  for (int lane = 0; lane < 4; ++lane) {
    if (!(mask & (1u << lane))) continue;
    if (offset + (uint32_t)lane == 0) {
      npc_log_putchar((char)((data >> (lane * 8)) & 0xffu));
    }
  }
}

/* ---- 设备接口 ---- */
void npc_init_serial(void) {
  npc_add_mmio_map("serial", NPC_SERIAL_PORT, 8, NULL,
                   serial_read_cb, serial_write_cb);
}
