#ifndef __NEMU_PLATFORM_GENERIC_MAP_H__
#define __NEMU_PLATFORM_GENERIC_MAP_H__

/*
 * NEMU generic machine address map.
 *
 * This file owns the numeric ABI of generic IOMap devices.  Legacy AM is an
 * explicitly selected variant of the generic profile; it is never available
 * in the ysyxSoC profile.  device/device_address.h only preserves the DEV_*
 * names used by existing device implementations.
 */
#include <generated/autoconf.h>

#define NEMU_GENERIC_PLATFORM_NAME          "generic"

/*
 * Generic RISC-V machine-level interrupt topology.
 *
 * These are platform capabilities, not optional decoder hints: when selected,
 * the complete CLINT/PLIC apertures belong to the generic machine.  Other ISAs
 * use this address header for generic devices but do not acquire RISC-V system
 * controllers merely by including it.
 */
#ifdef CONFIG_ISA_riscv
# define NEMU_GENERIC_HAS_RISCV_CLINT        1
# define NEMU_GENERIC_HAS_RISCV_PLIC         1
# define NEMU_GENERIC_CPU_EXTERNAL_IRQ_CONNECTED 1
#else
# define NEMU_GENERIC_HAS_RISCV_CLINT        0
# define NEMU_GENERIC_HAS_RISCV_PLIC         0
# define NEMU_GENERIC_CPU_EXTERNAL_IRQ_CONNECTED 0
#endif

#ifdef CONFIG_DEVICE_MAP_LEGACY
# define NEMU_GENERIC_UART_BASE              0xa00003f8u
# define NEMU_GENERIC_RTC_BASE               0xa0000048u
# define NEMU_GENERIC_KEYBOARD_BASE          0xa0000060u
# define NEMU_GENERIC_VGA_CONTROL_BASE       0xa0000100u
# define NEMU_GENERIC_FRAMEBUFFER_BASE       0xa1000000u
# define NEMU_GENERIC_VIRTIO_BLK_BASE        0xa0000300u
# define NEMU_GENERIC_AUDIO_CONTROL_BASE     0xa0000200u
# define NEMU_GENERIC_AUDIO_BUFFER_BASE      0xa1200000u
#else
# define NEMU_GENERIC_UART_BASE              0x10000000u
# define NEMU_GENERIC_VIRTIO_BLK_BASE        0x10001000u
# define NEMU_GENERIC_RTC_BASE               0x12000048u
# define NEMU_GENERIC_KEYBOARD_BASE          0x12000060u
# define NEMU_GENERIC_VGA_CONTROL_BASE       0x12000100u
# define NEMU_GENERIC_AUDIO_CONTROL_BASE     0x12000200u
# define NEMU_GENERIC_FRAMEBUFFER_BASE       0x13000000u
# define NEMU_GENERIC_AUDIO_BUFFER_BASE      0x13200000u
#endif

/* RISC-V system devices and explicit NEMU service extensions. */
#define NEMU_GENERIC_CLINT_BASE              0x02000000u
#define NEMU_GENERIC_PLIC_BASE               0x0c000000u
#define NEMU_GENERIC_VIRTIO_RNG_BASE         0x10002000u
#define NEMU_GENERIC_GOLDFISH_RTC_BASE       0x10003000u
#define NEMU_GENERIC_VIRTIO_NET_BASE         0x10004000u
#define NEMU_GENERIC_SYSCON_RESET_BASE       0x00100000u

#endif
