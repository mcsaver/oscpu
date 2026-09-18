.DEFAULT_GOAL := all
include ../../sim/build.mk
BUILD_DIR ?= ../../build/chengyue64/regress
TESTS ?= tb_r64_service_request_hint tb_r64_lsu_event_count tb_r64_lsu_wb_request tb_r64_dcache_write_buffer tb_r64_issue32 tb_r64_free_select tb_r64_dcache_split_owner tb_r64_fabric_groups tb_r64_fabric_read_continue tb_r64_dcache_store_overlap tb_r64_axi_write_bypass tb_r64_fabric_latency_bypass tb_r64_writeback_demand tb_r64_rr_bypass tb_r64_issue_mdu_pair tb_r64_scratch_resume tb_r64_lsu_network tb_r64_dcache_overlap tb_r64_dispatch_wants tb_r64_rr_raw_fp_pair tb_r64_completion_payload tb_r64_predictor_local_counter tb_r64_fetch_facts_reset tb_r64_fast_raw_owner tb_r64_fma_raw_owner tb_r64_direct_mem_execute tb_r64_lsu_direct_bind tb_r64_lsu_owner_bypass tb_r64_lsu_descriptor_payload tb_r64_lsu_query_pin tb_r64_direct_bind_trigger tb_r64_head_serial_class tb_r64_fetch_protection_owner tb_r64_frontend_prepared tb_r64_fp_qcredit tb_r64_fp_qcredit_vectors tb_r64_service_bank_pair tb_r64_service_cache_hot tb_r64_service_aux_owner tb_r64_service_qcredit tb_r64_dcache_amo_pipe tb_r64_data_terminal tb_r64_fetch_translation tb_r64_fetch_translation_owners tb_r64_packet_map tb_r64_packet_missing tb_r64_packet_headcut tb_r64_align_plan_threebank tb_r64_translation_equiv tb_r64_translation_poison tb_r64_frontend_ingress tb_r64_decode_stage tb_r64_rr_lsq_slot tb_r64_lsu_reserve tb_r64_platform_reset tb_r64_trap_prepare tb_r64_control_pipeline tb_r64_recovery_plan tb_r64_frontend_bundle tb_r64_frontend_training tb_r64_lsu_progress tb_r64_alu_pipe tb_r64_alu_lane tb_r64_fp_normalize tb_r64_clmul_writeback tb_r64_issue_serial tb_r64_fp_fast_pipeline tb_r64_fp_completion tb_r64_trap_vector tb_r64_counter tb_r64_fp_grs tb_r64_mul_booth tb_r64_fp_writeback tb_r64_lsu_metadata tb_r64_fp_product tb_r64_fabric_reset tb_r64_div_pipeline tb_r64_regread_pipeline tb_r64_div_writeback tb_r64_lsu_request_queue tb_r64_writeback_lanes tb_r64_mul_writeback tb_uart tb_axi_clint tb_r64_mul_pipeline tb_axi_reset_syscon tb_r64_lsu_order_select tb_axi_to_uart tb_r64_numeric_helpers tb_r64_lsu_select tb_r64_fabric_latency tb_r64_early_frontend tb_r64_early_wakeup tb_r64_store_done tb_axi_plic tb_r64_tensor_memory tb_r64_mem_admission tb_r64_fetch tb_r64_rvc tb_r64_rob_rename tb_r64_issue_regread tb_r64_writeback tb_r64_axi_read tb_r64_axi_write tb_r64_icache tb_r64_tlb tb_r64_pagewalk tb_r64_translation tb_r64_decode tb_r64_arithmetic tb_r64_backend tb_r64_frontend tb_r64_protection tb_r64_pte_port tb_r64_csr tb_r64_serial tb_r64_commit tb_r64_fp_round tb_r64_fp_fma tb_r64_fp_long tb_r64_fp_fast tb_r64_fp_execute tb_r64_backend_fp tb_r64_predictor tb_r64_pipeline tb_r64_lsu tb_r64_lsu_completion tb_r64_lsu_memory tb_r64_memory_service tb_r64_lsu_coupled tb_r64_lsu_misaligned tb_r64_dcache tb_r64_fabric tb_r64_fabric_devices tb_r64_rtc
TEST_ARGS_tb_r64_lsu := +prepared-capture
TEST_ARGS_tb_r64_dcache_amo_pipe := +late-invalidate
TEST_ORACLES := oracles/R64BackendWantsReference.v oracles/R64RegReadReference.v oracles/R64LsuCompletionReference.v oracles/R64PredictorReference.v oracles/R64ExecuteReference.v oracles/R64BackendCommitActual.v oracles/R64BackendCommitReference.v oracles/R64BackendReference.v oracles/R64RobReference.v oracles/R64ICacheReference.v oracles/R64AlignMapBaseline.v oracles/R64TranslationBaseline.v oracles/R64DecodeReference.v ../../vsrc/decode/OooRvcDecompressor.v ../../vsrc/decode/DecodeUnit.v ../../vsrc/decode/OooFpDecode.v ../../vsrc/core/CsrFile.v oracles/R64CsrBaseline.v oracles/R64AxiPlatformBaseline.v
IVERILOG ?= iverilog
VVP ?= vvp
# 16-entry PMP plus four fetch queries exercise 30k independent region models.
TEST_TIMEOUT_tb_r64_packet_map := 180
# Full SoftFloat FMA vectors can exceed 60 host seconds under EDA load.
TEST_TIMEOUT_tb_r64_fp_fma := 180
TEST_TIMEOUT_tb_r64_protection := 600
FP_VECTOR_DIR := $(abspath $(BUILD_DIR)/fp-vectors)
FP_KINDS := round fma long fast
FP_VECTOR_FILES := $(FP_KINDS:%=$(FP_VECTOR_DIR)/fp-%-vectors.txt)
$(foreach kind,$(FP_KINDS),$(eval TEST_ARGS_tb_r64_fp_$(kind) := +vectors=$(FP_VECTOR_DIR)/fp-$(kind)-vectors.txt))
TEST_ARGS_tb_r64_fp_execute := +vectors_dir=$(FP_VECTOR_DIR)
TEST_ARGS_tb_r64_fp_qcredit_vectors := +vectors_dir=$(FP_VECTOR_DIR)
.SECONDARY:
.PHONY: all run negative
all: run
run: $(TESTS:%=$(BUILD_DIR)/%.pass)
$(BUILD_DIR):
	mkdir -p $@
$(BUILD_DIR)/%.vvp: modules/%.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) $(TEST_ORACLES) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s $* -o $@ $(R64_RTL_SRCS) $(TEST_ORACLES) $<
$(BUILD_DIR)/%.pass: $(BUILD_DIR)/%.vvp
	timeout $(or $(TEST_TIMEOUT_$*),60) $(VVP) $< $(TEST_ARGS_$*) > $(BUILD_DIR)/$*.log 2>&1
	rg -e '^\[PASS\] $*($$| )' $(BUILD_DIR)/$*.log
	touch $@
negative: $(BUILD_DIR)/tb_r64_axi_read.vvp $(BUILD_DIR)/tb_r64_axi_write.vvp $(BUILD_DIR)/tb_r64_fabric.vvp
	@if $(VVP) $(BUILD_DIR)/tb_r64_axi_read.vvp +bad-id > $(BUILD_DIR)/axi-bad-id.log 2>&1; then echo 'invalid AXI ID was accepted'; exit 1; fi
	rg -F 'AXI read response has no owner or incorrect RLAST' $(BUILD_DIR)/axi-bad-id.log
	@if $(VVP) $(BUILD_DIR)/tb_r64_axi_write.vvp +early-b > $(BUILD_DIR)/axi-early-b.log 2>&1; then echo 'premature B was accepted'; exit 1; fi
	rg -F 'AXI B response has no completed AW/W owner' $(BUILD_DIR)/axi-early-b.log

# One grouped recipe generates all four oracles, even under parallel make.
$(FP_VECTOR_FILES) &: scripts/prepare_r64_fp_vectors.sh generators/generate_r64_fp_vectors.c | $(BUILD_DIR)
	bash scripts/prepare_r64_fp_vectors.sh $(FP_VECTOR_DIR) > $(BUILD_DIR)/fp-vectors-build.log 2>&1
$(foreach kind,$(FP_KINDS),$(eval $(BUILD_DIR)/tb_r64_fp_$(kind).pass: $(FP_VECTOR_DIR)/fp-$(kind)-vectors.txt))
$(BUILD_DIR)/tb_r64_fp_execute.pass: $(FP_VECTOR_FILES)
$(BUILD_DIR)/tb_r64_fp_qcredit_vectors.pass: $(FP_VECTOR_FILES)

negative-fabric: $(BUILD_DIR)/tb_r64_fabric.vvp
	@if $(VVP) $(BUILD_DIR)/tb_r64_fabric.vvp +bad-last > $(BUILD_DIR)/fabric-bad-last.log 2>&1; then echo "invalid WLAST was accepted"; exit 1; fi
	rg -F "fabric WLAST disagrees with accepted AWLEN" $(BUILD_DIR)/fabric-bad-last.log

negative: negative-fabric
.PHONY: pipeline-matrix negative-fabric
pipeline-matrix: $(BUILD_DIR)/tb_r64_pipeline.vvp
	@set -e; for w in 0 1 2 3; do timeout 60 $(VVP) $< +workload=$$w > $(BUILD_DIR)/pipeline-$$w.log; rg -F -x "[PASS] tb_r64_pipeline" $(BUILD_DIR)/pipeline-$$w.log; done
	@set -e; for w in 0 1 2; do timeout 60 $(VVP) $< +workload=$$w +stalls > $(BUILD_DIR)/pipeline-stalls-$$w.log; rg -F -x "[PASS] tb_r64_pipeline" $(BUILD_DIR)/pipeline-stalls-$$w.log; done

# Whole native core with independent instruction/GPR/FPR/CSR reference.
CORE_PROGRAMS := program sv39 sdtrig lsu_contention backend_network
.PHONY: core-run core-reference
$(CORE_BUILD_DIR)/%.elf: programs/r64_core_%.S | $(CORE_BUILD_DIR)
	riscv64-linux-gnu-gcc -nostdlib -static -march=rv64gc -mabi=lp64d -Wl,-Ttext=0x80000000 -Wl,--build-id=none $< -o $@
$(CORE_BUILD_DIR)/%.bin: $(CORE_BUILD_DIR)/%.elf
	riscv64-linux-gnu-objcopy -O binary $< $@
core-run: core-reference $(CORE_BIN) $(CORE_PROGRAMS:%=$(CORE_BUILD_DIR)/%.bin)
	@set -e; for p in $(CORE_PROGRAMS); do timeout 60 $(CORE_BIN) $(CORE_BUILD_DIR)/$$p.bin $(CORE_REF) > $(CORE_BUILD_DIR)/$$p.log 2>&1; rg -F '[PASS] r64_core_program' $(CORE_BUILD_DIR)/$$p.log; timeout 60 $(CORE_BIN) $(CORE_BUILD_DIR)/$$p.bin $(CORE_REF) --stalls > $(CORE_BUILD_DIR)/$$p-stalls.log 2>&1; rg -F '[PASS] r64_core_program' $(CORE_BUILD_DIR)/$$p-stalls.log; done
# Identical native retirement/reference checker behind the real system fabric.
.PHONY: system-run
system-run: core-reference $(SYSTEM_BIN) $(CORE_PROGRAMS:%=$(CORE_BUILD_DIR)/%.bin)
	@set -e; for p in $(CORE_PROGRAMS); do timeout 60 $(SYSTEM_BIN) $(CORE_BUILD_DIR)/$$p.bin $(CORE_REF) > $(SYSTEM_BUILD_DIR)/$$p.log 2>&1; rg -F '[PASS] r64_core_program' $(SYSTEM_BUILD_DIR)/$$p.log; timeout 60 $(SYSTEM_BIN) $(CORE_BUILD_DIR)/$$p.bin $(CORE_REF) --stalls > $(SYSTEM_BUILD_DIR)/$$p-stalls.log 2>&1; rg -F '[PASS] r64_core_program' $(SYSTEM_BUILD_DIR)/$$p-stalls.log; done
# Full pipeline throughput includes real fetch/cache/AXI and NEMU comparison.
.PHONY: system-throughput
system-throughput: core-reference $(SYSTEM_BIN) $(CORE_BUILD_DIR)/throughput.bin
	python3 scripts/check_r64_core_throughput.py --sim $(SYSTEM_BIN) --image $(CORE_BUILD_DIR)/throughput.bin --elf $(CORE_BUILD_DIR)/throughput.elf --ref $(CORE_REF) --out $(SYSTEM_BUILD_DIR)/throughput

# Optional complete CPU + real Tensor NPU. Pure CPU regressions use SystemTop.
.PHONY: tensor-run
tensor-run: core-reference $(TENSOR_BIN) $(CORE_BUILD_DIR)/tensor.bin
	@set -e; for mode in plain stalls; do arg=; test $$mode != stalls || arg=--stalls; timeout 120 $(TENSOR_BIN) $(CORE_BUILD_DIR)/tensor.bin $(CORE_REF) $$arg > $(TENSOR_BUILD_DIR)/$$mode.log 2>&1; rg -F '[PASS] r64_core_program' $(TENSOR_BUILD_DIR)/$$mode.log; done

.PHONY: admission-matrix
admission-matrix: $(BUILD_DIR)/tb_r64_mem_admission.vvp
	@set -e; for cap in 6 4; do for mode in 0 1 2 3; do for stall in plain stalls; do arg=; test $$stall != stalls || arg=+stalls; log=$(BUILD_DIR)/admission-$$mode-$$stall.log; test $$cap = 6 || log=$(BUILD_DIR)/admission-cap4-$$mode-$$stall.log; timeout 60 $(VVP) $< +mode=$$mode +credit-cap=$$cap $$arg > $$log 2>&1; rg -e '^\[PASS\] tb_r64_mem_admission($$| )' $$log; done; done; done


# Retained physical PLIC tests run against the same IP in R64AxiPlatform.
$(BUILD_DIR)/tb_axi_plic.vvp: ../tests/tb_axi_plic.sv ../../vsrc/bus/AxiPlic.v ../common/tb_common.svh | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -I ../../vsrc/include -I ../common -s tb_axi_plic -o $@ ../tests/tb_axi_plic.sv ../../vsrc/bus/AxiPlic.v
negative: negative-lsu
.PHONY: negative-lsu
negative-lsu: $(BUILD_DIR)/tb_r64_lsu.vvp
	@if $(VVP) $< +bad-owner > $(BUILD_DIR)/lsu-bad-owner.log 2>&1; then echo 'unowned LSU response was accepted'; exit 1; fi
	rg -F 'R64Lsu physical response without owner' $(BUILD_DIR)/lsu-bad-owner.log
	@if $(VVP) $< +bad-store-cancel > $(BUILD_DIR)/lsu-bad-store-cancel.log 2>&1; then echo 'older store cancellation retained younger memory'; exit 1; fi
	rg -F 'R64Lsu cancelled older store retained younger memory owner' $(BUILD_DIR)/lsu-bad-store-cancel.log

# Full preserved non-OS software cohorts. Build inputs from checked-in sources;
# historical frozen benchmark images remain separately selectable for CPI A/B.
WORKSPACE_ROOT := $(abspath ../../../..)
SOFTWARE_BUILD_DIR ?= $(abspath ../../build/chengyue64)
AM_SOURCE_DIR := $(SOFTWARE_BUILD_DIR)/am-source
OFFICIAL_SOURCE_DIR := $(SOFTWARE_BUILD_DIR)/official-source
ACT4_SOURCE_DIR := $(SOFTWARE_BUILD_DIR)/act4-profile
REGRESSION_DIR ?= $(SOFTWARE_BUILD_DIR)/software
.PHONY: am-images official-images act4-images am-run official-run act4-run software-run
am-images:
	bash scripts/prepare_r64_am.sh $(AM_SOURCE_DIR) > $(SOFTWARE_BUILD_DIR)/am-source-build.log 2>&1
official-images:
	python3 scripts/prepare_r64_official.py --out $(OFFICIAL_SOURCE_DIR) --jobs $(CORE_JOBS) > $(SOFTWARE_BUILD_DIR)/official-source-build.log 2>&1
act4-images:
	bash scripts/prepare_r64_act4.sh $(ACT4_SOURCE_DIR) > $(SOFTWARE_BUILD_DIR)/act4-source-build.log 2>&1
am-run: core-reference $(SYSTEM_BIN) am-images
	python3 scripts/run_r64_am.py --tests $(WORKSPACE_ROOT)/am-kernels/tests/cpu-tests/tests --images $(AM_SOURCE_DIR)/images --sim $(SYSTEM_BIN) --ref $(CORE_REF) --out $(REGRESSION_DIR)/am --jobs 4
official-run: core-reference $(SYSTEM_BIN) official-images
	python3 scripts/run_r64_official.py --bin-dir $(OFFICIAL_SOURCE_DIR)/bins --elf-dir $(OFFICIAL_SOURCE_DIR)/elfs --sim $(SYSTEM_BIN) --ref $(CORE_REF) --out $(REGRESSION_DIR)/official --jobs 4
act4-run: core-reference $(SYSTEM_BIN) act4-images
	python3 scripts/run_r64_act4.py --elf-root $(ACT4_SOURCE_DIR)/work/r64-rebuild/elfs --sim $(SYSTEM_BIN) --ref $(CORE_REF) --out $(REGRESSION_DIR)/act4 --jobs 4
software-run: am-run official-run act4-run

TENSOR_UNIT_DIR := $(abspath $(BUILD_DIR)/tensor-unit)
TENSOR_UNIT_BIN := $(TENSOR_UNIT_DIR)/Vtb_r64_tensor
TENSOR_UNIT_SRCS := $(filter-out %/R64TensorSystemTop.v,$(R64_TENSOR_SRCS)) ../../vsrc/chengyue64/platform/R64TensorMemory.v
$(TENSOR_UNIT_BIN): modules/tb_r64_tensor.sv $(TENSOR_UNIT_SRCS) $(R64_SIM_WARNINGS) Makefile
	mkdir -p $(TENSOR_UNIT_DIR)
	verilator -Imodules --binary --timing --build -j $(CORE_JOBS) --top-module tb_r64_tensor -Mdir $(TENSOR_UNIT_DIR) --assert -DR64_ASSERT $(TENSOR_FLAGS) -I../../vsrc/include -I../../vsrc/chengyue64/backend -I../../vsrc/chengyue64/platform $(R64_SIM_WARNINGS) $(TENSOR_UNIT_SRCS) modules/tb_r64_tensor.sv > $(TENSOR_UNIT_DIR)/build.log 2>&1
.PHONY: tensor-unit
tensor-unit: $(TENSOR_UNIT_BIN)
	timeout 120 $(TENSOR_UNIT_BIN) > $(TENSOR_UNIT_DIR)/run.log 2>&1
	rg -F -x '[PASS] tb_r64_tensor' $(TENSOR_UNIT_DIR)/run.log
	@if (ulimit -c 0; $(TENSOR_UNIT_BIN) +bad-tag > $(TENSOR_UNIT_DIR)/bad-tag.log 2>&1); then echo 'wrong Tensor response owner accepted'; exit 1; fi
	rg -F 'Tensor GMEM response owner mismatch' $(TENSOR_UNIT_DIR)/bad-tag.log
tensor-run: tensor-unit

.PHONY: negative-store store-matrix
negative-store: $(BUILD_DIR)/tb_r64_lsu_coupled.vvp
	@if $(VVP) $< +bad-store-flush > $(BUILD_DIR)/store-bad-flush.log 2>&1; then echo 'visible store cancellation accepted'; exit 1; fi
	rg -F 'R64Lsu visible store cancelled before retirement' $(BUILD_DIR)/store-bad-flush.log
negative: negative-store
$(BUILD_DIR)/tb_r64_lsu_coupled_baseline.vvp: modules/tb_r64_lsu_coupled.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_lsu_coupled -Ptb_r64_lsu_coupled.EARLY_STORE=0 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_lsu_prepared.vvp: modules/tb_r64_lsu.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_lsu -Ptb_r64_lsu.EARLY_STORE=1 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_lsu_prepared.pass: $(BUILD_DIR)/tb_r64_lsu_prepared.vvp
	timeout 60 $(VVP) $< +prepared-hold > $(BUILD_DIR)/tb_r64_lsu_prepared.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/tb_r64_lsu_prepared.log
	touch $@
store-matrix: $(BUILD_DIR)/tb_r64_lsu_prepared.pass $(BUILD_DIR)/tb_r64_lsu_coupled.pass $(BUILD_DIR)/tb_r64_lsu_coupled_baseline.vvp
	timeout 60 $(VVP) $(BUILD_DIR)/tb_r64_lsu_coupled_baseline.vvp > $(BUILD_DIR)/store-baseline.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu_coupled($$| )' $(BUILD_DIR)/store-baseline.log
	rg -F 'LSU_STORE_ROI' $(BUILD_DIR)/store-baseline.log $(BUILD_DIR)/tb_r64_lsu_coupled.log

$(BUILD_DIR)/tb_uart.vvp: ../tests/tb_uart.sv ../../vsrc/bus/Uart.v | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -I ../../vsrc/include -I ../common -s tb_uart -o $@ $^

$(BUILD_DIR)/tb_axi_to_uart.vvp: ../tests/tb_axi_to_uart.sv ../../vsrc/bus/AxiToUart.v ../../vsrc/bus/Uart.v | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -I ../../vsrc/include -I ../common -s tb_axi_to_uart -o $@ $^

$(BUILD_DIR)/tb_axi_reset_syscon.vvp: ../tests/tb_axi_reset_syscon.sv ../../vsrc/bus/AxiResetSyscon.v | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -I ../../vsrc/include -I ../common -s tb_axi_reset_syscon -o $@ $^

$(BUILD_DIR)/tb_axi_clint.vvp: ../tests/tb_axi_clint.sv ../../vsrc/bus/AxiClint.v | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -I ../../vsrc/include -I ../common -s tb_axi_clint -o $@ $^


$(BUILD_DIR)/tb_r64_lsu_metadata.vvp: modules/tb_r64_lsu.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_lsu -Ptb_r64_lsu.DEPTH=2 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_lsu_metadata.pass: $(BUILD_DIR)/tb_r64_lsu_metadata.vvp
	timeout 60 $(VVP) $< +metadata-hold > $(BUILD_DIR)/tb_r64_lsu_metadata.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/tb_r64_lsu_metadata.log
	touch $@


.PHONY: lsu-source-pin
lsu-source-pin: $(BUILD_DIR)/tb_r64_lsu_coupled.vvp
	timeout 60 $(VVP) $< +source-pin > $(BUILD_DIR)/lsu-source-pin.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu_coupled($$| )' $(BUILD_DIR)/lsu-source-pin.log
store-matrix: lsu-source-pin

.PHONY: trigger-matrix
trigger-matrix: $(BUILD_DIR)/tb_r64_lsu.vvp
	timeout 60 $(VVP) $< +trigger > $(BUILD_DIR)/lsu-trigger.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/lsu-trigger.log
admission-matrix: trigger-matrix


# A late head IO/atomic/split must retain a reserved ingress even when younger
# ordinary descriptors fill the speculative queues.
$(BUILD_DIR)/tb_r64_lsu_progress.pass: $(BUILD_DIR)/tb_r64_lsu_prepared.vvp
	timeout 60 $(VVP) $< +late-io > $(BUILD_DIR)/lsu-late-io.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/lsu-late-io.log
	timeout 60 $(VVP) $< +late-special > $(BUILD_DIR)/lsu-late-special.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/lsu-late-special.log
	timeout 60 $(VVP) $< +late-special +late-amo > $(BUILD_DIR)/lsu-late-amo.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/lsu-late-amo.log
	timeout 60 $(VVP) $< +late-special +late-split > $(BUILD_DIR)/lsu-late-split.log 2>&1
	rg -e '^\[PASS\] tb_r64_lsu($$| )' $(BUILD_DIR)/lsu-late-split.log
	touch $@


# Dispatch reserves LSQ ownership before operand bind. Preserve both ABI
# rejection checks in the default negative suite.
.PHONY: negative-lsu-reserve
negative: negative-lsu-reserve
negative-lsu-reserve: $(BUILD_DIR)/tb_r64_lsu_reserve.vvp
	@if $(VVP) $< +bad-class > $(BUILD_DIR)/lsu-bind-class.log 2>&1; then echo 'changed reserved memory classification was accepted'; exit 1; fi
	rg -F 'R64Lsu bind changed reserved classification' $(BUILD_DIR)/lsu-bind-class.log
	@if $(VVP) $< +bad-double-bind > $(BUILD_DIR)/lsu-bind-duplicate.log 2>&1; then echo 'duplicate live operand bind was accepted'; exit 1; fi
	rg -F 'R64Lsu duplicate live bind' $(BUILD_DIR)/lsu-bind-duplicate.log


# Fixed terminal credit must preserve held owners when full+pop and kill meet.
.PHONY: rr-qcredit-matrix
rr-qcredit-matrix: | $(BUILD_DIR)
	@set -e; for q in 0 1; do for k in 0 1; do name=rr-qcredit-$$q-$$k; $(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_rr_qcredit -Ptb_r64_rr_qcredit.Q_ONLY_TERMINAL=$$q -Ptb_r64_rr_qcredit.TARGET_INGRESS_KILL=$$k -o $(BUILD_DIR)/$$name.vvp $(R64_RTL_SRCS) modules/tb_r64_rr_qcredit.sv > $(BUILD_DIR)/$$name-build.log 2>&1; timeout 90 $(VVP) $(BUILD_DIR)/$$name.vvp > $(BUILD_DIR)/$$name.log 2>&1; rg -F '[PASS] rr_qcredit' $(BUILD_DIR)/$$name.log; done; done

.PHONY: negative-data-terminal
negative: negative-data-terminal
negative-data-terminal: $(BUILD_DIR)/tb_r64_data_terminal.vvp
	@if $(VVP) $< +bad-terminal > $(BUILD_DIR)/data-terminal-negative.log 2>&1; then echo 'reserved terminal backpressure accepted'; exit 1; fi
	rg -F 'R64DataTranslation reserved terminal response backpressured' $(BUILD_DIR)/data-terminal-negative.log

.PHONY: negative-fp-qcredit
negative: negative-fp-qcredit
negative-fp-qcredit: $(BUILD_DIR)/tb_r64_fp_qcredit.vvp
	@if $(VVP) $< +bad-credit > $(BUILD_DIR)/fp-qcredit-overflow.log 2>&1; then echo 'occupied FP ingress slot accepted a new owner'; exit 1; fi
	rg -e 'R64 FP ingress queue overwrote occupied slot|R64 FP ingress without credit' $(BUILD_DIR)/fp-qcredit-overflow.log

TEST_TIMEOUT_tb_r64_direct_mem_execute := 180
TEST_ARGS_tb_r64_head_serial_class := +head-stop

TEST_ARGS_tb_r64_dispatch_wants := +mode=3
TEST_TIMEOUT_tb_r64_rr_raw_fp_pair := 180
.PHONY: dispatch-query-matrix
admission-matrix: dispatch-query-matrix
dispatch-query-matrix: $(BUILD_DIR)/tb_r64_dispatch_wants.vvp
	@set -e; for m in 0 1 3; do timeout 60 $(VVP) $< +mode=$$m > $(BUILD_DIR)/dispatch-query-$$m.log; rg -F '[PASS] tb_r64_dispatch_wants ' $(BUILD_DIR)/dispatch-query-$$m.log; done
	timeout 60 $(VVP) $< +mode=2 +stop-query > $(BUILD_DIR)/dispatch-query-stop.log
	rg -F '[PASS] tb_r64_dispatch_wants ' $(BUILD_DIR)/dispatch-query-stop.log

# Query references: nonalias, unused bytes, superseded sources, true sources,
# and the conservative descriptor pin at a simultaneous commit/capture edge.
.PHONY: lsu-query-pin-matrix
lsu-query-pin-matrix: $(BUILD_DIR)/tb_r64_lsu_query_pin.pass
	@set -e; for mode in outside-mask shadowed referenced multi-source commit-capture; do timeout 60 $(VVP) $(BUILD_DIR)/tb_r64_lsu_query_pin.vvp +$$mode > $(BUILD_DIR)/query-pin-$$mode.log 2>&1; rg -e '^\[PASS\] tb_r64_lsu_query_pin($$| )' $(BUILD_DIR)/query-pin-$$mode.log; done

# Query exit isolation, source snapshot/reuse, response drain and source service.
.PHONY: lsu-network-matrix
lsu-network-matrix: $(BUILD_DIR)/tb_r64_lsu_network.pass
	@set -e; for mode in reverse dead fair spill-cancel; do timeout 60 $(VVP) $(BUILD_DIR)/tb_r64_lsu_network.vvp +$$mode > $(BUILD_DIR)/lsu-network-$$mode.log 2>&1; rg -F '[PASS] tb_r64_lsu_network' $(BUILD_DIR)/lsu-network-$$mode.log; done

# Same real RR/ALU/WB-holder fixture with acceptance-time wake enabled.
.PHONY: early-accept-matrix
early-accept-matrix: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_early_wakeup -Ptb_r64_early_wakeup.EARLY_ACCEPT=1 -o $(BUILD_DIR)/early-accept.vvp $(R64_RTL_SRCS) modules/tb_r64_early_wakeup.sv > $(BUILD_DIR)/early-accept-build.log 2>&1
	timeout 60 $(VVP) $(BUILD_DIR)/early-accept.vvp > $(BUILD_DIR)/early-accept.log 2>&1
	rg -F '[PASS] tb_r64_early_wakeup ' $(BUILD_DIR)/early-accept.log

$(BUILD_DIR)/tb_r64_axi_write_bypass.vvp: modules/tb_r64_axi_write.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_axi_write -Ptb_r64_axi_write.B_BYPASS=1 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_axi_write_bypass.pass: $(BUILD_DIR)/tb_r64_axi_write_bypass.vvp
	timeout 60 $(VVP) $< > $(BUILD_DIR)/tb_r64_axi_write_bypass.log 2>&1
	rg -F '[PASS] tb_r64_axi_write' $(BUILD_DIR)/tb_r64_axi_write_bypass.log
	touch $@

$(BUILD_DIR)/tb_r64_fabric_latency_bypass.vvp: modules/tb_r64_fabric_latency.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_fabric_latency -Ptb_r64_fabric_latency.B_BYPASS=1 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_fabric_latency_bypass.pass: $(BUILD_DIR)/tb_r64_fabric_latency_bypass.vvp
	timeout 60 $(VVP) $< > $(BUILD_DIR)/tb_r64_fabric_latency_bypass.log 2>&1
	rg -F '[PASS] tb_r64_fabric_latency' $(BUILD_DIR)/tb_r64_fabric_latency_bypass.log
	touch $@

negative: negative-bypass
.PHONY: negative-bypass
negative-bypass: $(BUILD_DIR)/tb_r64_axi_write_bypass.vvp
	@if $(VVP) $< +early-b > $(BUILD_DIR)/axi-bypass-early-b.log 2>&1; then echo 'premature bypass B was accepted'; exit 1; fi
	rg -F 'AXI B response has no completed AW/W owner' $(BUILD_DIR)/axi-bypass-early-b.log

.PHONY: fabric-read-matrix
fabric-read-matrix: | $(BUILD_DIR)
	@set -e; for c in 0 1; do for e in 0 1; do name=read-continue-$$c-$$e; $(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_fabric_read_continue -Ptb_r64_fabric_read_continue.READ_CONTINUE=$$c -Ptb_r64_fabric_read_continue.EARLY_RETURN=$$e -o $(BUILD_DIR)/$$name.vvp $(R64_RTL_SRCS) modules/tb_r64_fabric_read_continue.sv > $(BUILD_DIR)/$$name-build.log 2>&1; timeout 60 $(VVP) $(BUILD_DIR)/$$name.vvp > $(BUILD_DIR)/$$name.log 2>&1; rg -F '[PASS] tb_r64_fabric_read_continue' $(BUILD_DIR)/$$name.log; done; done

.PHONY: fabric-group-matrix
fabric-group-matrix: $(BUILD_DIR)/tb_r64_fabric_groups.pass
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -s tb_r64_fabric_groups -Ptb_r64_fabric_groups.GROUPED=0 -o $(BUILD_DIR)/groups-control.vvp $(R64_RTL_ROOT)/platform/R64AxiFabric.v $(R64_RTL_ROOT)/platform/R64AxiReadService.v modules/tb_r64_fabric_groups.sv
	timeout 60 $(VVP) $(BUILD_DIR)/groups-control.vvp > $(BUILD_DIR)/groups-control.log 2>&1
	rg -F '[PASS] tb_r64_fabric_groups' $(BUILD_DIR)/groups-control.log
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -s tb_r64_fabric -Ptb_r64_fabric.READ_MEMORY_MASK=3 -o $(BUILD_DIR)/groups-random.vvp $(R64_RTL_ROOT)/platform/R64AxiFabric.v $(R64_RTL_ROOT)/platform/R64AxiReadService.v modules/tb_r64_fabric.sv
	timeout 60 $(VVP) $(BUILD_DIR)/groups-random.vvp > $(BUILD_DIR)/groups-random.log 2>&1
	rg -F '[PASS] tb_r64_fabric' $(BUILD_DIR)/groups-random.log


# Icarus elaboration of the 32-row age/port matrix scales poorly. Run the same
# assertion-bearing scenario with Verilator; production strict lint is separate.
$(BUILD_DIR)/tb_r64_issue32.pass: modules/tb_r64_issue32.sv modules/tb_r64_issue_regread.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS)
	mkdir -p $(BUILD_DIR)
	verilator -Imodules --binary --timing --assert -DR64_ASSERT -Wno-fatal -j 4 --top-module tb_r64_issue32 --prefix Vtb_r64_issue32 -Mdir $(BUILD_DIR)/issue32-obj -I../../vsrc/include -I../../vsrc/chengyue64/backend -I../../vsrc/chengyue64/platform $(R64_RTL_SRCS) modules/tb_r64_issue32.sv > $(BUILD_DIR)/tb_r64_issue32-build.log 2>&1
	timeout 60 $(BUILD_DIR)/issue32-obj/Vtb_r64_issue32 > $(BUILD_DIR)/tb_r64_issue32.log 2>&1
	rg -e '^\[PASS\] tb_r64_issue32($$| )' $(BUILD_DIR)/tb_r64_issue32.log
	touch $@

# Host loader and full-system environment contract (independent of long OS boot).
.PHONY: image-test system-io
$(SYSTEM_BUILD_DIR)/test_r64_image: host/test_r64_image.cpp $(R64_SIM_DIR)/include/r64_image.h | $(SYSTEM_BUILD_DIR)
	$(CXX) -std=c++17 -O2 -Wall -Wextra -Werror -I$(R64_SIM_DIR)/include $< -o $@
image-test: $(SYSTEM_BUILD_DIR)/test_r64_image
	$< $(SYSTEM_BUILD_DIR)/image-fixtures
$(SYSTEM_BUILD_DIR)/system-io-sentinel.bin: | $(SYSTEM_BUILD_DIR)
	python3 -c 'from pathlib import Path; Path("$@").write_bytes(bytes.fromhex("8877665544332211"))'
system-io: core-reference $(SYSTEM_BIN) $(CORE_BUILD_DIR)/uart16550.bin $(CORE_BUILD_DIR)/system_io.bin $(SYSTEM_BUILD_DIR)/system-io-sentinel.bin image-test
	@set -e; for mode in plain stalls; do arg=; test $$mode != stalls || arg=--stalls; timeout 60 $(SYSTEM_BIN) $(CORE_BUILD_DIR)/system_io.bin $(CORE_REF) --system --load=0x81000000:$(SYSTEM_BUILD_DIR)/system-io-sentinel.bin '--uart-input=?:Z' $$arg > $(SYSTEM_BUILD_DIR)/system-io-$$mode.log 2>&1; rg -F '[PASS] r64_system_poweroff' $(SYSTEM_BUILD_DIR)/system-io-$$mode.log; done
	@set -e; for mode in plain stalls; do arg=; test $$mode != stalls || arg=--stalls; timeout 60 $(SYSTEM_BIN) $(CORE_BUILD_DIR)/uart16550.bin $(CORE_REF) --system $$arg > $(SYSTEM_BUILD_DIR)/uart16550-$$mode.log 2>&1; rg -F '[PASS] r64_system_poweroff' $(SYSTEM_BUILD_DIR)/uart16550-$$mode.log; done

# Real external virtio AXI endpoint, coherent DMA and IRQ2 through PLIC.
BLOCK_TEMPLATE := $(SYSTEM_BUILD_DIR)/block-template.ext4
$(BLOCK_TEMPLATE): | $(SYSTEM_BUILD_DIR)
	truncate -s 8M $@
	mkfs.ext4 -q -F $@
$(CORE_BUILD_DIR)/block_read.elf: $(WORKSPACE_ROOT)/Linux/tools/virtio-blk-smoke.S | $(CORE_BUILD_DIR)
	riscv64-linux-gnu-gcc -nostdlib -static -march=rv64gc -mabi=lp64d -Wl,-Ttext=0x80000000 -Wl,--build-id=none $< -o $@
$(CORE_BUILD_DIR)/block_errors.elf: $(WORKSPACE_ROOT)/Linux/tools/virtio-blk-error-smoke.S | $(CORE_BUILD_DIR)
	riscv64-linux-gnu-gcc -nostdlib -static -march=rv64gc -mabi=lp64d -Wl,-Ttext=0x80000000 -Wl,--build-id=none $< -o $@
$(CORE_BUILD_DIR)/block_irq.elf: $(WORKSPACE_ROOT)/Linux/tools/virtio-blk-smoke.S
.PHONY: block-run
block-run: SHELL := /bin/bash
block-run: core-reference $(SYSTEM_BIN) $(BLOCK_TEMPLATE) $(CORE_BUILD_DIR)/block_read.bin $(CORE_BUILD_DIR)/block_errors.bin $(CORE_BUILD_DIR)/block_irq.bin
	@set -e; \
	out=$$(mktemp -d "$(SYSTEM_BUILD_DIR)/block-run-XXXXXX"); \
	sha256sum "$(BLOCK_TEMPLATE)" >"$$out/template.sha256"; \
	for test in block_read block_irq block_errors; do \
	  for mode in plain stalls; do \
	    args=(); if [ "$$mode" = stalls ]; then args+=(--stalls); fi; \
	    if [ "$$test" = block_errors ]; then args+=(--system); fi; \
	    cp --reflink=auto "$(BLOCK_TEMPLATE)" "$$out/$$test-$$mode.ext4"; \
	    timeout 180 "$(SYSTEM_BIN)" "$(CORE_BUILD_DIR)/$$test.bin" "$(CORE_REF)" \
	      --memory=0x08000000 --block="$$out/$$test-$$mode.ext4" --maxcycles=200000 \
	      "$${args[@]}" >"$$out/$$test-$$mode.log" 2>&1; \
	    rg -F '[PASS] r64_' "$$out/$$test-$$mode.log"; \
	  done; \
	done; \
	sha256sum -c "$$out/template.sha256"; \
	printf 'block results: %s\n' "$$out"

# Exercise the explicitly enabled Split-to-Service request preselection contract.
$(BUILD_DIR)/tb_r64_service_request_hint.vvp: modules/tb_r64_service_bank_pair.sv $(R64_RTL_SRCS) $(R64_RTL_HDRS) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I modules -DR64_ASSERT -I ../../vsrc/include -I ../../vsrc/chengyue64/backend -I ../../vsrc/chengyue64/platform -s tb_r64_service_bank_pair -Ptb_r64_service_bank_pair.REQUEST_HINTS=1 -o $@ $(R64_RTL_SRCS) $<
$(BUILD_DIR)/tb_r64_service_request_hint.pass: $(BUILD_DIR)/tb_r64_service_request_hint.vvp
	timeout 60 $(VVP) $< > $(BUILD_DIR)/tb_r64_service_request_hint.log 2>&1
	rg -F '[PASS] tb_r64_service_bank_pair ' $(BUILD_DIR)/tb_r64_service_request_hint.log
	touch $@

.PHONY: negative-service-request-hint
negative: negative-service-request-hint
negative-service-request-hint: $(BUILD_DIR)/tb_r64_service_request_hint.vvp
	@if $(VVP) $< +bad-request-hint > $(BUILD_DIR)/service-request-hint-negative.log 2>&1; then echo 'inconsistent live request hint was accepted'; exit 1; fi
	rg -F 'R64MemoryService request hint differs with live CPU input' $(BUILD_DIR)/service-request-hint-negative.log

# Reference construction is owned by the DiffTest adapter.
core-reference: | $(CORE_BUILD_DIR)
	$(MAKE) --no-print-directory -C ../../difftest reference CORE_REF=$(CORE_REF) > $(CORE_BUILD_DIR)/reference-build.log 2>&1
