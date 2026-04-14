NPC_HOME := $(abspath .)
NEMU_HOME ?= $(abspath ../../nemu)
.DEFAULT_GOAL := default

ifeq ($(wildcard $(NEMU_HOME)/Kconfig),)
	$(error NEMU_HOME=$(NEMU_HOME) is not a valid NEMU repo)
endif

-include $(NPC_HOME)/include/config/auto.conf
-include $(NPC_HOME)/include/config/auto.conf.cmd

remove_quote = $(patsubst "%",%,$(1))

ifneq ($(CONFIG_CC),)
	CXX := $(call remove_quote,$(CONFIG_CC))
endif

TOPNAME = NpcSimTop
VERILATOR = verilator
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

INC_PATH ?=
IMG ?=
RUN_ARGS ?=

INC_PATH += $(abspath ./csrc/include)

CXXFLAGS_BUILD += $(call remove_quote,$(CONFIG_CC_OPT))
CXXFLAGS_BUILD += $(if $(CONFIG_CC_DEBUG),-Og -ggdb3,)

# 这里直接让 Verilator 一次把 RTL、DPI 包装层和 C++ 宿主编成可执行文件，避免再手写额外链接步骤。
VERILATOR_FLAGS += -MMD --build --cc --exe --trace \
			   --x-assign fast --x-initial fast --noassert \
			   -Wall -Wno-DECLFILENAME \
			   -I$(abspath ./vsrc)

$(shell mkdir -p $(BUILD_DIR))

VSRCS = $(shell find $(abspath ./vsrc) \( -name "*.v" -o -name "*.sv" \))
CSRCS = $(shell find $(abspath ./csrc) \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" \))

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(CXXFLAGS_BUILD) $(INCFLAGS) -include $(abspath ./include/generated/autoconf.h)

default: $(BIN)

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN))

lint:
	$(VERILATOR) --lint-only -Wall -I$(abspath ./vsrc) --top-module $(TOPNAME) $(VSRCS)

all: default

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@if [ -z "$(IMG)" ]; then \
		echo "Usage: make sim IMG=/path/to/image.bin [RUN_ARGS='--max-cycles 2000000 --trace']"; \
		exit 1; \
	fi
	@$(BIN) $(IMG) $(RUN_ARGS)

run: $(BIN)
	@if [ -z "$(IMG)" ]; then \
		echo "Usage: make run IMG=/path/to/image.bin [RUN_ARGS='--max-cycles 2000000 --trace']"; \
		exit 1; \
	fi
	@# AM 平台的 riscv32-npc run 最终也会走到这里，所以这里保持“镜像路径 + 原样透传运行参数”的简单边界。
	@$(BIN) $(IMG) $(RUN_ARGS)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default all lint sim run clean

include $(NPC_HOME)/scripts/config.mk

include ../../Makefile
