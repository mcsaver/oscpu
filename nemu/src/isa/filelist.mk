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

## RISC-V 的 RV32/RV64 共用同一套 XLEN 参数化解释器实现；CONFIG_RV64 负责决定 word_t/CPU_state 宽度。
ISA_SRC_DIR := $(if $(filter riscv64,$(GUEST_ISA)),riscv32,$(GUEST_ISA))
INC_PATH += $(NEMU_HOME)/src/isa/$(ISA_SRC_DIR)/include
DIRS-y += src/isa/$(ISA_SRC_DIR)
