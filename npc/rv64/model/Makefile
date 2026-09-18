CXX ?= g++
CXXFLAGS ?= -O3 -std=c++17 -Wall -Wextra -Werror
BUILD ?= ../build/perf-model
.PHONY: all test
all: $(BUILD)/r64-model $(BUILD)/trace-nemu $(BUILD)/import-rtl
$(BUILD):
	mkdir -p $@
$(BUILD)/r64-model: src/model.cpp src/trace.hpp src/decode.hpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ src/model.cpp
$(BUILD)/trace-nemu: src/trace_nemu.cpp src/trace.hpp src/decode.hpp ../testbench/chengyue64/r64_image.h | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ src/trace_nemu.cpp -ldl -Wl,--no-as-needed -lreadline
test: all $(BUILD)/test-decode
	$(BUILD)/test-decode
	python3 tests/test_model.py --build $(BUILD)
	python3 tests/test_tools.py --build $(BUILD)

$(BUILD)/import-rtl: src/import_rtl.cpp src/trace.hpp src/decode.hpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ src/import_rtl.cpp

$(BUILD)/test-decode: tests/test_decode.cpp src/trace.hpp src/decode.hpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ tests/test_decode.cpp

.PHONY: test-cxxrtl
test-cxxrtl:
	python3 tests/test_cxxrtl.py

NETWORK_REPORT ?= ../../../tmp/rv64-protocol-network
.PHONY: network test-network
network:
	PYTHONDONTWRITEBYTECODE=1 python3 network/run.py --out "$(NETWORK_REPORT)"
test-network:
	PYTHONDONTWRITEBYTECODE=1 python3 network/run.py --skip-bench --out "$(NETWORK_REPORT)-tests"

# Whole CPU, imported as an exact word-level event network.
CPU_NETWORK_BUILD ?= ../build/network-model
CPU_NETWORK_REPORT ?= ../../../tmp/rv64-cpu-network
.PHONY: cpu-network test-cpu-network test-network-compiler
cpu-network:
	PYTHONDONTWRITEBYTECODE=1 python3 network/build_cpu.py --out "$(CPU_NETWORK_BUILD)"
test-cpu-network:
	PYTHONDONTWRITEBYTECODE=1 python3 network/validate_cpu.py --model "$(CPU_NETWORK_BUILD)/r64-network" --out "$(CPU_NETWORK_REPORT)"
test-network-compiler:
	PYTHONDONTWRITEBYTECODE=1 python3 network/tests/test_rtl_compile.py

# Experimental shared-old-state parallel backend; serial remains the default.
CPU_PARALLEL_BUILD ?= ../build/network-parallel
CPU_PARALLEL_REPORT ?= ../../../tmp/rv64-cpu-parallel
CPU_PARALLEL_THREADS ?= 4
.PHONY: cpu-parallel test-cpu-parallel
cpu-parallel:
	PYTHONDONTWRITEBYTECODE=1 python3 network/build_cpu.py --backend parallel --out "$(CPU_PARALLEL_BUILD)"
test-cpu-parallel:
	R64_MODEL_THREADS=$(CPU_PARALLEL_THREADS) PYTHONDONTWRITEBYTECODE=1 python3 network/validate_cpu.py --model "$(CPU_PARALLEL_BUILD)/r64-network" --out "$(CPU_PARALLEL_REPORT)"

.PHONY: test-behavior
test-behavior:
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s behavior -p 'test_*.py' -v

# Build the explicit single-CTA device prototype; this does not execute a GPU.
BEHAVIOR_CUDA_MODEL ?= counter
BEHAVIOR_CUDA_BUILD ?= ../build/behavior-cuda/$(BEHAVIOR_CUDA_MODEL)
NVCC ?= nvcc
CUDA_HOST_CXX ?= g++-12
CUDA_ARCH ?= sm_70
.PHONY: behavior-cuda
behavior-cuda:
	PYTHONDONTWRITEBYTECODE=1 python3 behavior/cuda_codegen.py --model $(BEHAVIOR_CUDA_MODEL) --driver-dir "$(BEHAVIOR_CUDA_BUILD)"
	$(NVCC) -ccbin $(CUDA_HOST_CXX) -std=c++17 -arch=$(CUDA_ARCH) -I behavior "$(BEHAVIOR_CUDA_BUILD)/driver.cu" -o "$(BEHAVIOR_CUDA_BUILD)/behavior-cuda"

# Existing Intel integrated GPU via native WSL Direct3D12; no Windows executables.
BEHAVIOR_IGPU_BUILD ?= ../build/behavior-d3d12
.PHONY: behavior-igpu test-behavior-igpu
behavior-igpu:
	PYTHONDONTWRITEBYTECODE=1 python3 behavior/setup_igpu.py --build "$(BEHAVIOR_IGPU_BUILD)"
test-behavior-igpu: behavior-igpu
	PYTHONDONTWRITEBYTECODE=1 python3 behavior/validate_igpu.py --build "$(BEHAVIOR_IGPU_BUILD)"

.PHONY: test-behavior-terminal-gpu
test-behavior-terminal-gpu: behavior-igpu
	PYTHONDONTWRITEBYTECODE=1 python3 behavior/validate_terminal_gpu.py --build "$(BEHAVIOR_IGPU_BUILD)"
