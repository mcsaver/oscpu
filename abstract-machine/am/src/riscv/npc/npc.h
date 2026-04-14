#ifndef __AM_RISCV_NPC_H__
#define __AM_RISCV_NPC_H__

#include <riscv/riscv.h>

#define DEVICE_BASE 0xa0000000ul

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR    (DEVICE_BASE + 0x0000060)
#define RTC_ADDR    (DEVICE_BASE + 0x0000048)

#define npc_trap(code) asm volatile("mv a0, %0; ebreak" : : "r"(code))

#endif