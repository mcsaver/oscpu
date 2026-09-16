/* NPC 键盘设备接口
 * 从 device.c 拆出，学习 NEMU 的 IO/设备分层设计：
 * 每个设备文件管理自己的 static 状态，通过 IO 基础设施层注册到总线。
 * VGA 的 SDL 事件循环通过 npc_kbd_push_event() 往键盘推事件。 */
#ifndef NPC_SINGLE_CSRC_DEVICE_KEYBOARD_H_
#define NPC_SINGLE_CSRC_DEVICE_KEYBOARD_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* 初始化键盘设备并注册到 MMIO 总线 */
void npc_kbd_init(bool enable);
void npc_kbd_shutdown(void);
void npc_kbd_poll(void);
/* VGA SDL 事件路径用：把一个键盘事件推入环形缓冲区 */
void npc_kbd_push_event(int keycode, bool keydown);

#ifdef __cplusplus
}
#endif

#endif
