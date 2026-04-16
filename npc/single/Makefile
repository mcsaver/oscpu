NPC_HOME := $(abspath .)
NEMU_HOME ?= $(abspath ../../nemu)
YOSYS_STA_HOME ?= $(abspath ../../yosys-sta)
OSS_CAD_SUITE_HOME ?= $(abspath ../../oss-cad-suite)
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
CAPSTONE_HOME = $(abspath $(NEMU_HOME)/tools/capstone)
CAPSTONE_REPO = $(CAPSTONE_HOME)/repo
CAPSTONE_LIB = $(CAPSTONE_REPO)/libcapstone.so.5

INC_PATH ?=
IMG ?=
RUN_ARGS ?=
LDLIBS_BUILD ?=

INC_PATH += $(abspath ./csrc/include)

ifeq ($(CONFIG_NPC_ITRACE),y)
	# itrace 的反汇编直接复用 NEMU 已经在维护的 Capstone 依赖，避免 NPC 再养一套重复 decode 逻辑。
	INC_PATH += $(CAPSTONE_REPO)/include
	LDLIBS_BUILD += -ldl
endif

SDL2_PKGCONFIG_AVAILABLE := $(shell if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2; then echo 1; else echo 0; fi)
SDL2_CONFIG_AVAILABLE := $(shell if command -v sdl2-config >/dev/null 2>&1; then echo 1; else echo 0; fi)

ifeq ($(SDL2_PKGCONFIG_AVAILABLE),1)
	# VGA/窗口键盘优先直接复用 SDL2；找不到时再自动退回 headless + stdin 键盘，不把整条构建链卡死。
	SDL2_CFLAGS := $(shell pkg-config --cflags sdl2)
	SDL2_LIBS := $(shell pkg-config --libs sdl2)
	CXXFLAGS_BUILD += -DNPC_HAS_SDL=1 $(SDL2_CFLAGS)
	LDLIBS_BUILD += $(SDL2_LIBS)
else ifeq ($(SDL2_CONFIG_AVAILABLE),1)
	SDL2_CFLAGS := $(shell sdl2-config --cflags)
	SDL2_LIBS := $(shell sdl2-config --libs)
	CXXFLAGS_BUILD += -DNPC_HAS_SDL=1 $(SDL2_CFLAGS)
	LDLIBS_BUILD += $(SDL2_LIBS)
else
	CXXFLAGS_BUILD += -DNPC_HAS_SDL=0
endif

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

# 这组变量把“纯 RTL 核心的网表综合/STA”和 Verilator 仿真壳分开管理；以后直接 make syn/make sta 即可，不必再回 yosys-sta 目录拼长命令。
STA_DESIGN ?= NpcCore
STA_PDK ?= icsprout55
STA_CLK_PORT_NAME ?= clk
STA_CLK_FREQ_MHZ ?= 500
STA_SDC_FILE ?= $(abspath $(YOSYS_STA_HOME)/scripts/default.sdc)
STA_RESULT_ROOT ?= $(abspath $(BUILD_DIR)/sta)
# 显式列出可综合核心文件，避免把含 DPI-C 的 NpcSimTop.sv 或纯宏头 define.v 混进综合网表。
STA_RTL_FILES ?= $(strip \
	$(abspath ./vsrc/ALU.v) \
	$(abspath ./vsrc/CompareUnit.v) \
	$(abspath ./vsrc/DecodeUnit.v) \
	$(abspath ./vsrc/ImmGen.v) \
	$(abspath ./vsrc/LSU.v) \
	$(abspath ./vsrc/RegisterFile.v) \
	$(abspath ./vsrc/WBU.v) \
	$(abspath ./vsrc/NpcCore.v))
STA_RESULT_DIR = $(STA_RESULT_ROOT)/$(STA_DESIGN)-$(STA_CLK_FREQ_MHZ)MHz
STA_MAKE_ARGS = \
	DESIGN=$(STA_DESIGN) \
	PDK=$(STA_PDK) \
	CLK_PORT_NAME=$(STA_CLK_PORT_NAME) \
	CLK_FREQ_MHZ=$(STA_CLK_FREQ_MHZ) \
	SDC_FILE=$(STA_SDC_FILE) \
	O=$(STA_RESULT_ROOT) \
	RTL_FILES="$(STA_RTL_FILES)"

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(CXXFLAGS_BUILD) $(INCFLAGS) -include $(abspath ./include/generated/autoconf.h)

default: $(BIN)

$(CAPSTONE_LIB):
	$(MAKE) -C $(CAPSTONE_HOME)

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDLIBS_BUILD)) \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN))

ifeq ($(CONFIG_NPC_ITRACE),y)
$(BIN): $(CAPSTONE_LIB)
endif

lint:
	$(VERILATOR) --lint-only -Wall -I$(abspath ./vsrc) --top-module $(TOPNAME) $(VSRCS)

all: default

syn-check-env:
	@# 先把工具和约束文件检查清楚，错误会直接指向缺失项，避免在 yosys-sta 子流程里晚失败。
	@if [ ! -f "$(YOSYS_STA_HOME)/Makefile" ]; then \
		echo "[npc-sta] missing yosys-sta workspace: $(YOSYS_STA_HOME)"; \
		exit 1; \
	fi
	@if [ ! -x "$(OSS_CAD_SUITE_HOME)/bin/yosys" ]; then \
		echo "[npc-sta] missing yosys binary: $(OSS_CAD_SUITE_HOME)/bin/yosys"; \
		exit 1; \
	fi
	@if [ ! -f "$(STA_SDC_FILE)" ]; then \
		echo "[npc-sta] missing SDC file: $(STA_SDC_FILE)"; \
		exit 1; \
	fi

sta-check-env: syn-check-env
	@if [ ! -x "$(YOSYS_STA_HOME)/bin/iEDA" ]; then \
		echo "[npc-sta] missing iEDA binary: $(YOSYS_STA_HOME)/bin/iEDA"; \
		exit 1; \
	fi

syn: syn-check-env
	@# 这里只综合 NpcCore 及其纯 RTL 子模块；改完后可以直接从 npc/single 目录产出标准单元网表，不再手动切目录拼参数。
	@PATH="$(OSS_CAD_SUITE_HOME)/bin:$$PATH" $(MAKE) -C $(YOSYS_STA_HOME) syn $(STA_MAKE_ARGS)
	@echo "[npc-sta] synthesized netlist: $(STA_RESULT_DIR)/$(STA_DESIGN).netlist.v"

sta: sta-check-env
	@# 这里复用同一套参数继续跑 STA/功耗分析；改完后 make sta 会同时管理综合产物和分析报告的落点。
	@PATH="$(OSS_CAD_SUITE_HOME)/bin:$$PATH" $(MAKE) -C $(YOSYS_STA_HOME) sta $(STA_MAKE_ARGS)
	@echo "[npc-sta] sta report: $(STA_RESULT_DIR)/$(STA_DESIGN).rpt"
	@echo "[npc-sta] power report: $(STA_RESULT_DIR)/$(STA_DESIGN).pwr"

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

.PHONY: default all lint syn-check-env sta-check-env syn sta sim run clean

include $(NPC_HOME)/scripts/config.mk

include ../../Makefile
