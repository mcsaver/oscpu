# 让 AM guest 的 -march/-mabi 直接消费 NEMU 顶层配置结果。
# RV32/RV64 共用这一份拼装规则，模拟器接受的扩展就是 guest 可以生成的扩展。
-include $(NEMU_HOME)/include/config/auto.conf
EXTRA_DEPS += $(NEMU_HOME)/include/config/auto.conf

AM_RISCV_XLEN ?= 32
AM_RISCV_BASE_EXT ?= i
ifneq ($(CONFIG_RVE),)
AM_RISCV_BASE_EXT := e
endif

AM_RISCV_BASE := rv$(AM_RISCV_XLEN)$(AM_RISCV_BASE_EXT)
AM_RISCV_EXTENSION_M := $(if $(CONFIG_RISCV_EXT_M),m,)
AM_RISCV_EXTENSION_A := $(if $(CONFIG_RISCV_EXT_A),a,)
AM_RISCV_EXTENSION_F := $(if $(CONFIG_RISCV_EXT_F),f,)
AM_RISCV_EXTENSION_D := $(if $(CONFIG_RISCV_EXT_D),d,)
AM_RISCV_EXTENSION_C := $(if $(CONFIG_RISCV_EXT_C),c,)
AM_RISCV_SINGLE_EXTS := $(AM_RISCV_EXTENSION_M)$(AM_RISCV_EXTENSION_A)$(AM_RISCV_EXTENSION_F)$(AM_RISCV_EXTENSION_D)$(AM_RISCV_EXTENSION_C)
# NEMU 译码始终实现 fence.i；guest 侧同步声明 zifencei，避免自修改代码测试在汇编阶段被工具链拒绝。
AM_RISCV_MULTI_EXTS := _zicsr_zifencei$(if $(CONFIG_RISCV_EXT_B),_zba_zbb_zbc_zbs,)
AM_RISCV_MARCH := $(AM_RISCV_BASE)$(AM_RISCV_SINGLE_EXTS)$(AM_RISCV_MULTI_EXTS)
AM_RISCV_INTEGER_ABI := $(if $(filter 64,$(AM_RISCV_XLEN)),lp64,$(if $(filter e,$(AM_RISCV_BASE_EXT)),ilp32e,ilp32))
# The psABI defines ILP32E only as a soft-float ABI: there is no ilp32ef/ed.
# RV32E may still expose architectural F registers for decoder tests, but AM C
# code must keep the ILP32E calling convention instead of inventing an ABI name.
AM_RISCV_FLOAT_ABI := $(if $(filter e,$(AM_RISCV_BASE_EXT)),,$(if $(CONFIG_RISCV_EXT_D),d,$(if $(CONFIG_RISCV_EXT_F),f,)))
AM_RISCV_MABI := $(AM_RISCV_INTEGER_ABI)$(AM_RISCV_FLOAT_ABI)

# AM guests are freestanding programs.  Besides documenting that execution
# environment, this keeps a Linux-targeted cross compiler on its compiler
# provided integer types instead of pulling in host libc multilib headers
# (for example gnu/stubs-ilp32d.h for an RV32D guest).
COMMON_CFLAGS += -ffreestanding \
  -march=$(AM_RISCV_MARCH) -mabi=$(AM_RISCV_MABI)
