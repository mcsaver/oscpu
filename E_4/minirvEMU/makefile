# 指定 C 编译器变量（默认使用 gcc）
CC = gcc
# 指定编译器选项（警告开启）
CFLAGS = -Wall -Wextra

# 调试跟踪的默认限制（可通过 make run DEBUG=1 TRACE_LIMIT=... 覆盖）
TRACE_LIMIT ?= 200
SHOW_REGS_AFTER ?= 0
PROGRESS_EVERY ?= 0
LOOP_THRESH ?= 1000000
LOOP_MAX_STEPS ?= 5000000

# 声明伪目标，避免与同名文件冲突：all run clean help usage
.PHONY: all run clean help usage

# 默认目标 all，依赖于 minirvEMU（即执行 make 会先构建 minirvEMU）
all: minirvEMU

# 构建可执行 minirvEMU，依赖源文件 minirvEMU.c
minirvEMU: minirvEMU.c
	@$(CC) $(CFLAGS) -o $@ $<

# 将 .hex 转换为小端 .bin 的规则（使用 Perl 避免 Makefile 中的转义问题）
# 规则说明：对每一行去掉地址前缀，提取每个 8 个十六进制字符的词（对应一条 32-bit 指令），
# 然后以小端顺序写入二进制文件。
%.bin: %.hex
	perl -ne 'next if /^v3\.0/; s/.*://; for $$w (split) { $$w =~ s/[^0-9a-fA-F]//g; next unless length($$w)==8; print pack("V", hex($$w)); }' $< > $@

# run: 先构建（all），再把 HEX(.hex) 转为 .bin 并运行模拟器，最后删除生成的 .bin

run: all
	@# 若未提供 HEX 变量则提示用法并退出
	@if [ -z "$(HEX)" ]; then echo "Usage: make run HEX=your.hex"; exit 1; fi
	@# 使用 Make 的 patsubst 在 Make 层计算 bin 名称，避免 shell 变量与多行配方的作用域问题
	@$(MAKE) -s -B $(patsubst %.hex,%.bin,$(HEX))
	@# 如果设置 DEBUG=1，则以 TRACE_INS=1 启动模拟器以便打印指令跟踪
	@# 使用简单的 shell 分支以便兼容各种 make 实现
	@if [ -n "$(DEBUG)" ]; then \
		 env TRACE_INS=1 \
		     TRACE_LIMIT=$(TRACE_LIMIT) \
		     SHOW_REGS_AFTER=$(SHOW_REGS_AFTER) \
		     PROGRESS_EVERY=$(PROGRESS_EVERY) \
		     LOOP_THRESH=$(LOOP_THRESH) \
		     LOOP_MAX_STEPS=$(LOOP_MAX_STEPS) \
		     ./minirvEMU $(patsubst %.hex,%.bin,$(HEX)); \
	else \
		 ./minirvEMU $(patsubst %.hex,%.bin,$(HEX)); \
	fi
	@# 运行结束后清理生成的可执行文件和中间二进制文件（方便短期调试）
	@$(MAKE) -s clean

# clean: 删除可执行与二进制文件
clean:
	rm -f minirvEMU *.bin

# @的作用是只隐藏命令行本身，且仅仅影响它所在的那一行

# help: 构建后打印程序用法（等价运行 ./minirvEMU -h）
help: all
	@./minirvEMU -h
	@echo ""
	@echo "Make targets and examples:"
	@echo "  make run HEX=your.hex                           # convert HEX->BIN and run"
	@echo "  make run HEX=your.hex DEBUG=1 TRACE_LIMIT=50    # enable trace and limit"
	@echo "  make run HEX=your.hex DEBUG=1 PROGRESS_EVERY=1e5 SHOW_REGS_AFTER=1"
	@echo ""
	@echo "Variables (override defaults):"
	@echo "  TRACE_LIMIT=$(TRACE_LIMIT)  SHOW_REGS_AFTER=$(SHOW_REGS_AFTER)  PROGRESS_EVERY=$(PROGRESS_EVERY)"
	@echo "  LOOP_THRESH=$(LOOP_THRESH)  LOOP_MAX_STEPS=$(LOOP_MAX_STEPS)"
	@echo "  Note: DEBUG=1 sets TRACE_INS=1 and forwards the above variables to ./minirvEMU."

# usage: help 的别名
usage: help