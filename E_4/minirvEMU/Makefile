# 工程名称与源文件列表，按照分层目录组织。
NAME = minirvEMU
SRCS = \
	app_main.c \
	src/runtime/config.c \
	src/runtime/loader.c \
	src/hardware/memory.c \
	src/hardware/core.c \
	src/platform/soc.c \
	src/hardware/trace.c \
	src/platform/loopguard.c \
	src/platform/video.c

# 编译参数：开启严格告警并引入头文件目录。
CFLAGS += -Wall -Wextra -Werror -std=gnu11 -Iinclude

ARCH ?= native
export ARCH

include $(AM_HOME)/Makefile

# HEX → BIN 转换规则：过滤掉 Logisim 生成的前导信息。
%.bin: %.hex
	perl -ne 'next if /^v3\.0/; s/.*://; for $$w (split) { $$w =~ s/[^0-9a-fA-F]//g; next unless length($$w)==8; print pack("V", hex($$w)); }' $< > $@

# 运行时环境变量的默认值，可被命令行覆盖。
TRACE_LIMIT ?= 200
SHOW_REGS_AFTER ?= 0
PROGRESS_EVERY ?= 0
LOOP_THRESH ?= 1000000
LOOP_MAX_STEPS ?= 5000000
HOLD_IMAGE_AFTER_HALT ?= 0
AUTO_CLEAN_AFTER_HALT ?= 1

.PHONY: runhex clean help usage

# runhex 目标：根据 HEX 文件生成二进制并执行仿真，可选 DEBUG 模式。
runhex: image
	@if [ -z "$(HEX)" ]; then echo "Usage: make runhex HEX=your.hex [DEBUG=1]"; exit 1; fi
	@$(MAKE) -s -B $(patsubst %.hex,%.bin,$(HEX))
	@if [ -n "$(DEBUG)" ]; then \
		env mainargs=$(abspath $(patsubst %.hex,%.bin,$(HEX))) TRACE_INS=1 TRACE_LIMIT=$(TRACE_LIMIT) SHOW_REGS_AFTER=$(SHOW_REGS_AFTER) \
		    PROGRESS_EVERY=$(PROGRESS_EVERY) LOOP_THRESH=$(LOOP_THRESH) LOOP_MAX_STEPS=$(LOOP_MAX_STEPS) \
		    HOLD_IMAGE_AFTER_HALT=$(HOLD_IMAGE_AFTER_HALT) AUTO_CLEAN_AFTER_HALT=$(AUTO_CLEAN_AFTER_HALT) \
		    $(IMAGE).elf; \
	else \
		env mainargs=$(abspath $(patsubst %.hex,%.bin,$(HEX))) HOLD_IMAGE_AFTER_HALT=$(HOLD_IMAGE_AFTER_HALT) AUTO_CLEAN_AFTER_HALT=$(AUTO_CLEAN_AFTER_HALT) $(IMAGE).elf; \
	fi

# help/usage 目标：输出常见命令提示。
help:
	@echo "Targets:"
	@echo "  make runhex HEX=path/to/program.hex    # convert and run"
	@echo "  make run                                # run without extra args"
	@echo "Variables: DEBUG=1 enables tracing"

usage: help