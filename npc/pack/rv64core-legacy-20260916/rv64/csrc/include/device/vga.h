/* NPC VGA 设备接口
 * 从 device.c 拆出，学习 NEMU 的 IO/设备分层设计。
 * VGA 设备管理 framebuffer、SDL 窗口和控制寄存器，
 * 初始化时自行注册 vgactl 与 framebuffer 两段 MMIO。
 * 所有状态在 vga.c 内部 static 管理。 */
#ifndef NPC_SINGLE_CSRC_DEVICE_VGA_H_
#define NPC_SINGLE_CSRC_DEVICE_VGA_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* 初始化 VGA 设备并注册 vgactl + framebuffer 到 MMIO 总线 */
void npc_vga_init(bool enable);
void npc_vga_shutdown(void);
void npc_vga_poll(void);

#ifdef __cplusplus
}
#endif

#endif
