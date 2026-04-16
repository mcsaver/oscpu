/* NPC 设备层编排入口
 * 学习 NEMU 的 IO/设备分层设计：device.c 只负责调用各设备的
 * init/update/fini，具体设备行为分散在各自的 .c 文件中。
 * IO 基础设施（地址映射和读写分发）由 map.c 单独管理。 */
#include "device/device.h"
#include "device/keyboard.h"
#include "device/vga.h"
#include "device/map.h"

/* serial.c 和 timer.c 没有独立头文件——像 NEMU 一样直接前向声明 */
void npc_init_serial(void);
void npc_init_timer(void);

/* ==== 公共接口 ==== */
void npc_init_device(bool enable_stdin_keyboard, bool enable_vga) {
  npc_init_map();
  npc_init_serial();
  npc_init_timer();
  npc_kbd_init(enable_stdin_keyboard);
  npc_vga_init(enable_vga);
}

void npc_device_update(void) {
  npc_vga_poll();
  npc_kbd_poll();
}

void npc_fini_device(void) {
  npc_vga_shutdown();
  npc_kbd_shutdown();
  npc_clear_map();
}
