NPC_SINGLE_HOME := $(abspath ..)
VSRCDIR := $(NPC_SINGLE_HOME)/vsrc
BUILD_DIR ?= build
RESULT_DIR ?= ../perf/results/$(shell date +%Y%m%d-%H%M%S)/module-testbench
LOG_DIR := $(RESULT_DIR)/logs

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
TB_SRCS_tb_icache := tests/tb_icache.sv $(VSRCDIR)/ICache.v
TB_SRCS_tb_dcache := tests/tb_dcache.sv $(VSRCDIR)/DCache.v
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
  $(VSRCDIR)/WBU.v \
  $(VSRCDIR)/NpcCore.v

.DEFAULT_GOAL := run

run: $(TESTS:%=$(LOG_DIR)/%.log) summary
	@cat $(RESULT_DIR)/summary.txt

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

clean:
	rm -rf $(BUILD_DIR)

.PHONY: run summary clean
