NPC_HOME := $(abspath .)
NEMU_HOME ?= $(abspath ../../nemu)
# 工作区根：通用工具(tool/kconfig 等)定位锚点，独立于 nemu
YSYX_HOME ?= $(abspath ../..)
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

RTL_CORE_TOP ?= NpcTop
SIM_TOP ?= NpcSimTop
TOPNAME = $(SIM_TOP)
VERILATOR = verilator
RV64_PRODUCT_RTL_DEFAULTS ?= $(NPC_HOME)/configs/product-rtl-defaults.mk
include $(RV64_PRODUCT_RTL_DEFAULTS)
BUILD_DIR ?= ./build$(if $(filter 1 y,$(OOO_CSR_QUEUE_HEAD)),-csrqh,)
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
CAPSTONE_HOME = $(abspath $(NEMU_HOME)/tools/capstone)
CAPSTONE_REPO = $(CAPSTONE_HOME)/repo
CAPSTONE_LIB = $(CAPSTONE_REPO)/libcapstone.so.5
DEFAULT_DIFF_SO = $(abspath $(NEMU_HOME)/build/riscv64-nemu-interpreter-so)

INC_PATH ?=
IMG ?=
RUN_ARGS ?=
LDLIBS_BUILD ?=
VERILATOR_PROFILE ?= 0
VERILATOR_PROF_EXEC ?= 0
VERILATOR_THREADS ?= 1
VERILATOR_THREADS_DPI ?= none
VERILATOR_THREADS_MAX_MTASKS ?=
VERILATOR_BUILD_JOBS ?= $(if $(filter 1,$(VERILATOR_THREADS)),1,$(VERILATOR_THREADS))

VSRCDIR := $(abspath ./vsrc)
include $(VSRCDIR)/filelist.mk

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
CXXFLAGS_BUILD += -DNPC_XLEN=64 -DNPC_GUEST_ISA_RV64=1
RTL_VERILATOR_DEFINES :=
# 由 Kconfig 派生:统计/调试探针的 `ifdef 仅在对应 CONFIG 打开时编进 RTL(perf 模式下全空)。
RTL_VERILATOR_DEFINES += $(if $(filter y,$(CONFIG_NPC_SIM_STATS)),+define+CONFIG_NPC_SIM_STATS)
RTL_VERILATOR_DEFINES += $(if $(filter y,$(CONFIG_NPC_BRANCH_STATS)),+define+CONFIG_NPC_BRANCH_STATS)
RTL_VERILATOR_DEFINES += $(if $(filter y,$(CONFIG_NPC_CACHE_STATS)),+define+CONFIG_NPC_CACHE_STATS)
RTL_VERILATOR_DEFINES += $(if $(filter y,$(CONFIG_NPC_OOO_STATS)),+define+CONFIG_NPC_OOO_STATS)
RTL_VERILATOR_DEFINES += $(if $(filter y,$(CONFIG_NPC_DEBUG_PORTS)),+define+CONFIG_NPC_DEBUG_PORTS)
RTL_VERILATOR_DEFINES += $(if $(filter y,$(F2_PROBE)),+define+F2_PROBE +define+DBRA_PROBE)
RTL_VERILATOR_DEFINES += $(if $(filter 1 y,$(OOO_CSR_QUEUE_HEAD)),+define+OOO_CSR_QUEUE_HEAD=1)
RTL_VERILATOR_DEFINES += $(if $(filter 1 y,$(OOO_TERMINAL_HOLDER_ASSERT)),+define+OOO_TERMINAL_HOLDER_ASSERT)

# 这里直接让 Verilator 一次把 RTL、DPI 包装层和 C++ 宿主编成可执行文件，避免再手写额外链接步骤。
# 优化要点：
#   1. -O3 让 Verilator 对 RTL→C++ 做更激进的内联与死码消除
#   2. --trace 改为条件编译——即使不写 VCD，trace 基础设施也会给每次 eval() 加 ~30% 信号跟踪开销
#   3. profiling 只在显式目标中打开；--prof-cfuncs 会触发 -pg 插桩，不能混进普通性能基线
VERILATOR_FLAGS += -MMD --cc --exe \
			   -O3 \
			   --x-assign fast --x-initial fast --assert \
			   --timescale 1ns/1ps \
			   -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL \
			   -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR)

ifeq ($(VERILATOR_PROFILE),1)
VERILATOR_FLAGS += --prof-cfuncs
endif

ifeq ($(VERILATOR_PROF_EXEC),1)
VERILATOR_FLAGS += --prof-exec
endif

ifneq ($(VERILATOR_THREADS),1)
VERILATOR_FLAGS += --threads $(VERILATOR_THREADS) --threads-dpi $(VERILATOR_THREADS_DPI)
# 多线程构建时 Verilator 可能提示当前 RTL 只能切出较少 mtask；这本身是性能诊断，
# 不应阻止我们用长 workload 实测多线程是否值得保留。
VERILATOR_FLAGS += -Wno-UNOPTTHREADS
ifneq ($(strip $(VERILATOR_THREADS_MAX_MTASKS)),)
VERILATOR_FLAGS += --threads-max-mtasks $(VERILATOR_THREADS_MAX_MTASKS)
endif
endif

VERILATOR_FLAGS += $(RTL_VERILATOR_DEFINES)
# 契约立即断言探针（architecture-first，见 .github/instructions/interface-contract-first.instructions.md）：
# 让六类契约中已编码为过程式 $error/$fatal 的立即断言常驻全核 sim 回归；make syn 网表不含此 define。
# 如需临时关闭断言（如排查误报），删除下一行即可。
VERILATOR_FLAGS += +define+OOO_ASSERT

# 只在确实需要波形时才打开 --trace，避免无谓的 eval() 开销
ifeq ($(CONFIG_NPC_TRACE_BY_DEFAULT),y)
VERILATOR_FLAGS += --trace
endif
ifdef TRACE
VERILATOR_FLAGS += --trace
endif

$(shell mkdir -p $(BUILD_DIR))

CSRCS_ALL = $(shell find $(abspath ./csrc) \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" \))
DIFFTEST_CSRC := $(abspath ./csrc/cpu/difftest.cpp)
ifeq ($(CONFIG_NPC_DIFFTEST),y)
CSRCS = $(CSRCS_ALL)
else
CSRCS = $(filter-out $(DIFFTEST_CSRC),$(CSRCS_ALL))
endif

# 这组变量把“可综合 NPC 顶层的网表综合/STA”和 Verilator 仿真壳分开管理；以后直接 make syn/make sta 即可，不必再回 yosys-sta 目录拼长命令。
STA_DESIGN ?= $(RTL_CORE_TOP)
STA_PDK ?= icsprout55
STA_CLK_PORT_NAME ?= clk
STA_CLK_FREQ_MHZ ?= 500
STA_SDC_FILE ?= $(abspath $(YOSYS_STA_HOME)/scripts/default.sdc)
STA_RESULT_ROOT ?= $(abspath $(BUILD_DIR)/sta)
STA_VERILOG_INCLUDE_DIRS ?= $(VSRCDIR) $(RTL_INCLUDE_DIR)
STA_VERILOG_DEFINES ?=
STA_SYNTH_FLATTEN ?= 0
STA_SYNTH_SHARE ?= 0
STA_SYNTH_STOP_AFTER_COARSE ?= 0
STA_SYNTH_PUBLIC_AUTONAME ?= 1
STA_SYNTH_DFF_AUTONAME ?= 1
STA_SYNTH_STA_FLATTEN_EXPORT ?= 0
STA_SYNTH_STAGE_SCC ?= 0
STA_SYNTH_BLACKBOX_MODULES ?=
STA_KEEP_HIERARCHY_MODULES ?=
# 黑盒宏的 non-signoff 占位 liberty(见 syn/macro-lib/README.md):让 iEDA STA 的
# 时序图闭合出 rpt/pwr(消除 "liberty cell X is not exist"),数字不做签核;
# 端口表随 RTL 变更需重跑 syn/macro-lib/gen_macro_libs.py 再生成。
STA_EXTRA_LIB_FILES ?= \
	$(abspath syn/macro-lib/Sram4096x199.lib) \
	$(abspath syn/macro-lib/Sram4096x113.lib) \
	$(abspath syn/macro-lib/OooFpArithGate.lib) \
	$(abspath syn/macro-lib/OooBranchDirectionPredictor.lib)
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
	VERILOG_INCLUDE_DIRS="$(STA_VERILOG_INCLUDE_DIRS)" \
	VERILOG_DEFINES="$(STA_VERILOG_DEFINES)" \
	SYNTH_FLATTEN=$(STA_SYNTH_FLATTEN) \
	SYNTH_SHARE=$(STA_SYNTH_SHARE) \
	SYNTH_STOP_AFTER_COARSE=$(STA_SYNTH_STOP_AFTER_COARSE) \
	SYNTH_PUBLIC_AUTONAME=$(STA_SYNTH_PUBLIC_AUTONAME) \
	SYNTH_DFF_AUTONAME=$(STA_SYNTH_DFF_AUTONAME) \
	SYNTH_STA_FLATTEN_EXPORT=$(STA_SYNTH_STA_FLATTEN_EXPORT) \
	SYNTH_STAGE_SCC=$(STA_SYNTH_STAGE_SCC) \
	SYNTH_BLACKBOX_MODULES="$(STA_SYNTH_BLACKBOX_MODULES)" \
	KEEP_HIERARCHY_MODULES="$(STA_KEEP_HIERARCHY_MODULES)" \
	EXTRA_LIB_FILES="$(STA_EXTRA_LIB_FILES)" \
	RTL_FILES="$(STA_RTL_FILES)"

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(CXXFLAGS_BUILD) $(INCFLAGS) -include $(abspath ./include/generated/autoconf.h)
CONFIG_OUTPUTS := $(abspath ./include/generated/autoconf.h) $(abspath ./include/config/auto.conf)

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
	$(MAKE) -C $(OBJ_DIR) -f V$(TOPNAME).mk -j$(VERILATOR_BUILD_JOBS)

ifeq ($(CONFIG_NPC_TEXT_TRACE),y)
$(BIN): $(CAPSTONE_LIB)
endif

lint:
	$(VERILATOR) --lint-only --timescale 1ns/1ps -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) $(RTL_VERILATOR_DEFINES) --top-module $(TOPNAME) $(VSRCS)

.PHONY: print-product-rtl-config
print-product-rtl-config:
	@printf '%s\n' \
	  "schema=$(NPC_PRODUCT_RTL_CONFIG_SCHEMA)" \
	  "manifest=$(RV64_PRODUCT_RTL_DEFAULTS)" \
	  "OOO_CSR_QUEUE_HEAD=$(OOO_CSR_QUEUE_HEAD)" \
	  "OOO_TERMINAL_HOLDER_ASSERT=$(OOO_TERMINAL_HOLDER_ASSERT)" \
	  "BUILD_DIR=$(BUILD_DIR)" \
	  "RTL_VERILATOR_DEFINES=$(RTL_VERILATOR_DEFINES)"

# 打印可综合核心 RTL 文件清单(供 RTL 风格检查器使用)
print-synth-rtl:
	@echo $(RTL_CORE_SRCS)

# RTL 写作规范风格检查器(可综合硬件用 .v + Verilog-2001 always 关键字):
# 强制 .github/instructions/rtl-generation-workflow.instructions.md 的可执行子集——
# 可综合文件须为 .v、不得用 SV 的 always_comb/always_ff/logic(iverilog 模块 TB 不兼容)。
check-rtl-style:
	@RTL_FILES="$$($(MAKE) -s print-synth-rtl)" $(abspath eval/check-rtl-style.sh)
	@bash $(abspath eval/tests/test-check-rtl-style.sh)

# Finite-generation ProducerId holder census.  The first command proves the
# checker fails closed under added fields/stages/tokens, cut unions, raw-index
# lookup, and manifest overclaim; the second binds the current production RTL,
# manifest, checker and per-source hashes.
.PHONY: check-producer-holder-census
check-producer-holder-census: check-producer-holder-instance-graph
	@python3 -m unittest -q eval/ppa/tests/test_producer_holder_census.py
	@python3 $(abspath eval/ppa/tools/producer_holder_census.py)

# Current product NpcTop elaboration companion to the source-level census.
# The manifest-selected current task-run bundle binds every holder-bearing
# module to every reachable instance, including duplicated MIQ and memory-
# bridge instances.  The daily gate replays the fail-closed unit suite and
# frozen full-graph receipt without rewriting task-run history.  Fresh Yosys
# elaboration remains an explicit evidence-generation action.
.PHONY: check-producer-holder-instance-graph
check-producer-holder-instance-graph:
	@python3 -m unittest -q eval/ppa/tests/test_producer_holder_instance_graph.py
	@python3 $(abspath eval/ppa/tools/producer_holder_instance_graph.py) --check-frozen

# Current bounded semantic ledger.  All 44 inventoried units and 50 product
# bindings are local PASS.  A compact, fail-closed receipt joins V14G with the
# current V11 support set and the elaborated optional-lane1 constant-low chain.
# A separate frozen-log replay receipt binds the current design/config/guest
# system transaction.  Whole architecture remains RED and PPA unpromoted.
PRODUCER_HOLDER_SEMANTIC_LEDGER := $(abspath design/arch/producer-holder-semantic-coverage.json)
GLOBAL_PRODUCER_CLOSURE_TOOL := $(abspath eval/ppa/tools/global_producer_no_live_reuse.py)
GLOBAL_PRODUCER_CLOSURE_RECEIPT := $(abspath eval/ppa/evidence/global-producer-no-live-reuse-current.json)
.PHONY: check-producer-holder-semantic-coverage
check-producer-holder-semantic-coverage: check-producer-holder-census
	@python3 -m unittest -q \
	  eval/ppa/tests/test_compile_image_retirement.py \
	  eval/ppa/tests/test_load_queue_producer_checker_replay.py \
	  eval/ppa/tests/test_global_producer_no_live_reuse.py \
	  eval/ppa/tests/test_system_recertification_current.py \
	  eval/ppa/tests/test_producer_holder_semantic_coverage.py
	@python3 $(abspath eval/ppa/tools/producer_holder_semantic_coverage.py) \
	  verify --input $(PRODUCER_HOLDER_SEMANTIC_LEDGER)

# The normal gate reuses the compact receipt and reads only current RTL/tool/
# product-elaboration identities plus bounded evidence summaries.  The V14G
# simulation matrix is an explicit refresh action, not a per-check rebuild.
V14G_GLOBAL_OWNER_FENCE_RUNNER := $(abspath testbench/scripts/run_v14g_global_producer_owner_fence.py)
V14G_GLOBAL_OWNER_FENCE_RESULT ?= $(abspath ../../.github/runtime-artifacts/rv64-gates/v14g-global-owner-fence/run-$(shell date -u +%Y%m%dT%H%M%S%N))
.PHONY: check-global-producer-no-live-reuse refresh-global-producer-no-live-reuse
check-global-producer-no-live-reuse:
	@python3 -B $(abspath eval/ppa/tools/producer_holder_semantic_coverage.py) \
	  verify --input $(PRODUCER_HOLDER_SEMANTIC_LEDGER)

refresh-global-producer-no-live-reuse:
	@python3 -B $(V14G_GLOBAL_OWNER_FENCE_RUNNER) \
	  --result-dir "$(V14G_GLOBAL_OWNER_FENCE_RESULT)"
	@python3 -B $(GLOBAL_PRODUCER_CLOSURE_TOOL) capture \
	  --v14g-result "$(V14G_GLOBAL_OWNER_FENCE_RESULT)" \
	  --output $(GLOBAL_PRODUCER_CLOSURE_RECEIPT)
	@python3 -B $(abspath eval/ppa/tools/producer_holder_semantic_coverage.py) \
	  build --output $(PRODUCER_HOLDER_SEMANTIC_LEDGER)

# V11I exact memory-owner terminal lifecycle: the real IntBackend collector,
# tracker and LQ traverse all 32 tracker tokens before token-0 reuse.  Both
# assertions-on/off production profiles must stay quiet; a compile-success
# delayed-old-tuple RTL copy must be rejected by the holder assertion and the
# independent LQ/tracker raw-Q oracle.  This focused target never launches a
# full-system workload and cannot promote architecture or PPA by itself.
V11I_TERMINAL_LIFECYCLE_RESULT ?= $(abspath $(BUILD_DIR)/v11i-terminal-lifecycle)
V11I_TERMINAL_LIFECYCLE_VALIDATOR := $(abspath eval/ppa/tools/v11i_terminal_lifecycle_evidence.py)
.PHONY: check-memory-terminal-lifecycle
check-memory-terminal-lifecycle:
	@$(MAKE) --no-print-directory -C testbench \
	  V11I_TERMINAL_LIFECYCLE_RESULT="$(V11I_TERMINAL_LIFECYCLE_RESULT)" \
	  v11i-terminal-lifecycle
	@python3 $(V11I_TERMINAL_LIFECYCLE_VALIDATOR) \
	  --summary "$(V11I_TERMINAL_LIFECYCLE_RESULT)/summary.json" \
	  --receipt-out "$(V11I_TERMINAL_LIFECYCLE_RESULT)/validation-receipt.json"
	@V11I_EVIDENCE_SUMMARY="$(V11I_TERMINAL_LIFECYCLE_RESULT)/summary.json" \
	  python3 eval/ppa/tests/test_v11i_terminal_lifecycle_evidence.py -q

# OOO-2 selective scheduling: prove that a registered Universal reservation
# blocks only that terminal while independent ALU work continues through the
# physical ALU terminal.  The runner deliberately expects the remaining
# architecture inventory to stay RED and does not promote PPA.
.PHONY: check-selective-scheduling
check-selective-scheduling:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/run-focused.sh)

# OOO-1 true long-latency execution: accepted load miss plus real iterative
# MUL/DIV each retain one exact full-PID owner while four dual-issue cycles
# deliver eight younger completions; ROB retirement remains Q-only and ordered.
# The runner preserves OOO-2 evidence and deliberately leaves overall
# architecture RED, so this target cannot promote PPA.
.PHONY: check-true-ooo-long-latency
check-true-ooo-long-latency:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/run-focused.sh)

# DI-4 no static program-lane semantics: all six asymmetric classes are
# accepted from both dispatch-package positions, held as resident entries,
# and consumed through capability-selected physical terminals with exact full
# ProducerId identity.  This remains an issue-side claim and does not promote
# dual-memory hardware, memory ordering, recovery or PPA.
.PHONY: check-no-static-lane-semantics
check-no-static-lane-semantics:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/run-focused.sh)

# DI-3 pair matrix: two resident ordinary-integer memory entries atomically
# acquire distinct registered terminal owners and captured-data AGUs.  Shared
# translation/cache service remains serialized, so DI-5 and OOO-3 stay RED.
# The focused runner also refreshes OOO-1/OOO-2/DI-4 under the same RTL digest.
.PHONY: check-pair-matrix
check-pair-matrix:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/run-focused.sh)

# F0 dual-memory shared AXI miss-fabric leaf: registered selection, transaction
# owner lock, independent AW/W backpressure, exact response demux, assertions,
# and compile-success mutations.  It may appear once inside the unintegrated F1
# wrapper, but any canonical core/top integration remains forbidden here;
# DI-5/OOO-3/overall stay RED and this target cannot promote PPA.
.PHONY: check-dual-memory-fabric-foundation
check-dual-memory-fabric-foundation:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/run-focused.sh)

# F1 dual bridge/cache-hit wrapper: two default-off-capable bridges, exact
# cross-lane maintenance, independent hot-hit responses and the F0 miss fabric.
# This leaf gate accepts either the exact historical F1 topology or an explicit
# F2 promotion handoff, while keeping DI-5/OOO-3/overall RED and PPA unqualified.
.PHONY: check-dual-memory-bridge-wrapper
check-dual-memory-bridge-wrapper:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/run-focused.sh)

# F2 canonical integration checkpoint: the production core enables two memory
# banks end-to-end and proves request/MIQ/response/WB/SQ/flush/singleton
# behavior with fail-closed source checks and compile-success mutations.  F3
# final-PA SQ disambiguation and F4 sustained IPC/system evidence are absent,
# so DI-5/OOO-3/overall remain RED and PPA remains unqualified.
.PHONY: check-dual-memory-core-integration
check-dual-memory-core-integration:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/run-focused.sh)

# F4 production sustained dual-memory issue: exact pair turnover, registered
# next-head SQ query, station promotion, 64-cycle dual-bank trajectory and
# same-design DI-5 publication.  OOO-3/overall remain RED; PPA is unqualified.
.PHONY: check-dual-memory-sustained-issue
check-dual-memory-sustained-issue:
	@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/run-focused.sh)

# v8v OOO-3 shared retire-resident LQ plus physical SQ ordering and precise
# store request/B/retirement evidence.  The runner refreshes all predecessor
# GREEN records under the exact current RTL digest before publishing OOO-3;
# V9N first adds independent STORE/AMO next-edge physical-write owner
# residency checks and compile-success source variants.  DI-1/DI-2/OOO-4/
# overall remain RED and PPA remains unqualified.
.PHONY: check-memory-ordering
check-memory-ordering:
	@bash $(abspath ../../.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-focused.sh)
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-focused.sh)

# v8x OOO-4 verification closure: one real backend MIQ + canonical dual-memory
# wrapper trace proves active A/station B selective branch recovery across the
# shared AXI R drain, exact dual drop/pop/terminal accounting and final owner
# conservation.  This closes only the V8W combined-trace coverage gap;
# OOO-4/DI-5/OOO-3/overall stay RED and PPA remains unqualified.
.PHONY: check-backend-bridge-recovery
check-backend-bridge-recovery:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/run-focused.sh)

# v8y OOO-4 local RV64 control-flow closure: two simultaneously resident,
# independently ready branches prove oldest-first resolution in linear and ROB
# wrap layouts; strictly-younger pipeline state is removed while older/equal
# full-ProducerId completion and retirement each occur once.  The same focused
# binary also proves EX-stage removal and already-fired AXI read drain.  This
# target closes OOO-4 only; DI-1/DI-2/overall remain RED and PPA is unqualified.
.PHONY: check-speculation-recovery
check-speculation-recovery:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/run-focused.sh)

# v8z DI-1 local RV64 frontend closure: Bridge bare/paged H1 and the complete
# OooFrontend request/response/outstanding/FIFO/sink loop each sustain one
# packet per cycle for 64 post-warmup cycles.  PC ledgers, finite response
# backpressure, tail drain, source mutations and same-design predecessor
# refresh close DI-1 only; DI-2/overall remain RED and PPA is unqualified.
.PHONY: check-frontend-ii1
check-frontend-ii1:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/run-focused.sh)

# v9a DI-2 local RV64 width closure: a fixed 24-cycle warmup and 64-cycle
# measurement window proves exact two-uop activity at fetch/decode/rename/
# dispatch/issue/execute/retire.  Full ProducerId/payload ledgers, independent
# RenameMap/ROB/IQ/EX/WB sinks, compile-success RTL mutations and natural drain
# close DI-2.  This qualifies architecture only; formal PPA remains unqualified
# until the separate architecture-stable freeze and provenance gates complete.
.PHONY: check-width-continuity
check-width-continuity:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9a-width-continuity/run-focused.sh)

# V9C INSTRET-G1 local RV64 architectural retirement closure.  The canonical
# Sv39 program proves exception lanes add zero, MRET/SRET/SFENCE.VMA final
# control pseudo-commits add one, and CsrFile consumes only the post-mux count.
# Three current-source variants must compile and be dynamically rejected.
# This is architecture evidence; PPA remains unqualified and unpromoted.
.PHONY: check-instret-retirement
check-instret-retirement:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-focused.sh)

# V9M FENCE-G1 local RV64 ordinary-FENCE ordering closure.  A full-core
# store -> FENCE -> device-read program proves lane1 capture, complete memory
# drain and no younger observation before store drain/FENCE retirement.  A
# compile-success RTL source variant that removes the mem_idle predicate must
# be rejected by the independent drain-gate testbench.  PPA remains unqualified.
.PHONY: check-fence-ordering
check-fence-ordering:
	@bash $(abspath ../../.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/run-focused.sh)

# V9D FDG-G1 local RV64 architectural-trap admission closure. Four illegal FP
# encodings and one legal FADD.S traverse the real classify/admission chain;
# a full-core program proves exact trap capture, no backend presentation or
# invalid-instruction commit, and handler return. Three compile-success RTL
# verification variants must be dynamically rejected. PPA remains unqualified.
.PHONY: check-fdg-arch-trap
check-fdg-arch-trap:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-focused.sh)

# V9E XRET-G1 local RV64 current-mode and precise-exception closure. The
# seven-case MRET/SRET matrix and four full-core program markers cover legal
# return controls, head0/lane1 illegal-instruction ownership, exact mepc/mtval,
# no illegal CsrFile request or commit, and older-lane retirement. Eight
# compile-success RTL verification variants and two observer probes must be
# dynamically rejected. PPA remains unqualified and unpromoted.
.PHONY: check-xret-current-mode
check-xret-current-mode:
	@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9e-xret-current-design/run-focused.sh)

# V9U VECTORED-TRAP-G1 local RV64 trap-target closure.  CsrFile WARL,
# M/S interrupt vectors, synchronous BASE targeting, mem>ex>irq record
# selection, full-core xRET return and six compile-success RTL variants are
# checked against the live RTL source set.  PPA remains unqualified.
.PHONY: check-vectored-trap
check-vectored-trap:
	@bash $(abspath ../../.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/run-focused.sh)

# V9F MEM-ISSUE-G1 / MIQ-FLUSH-G1 local RV64 memory-transaction lifecycle
# closure. The focused traces prove atomic dual-memory capture, single-port
# terminal ordering, exact request-fire/consume/MIQ-owner identity under
# backpressure and competing owners, plus wrapped/no-pop DRAIN flush
# compaction. Eleven compile-success RTL verification variants must be
# dynamically rejected. PPA remains unqualified.
.PHONY: check-memory-issue-lifecycle
check-memory-issue-lifecycle:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/run-focused.sh)

# V9G IFU-AXI-G1 local RV64 instruction-fetch A-update write lifecycle
# closure. The bridge matrix covers independent AW/W acceptance, same-cycle
# flush plus final channel/B completion, repeated flush backpressure, payload
# stability and semantic quiet; the bridge+xbar trace proves B-owner release
# and a queued later master transaction. Compile-success RTL verification
# variants must be dynamically rejected. PPA remains unqualified.
.PHONY: check-ifu-axi-flush-drain
check-ifu-axi-flush-drain:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/run-focused.sh)

# V9H IFU-FETCH-G2 local RV64 page-fault byte-provenance closure. The bridge
# and packet decoder matrix binds F=0/2/4/6, independent PC-derived frontiers,
# stale-tail exclusion, response backpressure ownership, post-accept quiet and
# positive AR/fill/SRAM monitor sensitivity. Compile-success RTL verification
# variants must be dynamically rejected. PPA remains unqualified.
.PHONY: check-ifu-fetch-provenance
check-ifu-fetch-provenance:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/run-focused.sh)

# V9I IFU-ACCESS-G1 local RV64 exact instruction-access closure. The focused
# matrix binds C/32 footprint, F=0/2/4/6 PMP/RRESP ownership, AR attributes,
# device execute routing, sized DPI guard-page reads and decoder-to-pending
# lane ownership. Compile-success RTL verification variants must be rejected;
# this gate does not qualify physical PPA.
.PHONY: check-ifu-access
check-ifu-access:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/run-focused.sh)

# V9J IFU-TVAL-G1 local RV64 instruction-fault payload closure. The focused
# matrix separates faulting instruction PC from the first failing halfword
# address across PF/AF, F=0/2/4/6, packet FIFO, pending storage, drained CSR
# request and compressed-branch terminal/squash/invisible-lane cases.
# Compile-success RTL verification variants must be rejected; this gate does
# not qualify physical PPA.
.PHONY: check-ifu-tval
check-ifu-tval:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/run-focused.sh)

# V9K PTW-PMP-G1 local RV64 page-table PTE WRITE protection closure.  IFU
# and LSU walkers bind independent 8B/S-mode/WRITE checks, access-fault
# response ownership, F=2/4/6 instruction-prefix preservation, deny-cycle
# AW/W quiet and granted A/D update traffic to current-source RTL variants.
# This gate does not qualify physical PPA.
.PHONY: check-ptw-pmp
check-ptw-pmp:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/run-focused.sh)

# Current F0-G1 local RV64 same-design functional aggregation.  The caller
# must name a new immutable task-run; historical V9L output is never reset.
# Publication of the canonical current pointer is explicit, has an independent
# fail-closed status, and starts only after complete execution evidence is PASS.
# This functional gate does not qualify physical PPA.
FULL_CORE_RUN_DIR ?=
FULL_CORE_JOBS ?= 2
FULL_CORE_PUBLISH_CURRENT ?= n
.PHONY: check-functional-aggregate
check-functional-aggregate:
	@test -n "$(FULL_CORE_RUN_DIR)" || { \
	  printf '%s\n' 'FULL_CORE_RUN_DIR=.github/task-runs/<new-run-id> is required' >&2; \
	  exit 2; \
	}
	@bash $(abspath eval/ppa/run-full-core-current.sh) \
	  --run-dir "$(FULL_CORE_RUN_DIR)" --jobs "$(FULL_CORE_JOBS)" \
	  $(if $(filter y,$(FULL_CORE_PUBLISH_CURRENT)),--publish-current,)

# 契约立即断言 gate（architecture-first 的可执行牙齿）：强制
# .github/instructions/interface-contract-first.instructions.md 的机器可检子集——
# 全核 build 含 --assert + OOO_ASSERT、rv64 可综合 .v 的契约立即断言计数不回退。
check-contract: check-producer-holder-census
	@$(abspath eval/check-contract.sh)

# S2-Q2 v8a behavior-neutral shadow foundation: frozen structural checker,
# focused release/assert simulations, non-vacuous negative, and candidate vs
# pre-implementation old-ABI cycle-trace equivalence.
.PHONY: check-q2-v8a-shadow
check-q2-v8a-shadow:
	@bash $(abspath ../../.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-shadow-foundation-v8a-green.sh)

# S2-Q1A source-catalog-only abort priority: shared registered abort consumer,
# immediate handshake/grant mask, atomic held clear, and no epoch advance.
.PHONY: check-q1a-abort-priority
check-q1a-abort-priority:
	@bash $(abspath ../../.github/task-runs/2026-07-19-rv64-q1a-abort-priority/run-q1a-abort-priority.sh)

all: default

core-regress:
	@$(abspath testsuites/scripts/npc-rv64-core-regress.sh)

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
	@# 这里只综合可综合 RTL 顶层及其纯 RTL 子模块；改完后可以直接从当前 RV64 目录产出标准单元网表，不再手动切目录拼参数。
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
	@# AM 平台的 riscv64-npc run 最终也会走到这里，所以这里保持“镜像路径 + 原样透传运行参数”的简单边界。
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
	$(MAKE) -C $(NEMU_HOME) NEMU_HOME=$(NEMU_HOME) \
		AM_HOME=$(abspath ../../abstract-machine) ARCH=riscv64-npc \
		riscv64-npc_defconfig
	$(MAKE) -C $(NEMU_HOME) NEMU_HOME=$(NEMU_HOME) \
		GUEST_ISA=riscv64 SHARE=1 ENGINE=interpreter

.PHONY: default all lint syn-check-env sta-check-env syn sta sim run core-regress clean gprof-build prof-exec-build difftest-ref \
	menuconfig savedefconfig defconfig help-config distclean-config

include $(NPC_HOME)/scripts/config.mk

include ../../Makefile
