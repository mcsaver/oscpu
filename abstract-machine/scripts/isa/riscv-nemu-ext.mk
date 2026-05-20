# 让 AM guest 的 -march/-mabi 直接消费 NEMU Kconfig 结果。
# 这样 menuconfig 里开关 RV32 M/B/C 后，模拟器译码和 guest 编译器不会再各说各话。
-include $(NEMU_HOME)/include/config/auto.conf
EXTRA_DEPS += $(NEMU_HOME)/include/config/auto.conf

AM_RISCV_BASE_EXT ?= i
ifneq ($(CONFIG_RVE),)
AM_RISCV_BASE_EXT := e
endif

AM_RISCV_XLEN := 32
AM_RISCV_BASE := rv$(AM_RISCV_XLEN)$(AM_RISCV_BASE_EXT)
AM_RISCV_SINGLE_EXTS := $(if $(CONFIG_RISCV_EXT_M),m,)$(if $(CONFIG_RISCV_EXT_C),c,)
AM_RISCV_MULTI_EXTS := _zicsr$(if $(CONFIG_RISCV_EXT_B),_zba_zbb_zbc_zbs,)
AM_RISCV_MARCH := $(AM_RISCV_BASE)$(AM_RISCV_SINGLE_EXTS)$(AM_RISCV_MULTI_EXTS)
AM_RISCV_MABI := ilp32$(if $(filter e,$(AM_RISCV_BASE_EXT)),e,)

COMMON_CFLAGS += -march=$(AM_RISCV_MARCH) -mabi=$(AM_RISCV_MABI)
