AM_SRCS := riscv/npc/start.S \
           riscv/npc/trm.c \
           riscv/npc/ioe.c \
           riscv/npc/timer.c \
           riscv/npc/input.c \
           riscv/npc/gpu.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDSCRIPTS += $(AM_HOME)/scripts/linker.ld
LDFLAGS   += --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start
NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NPC_SIM_HOME ?= $(NPC_HOME)/sim
NPC_RUN_ARGS ?=

ifneq ($(origin NPC_SIM_BACKEND),undefined)
NPC_SIM_BACKEND_ARG := BACKEND=$(NPC_SIM_BACKEND)
else ifneq ($(origin NPC_PLATFORM),undefined)
NPC_SIM_BACKEND_ARG := BACKEND=$(NPC_PLATFORM)
else
NPC_SIM_BACKEND_ARG :=
endif

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = the_insert-arg_rule_in_Makefile_will_insert_mainargs_here
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=$(MAINARGS_PLACEHOLDER)

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) $(MAINARGS_PLACEHOLDER) "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
    # AM 侧只负责产出镜像和 mainargs，真正执行统一收口到 npc/sim 仿真顶层，避免两边各维护后端切换逻辑。
	$(MAKE) -C $(NPC_SIM_HOME) run $(NPC_SIM_BACKEND_ARG) IMG=$(IMAGE).bin RUN_ARGS="$(NPC_RUN_ARGS)"

.PHONY: insert-arg
