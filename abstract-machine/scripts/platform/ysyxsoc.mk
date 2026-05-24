AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/ioe.c \
           riscv/ysyxsoc/timer.c \
           riscv/ysyxsoc/uart.c \
           riscv/ysyxsoc/input.c \
           riscv/ysyxsoc/gpu.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDSCRIPTS += $(AM_HOME)/scripts/linker-ysyxsoc.ld
LDFLAGS   += --gc-sections -e _start

NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NPC_SIM_HOME ?= $(NPC_HOME)/sim
YSYXSOC_RUN_ARGS ?= $(NPC_RUN_ARGS)

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = the_insert-arg_rule_in_Makefile_will_insert_mainargs_here
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=$(MAINARGS_PLACEHOLDER)

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) $(MAINARGS_PLACEHOLDER) "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	@# ysyxsoc 平台的 AM 镜像默认进入 npc/sim 的 soc 后端，保持 AM 入口不依赖具体后端目录。
	$(MAKE) -C $(NPC_SIM_HOME) run BACKEND=soc IMG=$(IMAGE).bin RUN_ARGS="$(YSYXSOC_RUN_ARGS)"

.PHONY: insert-arg
