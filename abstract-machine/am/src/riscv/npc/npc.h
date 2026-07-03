#ifndef __AM_RISCV_NPC_H__
#define __AM_RISCV_NPC_H__

#include <riscv/riscv.h>
#include <device_address.h>   // 全 ISA 共用的设备地址单一集中点 (默认 Linux/SoC 图)

#define SERIAL_PORT DEV_SERIAL_BASE  // ns16550a THR@0 (RTL UART); AM putch 只写
#define KBD_ADDR    DEV_KBD_BASE
#define RTC_ADDR    DEV_RTC_BASE
#define VGACTL_ADDR DEV_VGACTL_BASE
#define FB_ADDR     DEV_FB_BASE

#define npc_trap(code) asm volatile("mv a0, %0; ebreak" : : "r"(code))

#endif
