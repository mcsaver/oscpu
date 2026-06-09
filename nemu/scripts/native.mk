#***************************************************************************************
# Copyright (c) 2014-2024 Zihao Yu, Nanjing University
#
# NEMU is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
#**************************************************************************************/

# NEMU 只需要复用根目录的 tracer 提交入口，不应直接 include 根 Makefile，
# 否则会把工作区级规则混入本地构建并增加递归 make/jobserver 噪声。
NEMU_YSYX_HOME := $(abspath $(NEMU_HOME)/..)
NEMU_YSYX_TRACE_MAKE := $(NEMU_YSYX_HOME)/Makefile
NEMU_YSYX_TRACE_LOCK_DIR := $(NEMU_YSYX_HOME)/.git/

ifneq ($(wildcard $(NEMU_YSYX_TRACE_MAKE)),)
define git_commit
	+@-flock $(NEMU_YSYX_TRACE_LOCK_DIR) $(MAKE) --no-print-directory -C $(NEMU_YSYX_HOME) NEMU_HOME='$(NEMU_HOME)' .git_commit MSG='$(1)'
	-@sync $(NEMU_YSYX_TRACE_LOCK_DIR)
endef
else
git_commit =
endif

include $(NEMU_HOME)/scripts/build.mk

include $(NEMU_HOME)/tools/difftest.mk

compile_git:
	$(call git_commit, "compile NEMU")
$(BINARY):: compile_git
#上文的意思是，在生成BINARY之前，先执行compile_git目标，从而记录当前的git提交信息。

# Some convenient rules

override ARGS ?= --log=$(BUILD_DIR)/nemu-log.txt
override ARGS += $(ARGS_DIFF)

# Command to execute NEMU
IMG ?=
# 组装允许NEMU的最终命令行，BINARY的作用是指定可执行文件，ARGS是传递给NEMU的参数，IMG是要加载的镜像文件。
NEMU_EXEC := $(BINARY) $(ARGS) $(IMG)

run-env: $(BINARY) $(DIFF_REF_SO)

c: run-env
	$(call git_commit, "run C")
	$(BINARY) -b $(ARGS) $(IMG)

run: run-env
	$(call git_commit, "run NEMU")
	$(NEMU_EXEC)

gdb: run-env
	$(call git_commit, "gdb NEMU")
	gdb -s $(BINARY) --args $(NEMU_EXEC)

clean-tools = $(dir $(shell find ./tools -maxdepth 2 -mindepth 2 -name "Makefile"))
$(clean-tools):
	-@$(MAKE) -s -C $@ clean
clean-tools: $(clean-tools)
clean-all: clean distclean clean-tools

#find .:从当前目录.递归查找
#\( -name '*.c' -o -name '*.h' \)：条件分组，匹配文件名以.c和.h结尾
#-o表示逻辑或，'*c'用引号防止shell预展开
#-print0:输出匹配路径并以NUL字符结尾（而非换行）便于处理含空格/特殊字符的文件名
#| xargs -0 wc -l：管道传给xargs；-0表示按NUL分隔读取参数，再用wc -l统计函数，wc -l会输出每个文件的行数，最后一行total为总计
count:
	find . \( -name '*.c' -o -name '*.h' \) -print0 | xargs -0 wc -l

.PHONY: run gdb run-env clean-tools clean-all $(clean-tools) count
