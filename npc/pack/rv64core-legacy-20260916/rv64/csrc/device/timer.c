/* NPC RTC 定时器设备
 * 学习 NEMU 的 IO/设备分层：设备行为独立，自行注册到总线。
 * 读操作触发 npc_get_time_us() 返回宿主时间戳。 */
#include "device/map.h"
#include "utils.h"

#include <stdint.h>

/* ---- MMIO 回调 ---- */
/* uptime 时基:仿真没有"与宿主无关的真实墙钟"。默认用 guest cycle 计数折算 uptime
 * (1 cycle ↦ 1 μs,标称 1 MHz):确定性、可复现,且让 CoreMark 等基准量到的是
 * "被仿真核心要花的 guest 时间"而非"宿主跑这次仿真的耗时"——后者在 ~200k inst/s 的
 * RTL 仿真下(host 时间 ≫ guest 时间)会把分值彻底压垮(原来 CoreMark 只报 1 Marks)。
 * CoreMark/MHz、CPI 等频率无关指标不受该时基取值影响。
 * 定义 NPC_RTC_USE_HOST_TIME 可回退到 clock_gettime 宿主墙钟(交互式 demo 实时节奏用)。 */
static uint32_t rtc_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque; (void)error;
#ifdef NPC_RTC_USE_HOST_TIME
  uint64_t now = npc_get_time_us();
#else
  uint64_t now = npc_stats()->cycles;   /* 1 cycle ↦ 1 μs */
#endif
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
