### 使用 AM(native) 来运行宿主程序，以获得窗口绘制能力
### 仅允许修改 E_4 目录，不改动 abstract-machine 本身

# 目标名称与源文件，交由 AM 的 Makefile 构建
NAME = minirvEMU
SRCS = minirv_main.c cpu.c

# 若未显式设置 ARCH，默认使用 native（SDL 窗口）
ARCH ?= native
export ARCH

# 引入 AM 的构建系统（要求已设置 AM_HOME 指向 abstract-machine 根目录）
include $(AM_HOME)/Makefile

### ========== 附加工具目标：将 Logisim .hex 转为小端 .bin ==========
%.bin: %.hex
	perl -ne 'next if /^v3\.0/; s/.*://; for $$w (split) { $$w =~ s/[^0-9a-fA-F]//g; next unless length($$w)==8; print pack("V", hex($$w)); }' $< > $@

### ========== 运行：指定 HEX，将其转为 BIN 后把 BIN 作为参数传给本程序 ==========
# 调试环境变量传递到程序中（见 cpu_load_runtime_config）
TRACE_LIMIT ?= 200
SHOW_REGS_AFTER ?= 0
PROGRESS_EVERY ?= 0
LOOP_THRESH ?= 1000000
LOOP_MAX_STEPS ?= 5000000
HOLD_IMAGE_AFTER_HALT ?= 0

.PHONY: runhex help usage

runhex: image
	@if [ -z "$(HEX)" ]; then echo "Usage: make runhex HEX=your.hex [DEBUG=1]"; exit 1; fi
	@$(MAKE) -s -B $(patsubst %.hex,%.bin,$(HEX))
	@if [ -n "$(DEBUG)" ]; then \
		env mainargs=$(abspath $(patsubst %.hex,%.bin,$(HEX))) TRACE_INS=1 TRACE_LIMIT=$(TRACE_LIMIT) SHOW_REGS_AFTER=$(SHOW_REGS_AFTER) \
		    PROGRESS_EVERY=$(PROGRESS_EVERY) LOOP_THRESH=$(LOOP_THRESH) LOOP_MAX_STEPS=$(LOOP_MAX_STEPS) \
		    HOLD_IMAGE_AFTER_HALT=$(HOLD_IMAGE_AFTER_HALT) \
		    $(IMAGE).elf; \
	else \
		env mainargs=$(abspath $(patsubst %.hex,%.bin,$(HEX))) HOLD_IMAGE_AFTER_HALT=$(HOLD_IMAGE_AFTER_HALT) $(IMAGE).elf; \
	fi

help:
	@echo "目标："
	@echo "  make runhex HEX=path/to/program.hex    # 转 bin 并运行，弹出窗口显示图像"
	@echo "  make run                                # 直接运行(无参数)；由 AM 提供"
	@echo "变量：DEBUG=1 可开启逐指令跟踪；其余阈值见 Makefile 内容"

usage: help