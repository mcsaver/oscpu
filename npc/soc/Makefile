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

RTL_CORE_TOP ?= NpcCore
SIM_TOP ?= NpcSimTop
SOC_TOP ?= ysyxSoCFull
TOPNAME = $(SIM_TOP)
VERILATOR = verilator
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
SOC_OBJ_DIR = $(BUILD_DIR)/obj_dir_$(SOC_TOP)
SOC_BIN = $(BUILD_DIR)/$(SOC_TOP)
CAPSTONE_HOME = $(abspath $(NEMU_HOME)/tools/capstone)
CAPSTONE_REPO = $(CAPSTONE_HOME)/repo
CAPSTONE_LIB = $(CAPSTONE_REPO)/libcapstone.so.5
DEFAULT_DIFF_SO = $(abspath $(NEMU_HOME)/build/riscv32-nemu-interpreter-so)

INC_PATH ?=
IMG ?=
RUN_ARGS ?=
LDLIBS_BUILD ?=
VERILATOR_PROFILE ?= 0
VERILATOR_PROF_EXEC ?= 0
VERILATOR_THREADS ?= 1
VERILATOR_THREADS_DPI ?= none
VERILATOR_THREADS_MAX_MTASKS ?=

VSRCDIR := $(abspath ./vsrc)
include $(VSRCDIR)/filelist.mk

YSYX_SOC_HOME ?= $(abspath ../../ysyxSoC)
YSYX_SOC_FULL_V ?= $(YSYX_SOC_HOME)/build/ysyxSoCFull.v
YSYX_SOC_PERIP_SRCS := $(sort $(shell find $(YSYX_SOC_HOME)/perip -type f -name "*.v" 2>/dev/null))
YSYX_SOC_INCLUDE_DIRS := \
	$(YSYX_SOC_HOME)/perip/uart16550/rtl \
	$(YSYX_SOC_HOME)/perip/spi/rtl
SOC_VSRCS := $(SOC_CPU_SRCS) $(YSYX_SOC_FULL_V) $(YSYX_SOC_PERIP_SRCS)
SOC_CSRCS := $(abspath ./csrc/soc-main.cpp)

INC_PATH += $(abspath ./csrc/include)

ifeq ($(CONFIG_NPC_DIFFTEST),y)
	# difftest 只在配置打开时编进二进制；性能配置关闭后不再链接 dlopen 路径，也不进入提交热路径检查。
	CXXFLAGS_BUILD += -DNPC_DEFAULT_DIFF_SO='\"$(DEFAULT_DIFF_SO)\"'
	LDLIBS_BUILD += -ldl
endif

ifeq ($(CONFIG_NPC_TEXT_TRACE),y)
	# itrace 的反汇编直接复用 NEMU 已经在维护的 Capstone 依赖，避免 NPC 再养一套重复 decode 逻辑。
	INC_PATH += $(CAPSTONE_REPO)/include
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
# 优化要点：
#   1. -O3 让 Verilator 对 RTL→C++ 做更激进的内联与死码消除
#   2. --trace 改为条件编译——即使不写 VCD，trace 基础设施也会给每次 eval() 加 ~30% 信号跟踪开销
#   3. profiling 只在显式目标中打开；--prof-cfuncs 会触发 -pg 插桩，不能混进普通性能基线
VERILATOR_FLAGS += -MMD --cc --exe \
			   -O3 \
			   --x-assign fast --x-initial fast --noassert \
			   -Wall -Wno-DECLFILENAME \
			   -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR)

ifeq ($(VERILATOR_PROFILE),1)
VERILATOR_FLAGS += --prof-cfuncs
endif

ifeq ($(VERILATOR_PROF_EXEC),1)
VERILATOR_FLAGS += --prof-exec
endif

ifneq ($(VERILATOR_THREADS),1)
VERILATOR_FLAGS += --threads $(VERILATOR_THREADS) --threads-dpi $(VERILATOR_THREADS_DPI)
ifneq ($(strip $(VERILATOR_THREADS_MAX_MTASKS)),)
VERILATOR_FLAGS += --threads-max-mtasks $(VERILATOR_THREADS_MAX_MTASKS)
endif
endif

# 只在确实需要波形时才打开 --trace，避免无谓的 eval() 开销
ifeq ($(CONFIG_NPC_TRACE_BY_DEFAULT),y)
VERILATOR_FLAGS += --trace
endif
ifdef TRACE
VERILATOR_FLAGS += --trace
endif

$(shell mkdir -p $(BUILD_DIR))

CSRCS_ALL_RAW = $(shell find $(abspath ./csrc) \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" \))
# soc-main.cpp 只服务 ysyxSoCFull 顶层，普通 NpcSimTop/AM 后端不能把它和 main.c 一起编进去。
CSRCS_ALL = $(filter-out $(SOC_CSRCS),$(CSRCS_ALL_RAW))
DIFFTEST_CSRC := $(abspath ./csrc/cpu/difftest.cpp)
ifeq ($(CONFIG_NPC_DIFFTEST),y)
CSRCS = $(CSRCS_ALL)
else
CSRCS = $(filter-out $(DIFFTEST_CSRC),$(CSRCS_ALL))
endif

# 这组变量把“纯 RTL 核心的网表综合/STA”和 Verilator 仿真壳分开管理；以后直接 make syn/make sta 即可，不必再回 yosys-sta 目录拼长命令。
STA_DESIGN ?= $(RTL_CORE_TOP)
STA_PDK ?= icsprout55
STA_CLK_PORT_NAME ?= clk
STA_CLK_FREQ_MHZ ?= 500
STA_SDC_FILE ?= $(abspath $(YOSYS_STA_HOME)/scripts/default.sdc)
STA_RESULT_ROOT ?= $(abspath $(BUILD_DIR)/sta)
# 显式列出可综合核心文件，避免把含 DPI-C 的 NpcSimTop.sv 或纯宏头 define.v 混进综合网表。
STA_RTL_FILES ?= $(RTL_CORE_SRCS)
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
CONFIG_OUTPUTS := $(abspath ./include/generated/autoconf.h) $(abspath ./include/config/auto.conf)
SOC_VERILATOR_WARN_FLAGS := \
	-Wno-PINCONNECTEMPTY \
	-Wno-DEFPARAM \
	-Wno-ASSIGNDLY \
	-Wno-UNUSEDSIGNAL \
	-Wno-UNUSEDPARAM \
	-Wno-UNDRIVEN \
	-Wno-SYNCASYNCNET
SOC_VERILATOR_FLAGS = $(VERILATOR_FLAGS) $(SOC_VERILATOR_WARN_FLAGS) --timescale "1ns/1ns" --no-timing \
	$(addprefix -I,$(YSYX_SOC_INCLUDE_DIRS))

default: $(BIN)

$(CAPSTONE_LIB):
	$(MAKE) -C $(CAPSTONE_HOME)

# Kconfig 输出会改变 CFLAGS 和条件编译；列入依赖后，切换配置不会继续沿用旧 NpcSimTop。
$(BIN): $(VSRCS) $(RTL_HEADER_SRCS) $(CSRCS) $(CONFIG_OUTPUTS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDLIBS_BUILD)) \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN))
	@ln -sf V$(TOPNAME)__pch.h $(OBJ_DIR)/V$(TOPNAME)__pch.h.fast
	@ln -sf V$(TOPNAME)__pch.h $(OBJ_DIR)/V$(TOPNAME)__pch.h.slow
	$(MAKE) -C $(OBJ_DIR) -f V$(TOPNAME).mk

ifeq ($(CONFIG_NPC_TEXT_TRACE),y)
$(BIN): $(CAPSTONE_LIB)
endif

$(YSYX_SOC_FULL_V):
	$(MAKE) -C $(YSYX_SOC_HOME) verilog

soc: $(SOC_BIN)

soc-run: $(SOC_BIN)
	@# ysyxSoCFull 入口可直接加载 MROM 镜像；IMG 为空时运行内建两条指令 smoke。
	@$(SOC_BIN) $(IMG) $(RUN_ARGS)

$(SOC_BIN): $(SOC_VSRCS) $(SOC_CSRCS)
	@rm -rf $(SOC_OBJ_DIR)
	$(VERILATOR) $(SOC_VERILATOR_FLAGS) \
		--top-module $(SOC_TOP) $(SOC_VSRCS) $(SOC_CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		--Mdir $(SOC_OBJ_DIR) -o $(abspath $(SOC_BIN))
	@ln -sf V$(SOC_TOP)__pch.h $(SOC_OBJ_DIR)/V$(SOC_TOP)__pch.h.fast
	@ln -sf V$(SOC_TOP)__pch.h $(SOC_OBJ_DIR)/V$(SOC_TOP)__pch.h.slow
	$(MAKE) -C $(SOC_OBJ_DIR) -f V$(SOC_TOP).mk

lint:
	$(VERILATOR) --lint-only -Wall -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) --top-module $(TOPNAME) $(VSRCS)

soc-lint: $(SOC_VSRCS)
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME $(SOC_VERILATOR_WARN_FLAGS) \
		-I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) \
		$(addprefix -I,$(YSYX_SOC_INCLUDE_DIRS)) \
		--timescale "1ns/1ns" --no-timing \
		--top-module $(SOC_TOP) $(SOC_VSRCS)

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

# 带 gprof 插桩的构建入口，产物可以送给 gprof 分析热点
gprof-build: VERILATOR_PROFILE = 1
gprof-build: default

# 生成 Verilator 执行 profile，配合多线程 mtask/调度分析使用
prof-exec-build: VERILATOR_PROF_EXEC = 1
prof-exec-build: default

difftest-ref:
	$(MAKE) -C $(NEMU_HOME) GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter

.PHONY: default all lint soc soc-run soc-lint syn-check-env sta-check-env syn sta sim run clean gprof-build prof-exec-build difftest-ref

include $(NPC_HOME)/scripts/config.mk

include ../../Makefile
