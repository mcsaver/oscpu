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

NAME = gen-expr
SRCS = gen-expr.c
include $(NEMU_HOME)/scripts/build.mk

# ====== 补充常用目标 ======

.PHONY: all clean run input help clean-extra

# 生成用例数与输出文件名，可在命令行覆盖：
# make input LOOP=10000 OUT=input
LOOP ?= 100
OUT  ?= input

all: $(NAME)

run: all
	./$(NAME) 100

gdb: all
	gdb ./$(NAME) 100

input: all
	./$(NAME) $(LOOP) > $(OUT)

# build.mk 已经定义了 clean（删除 BUILD_DIR）。这里通过“追加依赖”的方式扩展清理项，
# 不覆盖原有 clean 的配方，从而避免告警/冲突。
clean: clean-extra

clean-extra:
	rm -f $(NAME) *.o *.d /tmp/.code.c /tmp/.expr input

# 帮助信息
help:
	@echo "make        # 编译生成 $(NAME)"
	@echo "make run    # 编译并运行"
	@echo "make clean  # 清理生成文件"



