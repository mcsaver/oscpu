# Shared simulator construction; test scenarios live in testbench/.
R64_SIM_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
R64_HOME := $(abspath $(R64_SIM_DIR)/..)
include $(R64_HOME)/vsrc/filelist.mk
include $(R64_HOME)/vsrc/tensor-filelist.mk
R64_RTL_HDRS := $(wildcard $(R64_RTL_ROOT)/backend/*.vh $(R64_RTL_ROOT)/platform/*.vh)
R64_SIM_SRCS := $(R64_SIM_DIR)/src/r64_sim_main.cpp $(R64_HOME)/difftest/src/r64_difftest.cpp
R64_SIM_HDRS := $(wildcard $(R64_SIM_DIR)/include/*.h $(R64_HOME)/difftest/include/*.h)
R64_SIM_WARNINGS := $(R64_SIM_DIR)/config/npu-existing-warnings.vlt
R64_SIM_INCLUDES := -I$(R64_HOME)/vsrc/include -I$(R64_RTL_ROOT)/backend -I$(R64_RTL_ROOT)/platform -I$(R64_SIM_DIR)/vsrc
R64_HOST_INCLUDES := -I$(R64_SIM_DIR)/include -I$(R64_HOME)/difftest/include
CORE_BUILD_DIR ?= $(R64_HOME)/build/chengyue64/core
SYSTEM_BUILD_DIR ?= $(R64_HOME)/build/chengyue64/system
TENSOR_BUILD_DIR ?= $(R64_HOME)/build/chengyue64/tensor-system
CORE_REF ?= $(abspath $(R64_HOME)/../../nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so)
CORE_BIN := $(CORE_BUILD_DIR)/obj/VR64CoreTestTop
SYSTEM_BIN := $(SYSTEM_BUILD_DIR)/obj/VR64SystemTestTop
TENSOR_BIN := $(TENSOR_BUILD_DIR)/obj/VR64TensorTestTop
CORE_JOBS ?= 6
# Host-code optimization only; never changes RTL assertions or DiffTest.
CORE_CXXFLAGS ?= -O2
CORE_THREADS ?= 1
# Naming/unused-observation diagnostics only. Width, latch, multiple-driver
# and combinational-cycle diagnostics and all R64_ASSERT checks remain fatal.
CORE_LINT_FLAGS := -Wall -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-GENUNNAMED -Wno-VARHIDDEN -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-BLKSEQ
TENSOR_FLAGS := $(CORE_LINT_FLAGS) -Wno-TIMESCALEMOD $(R64_TENSOR_INCLUDES)
R64_SIM_DEPS := $(R64_SIM_SRCS) $(R64_SIM_HDRS) $(R64_SIM_DIR)/build.mk $(R64_HOME)/vsrc/filelist.mk

$(CORE_BUILD_DIR) $(SYSTEM_BUILD_DIR) $(TENSOR_BUILD_DIR):
	mkdir -p $@
$(CORE_BIN): $(R64_RTL_SRCS) $(R64_RTL_HDRS) $(R64_SIM_DIR)/vsrc/R64CoreTestTop.sv $(R64_SIM_DEPS) | $(CORE_BUILD_DIR)
	verilator --cc --exe --build --threads $(CORE_THREADS) -j $(CORE_JOBS) --top-module R64CoreTestTop --prefix VR64CoreTestTop -Mdir $(CORE_BUILD_DIR)/obj -O3 --assert -DR64_ASSERT $(CORE_LINT_FLAGS) $(R64_SIM_INCLUDES) $(R64_RTL_SRCS) $(R64_SIM_DIR)/vsrc/R64CoreTestTop.sv $(R64_SIM_SRCS) -CFLAGS '-DR64_HOST_THREADS=$(CORE_THREADS) $(CORE_CXXFLAGS) $(R64_HOST_INCLUDES)' -LDFLAGS '-ldl -Wl,--no-as-needed -lreadline' > $(CORE_BUILD_DIR)/build.log 2>&1
$(SYSTEM_BIN): $(R64_RTL_SRCS) $(R64_RTL_HDRS) $(R64_SIM_DIR)/vsrc/R64SystemTestTop.sv $(R64_SIM_DIR)/vsrc/R64CpiProfile.svh $(R64_SIM_DEPS) | $(SYSTEM_BUILD_DIR)
	verilator --cc --exe --build --threads $(CORE_THREADS) -j $(CORE_JOBS) --top-module R64SystemTestTop --prefix VR64SystemTestTop -Mdir $(SYSTEM_BUILD_DIR)/obj -O3 --assert -DR64_ASSERT $(CORE_LINT_FLAGS) $(R64_SIM_INCLUDES) $(R64_RTL_SRCS) $(R64_SIM_DIR)/vsrc/R64SystemTestTop.sv $(R64_SIM_SRCS) -CFLAGS '-DR64_HOST_THREADS=$(CORE_THREADS) $(CORE_CXXFLAGS) $(R64_HOST_INCLUDES) -DR64_SYSTEM' -LDFLAGS '-ldl -Wl,--no-as-needed -lreadline' > $(SYSTEM_BUILD_DIR)/build.log 2>&1
$(TENSOR_BIN): $(R64_RTL_SRCS) $(R64_RTL_HDRS) $(R64_TENSOR_SRCS) $(R64_SIM_DIR)/vsrc/R64SystemTestTop.sv $(R64_SIM_DIR)/vsrc/R64CpiProfile.svh $(R64_SIM_DEPS) $(R64_SIM_WARNINGS) $(R64_HOME)/vsrc/tensor-filelist.mk | $(TENSOR_BUILD_DIR)
	verilator --cc --exe --build --threads $(CORE_THREADS) -j $(CORE_JOBS) --top-module R64TensorTestTop --prefix VR64TensorTestTop -Mdir $(TENSOR_BUILD_DIR)/obj -O3 --assert -DR64_ASSERT -DR64_TENSOR $(TENSOR_FLAGS) $(R64_SIM_INCLUDES) $(R64_SIM_WARNINGS) $(R64_TENSOR_SRCS) $(R64_RTL_SRCS) $(R64_SIM_DIR)/vsrc/R64SystemTestTop.sv $(R64_SIM_SRCS) -CFLAGS '-DR64_HOST_THREADS=$(CORE_THREADS) $(CORE_CXXFLAGS) $(R64_HOST_INCLUDES) -DR64_SYSTEM -DR64_TENSOR' -LDFLAGS '-ldl -Wl,--no-as-needed -lreadline' > $(TENSOR_BUILD_DIR)/build.log 2>&1

.PHONY: core-lint system-lint platform-lint tensor-lint force-simulation-config
core-lint:
	verilator --lint-only --top-module R64CoreTop --assert -DR64_ASSERT $(CORE_LINT_FLAGS) $(R64_SIM_INCLUDES) $(R64_RTL_SRCS)
system-lint:
	verilator --lint-only --top-module R64SystemTop --assert -DR64_ASSERT $(CORE_LINT_FLAGS) $(R64_SIM_INCLUDES) $(R64_RTL_SRCS)
platform-lint:
	verilator --lint-only --top-module R64AxiPlatform --assert -DR64_ASSERT $(CORE_LINT_FLAGS) $(R64_SIM_INCLUDES) $(R64_RTL_SRCS)
tensor-lint:
	verilator --lint-only --top-module R64TensorSystemTop --assert -DR64_ASSERT $(TENSOR_FLAGS) $(R64_SIM_INCLUDES) $(R64_SIM_WARNINGS) $(R64_TENSOR_SRCS) $(R64_RTL_SRCS)

# Compiler/thread options are inputs, scoped to each model's build directory.
force-simulation-config:
$(CORE_BUILD_DIR)/simulation-config.txt $(SYSTEM_BUILD_DIR)/simulation-config.txt $(TENSOR_BUILD_DIR)/simulation-config.txt: force-simulation-config
	@mkdir -p "$(@D)"
	@printf '%s\n' 'threads=$(CORE_THREADS)' 'cxxflags=$(CORE_CXXFLAGS)' >"$@.tmp"
	@cmp -s "$@.tmp" "$@" && rm "$@.tmp" || mv "$@.tmp" "$@"
$(CORE_BIN): $(CORE_BUILD_DIR)/simulation-config.txt
$(SYSTEM_BIN): $(SYSTEM_BUILD_DIR)/simulation-config.txt
$(TENSOR_BIN): $(TENSOR_BUILD_DIR)/simulation-config.txt
