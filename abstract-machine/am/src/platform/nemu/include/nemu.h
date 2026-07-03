#ifndef NEMU_H__
#define NEMU_H__

#include <klib-macros.h>
#include <device_address.h>   // 全 ISA 共用的设备地址图 (默认 Linux/SoC, -DDEVICE_MAP_LEGACY 切回旧图)


#include ISA_H // the macro `ISA_H` is defined in CFLAGS
               // it will be expanded as "x86/x86.h", "mips/mips32.h", ...

#if defined(__ISA_X86__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_MIPS32__)
# define nemu_trap(code) asm volatile ("move $v0, %0; sdbbp" : :"r"(code))
#elif defined(__riscv)
# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#elif defined(__ISA_LOONGARCH32R__)
# define nemu_trap(code) asm volatile("move $a0, %0; break 0" : :"r"(code))
#else
# error unsupported ISA __ISA__
#endif

// 设备地址全部来自 <device_address.h> —— 所有 ISA 共用同一套图,不再按 ISA 分支。
#define SERIAL_PORT     DEV_SERIAL_BASE  // ns16550a THR@0
#define KBD_ADDR        DEV_KBD_BASE
#define RTC_ADDR        DEV_RTC_BASE
#define VGACTL_ADDR     DEV_VGACTL_BASE
#define AUDIO_ADDR      DEV_AUDIO_BASE
#define DISK_ADDR       DEV_DISK_BASE
#define FB_ADDR         DEV_FB_BASE
#define AUDIO_SBUF_ADDR DEV_AUDIO_SBUF

#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
// riscv64-nemu(设备树图): AM 的 halt/timer 不再依赖 NEMU 未实现的简易设备,
// 而是统一架构在设备树真设备上——halt 走 reset_syscon, timer 走 goldfish-rtc。
#define SYSCON_ADDR        DEV_SYSCON_BASE        // SiFive Test Finisher (poweroff/exit)
#define GOLDFISH_RTC_ADDR  DEV_GOLDFISH_RTC_BASE  // 纳秒时间源
#endif

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

#if defined(DEVICE_MAP_LEGACY)
// 旧图: 设备集中在 0xa0000000 段
# define NEMU_PADDR_SPACE \
  RANGE(&_pmem_start, PMEM_END), \
  RANGE(FB_ADDR, FB_ADDR + 0x200000), \
  RANGE(0xa0000000, 0xa0000000 + 0x1000) /* serial, rtc, screen, keyboard */
#else
// 默认 Linux/SoC 图: 设备分散在低地址簇与 0x21000000 段,分段覆盖 MMIO 空间
# define NEMU_PADDR_SPACE \
  RANGE(&_pmem_start, PMEM_END), \
  RANGE(DEV_SYSCON_BASE, DEV_SYSCON_BASE + 0x1000), /* reset_syscon (halt) */ \
  RANGE(DEV_CLINT_BASE, DEV_CLINT_BASE + 0x10000),  /* clint */ \
  RANGE(0x10000000, 0x10014000),                    /* serial/virtio/goldfish-rtc/rtc/kbd/disk/audio 簇 */ \
  RANGE(DEV_VGACTL_BASE, DEV_AUDIO_SBUF + 0x200000) /* vgactl/fb/audio-sbuf */
#endif

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
