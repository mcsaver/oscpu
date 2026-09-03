#ifndef __NEMU_PLATFORM_MAP_H__
#define __NEMU_PLATFORM_MAP_H__

#include <generated/autoconf.h>

/*
 * CONFIG_SOC_SIM selects a complete machine profile, not an address alias.
 * Consumers should keep using the profile-specific names supplied by the
 * selected header so equal numbers never erase different device semantics.
 */
#ifdef CONFIG_SOC_SIM
# include <platform/ysyxsoc-map.h>
# define NEMU_PLATFORM_NAME YSYXSOC_PLATFORM_NAME
# define NEMU_PLATFORM_IS_SOC 1
# define NEMU_PLATFORM_HAS_RISCV_CLINT YSYXSOC_HAS_RISCV_CLINT
# define NEMU_PLATFORM_HAS_RISCV_PLIC YSYXSOC_HAS_RISCV_PLIC
# define NEMU_PLATFORM_CPU_EXTERNAL_IRQ_CONNECTED YSYXSOC_CPU_EXTERNAL_IRQ_CONNECTED
# define NEMU_PLATFORM_HAS_RISCV_TIME_COUNTER YSYXSOC_HAS_RISCV_TIME_COUNTER
#else
# include <platform/generic-map.h>
# define NEMU_PLATFORM_NAME NEMU_GENERIC_PLATFORM_NAME
# define NEMU_PLATFORM_IS_SOC 0
# define NEMU_PLATFORM_HAS_RISCV_CLINT NEMU_GENERIC_HAS_RISCV_CLINT
# define NEMU_PLATFORM_HAS_RISCV_PLIC NEMU_GENERIC_HAS_RISCV_PLIC
# define NEMU_PLATFORM_CPU_EXTERNAL_IRQ_CONNECTED NEMU_GENERIC_CPU_EXTERNAL_IRQ_CONNECTED
# ifdef CONFIG_ISA_riscv
#  define NEMU_PLATFORM_HAS_RISCV_TIME_COUNTER 1
# else
#  define NEMU_PLATFORM_HAS_RISCV_TIME_COUNTER 0
# endif
#endif

#endif
