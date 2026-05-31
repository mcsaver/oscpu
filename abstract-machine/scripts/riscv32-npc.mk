NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NPC_SIM_HOME ?= $(NPC_HOME)/sim
NPC_SIM_CONFIG_AUTO := $(NPC_SIM_HOME)/include/config/auto.conf
NPC_SIM_CONFIG_DOT := $(NPC_SIM_HOME)/.config
NPC_SIM_CONFIGURED_BACKEND := $(shell \
  if [ -f "$(NPC_SIM_CONFIG_AUTO)" ]; then \
    sed -n 's/^CONFIG_NPC_SIM_BACKEND="\([^"]*\)"/\1/p' "$(NPC_SIM_CONFIG_AUTO)"; \
  elif [ -f "$(NPC_SIM_CONFIG_DOT)" ]; then \
    sed -n 's/^CONFIG_NPC_SIM_BACKEND="\([^"]*\)"/\1/p' "$(NPC_SIM_CONFIG_DOT)"; \
  fi)

ifeq ($(origin NPC_SIM_BACKEND),undefined)
ifeq ($(NPC_SIM_CONFIGURED_BACKEND),rv64)
NPC_SIM_BACKEND := rv64
endif
endif

include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/npc.mk

ifeq ($(NPC_SIM_BACKEND),rv64)
override ISA := riscv64
COMMON_CFLAGS += -ffreestanding -march=rv64im_zicsr_zifencei_zba_zbb_zbc_zbs -mabi=lp64
LDFLAGS       += -melf64lriscv
else
COMMON_CFLAGS += -march=rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs -mabi=ilp32 # overwrite
LDFLAGS       += -melf32lriscv                   # overwrite

AM_SRCS += riscv/npc/libgcc/div.S \
           riscv/npc/libgcc/muldi3.S \
           riscv/npc/libgcc/multi3.c \
           riscv/npc/libgcc/ashldi3.c \
           riscv/npc/libgcc/unused.c
endif
