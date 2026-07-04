# ace-sim 构建。C++20,header-heavy 内核 + 少量 .cc。
CXX       := g++
CXXFLAGS  := -std=c++20 -O2 -Wall -Wextra -Wshadow -Isrc -g
BUILD     := build

V1_SRCS   := src/main.cc     src/cpu/simple_cpu.cc src/mem/simple_mem.cc
V2_SRCS   := src/main_ooo.cc src/core/top/CpuTop.cc    src/cpu/simple_cpu.cc src/mem/simple_mem.cc
V3_SRCS   := src/main_lsq.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc
V4_SRCS   := src/main_spec.cc src/core/top/CpuTop.cc    src/mem/simple_mem.cc
V5_SRCS   := src/main_ff.cc   src/core/top/CpuTop.cc    src/mem/simple_mem.cc
MEM_SRCS  := src/main_mem.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc src/mem/mem_system.cc
FP_SRCS   := src/main_fp.cc   src/core/top/CpuTop.cc    src/mem/simple_mem.cc
CSR_SRCS  := src/main_csr.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc
MMU_SRCS  := src/main_mmu.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc
GSH_SRCS  := src/main_gshare.cc src/core/top/CpuTop.cc  src/mem/simple_mem.cc
STA_SRCS  := src/main_sta.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc
DBT_SRCS  := src/main_dbt.cc  src/core/top/CpuTop.cc    src/mem/simple_mem.cc
TEST_SRCS := test/test_kernel.cc
UNIT_SRCS := test/unit/tb_modules.cc

.PHONY: all run run-ooo run-lsq run-spec run-ff run-mem run-fp run-csr run-mmu run-gshare run-sta run-dbt test unit clean
all: $(BUILD)/ace-sim $(BUILD)/ace-sim-ooo $(BUILD)/ace-sim-lsq $(BUILD)/ace-sim-spec $(BUILD)/ace-sim-ff $(BUILD)/ace-sim-mem $(BUILD)/ace-sim-fp $(BUILD)/ace-sim-csr $(BUILD)/ace-sim-mmu $(BUILD)/ace-sim-gshare $(BUILD)/ace-sim-sta $(BUILD)/ace-sim-dbt $(BUILD)/test_kernel $(BUILD)/tb_modules

$(BUILD)/ace-sim: $(V1_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(V1_SRCS) -o $@

$(BUILD)/ace-sim-ooo: $(V2_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(V2_SRCS) -o $@

$(BUILD)/ace-sim-lsq: $(V3_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(V3_SRCS) -o $@

$(BUILD)/ace-sim-spec: $(V4_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(V4_SRCS) -o $@

$(BUILD)/ace-sim-ff: $(V5_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(V5_SRCS) -o $@

$(BUILD)/ace-sim-mem: $(MEM_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(MEM_SRCS) -o $@

$(BUILD)/ace-sim-fp: $(FP_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(FP_SRCS) -o $@

$(BUILD)/ace-sim-csr: $(CSR_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(CSR_SRCS) -o $@

$(BUILD)/ace-sim-mmu: $(MMU_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(MMU_SRCS) -o $@

$(BUILD)/ace-sim-gshare: $(GSH_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(GSH_SRCS) -o $@

$(BUILD)/ace-sim-sta: $(STA_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(STA_SRCS) -o $@

$(BUILD)/ace-sim-dbt: $(DBT_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(DBT_SRCS) -o $@

$(BUILD)/test_kernel: $(TEST_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(TEST_SRCS) -o $@

$(BUILD)/tb_modules: $(UNIT_SRCS) | $(BUILD)
	$(CXX) $(CXXFLAGS) $(UNIT_SRCS) -o $@

$(BUILD):
	mkdir -p $(BUILD)

run: $(BUILD)/ace-sim
	./$(BUILD)/ace-sim

run-ooo: $(BUILD)/ace-sim-ooo
	./$(BUILD)/ace-sim-ooo

run-lsq: $(BUILD)/ace-sim-lsq
	./$(BUILD)/ace-sim-lsq

run-spec: $(BUILD)/ace-sim-spec
	./$(BUILD)/ace-sim-spec

run-ff: $(BUILD)/ace-sim-ff
	./$(BUILD)/ace-sim-ff

run-mem: $(BUILD)/ace-sim-mem
	./$(BUILD)/ace-sim-mem

run-fp: $(BUILD)/ace-sim-fp
	./$(BUILD)/ace-sim-fp

run-csr: $(BUILD)/ace-sim-csr
	./$(BUILD)/ace-sim-csr

run-mmu: $(BUILD)/ace-sim-mmu
	./$(BUILD)/ace-sim-mmu

run-gshare: $(BUILD)/ace-sim-gshare
	./$(BUILD)/ace-sim-gshare

run-sta: $(BUILD)/ace-sim-sta
	./$(BUILD)/ace-sim-sta

run-dbt: $(BUILD)/ace-sim-dbt
	./$(BUILD)/ace-sim-dbt

test: $(BUILD)/test_kernel
	./$(BUILD)/test_kernel

unit: $(BUILD)/tb_modules
	./$(BUILD)/tb_modules

clean:
	rm -rf $(BUILD)
