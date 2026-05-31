/* NPC RTC 定时器设备
 * 学习 NEMU 的 IO/设备分层：设备行为独立，自行注册到总线。
 * 读操作触发 npc_get_time_us() 返回宿主时间戳。 */
#include "device/map.h"
#include "utils.h"

#include <stdint.h>

/* ---- MMIO 回调 ---- */
static uint32_t rtc_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque; (void)error;
  uint64_t now = npc_get_time_us();
  return (offset == 4) ? (uint32_t)(now >> 32) : (uint32_t)(now & 0xffffffffu);
}

static void rtc_write_cb(void *o, uint32_t off, uint32_t d, uint32_t m, bool *e) {
  (void)o; (void)off; (void)d; (void)m; (void)e;
}

/* ---- 设备接口 ---- */
void npc_init_timer(void) {
  npc_add_mmio_map("rtc", NPC_RTC_ADDR, 8, NULL,
                   rtc_read_cb, rtc_write_cb);
}
