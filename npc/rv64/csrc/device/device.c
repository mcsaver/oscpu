/* NPC 设备层编排入口
 * 学习 NEMU 的 IO/设备分层设计：device.c 只负责调用各设备的
 * init/update/fini，具体设备行为分散在各自的 .c 文件中。
 * IO 基础设施（地址映射和读写分发）由 map.c 单独管理。 */
#include "device/device.h"
#include "device/keyboard.h"
#include "device/vga.h"
#include "device/map.h"

/* timer.c 没有独立头文件——像 NEMU 一样直接前向声明。
 * serial 现由真 RTL UART(Uart.v @ 0x10000000)承载,输出/skip_ref 走 dpi.c 的
 * npc_uart_event,csrc 不再注册独立 serial 模型。 */
void npc_init_timer(void);

/* ==== 公共接口 ==== */
void npc_init_device(bool enable_stdin_keyboard, bool enable_vga) {
  npc_init_map();
  npc_init_timer();
  npc_kbd_init(enable_stdin_keyboard);
  npc_vga_init(enable_vga);
}

/* 设备轮询节流计数器——和 NEMU 一样按执行周期批量检查，避免每拍做一次 poll() 系统调用。
 * 经测试 poll() 在热循环里是仿真速度的主要瓶颈之一；节流后 CoreMark 级长跑提速显著。 */
#define DEVICE_POLL_INTERVAL 65536
static uint64_t s_device_poll_counter = 0;

void npc_device_update(void) {
  if (++s_device_poll_counter < DEVICE_POLL_INTERVAL) return;
  s_device_poll_counter = 0;
  npc_vga_poll();
  npc_kbd_poll();
}

void npc_fini_device(void) {
  npc_vga_shutdown();
  npc_kbd_shutdown();
  npc_clear_map();
}
