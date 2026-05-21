NPC_SINGLE_HOME := $(abspath ..)
VSRCDIR := $(NPC_SINGLE_HOME)/vsrc
BUILD_DIR ?= build
RESULT_TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
RESULT_DIR ?= ../perf/results/$(RESULT_TIMESTAMP)/module-testbench
LOG_DIR := $(RESULT_DIR)/logs
PIPE_RESULT_DIR ?= ../perf/results/$(RESULT_TIMESTAMP)/pipe-test
PIPE_LOG_DIR := $(PIPE_RESULT_DIR)/logs
PIPE_EXPECT_LOAD_HIT_ZERO ?= 1
PIPE_EXPECT_FRONTEND_HIT_ZERO ?= 1
PIPE_EXPECT_ARG := $(if $(filter 1,$(PIPE_EXPECT_LOAD_HIT_ZERO)),+EXPECT_LOAD_HIT_ZERO,)
PIPE_EXPECT_FRONTEND_ARG := $(if $(filter 1,$(PIPE_EXPECT_FRONTEND_HIT_ZERO)),+EXPECT_FRONTEND_HIT_ZERO,)

IVERILOG ?= iverilog
# 当前 PATH 里可能先命中不完整 oss-cad-suite 的 vvp；优先使用系统 Icarus vvp，保证模块级 testbench 可独立复跑。
VVP ?= $(if $(wildcard /usr/bin/vvp),/usr/bin/vvp,vvp)
IVFLAGS ?= -g2012 -Wall -I$(VSRCDIR) -Icommon

TESTS := \
  tb_alu \
  tb_compare \
  tb_immgen \
  tb_wbu \
  tb_lsu_control \
  tb_lsu_datapath \
  tb_lsu \
  tb_decode_unit \
  tb_decode_stage \
  tb_register_file \
  tb_pipe_regs \
  tb_cache_control \
  tb_memory_stage_control \
  tb_memory_stage \
  tb_pipeline_control \
  tb_divider \
  tb_branch_predictor \
  tb_icache \
  tb_dcache \
  tb_if_stage \
  tb_npc_core_smoke

TB_SRCS_tb_alu := tests/tb_alu.sv $(VSRCDIR)/ALU.v
TB_SRCS_tb_compare := tests/tb_compare.sv $(VSRCDIR)/CompareUnit.v
TB_SRCS_tb_immgen := tests/tb_immgen.sv $(VSRCDIR)/ImmGen.v
TB_SRCS_tb_wbu := tests/tb_wbu.sv $(VSRCDIR)/WBU.v
TB_SRCS_tb_lsu_control := tests/tb_lsu_control.sv $(VSRCDIR)/LSUControl.v
TB_SRCS_tb_lsu_datapath := tests/tb_lsu_datapath.sv $(VSRCDIR)/LSUDataPath.v
TB_SRCS_tb_lsu := tests/tb_lsu.sv $(VSRCDIR)/LSUControl.v $(VSRCDIR)/LSUDataPath.v $(VSRCDIR)/LSU.v
TB_SRCS_tb_decode_unit := tests/tb_decode_unit.sv $(VSRCDIR)/DecodeUnit.v
TB_SRCS_tb_decode_stage := tests/tb_decode_stage.sv $(VSRCDIR)/DecodeUnit.v $(VSRCDIR)/ImmGen.v $(VSRCDIR)/DecodeStage.v
TB_SRCS_tb_register_file := tests/tb_register_file.sv $(VSRCDIR)/RegisterFile.v
TB_SRCS_tb_pipe_regs := tests/tb_pipe_regs.sv $(VSRCDIR)/IfIdPipeReg.v $(VSRCDIR)/IdExPipeReg.v $(VSRCDIR)/ExMemPipeReg.v $(VSRCDIR)/MemWbPipeReg.v
TB_SRCS_tb_cache_control := tests/tb_cache_control.sv $(VSRCDIR)/CacheControl.v
TB_SRCS_tb_memory_stage_control := tests/tb_memory_stage_control.sv $(VSRCDIR)/MemoryStageControl.v
TB_SRCS_tb_memory_stage := tests/tb_memory_stage.sv $(VSRCDIR)/LSUControl.v $(VSRCDIR)/LSUDataPath.v $(VSRCDIR)/LSU.v $(VSRCDIR)/MemoryStageControl.v $(VSRCDIR)/MemoryStage.v
TB_SRCS_tb_pipeline_control := tests/tb_pipeline_control.sv $(VSRCDIR)/PipelineControl.v
TB_SRCS_tb_divider := tests/tb_divider.sv $(VSRCDIR)/Rv32Divider.v
TB_SRCS_tb_branch_predictor := tests/tb_branch_predictor.sv $(VSRCDIR)/BranchPredictor.v
TB_SRCS_tb_icache := tests/tb_icache.sv $(VSRCDIR)/Sram2R1W.v $(VSRCDIR)/ICache.v
TB_SRCS_tb_dcache := tests/tb_dcache.sv $(VSRCDIR)/Sram1Rw.v $(VSRCDIR)/DCache.v
TB_SRCS_tb_if_stage := tests/tb_if_stage.sv $(VSRCDIR)/BranchPredictor.v $(VSRCDIR)/IfStage.v
TB_SRCS_tb_npc_core_smoke := tests/tb_npc_core_smoke.sv \
  $(VSRCDIR)/ALU.v \
  $(VSRCDIR)/BranchPredictor.v \
  $(VSRCDIR)/CacheControl.v \
  $(VSRCDIR)/CompareUnit.v \
  $(VSRCDIR)/DCache.v \
  $(VSRCDIR)/DecodeStage.v \
  $(VSRCDIR)/DecodeUnit.v \
  $(VSRCDIR)/ICache.v \
  $(VSRCDIR)/IfStage.v \
  $(VSRCDIR)/ImmGen.v \
  $(VSRCDIR)/IfIdPipeReg.v \
  $(VSRCDIR)/IdExPipeReg.v \
  $(VSRCDIR)/ExMemPipeReg.v \
  $(VSRCDIR)/LSUControl.v \
  $(VSRCDIR)/LSUDataPath.v \
  $(VSRCDIR)/LSU.v \
  $(VSRCDIR)/MemWbPipeReg.v \
  $(VSRCDIR)/MemoryStageControl.v \
  $(VSRCDIR)/MemoryStage.v \
  $(VSRCDIR)/PipelineControl.v \
  $(VSRCDIR)/RegisterFile.v \
  $(VSRCDIR)/Rv32Divider.v \
  $(VSRCDIR)/Sram1Rw.v \
  $(VSRCDIR)/Sram2R1W.v \
  $(VSRCDIR)/WBU.v \
  $(VSRCDIR)/NpcCore.v

PIPE_TEST_SRCS := tests/pipe_test.sv \
  $(VSRCDIR)/LSUControl.v \
  $(VSRCDIR)/LSUDataPath.v \
  $(VSRCDIR)/LSU.v \
  $(VSRCDIR)/MemoryStageControl.v \
  $(VSRCDIR)/MemoryStage.v \
  $(VSRCDIR)/Sram1Rw.v \
  $(VSRCDIR)/DCache.v \
  $(VSRCDIR)/PipelineControl.v

STAGE_PIPE_TEST_SRCS := tests/stage_pipe_test.sv \
  $(VSRCDIR)/BranchPredictor.v \
  $(VSRCDIR)/IfStage.v \
  $(VSRCDIR)/IfIdPipeReg.v \
  $(VSRCDIR)/Sram2R1W.v \
  $(VSRCDIR)/ICache.v \
  $(VSRCDIR)/LSUControl.v \
  $(VSRCDIR)/LSUDataPath.v \
  $(VSRCDIR)/LSU.v \
  $(VSRCDIR)/MemoryStageControl.v \
  $(VSRCDIR)/MemoryStage.v \
  $(VSRCDIR)/Sram1Rw.v \
  $(VSRCDIR)/DCache.v \
  $(VSRCDIR)/PipelineControl.v

.DEFAULT_GOAL := run

run: $(TESTS:%=$(LOG_DIR)/%.log) summary
	@cat $(RESULT_DIR)/summary.txt

pipe_test: $(PIPE_LOG_DIR)/pipe_test.log $(PIPE_LOG_DIR)/stage_pipe_test.log pipe_summary
	@cat $(PIPE_RESULT_DIR)/summary.txt

define RUN_TEST
$(LOG_DIR)/$(1).log: $$(TB_SRCS_$(1)) common/tb_common.svh common/rv32_encode.svh Makefile
	@mkdir -p $(BUILD_DIR) $(LOG_DIR)
	@tmp="$$@.tmp"; \
	echo "[TEST] $(1)" > "$$$$tmp"; \
	echo "[COMPILE] $(IVERILOG) $(IVFLAGS) -s $(1) -o $(BUILD_DIR)/$(1).vvp $$(TB_SRCS_$(1))" >> "$$$$tmp"; \
	if $(IVERILOG) $(IVFLAGS) -s $(1) -o $(BUILD_DIR)/$(1).vvp $$(TB_SRCS_$(1)) >> "$$$$tmp" 2>&1 && \
	   $(VVP) $(BUILD_DIR)/$(1).vvp >> "$$$$tmp" 2>&1; then \
	  echo "[RESULT] PASS" >> "$$$$tmp"; \
	  mv "$$$$tmp" "$$@"; \
	else \
	  status=$$$$?; \
	  echo "[RESULT] FAIL status=$$$$status" >> "$$$$tmp"; \
	  mv "$$$$tmp" "$$@"; \
	  exit $$$$status; \
	fi
endef

$(foreach t,$(TESTS),$(eval $(call RUN_TEST,$(t))))

summary: $(TESTS:%=$(LOG_DIR)/%.log)
	@mkdir -p $(RESULT_DIR)
	@{ \
	  echo "# NPC single module testbench summary"; \
	  echo; \
	  echo "- result_dir: $(abspath $(RESULT_DIR))"; \
	  echo "- tool: $$($(IVERILOG) -V | sed -n '1p')"; \
	  echo; \
	  pass=0; fail=0; \
	  for t in $(TESTS); do \
	    if grep -q '\[RESULT\] PASS' "$(LOG_DIR)/$$t.log"; then \
	      printf -- "- PASS %s\n" "$$t"; \
	      pass=$$((pass + 1)); \
	    else \
	      printf -- "- FAIL %s\n" "$$t"; \
	      fail=$$((fail + 1)); \
	    fi; \
	  done; \
	  echo; \
	  echo "- total: $$((pass + fail))"; \
	  echo "- passed: $$pass"; \
	  echo "- failed: $$fail"; \
	  test "$$fail" -eq 0; \
	} > $(RESULT_DIR)/summary.txt

$(PIPE_LOG_DIR)/pipe_test.log: $(PIPE_TEST_SRCS) common/tb_common.svh Makefile
	@mkdir -p $(BUILD_DIR) $(PIPE_LOG_DIR)
	@tmp="$@.tmp"; \
	echo "[TEST] pipe_test" > "$$tmp"; \
	echo "[COMPILE] $(IVERILOG) $(IVFLAGS) -s pipe_test -o $(BUILD_DIR)/pipe_test.vvp $(PIPE_TEST_SRCS)" >> "$$tmp"; \
	if $(IVERILOG) $(IVFLAGS) -s pipe_test -o $(BUILD_DIR)/pipe_test.vvp $(PIPE_TEST_SRCS) >> "$$tmp" 2>&1 && \
	   $(VVP) $(BUILD_DIR)/pipe_test.vvp +REPORT=$(abspath $(PIPE_RESULT_DIR)/bubble_report.txt) $(PIPE_EXPECT_ARG) >> "$$tmp" 2>&1; then \
	  echo "[RESULT] PASS" >> "$$tmp"; \
	  mv "$$tmp" "$@"; \
	else \
	  status=$$?; \
	  echo "[RESULT] FAIL status=$$status" >> "$$tmp"; \
	  mv "$$tmp" "$@"; \
	  exit $$status; \
	fi

$(PIPE_LOG_DIR)/stage_pipe_test.log: $(STAGE_PIPE_TEST_SRCS) common/tb_common.svh Makefile
	@mkdir -p $(BUILD_DIR) $(PIPE_LOG_DIR)
	@tmp="$@.tmp"; \
	echo "[TEST] stage_pipe_test" > "$$tmp"; \
	echo "[COMPILE] $(IVERILOG) $(IVFLAGS) -s stage_pipe_test -o $(BUILD_DIR)/stage_pipe_test.vvp $(STAGE_PIPE_TEST_SRCS)" >> "$$tmp"; \
	if $(IVERILOG) $(IVFLAGS) -s stage_pipe_test -o $(BUILD_DIR)/stage_pipe_test.vvp $(STAGE_PIPE_TEST_SRCS) >> "$$tmp" 2>&1 && \
	   $(VVP) $(BUILD_DIR)/stage_pipe_test.vvp +REPORT=$(abspath $(PIPE_RESULT_DIR)/stage_bubble_report.txt) $(PIPE_EXPECT_FRONTEND_ARG) >> "$$tmp" 2>&1; then \
	  echo "[RESULT] PASS" >> "$$tmp"; \
	  mv "$$tmp" "$@"; \
	else \
	  status=$$?; \
	  echo "[RESULT] FAIL status=$$status" >> "$$tmp"; \
	  mv "$$tmp" "$@"; \
	  exit $$status; \
	fi

pipe_summary: $(PIPE_LOG_DIR)/pipe_test.log $(PIPE_LOG_DIR)/stage_pipe_test.log
	@mkdir -p $(PIPE_RESULT_DIR)
	@{ \
	  echo "# NPC single pipe_test summary"; \
	  echo; \
	  echo "- result_dir: $(abspath $(PIPE_RESULT_DIR))"; \
	  echo "- tool: $$($(IVERILOG) -V | sed -n '1p')"; \
	  echo "- expect_load_hit_zero: $(PIPE_EXPECT_LOAD_HIT_ZERO)"; \
	  echo "- expect_frontend_hit_zero: $(PIPE_EXPECT_FRONTEND_HIT_ZERO)"; \
	  echo; \
	  if grep -q '\[RESULT\] PASS' "$(PIPE_LOG_DIR)/pipe_test.log"; then \
	    echo "- PASS pipe_test"; \
	  else \
	    echo "- FAIL pipe_test"; \
	    exit 1; \
	  fi; \
	  if grep -q '\[RESULT\] PASS' "$(PIPE_LOG_DIR)/stage_pipe_test.log"; then \
	    echo "- PASS stage_pipe_test"; \
	  else \
	    echo "- FAIL stage_pipe_test"; \
	    exit 1; \
	  fi; \
	  echo; \
	  echo "## MEM Bubble Metrics"; \
	  if test -f "$(PIPE_RESULT_DIR)/bubble_report.txt"; then \
	    sed 's/^/- /' "$(PIPE_RESULT_DIR)/bubble_report.txt"; \
	  else \
	    echo "- bubble_report.txt missing"; \
	    exit 1; \
	  fi; \
	  echo; \
	  echo "## Stage Bubble Metrics"; \
	  if test -f "$(PIPE_RESULT_DIR)/stage_bubble_report.txt"; then \
	    sed 's/^/- /' "$(PIPE_RESULT_DIR)/stage_bubble_report.txt"; \
	  else \
	    echo "- stage_bubble_report.txt missing"; \
	    exit 1; \
	  fi; \
	} > $(PIPE_RESULT_DIR)/summary.txt

clean:
	rm -rf $(BUILD_DIR)

.PHONY: run summary pipe_test pipe_summary clean
