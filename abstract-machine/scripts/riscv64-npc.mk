NPC_SIM_BACKEND ?= rv64

include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/npc.mk

COMMON_CFLAGS += -ffreestanding -march=rv64im_zicsr_zifencei_zba_zbb_zbc_zbs -mabi=lp64
LDFLAGS += -melf64lriscv
