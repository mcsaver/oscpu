include $(AM_HOME)/scripts/isa/riscv.mk

NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NPC_SIM_HOME ?= $(NPC_HOME)/sim
-include $(NPC_SIM_HOME)/include/config/auto.conf

ifneq ($(origin YSYXSOC_BACKEND),undefined)
YSYXSOC_SELECTED_BACKEND := $(strip $(YSYXSOC_BACKEND))
else ifneq ($(origin NPC_SIM_BACKEND),undefined)
YSYXSOC_SELECTED_BACKEND := $(strip $(NPC_SIM_BACKEND))
else ifneq ($(origin NPC_PLATFORM),undefined)
YSYXSOC_SELECTED_BACKEND := $(strip $(NPC_PLATFORM))
else ifeq ($(CONFIG_NPC_SIM_BACKEND_SOC),y)
YSYXSOC_SELECTED_BACKEND := soc
else
YSYXSOC_SELECTED_BACKEND := single
endif

ifeq ($(YSYXSOC_SELECTED_BACKEND),ysyx-soc)
YSYXSOC_SELECTED_BACKEND := soc
endif
ifeq ($(YSYXSOC_SELECTED_BACKEND),ysyxSoC)
YSYXSOC_SELECTED_BACKEND := soc
endif
ifeq ($(YSYXSOC_SELECTED_BACKEND),am)
YSYXSOC_SELECTED_BACKEND := single
endif

ifeq ($(YSYXSOC_SELECTED_BACKEND),soc)
include $(AM_HOME)/scripts/platform/ysyxsoc.mk
else
NPC_SIM_BACKEND ?= single
include $(AM_HOME)/scripts/platform/npc.mk
CFLAGS += -U__PLATFORM_YSYXSOC -D__PLATFORM_NPC
endif

COMMON_CFLAGS += -march=rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs -mabi=ilp32
LDFLAGS       += -melf32lriscv

AM_SRCS += riscv/npc/libgcc/div.S \
           riscv/npc/libgcc/muldi3.S \
           riscv/npc/libgcc/multi3.c \
           riscv/npc/libgcc/ashldi3.c \
           riscv/npc/libgcc/unused.c
