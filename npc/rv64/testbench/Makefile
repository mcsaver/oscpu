NPC_SINGLE_HOME := $(abspath ..)
VSRCDIR := $(NPC_SINGLE_HOME)/vsrc
include $(VSRCDIR)/filelist.mk
BUILD_DIR ?= build
RESULT_TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
RESULT_DIR ?= ../perf/results/$(RESULT_TIMESTAMP)/module-testbench
LOG_DIR := $(RESULT_DIR)/logs

IVERILOG ?= iverilog
PYTHON ?= python3
TB_RESULT_CHECKER := scripts/check_tb_result.py
IFU_ICACHE_COHERENCE_CHECKER := scripts/check_ifu_icache_coherence_contract.py
ARCH_GATE_CHECKER := $(NPC_SINGLE_HOME)/eval/ppa/tools/architecture_hard_gates.py
ARCH_GATE_EVIDENCE ?= $(NPC_SINGLE_HOME)/eval/ppa/evidence/architecture-current.json
ARCH_GATE_RESULT ?= $(abspath $(BUILD_DIR)/arch-gates/result.json)
ARCH_GATE_TEST_DIR := $(NPC_SINGLE_HOME)/eval/ppa/tests
VECTORED_TRAP_MUTATION_RESULT ?= $(abspath $(RESULT_DIR)/vectored-trap-mutations)
VECTORED_TRAP_MUTATION_RUNNER := scripts/run_csr_vectored_trap_mutations.py
V11I_TERMINAL_LIFECYCLE_RESULT ?= $(abspath $(RESULT_DIR)/v11i-terminal-lifecycle)
V11I_TERMINAL_LIFECYCLE_RUNNER := scripts/run_v11i_terminal_lifecycle.py
V11J_BRIDGE_HOLDER_RESULT ?= $(abspath $(RESULT_DIR)/v11j-bridge-holder-semantic)
V11J_BRIDGE_HOLDER_RUNNER := scripts/run_v11j_bridge_holder_semantic.py
V11K_MIQ_HOLDER_RESULT ?= $(abspath $(RESULT_DIR)/v11k-miq-holder-semantic)
V11K_MIQ_HOLDER_RUNNER := scripts/run_v11k_miq_holder_semantic.py
V11L_MEMORY_RETRY_HOLDER_RESULT ?= $(abspath $(RESULT_DIR)/v11l-memory-retry-holder-semantic)
V11L_MEMORY_RETRY_HOLDER_RUNNER := scripts/run_v11l_memory_retry_holder_semantic.py
V11M_MEMORY_RESERVATION_HOLDER_RESULT ?= $(abspath $(RESULT_DIR)/v11m-memory-reservation-holder-semantic)
V11M_MEMORY_RESERVATION_HOLDER_RUNNER := scripts/run_v11m_memory_reservation_holder_semantic.py
V11N_MEMORY_PENDING_HOLDER_RESULT ?= $(abspath $(RESULT_DIR)/v11n-memory-pending-holder-semantic)
V11N_MEMORY_PENDING_HOLDER_RUNNER := scripts/run_v11n_memory_pending_holder_semantic.py
V11O_MEMORY_BUFFER_TOKEN_RESULT ?= $(abspath $(RESULT_DIR)/v11o-memory-buffer-token-semantic)
V11O_MEMORY_BUFFER_TOKEN_RUNNER := scripts/run_v11o_memory_buffer_token_semantic.py
V11P_CHECKPOINT_IRREVOCABLE_WRITE_RESULT ?= $(abspath $(RESULT_DIR)/v11p-checkpoint-irrevocable-write-semantic)
V11P_CHECKPOINT_IRREVOCABLE_WRITE_RUNNER := scripts/run_v11p_checkpoint_irrevocable_write_semantic.py
V11Q_INT_LANE0_PACKET_RESULT ?= $(abspath $(RESULT_DIR)/v11q-int-lane0-packet-semantic)
V11Q_INT_LANE0_PACKET_RUNNER := scripts/run_v11q_int_lane0_packet_semantic.py
V11R_INT_LANE1_PACKET_RESULT ?= $(abspath $(RESULT_DIR)/v11r-int-lane1-packet-semantic)
V11R_INT_LANE1_PACKET_RUNNER := scripts/run_v11r_int_lane1_packet_semantic.py
# iverilog 与 vvp 必须同源同版本：14.0 编译产物喂 12.0 runtime 会拒跑
# ("VVP input file 14.0 can not be run with run time version 12.0")。
# 取实际命中 iverilog 的同目录 vvp，找不到才退回 PATH。
# (旧方案硬选 /usr/bin/vvp 因"oss-cad-suite vvp 不完整"，该前提已过时：当前套件 vvp 可正常跑 TB。)
IVERILOG_BIN_DIR := $(dir $(shell command -v $(IVERILOG) 2>/dev/null))
VVP ?= $(if $(wildcard $(IVERILOG_BIN_DIR)vvp),$(IVERILOG_BIN_DIR)vvp,vvp)
IVFLAGS ?= -g2012 -Wall -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) -Icommon -DOOO_ASSERT
RTL_EVIDENCE_SHA ?=

TESTS := \
  tb_pipe_stage_reg \
  tb_alu \
  tb_compare \
  tb_immgen \
  tb_wbu \
  tb_lsu_control \
  tb_lsu_datapath \
  tb_lsu \
  tb_pmp_checker \
  tb_ooo_pma_checker \
  tb_ooo_typed_memory_classifier \
  tb_uart \
  tb_axi_to_uart \
  tb_axi_reset_syscon \
  tb_axi_clint \
  tb_axi_plic \
  tb_axi_xbar \
  tb_axi_exec_firewall \
  tb_csr_file \
  tb_csr_file_vectored_trap \
  tb_decode_unit \
  tb_decode_stage \
  tb_ooo_rename_map \
  tb_ooo_free_list \
  tb_ooo_load_queue \
  tb_ooo_store_queue \
  tb_ooo_mem_owner_tracker \
  tb_ooo_mem_owner_terminal_collector \
  tb_ooo_mem_inflight_queue \
  tb_ooo_mmu_epoch_owner \
  tb_ooo_rob \
  tb_ooo_phys_reg_file \
  tb_ooo_fp_reg_file \
  tb_ooo_fp_phys_reg_file \
  tb_ooo_busy_table \
  tb_ooo_int_issue_queue \
  tb_ooo_fp_issue_queue \
  tb_ooo_dispatch_backend \
  tb_ooo_muldiv_unit \
  tb_ooo_clmul_unit \
  tb_ooo_int_backend \
  tb_ooo_bitmanip_gate \
  tb_ooo_amo_gate \
  tb_ooo_alu_decode_backend \
  tb_ooo_alu_core_slice \
  tb_ooo_core_top_glue \
  tb_ooo_fp_iter \
  tb_ooo_fp_classify_gate \
  tb_ooo_fp_sgnj_gate \
  tb_ooo_fp_compare_gate \
  tb_ooo_fp_convert_gate \
  tb_ooo_fp_arith_gate \
  tb_ooo_fp_long_op_gate \
  tb_ooo_direct_ras_candidate_gate \
  tb_ooo_ras_update_gate \
  tb_ooo_branch_spec_tracker \
  tb_ooo_fetch_pc_outstanding_sequencer \
  tb_ooo_control_commit_sequencer \
  tb_ooo_commit_output_mux \
  tb_ooo_control_flush_sequencer \
  tb_ooo_control_event_apply_sequencer \
  tb_ooo_redirect_arbiter \
  tb_ooo_stop_pending_sequencer \
  tb_ooo_csr_access_request_mux \
  tb_ooo_csr_trap_request_mux \
  tb_ooo_pending_lane1_capture_gate \
  tb_ooo_pending_dispatch_arbiter \
  tb_ooo_pending_drain_resolve_gate \
  tb_ooo_pending_arch_trap_memory_terminal \
  tb_ooo_serialized_owner_exactly_once \
  tb_ooo_pending_system_admission_cancel_gate \
  tb_ooo_pending_system_sequencer \
  tb_ooo_pending_trap_exit_sequencer \
  tb_ooo_trap_exit_event_mux \
  tb_ooo_trap_exit_output_sequencer \
  tb_ooo_frontend_uop_safety \
  tb_ooo_frontend_dispatch_gate \
  tb_ooo_fp_legality_dispatch_path \
  tb_ooo_frontend_backend_dispatch_mux \
  tb_ooo_direct_branch_resolve_gate \
  tb_ooo_branch_resolve_recovery_gate \
  tb_ooo_branch_append_dispatch_gate \
  tb_ooo_branch_bpu_update_gate \
  tb_ooo_branch_direction_predictor \
  tb_ooo_memory_request_gate \
  tb_ooo_frontend_run_gate \
  tb_ooo_frontend_action_gate \
  tb_ooo_fetch_request_mux \
  tb_ooo_direct_branch_wait_buffer \
  tb_ooo_backend_drain_tracker \
  tb_ooo_fetch_packet_head_mux \
  tb_ooo_fetch_packet_seed_mux \
  tb_ooo_fetch_branch_target \
  tb_ooo_fetch_packet_decode \
  tb_ooo_fetch_packet_fifo \
  tb_ooo_fetch_flow_control \
  tb_ooo_fetch_static_classify \
  tb_ooo_fetch_head_pair_gate \
  tb_ooo_fetch_head_classify_gate \
  tb_ooo_fetch_packet_cache \
  tb_ooo_data_word_cache \
  tb_ooo_fetch_axi_bridge \
  tb_ooo_fetch_axi_access_attrs \
  tb_ooo_fetch_page_end_fault \
  tb_ooo_fetch_access_footprint \
  tb_ooo_ifu_lane1_fault_owner \
  tb_ooo_fetch_axi_bridge_xbar \
  tb_ooo_fetch_trap_gate \
  tb_ooo_priv_system \
  tb_ooo_sv39_boot \
  tb_ooo_dual_memory_sustained_issue \
  tb_ooo_lsu_axi_lane_adapter \
  tb_ooo_mem_axi_bridge

FOCUSED_TESTS := \
  tb_v9n_sq_owner_residency \
  tb_v9n_amo_owner_residency \
  tb_ooo_int_backend_hist_ser_qh_younger_store \
  tb_ooo_int_backend_v11i_terminal_lifecycle \
  tb_ooo_int_backend_v11l_memory_retry_holder \
  tb_ooo_int_backend_v11m_memory_reservation_holder \
  tb_ooo_int_backend_v11n_memory_pending_holder \
  tb_ooo_int_backend_v11o_memory_buffer_token \
  tb_ooo_int_backend_v11p_checkpoint_irrevocable_write \
  tb_ooo_int_backend_v11q_int_lane0_packet \
  tb_ooo_int_backend_v11r_int_lane1_packet \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  tb_ooo_mem_axi_bridge_v13p_store_b_fusion \
  tb_ooo_int_backend_v13p_store_b_fusion \
  tb_ooo_int_backend_v13q_store_b_error_backpressure \
  tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold \
  tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold \
  tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 \
  tb_ooo_dual_mem_bridge_holder_semantic \
  tb_ooo_dual_mem_inflight_queue_semantic \
  tb_ooo_core_top_glue_v9o_csr_qh \
  tb_ooo_core_top_glue_hist_ser_qh_stop_hold \
  tb_ooo_core_top_glue_v9a_width_continuity \
  tb_ooo_core_top_glue_v9a_width_stall_probe \
  tb_ooo_core_top_glue_v8z_frontend_ii1 \
  tb_ooo_int_backend_v8y_speculation_recovery \
  tb_ooo_int_backend_v8x_backend_bridge_recovery \
  tb_ooo_int_backend_v8w_memory_recovery
EXTRA_TESTS := $(FOCUSED_TESTS) tb_ooo_dual_mem_bridge_wrapper

TB_SRCS_tb_alu := tests/tb_alu.sv $(RTL_ALU)
TB_SRCS_tb_compare := tests/tb_compare.sv $(RTL_COMPARE_UNIT)
TB_SRCS_tb_immgen := tests/tb_immgen.sv $(RTL_IMM_GEN)
TB_SRCS_tb_wbu := tests/tb_wbu.sv $(RTL_WBU)
TB_SRCS_tb_lsu_control := tests/tb_lsu_control.sv $(RTL_LSU_CONTROL)
TB_SRCS_tb_lsu_datapath := tests/tb_lsu_datapath.sv $(RTL_LSU_DATAPATH)
TB_SRCS_tb_lsu := tests/tb_lsu.sv $(RTL_LSU_CONTROL) $(RTL_LSU_DATAPATH) $(RTL_LSU)
TB_SRCS_tb_pmp_checker := tests/tb_pmp_checker.sv $(RTL_PMP_CHECKER)
TB_SRCS_tb_ooo_pma_checker := tests/tb_ooo_pma_checker.sv $(RTL_TYPED_PMA_CHECKER) $(RTL_PMA_CHECKER)
TB_SRCS_tb_ooo_typed_memory_classifier := tests/tb_ooo_typed_memory_classifier.sv $(RTL_OOO_TYPED_MEMORY_CLASSIFIER)
TB_SRCS_tb_uart := tests/tb_uart.sv $(RTL_UART)
TB_SRCS_tb_axi_to_uart := tests/tb_axi_to_uart.sv $(RTL_UART) $(RTL_AXI_TO_UART)
TB_SRCS_tb_axi_reset_syscon := tests/tb_axi_reset_syscon.sv $(RTL_AXI_RESET_SYSCON)
TB_SRCS_tb_axi_clint := tests/tb_axi_clint.sv $(RTL_AXI_CLINT)
TB_SRCS_tb_axi_plic := tests/tb_axi_plic.sv $(RTL_AXI_PLIC)
TB_SRCS_tb_axi_xbar := tests/tb_axi_xbar.sv $(RTL_AXI_CROSSBAR)
TB_SRCS_tb_axi_exec_firewall := tests/tb_axi_exec_firewall.sv $(RTL_AXI_CROSSBAR) $(RTL_AXI_DEFAULT_SLAVE) $(RTL_UART) $(RTL_AXI_TO_UART)
TB_SRCS_tb_csr_file := tests/tb_csr_file.sv $(RTL_CSR_FILE)
TB_SRCS_tb_csr_file_vectored_trap := tests/tb_csr_file_vectored_trap.sv $(RTL_CSR_FILE)
TB_SRCS_tb_decode_unit := tests/tb_decode_unit.sv $(RTL_DECODE_UNIT)
TB_SRCS_tb_decode_stage := tests/tb_decode_stage.sv $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(RTL_DECODE_STAGE)
TB_SRCS_tb_ooo_rename_map := tests/tb_ooo_rename_map.sv $(RTL_OOO_RENAME_MAP)
TB_SRCS_tb_ooo_free_list := tests/tb_ooo_free_list.sv $(RTL_OOO_FREE_LIST)
TB_SRCS_tb_ooo_load_queue := tests/tb_ooo_load_queue.sv $(RTL_OOO_LOAD_QUEUE)
TB_SRCS_tb_ooo_store_queue := tests/tb_ooo_store_queue.sv $(RTL_OOO_STORE_QUEUE)
V9N_OWNER_RESIDENCY_DIR := $(abspath ../../../.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency)
TB_SRCS_tb_v9n_sq_owner_residency := $(V9N_OWNER_RESIDENCY_DIR)/tb_v9n_sq_owner_residency.sv tests/tb_ooo_store_queue.sv $(RTL_OOO_STORE_QUEUE)
TB_TOP_tb_v9n_sq_owner_residency := tb_v9n_sq_owner_residency
TB_SRCS_tb_ooo_mem_owner_tracker := \
  tests/tb_ooo_mem_owner_tracker.sv \
  tests/tb_ooo_mem_owner_tracker_semantic_checker.sv \
  $(RTL_OOO_MEM_OWNER_TRACKER)
TB_SRCS_tb_ooo_mem_owner_terminal_collector := tests/tb_ooo_mem_owner_terminal_collector.sv $(RTL_OOO_MEM_OWNER_TERMINAL_COLLECTOR)
TB_SRCS_tb_ooo_mem_inflight_queue := tests/tb_ooo_mem_inflight_queue.sv $(RTL_OOO_MEM_INFLIGHT_QUEUE)
TB_SRCS_tb_ooo_dual_mem_inflight_queue_semantic := tests/tb_ooo_dual_mem_inflight_queue_semantic.sv $(RTL_OOO_MEM_INFLIGHT_QUEUE)
TB_SRCS_tb_ooo_mmu_epoch_owner := tests/tb_ooo_mmu_epoch_owner.sv $(RTL_OOO_MMU_EPOCH_OWNER)
TB_SRCS_tb_ooo_rob := tests/tb_ooo_rob.sv $(RTL_OOO_ROB) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_CSR_TRAP_REQUEST_MUX)
TB_SRCS_tb_ooo_phys_reg_file := tests/tb_ooo_phys_reg_file.sv $(RTL_OOO_PHYS_REG_FILE)
TB_SRCS_tb_ooo_fp_reg_file := tests/tb_ooo_fp_reg_file.sv $(RTL_OOO_FP_REG_FILE)
TB_SRCS_tb_ooo_fp_phys_reg_file := tests/tb_ooo_fp_phys_reg_file.sv $(RTL_OOO_FP_PHYS_REG_FILE)
TB_SRCS_tb_ooo_busy_table := tests/tb_ooo_busy_table.sv $(RTL_OOO_BUSY_TABLE)
TB_SRCS_tb_ooo_int_issue_queue := tests/tb_ooo_int_issue_queue.sv $(RTL_OOO_INT_ISSUE_QUEUE)
TB_SRCS_tb_ooo_fp_issue_queue := tests/tb_ooo_fp_issue_queue.sv $(RTL_OOO_FP_ISSUE_QUEUE)
TB_SRCS_tb_ooo_dispatch_backend := tests/tb_ooo_dispatch_backend.sv $(RTL_OOO_DISPATCH_BACKEND) $(RTL_OOO_RENAME_MAP) $(RTL_OOO_FREE_LIST) $(RTL_OOO_BUSY_TABLE) $(RTL_OOO_ROB) $(RTL_OOO_INT_ISSUE_QUEUE)
TB_SRCS_tb_ooo_muldiv_unit := tests/tb_ooo_muldiv_unit.sv $(RTL_OOO_MULDIV_UNIT)
TB_SRCS_tb_ooo_clmul_unit := tests/tb_ooo_clmul_unit.sv $(RTL_OOO_CLMUL_UNIT)
TB_OOO_INT_BACKEND_FP_SRCS := $(RTL_OOO_FP_BACKEND) $(RTL_OOO_FP_REG_FILE) $(RTL_OOO_FP_ISSUE_QUEUE) $(RTL_OOO_FP_PHYS_REG_FILE) $(RTL_OOO_FP_ARITH_GATE) $(RTL_OOO_FP_LONG_OP_GATE) $(RTL_OOO_FP_DIV_ITER) $(RTL_OOO_FP_SQRT_ITER) $(RTL_OOO_FP_CLASSIFY_GATE) $(RTL_OOO_FP_SGNJ_GATE) $(RTL_OOO_FP_COMPARE_GATE) $(RTL_OOO_FP_CONVERT_GATE)
TB_OOO_INT_BACKEND_SRCS := $(TB_OOO_INT_BACKEND_FP_SRCS) $(RTL_OOO_MEM_INFLIGHT_QUEUE) $(RTL_OOO_STORE_QUEUE) $(RTL_OOO_LOAD_QUEUE) $(RTL_OOO_MEM_OWNER_TRACKER) $(RTL_OOO_MEM_OWNER_TERMINAL_COLLECTOR) $(RTL_OOO_MULDIV_UNIT) $(RTL_OOO_CLMUL_UNIT) $(RTL_OOO_INT_BACKEND) $(RTL_PIPE_STAGE_REG) $(RTL_OOO_BITMANIP_GATE) $(RTL_OOO_AMO_GATE) $(RTL_OOO_DISPATCH_BACKEND) $(RTL_OOO_RENAME_MAP) $(RTL_OOO_FREE_LIST) $(RTL_OOO_BUSY_TABLE) $(RTL_OOO_ROB) $(RTL_OOO_INT_ISSUE_QUEUE) $(RTL_OOO_PHYS_REG_FILE) $(RTL_ALU) $(RTL_COMPARE_UNIT) $(RTL_LSU_CONTROL) $(RTL_LSU_DATAPATH) $(RTL_LSU) $(RTL_WBU)
TB_SRCS_tb_ooo_int_backend := tests/tb_ooo_int_backend.sv $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_int_backend_hist_ser_qh_younger_store := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_hist_ser_qh_younger_store := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_hist_ser_qh_younger_store := -DOOO_CSR_QUEUE_HEAD=1 -DHIST_SER_QH_YOUNGER_STORE_FOCUSED $(HIST_QH_MODE_FLAG)
TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11i_terminal_lifecycle := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11i_terminal_lifecycle := -DOOO_ASSERT -DV11I_TERMINAL_LIFECYCLE_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11l_memory_retry_holder := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11l_memory_retry_holder := -DOOO_ASSERT -DV11L_MEMORY_RETRY_HOLDER_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11m_memory_reservation_holder := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11m_memory_reservation_holder := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11m_memory_reservation_holder := -DOOO_ASSERT -DV11M_MEMORY_RESERVATION_HOLDER_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11n_memory_pending_holder := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11n_memory_pending_holder := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11n_memory_pending_holder := -DOOO_ASSERT -DV11N_MEMORY_PENDING_HOLDER_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11o_memory_buffer_token := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11o_memory_buffer_token := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11o_memory_buffer_token := -DOOO_ASSERT -DV11O_MEMORY_BUFFER_TOKEN_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11p_checkpoint_irrevocable_write := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11p_checkpoint_irrevocable_write := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11p_checkpoint_irrevocable_write := -DOOO_ASSERT -DV11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11q_int_lane0_packet := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11q_int_lane0_packet := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11q_int_lane0_packet := -DOOO_ASSERT -DV11Q_INT_LANE0_PACKET_FOCUSED
TB_SRCS_tb_ooo_int_backend_v11r_int_lane1_packet := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v11r_int_lane1_packet := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v11r_int_lane1_packet := -DOOO_ASSERT -DV11R_INT_LANE1_PACKET_FOCUSED
TB_SRCS_tb_ooo_int_backend_v9r_sq_retry_c0 := $(TB_SRCS_tb_ooo_int_backend)
TB_TOP_tb_ooo_int_backend_v9r_sq_retry_c0 := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v9r_sq_retry_c0 := -DOOO_ASSERT -DV9R_SQ_RETRY_C0_FOCUSED
TB_SRCS_tb_v9n_amo_owner_residency := $(V9N_OWNER_RESIDENCY_DIR)/tb_v9n_amo_owner_residency.sv tests/tb_ooo_int_backend.sv $(TB_OOO_INT_BACKEND_SRCS)
TB_TOP_tb_v9n_amo_owner_residency := tb_v9n_amo_owner_residency
TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery := tests/tb_ooo_int_backend.sv $(TB_OOO_INT_BACKEND_SRCS) $(RTL_PMP_CHECKER) $(RTL_TYPED_PMA_CHECKER) $(RTL_OOO_TYPED_MEMORY_CLASSIFIER) $(RTL_PMA_CHECKER) $(RTL_OOO_POST_TRANSLATE_MEMORY_CLASS) $(RTL_OOO_DATA_WORD_CACHE) $(RTL_SRAM_DATA_WORD) $(RTL_OOO_SV39_TLB) $(RTL_OOO_MEM_AXI_BRIDGE) $(RTL_OOO_DUAL_MEM_AXI_ARBITER) $(RTL_OOO_DUAL_MEM_BRIDGE_WRAPPER)
TB_DEPS_tb_ooo_int_backend_v8x_backend_bridge_recovery := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v8x_backend_bridge_recovery := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v8x_backend_bridge_recovery := -DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
TB_SRCS_tb_ooo_int_backend_v13p_store_b_fusion := $(TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery)
TB_DEPS_tb_ooo_int_backend_v13p_store_b_fusion := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v13p_store_b_fusion := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v13p_store_b_fusion := -DOOO_ASSERT -DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED -DV13P_BACKEND_BRIDGE_STORE_FOCUSED
TB_SRCS_tb_ooo_int_backend_v13q_store_b_error_backpressure := $(TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery)
TB_DEPS_tb_ooo_int_backend_v13q_store_b_error_backpressure := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v13q_store_b_error_backpressure := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v13q_store_b_error_backpressure := -DOOO_ASSERT -DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED -DV13Q_BACKEND_BRIDGE_STORE_ERROR_BP_FOCUSED
TB_SRCS_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold := $(TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery)
TB_DEPS_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold := -DOOO_ASSERT -DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED -DV13Q_BACKEND_BRIDGE_STORE_ERROR_BP_FOCUSED -DV13R_BACKEND_BRIDGE_STORE_ERROR_HOLD_FOCUSED
TB_SRCS_tb_ooo_int_backend_v8y_speculation_recovery := $(TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery)
TB_DEPS_tb_ooo_int_backend_v8y_speculation_recovery := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v8y_speculation_recovery := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v8y_speculation_recovery := -DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED -DV8Y_SPECULATION_RECOVERY_FOCUSED
TB_SRCS_tb_ooo_int_backend_v8w_memory_recovery := tests/tb_ooo_int_backend.sv $(TB_OOO_INT_BACKEND_SRCS)
TB_DEPS_tb_ooo_int_backend_v8w_memory_recovery := tests/tb_ooo_int_backend_v8x_bridge.svh
TB_TOP_tb_ooo_int_backend_v8w_memory_recovery := tb_ooo_int_backend
TB_IVFLAGS_tb_ooo_int_backend_v8w_memory_recovery := -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET
TB_SRCS_tb_ooo_bitmanip_gate := tests/tb_ooo_bitmanip_gate.sv $(RTL_OOO_BITMANIP_GATE)
TB_SRCS_tb_ooo_amo_gate := tests/tb_ooo_amo_gate.sv $(RTL_OOO_AMO_GATE)
TB_SRCS_tb_ooo_alu_decode_backend := tests/tb_ooo_alu_decode_backend.sv $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_alu_core_slice := tests/tb_ooo_alu_core_slice.sv $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_core_top_glue := tests/tb_ooo_core_top_glue.sv $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_core_top_glue_v8z_frontend_ii1 := $(TB_SRCS_tb_ooo_core_top_glue)
TB_TOP_tb_ooo_core_top_glue_v8z_frontend_ii1 := tb_ooo_core_top_glue
TB_IVFLAGS_tb_ooo_core_top_glue_v8z_frontend_ii1 := -DV8Z_FRONTEND_II1_FOCUSED
TB_SRCS_tb_ooo_core_top_glue_v9o_csr_qh := $(TB_SRCS_tb_ooo_core_top_glue)
TB_TOP_tb_ooo_core_top_glue_v9o_csr_qh := tb_ooo_core_top_glue
TB_IVFLAGS_tb_ooo_core_top_glue_v9o_csr_qh := -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCUSED
TB_SRCS_tb_ooo_core_top_glue_hist_ser_qh_stop_hold := $(TB_SRCS_tb_ooo_core_top_glue)
TB_TOP_tb_ooo_core_top_glue_hist_ser_qh_stop_hold := tb_ooo_core_top_glue
TB_IVFLAGS_tb_ooo_core_top_glue_hist_ser_qh_stop_hold := -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCUSED -DHIST_SER_QH_STOP_HOLD_FOCUSED
TB_SRCS_tb_ooo_core_top_glue_v9a_width_continuity := $(TB_SRCS_tb_ooo_core_top_glue)
TB_TOP_tb_ooo_core_top_glue_v9a_width_continuity := tb_ooo_core_top_glue
TB_IVFLAGS_tb_ooo_core_top_glue_v9a_width_continuity := -DV9A_WIDTH_CONTINUITY_FOCUSED
TB_SRCS_tb_ooo_core_top_glue_v9a_width_stall_probe := $(TB_SRCS_tb_ooo_core_top_glue)
TB_TOP_tb_ooo_core_top_glue_v9a_width_stall_probe := tb_ooo_core_top_glue
TB_IVFLAGS_tb_ooo_core_top_glue_v9a_width_stall_probe := -DV9A_WIDTH_CONTINUITY_FOCUSED -DV9A_WIDTH_WINDOW_STALL_PROBE
TB_SRCS_tb_ooo_fp_iter := tests/tb_ooo_fp_iter.sv $(RTL_OOO_FP_DIV_ITER) $(RTL_OOO_FP_SQRT_ITER)
TB_SRCS_tb_ooo_fp_classify_gate := tests/tb_ooo_fp_classify_gate.sv $(RTL_OOO_FP_CLASSIFY_GATE)
TB_SRCS_tb_ooo_fp_sgnj_gate := tests/tb_ooo_fp_sgnj_gate.sv $(RTL_OOO_FP_SGNJ_GATE)
TB_SRCS_tb_ooo_fp_compare_gate := tests/tb_ooo_fp_compare_gate.sv $(RTL_OOO_FP_COMPARE_GATE)
TB_SRCS_tb_ooo_fp_convert_gate := tests/tb_ooo_fp_convert_gate.sv $(RTL_OOO_FP_CONVERT_GATE)
TB_SRCS_tb_ooo_fp_arith_gate := tests/tb_ooo_fp_arith_gate.sv $(RTL_OOO_FP_ARITH_GATE)
TB_SRCS_tb_ooo_fp_long_op_gate := tests/tb_ooo_fp_long_op_gate.sv $(RTL_OOO_FP_LONG_OP_GATE) $(RTL_OOO_FP_DIV_ITER) $(RTL_OOO_FP_SQRT_ITER)
TB_SRCS_tb_ooo_direct_ras_candidate_gate := tests/tb_ooo_direct_ras_candidate_gate.sv $(RTL_OOO_DIRECT_RAS_CANDIDATE_GATE)
TB_SRCS_tb_ooo_ras_update_gate := tests/tb_ooo_ras_update_gate.sv $(RTL_OOO_RAS_UPDATE_GATE)
TB_SRCS_tb_ooo_branch_spec_tracker := tests/tb_ooo_branch_spec_tracker.sv $(RTL_OOO_BRANCH_SPEC_TRACKER)
TB_SRCS_tb_ooo_fetch_pc_outstanding_sequencer := tests/tb_ooo_fetch_pc_outstanding_sequencer.sv $(RTL_OOO_FETCH_PC_OUTSTANDING_SEQUENCER)
TB_SRCS_tb_ooo_control_commit_sequencer := tests/tb_ooo_control_commit_sequencer.sv $(RTL_OOO_CONTROL_COMMIT_SEQUENCER)
TB_SRCS_tb_ooo_commit_output_mux := tests/tb_ooo_commit_output_mux.sv $(RTL_OOO_COMMIT_OUTPUT_MUX)
TB_SRCS_tb_ooo_control_flush_sequencer := tests/tb_ooo_control_flush_sequencer.sv $(RTL_OOO_CONTROL_FLUSH_SEQUENCER)
TB_SRCS_tb_ooo_control_event_apply_sequencer := tests/tb_ooo_control_event_apply_sequencer.sv $(RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER)
TB_SRCS_tb_ooo_redirect_arbiter := tests/tb_ooo_redirect_arbiter.sv $(RTL_OOO_REDIRECT_ARBITER)
TB_SRCS_tb_ooo_stop_pending_sequencer := tests/tb_ooo_stop_pending_sequencer.sv $(RTL_OOO_STOP_PENDING_SEQUENCER)
TB_SRCS_tb_ooo_csr_access_request_mux := tests/tb_ooo_csr_access_request_mux.sv $(RTL_OOO_CSR_ACCESS_REQUEST_MUX)
TB_SRCS_tb_ooo_csr_trap_request_mux := tests/tb_ooo_csr_trap_request_mux.sv $(RTL_OOO_CSR_TRAP_REQUEST_MUX)
TB_SRCS_tb_ooo_pending_lane1_capture_gate := tests/tb_ooo_pending_lane1_capture_gate.sv $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE)
TB_SRCS_tb_ooo_pending_dispatch_arbiter := tests/tb_ooo_pending_dispatch_arbiter.sv $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE) $(RTL_OOO_PENDING_DISPATCH_ARBITER)
TB_SRCS_tb_ooo_pending_drain_resolve_gate := tests/tb_ooo_pending_drain_resolve_gate.sv $(RTL_OOO_PENDING_DRAIN_RESOLVE_GATE)
TB_SRCS_tb_ooo_pending_arch_trap_memory_terminal := tests/tb_ooo_pending_arch_trap_memory_terminal.sv $(RTL_OOO_PENDING_DRAIN_RESOLVE_GATE) $(RTL_OOO_CSR_TRAP_REQUEST_MUX)
TB_SRCS_tb_ooo_serialized_owner_exactly_once := tests/tb_ooo_serialized_owner_exactly_once.sv $(RTL_OOO_FRONTEND_RUN_GATE) $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE) $(RTL_OOO_PENDING_DISPATCH_ARBITER) $(RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER) $(RTL_OOO_PENDING_SYSTEM_SEQUENCER) $(RTL_OOO_STOP_PENDING_SEQUENCER) $(RTL_OOO_PENDING_DRAIN_RESOLVE_GATE) $(RTL_OOO_CSR_TRAP_REQUEST_MUX) $(RTL_OOO_TRAP_EXIT_EVENT_MUX) $(RTL_OOO_TRAP_EXIT_OUTPUT_SEQUENCER) $(RTL_CSR_FILE)
TB_SRCS_tb_ooo_pending_system_admission_cancel_gate := tests/tb_ooo_pending_system_admission_cancel_gate.sv $(RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE)
TB_SRCS_tb_ooo_pending_system_sequencer := tests/tb_ooo_pending_system_sequencer.sv $(RTL_OOO_PENDING_SYSTEM_SEQUENCER)
TB_SRCS_tb_ooo_pending_system_lease_probe := tests/tb_ooo_pending_system_lease_probe.sv $(RTL_OOO_PENDING_SYSTEM_SEQUENCER)
TB_SRCS_tb_ooo_pending_trap_exit_sequencer := tests/tb_ooo_pending_trap_exit_sequencer.sv $(RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER)
TB_SRCS_tb_ooo_trap_exit_event_mux := tests/tb_ooo_trap_exit_event_mux.sv $(RTL_OOO_TRAP_EXIT_EVENT_MUX)
TB_SRCS_tb_ooo_trap_exit_output_sequencer := tests/tb_ooo_trap_exit_output_sequencer.sv $(RTL_OOO_TRAP_EXIT_OUTPUT_SEQUENCER)
TB_SRCS_tb_ooo_frontend_uop_safety := tests/tb_ooo_frontend_uop_safety.sv $(RTL_OOO_FRONTEND_UOP_SAFETY)
TB_SRCS_tb_ooo_frontend_dispatch_gate := tests/tb_ooo_frontend_dispatch_gate.sv $(RTL_OOO_FRONTEND_DISPATCH_GATE)
TB_SRCS_tb_ooo_fp_legality_dispatch_path := tests/tb_ooo_fp_legality_dispatch_path.sv $(RTL_DECODE_UNIT) $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_STATIC_CLASSIFY) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE) $(RTL_OOO_FRONTEND_DISPATCH_GATE)
TB_SRCS_tb_ooo_frontend_backend_dispatch_mux := tests/tb_ooo_frontend_backend_dispatch_mux.sv $(RTL_OOO_FRONTEND_BACKEND_DISPATCH_MUX)
TB_SRCS_tb_ooo_direct_branch_resolve_gate := tests/tb_ooo_direct_branch_resolve_gate.sv $(RTL_OOO_DIRECT_BRANCH_RESOLVE_GATE)
TB_SRCS_tb_ooo_branch_resolve_recovery_gate := tests/tb_ooo_branch_resolve_recovery_gate.sv $(RTL_OOO_BRANCH_RESOLVE_RECOVERY_GATE)
# [wave5b 死硅拆除] tb_ooo_pending_control_resolve_gate / _branch_sequencer / _jump_sequencer 已删（模块退休）
TB_SRCS_tb_ooo_branch_append_dispatch_gate := tests/tb_ooo_branch_append_dispatch_gate.sv $(RTL_OOO_BRANCH_APPEND_DISPATCH_GATE)
TB_SRCS_tb_ooo_branch_bpu_update_gate := tests/tb_ooo_branch_bpu_update_gate.sv $(RTL_OOO_BRANCH_BPU_UPDATE_GATE)
TB_SRCS_tb_ooo_branch_direction_predictor := tests/tb_ooo_branch_direction_predictor.sv $(RTL_OOO_BRANCH_DIRECTION_PREDICTOR) $(RTL_OOO_BRANCH_DIRECTION_PREDICTOR_CHECKER)
TB_SRCS_tb_ooo_memory_request_gate := tests/tb_ooo_memory_request_gate.sv $(RTL_OOO_MEMORY_REQUEST_GATE)
TB_SRCS_tb_ooo_frontend_run_gate := tests/tb_ooo_frontend_run_gate.sv $(RTL_OOO_FRONTEND_RUN_GATE)
TB_SRCS_tb_ooo_frontend_action_gate := tests/tb_ooo_frontend_action_gate.sv $(RTL_OOO_FRONTEND_ACTION_GATE)
TB_SRCS_tb_ooo_fetch_request_mux := tests/tb_ooo_fetch_request_mux.sv $(RTL_OOO_FETCH_REQUEST_MUX)
TB_SRCS_tb_ooo_direct_branch_wait_buffer := tests/tb_ooo_direct_branch_wait_buffer.sv $(RTL_OOO_DIRECT_BRANCH_WAIT_BUFFER)
TB_SRCS_tb_ooo_backend_drain_tracker := tests/tb_ooo_backend_drain_tracker.sv $(RTL_OOO_BACKEND_DRAIN_TRACKER)
TB_SRCS_tb_ooo_fetch_packet_head_mux := tests/tb_ooo_fetch_packet_head_mux.sv $(RTL_OOO_FETCH_PACKET_HEAD_MUX)
TB_SRCS_tb_ooo_fetch_packet_seed_mux := tests/tb_ooo_fetch_packet_seed_mux.sv $(RTL_OOO_FETCH_PACKET_SEED_MUX)
TB_SRCS_tb_ooo_fetch_branch_target := tests/tb_ooo_fetch_branch_target.sv $(RTL_OOO_FETCH_BRANCH_TARGET)
TB_SRCS_tb_ooo_fetch_packet_decode := tests/tb_ooo_fetch_packet_decode.sv $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE)
TB_SRCS_tb_ooo_fetch_packet_fifo := tests/tb_ooo_fetch_packet_fifo.sv $(RTL_OOO_FETCH_PACKET_FIFO)
TB_SRCS_tb_ooo_fetch_flow_control := tests/tb_ooo_fetch_flow_control.sv $(RTL_OOO_FETCH_FLOW_CONTROL)
TB_SRCS_tb_ooo_fetch_static_classify := tests/tb_ooo_fetch_static_classify.sv $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_STATIC_CLASSIFY)
TB_SRCS_tb_ooo_fetch_head_pair_gate := tests/tb_ooo_fetch_head_pair_gate.sv $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_STATIC_CLASSIFY) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE) $(RTL_OOO_FETCH_HEAD_PAIR_GATE)
TB_SRCS_tb_ooo_fetch_head_classify_gate := tests/tb_ooo_fetch_head_classify_gate.sv $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_STATIC_CLASSIFY) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE)
TB_SRCS_tb_pipe_stage_reg := tests/tb_pipe_stage_reg.sv $(RTL_PIPE_STAGE_REG)
TB_SRCS_tb_ooo_fetch_packet_cache := tests/tb_ooo_fetch_packet_cache.sv $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_FETCH_PACKET_CACHE_CHECKER)
TB_SRCS_tb_ooo_data_word_cache := tests/tb_ooo_data_word_cache.sv $(RTL_OOO_DATA_WORD_CACHE) $(RTL_SRAM_DATA_WORD) $(RTL_OOO_DATA_WORD_CACHE_CHECKER)
TB_SRCS_tb_ooo_fetch_axi_bridge := tests/tb_ooo_fetch_axi_bridge.sv $(RTL_PMP_CHECKER) $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE)
TB_SRCS_tb_ooo_fetch_axi_access_attrs := tests/tb_ooo_fetch_axi_access_attrs.sv $(RTL_PMP_CHECKER) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE)
TB_SRCS_tb_ooo_fetch_page_end_fault := tests/tb_ooo_fetch_page_end_fault.sv $(RTL_PMP_CHECKER) $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE)
TB_SRCS_tb_ooo_fetch_access_footprint := tests/tb_ooo_fetch_access_footprint.sv $(RTL_PMP_CHECKER) $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE)
TB_SRCS_tb_ooo_ifu_lane1_fault_owner := tests/tb_ooo_ifu_lane1_fault_owner.sv $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE) $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_STATIC_CLASSIFY) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE) $(RTL_OOO_FETCH_HEAD_PAIR_GATE) $(RTL_OOO_FRONTEND_DISPATCH_GATE) $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE) $(RTL_OOO_PENDING_DISPATCH_ARBITER) $(RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER) $(RTL_OOO_STOP_PENDING_SEQUENCER) $(RTL_OOO_CSR_TRAP_REQUEST_MUX)
TB_SRCS_tb_ooo_fetch_axi_bridge_xbar := tests/tb_ooo_fetch_axi_bridge_xbar.sv $(RTL_PMP_CHECKER) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_SRAM_FETCH_PACKET) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE) $(RTL_AXI_CROSSBAR)
TB_SRCS_tb_ooo_fetch_trap_gate := tests/tb_ooo_fetch_trap_gate.sv $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_priv_system := tests/tb_ooo_priv_system.sv $(RTL_TYPED_PMA_CHECKER) $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_sv39_boot := tests/tb_ooo_sv39_boot.sv $(RTL_CORE_SRCS)
TB_SRCS_tb_ooo_dual_memory_sustained_issue := tests/tb_ooo_dual_memory_sustained_issue.sv $(RTL_CORE_SRCS)
TB_SRCS_tb_ooo_lsu_axi_lane_adapter := tests/tb_ooo_lsu_axi_lane_adapter.sv $(RTL_OOO_LSU_AXI_LANE_ADAPTER)
TB_SRCS_tb_ooo_mem_axi_bridge := tests/tb_ooo_mem_axi_bridge.sv $(RTL_PMP_CHECKER) $(RTL_TYPED_PMA_CHECKER) $(RTL_OOO_TYPED_MEMORY_CLASSIFIER) $(RTL_PMA_CHECKER) $(RTL_OOO_POST_TRANSLATE_MEMORY_CLASS) $(RTL_OOO_DATA_WORD_CACHE) $(RTL_SRAM_DATA_WORD) $(RTL_OOO_SV39_TLB) $(RTL_OOO_MEM_AXI_BRIDGE)
TB_SRCS_tb_ooo_mem_axi_bridge_v13p_store_b_fusion := $(TB_SRCS_tb_ooo_mem_axi_bridge)
TB_TOP_tb_ooo_mem_axi_bridge_v13p_store_b_fusion := tb_ooo_mem_axi_bridge
TB_IVFLAGS_tb_ooo_mem_axi_bridge_v13p_store_b_fusion := -DOOO_ASSERT -DV13P_STORE_B_FUSION_FOCUSED
TB_SRCS_tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold := $(TB_SRCS_tb_ooo_mem_axi_bridge)
TB_TOP_tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold := tb_ooo_mem_axi_bridge
TB_IVFLAGS_tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold := -DOOO_ASSERT -DV13R_STORE_B_MULTICYCLE_HOLD_FOCUSED
TB_SRCS_tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 := $(TB_SRCS_tb_ooo_mem_axi_bridge)
TB_TOP_tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 := tb_ooo_mem_axi_bridge
TB_IVFLAGS_tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 := -DOOO_ASSERT -DV9R_SQ_RETRY_C0_FOCUSED
TB_SRCS_tb_ooo_dual_mem_bridge_wrapper := tests/tb_ooo_dual_mem_bridge_wrapper.sv $(RTL_PMP_CHECKER) $(RTL_TYPED_PMA_CHECKER) $(RTL_OOO_TYPED_MEMORY_CLASSIFIER) $(RTL_PMA_CHECKER) $(RTL_OOO_POST_TRANSLATE_MEMORY_CLASS) $(RTL_OOO_DATA_WORD_CACHE) $(RTL_SRAM_DATA_WORD) $(RTL_OOO_SV39_TLB) $(RTL_OOO_MEM_AXI_BRIDGE) $(RTL_OOO_DUAL_MEM_AXI_ARBITER) $(RTL_OOO_DUAL_MEM_BRIDGE_WRAPPER)
TB_SRCS_tb_ooo_dual_mem_bridge_holder_semantic := $(TB_SRCS_tb_ooo_dual_mem_bridge_wrapper)
TB_TOP_tb_ooo_dual_mem_bridge_holder_semantic := tb_ooo_dual_mem_bridge_wrapper
TB_IVFLAGS_tb_ooo_dual_mem_bridge_holder_semantic := -DV11J_BRIDGE_HOLDER_FOCUSED
.DEFAULT_GOAL := run

.PHONY: axi-dpi-sized ifu-access-assert-negative ifu-icache-coherence-contract \
        arch-gates arch-gates-self-test print-tests vectored-trap \
        vectored-trap-mutations print-v11i-terminal-lifecycle-context \
        v11i-terminal-lifecycle-self-test v11i-terminal-lifecycle \
        print-v11j-bridge-holder-context \
        v11j-bridge-holder-self-test v11j-bridge-holder-semantic \
        print-v11k-miq-holder-context \
        print-v11k-miq-holder-regression-context \
        v11k-miq-holder-self-test v11k-miq-holder-semantic \
        print-v11l-memory-retry-holder-context \
        print-v11l-memory-retry-holder-regression-context \
        v11l-memory-retry-holder-self-test \
        v11l-memory-retry-holder-semantic \
        print-v11m-memory-reservation-holder-context \
        print-v11m-memory-reservation-holder-regression-context \
        v11m-memory-reservation-holder-self-test \
        v11m-memory-reservation-holder-semantic \
        print-v11q-int-lane0-packet-context \
        print-v11q-int-lane0-packet-regression-context \
        v11q-int-lane0-packet-self-test \
        v11q-int-lane0-packet-semantic v13p-store-b-fusion-focused \
        v13q-store-b-error-backpressure-focused \
        v13r-store-b-multicycle-retire-hold-focused \
        print-v11r-int-lane1-packet-context \
        print-v11r-int-lane1-packet-regression-context \
        v11r-int-lane1-packet-self-test \
        v11r-int-lane1-packet-semantic
print-tests:
	@printf '%s\n' $(TESTS)

vectored-trap: $(LOG_DIR)/tb_csr_file_vectored_trap.log
	@grep -E '\[VECTORED-TRAP-|\[PASS\]|\[RESULT\]' $<

vectored-trap-mutations:
	@$(PYTHON) $(VECTORED_TRAP_MUTATION_RUNNER) \
	  --result-dir "$(VECTORED_TRAP_MUTATION_RESULT)"

print-v11i-terminal-lifecycle-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))

v11i-terminal-lifecycle-self-test:
	@$(PYTHON) scripts/test_run_v11i_terminal_lifecycle.py -q

v11i-terminal-lifecycle: v11i-terminal-lifecycle-self-test
	@$(PYTHON) $(V11I_TERMINAL_LIFECYCLE_RUNNER) \
	  --result-dir "$(V11I_TERMINAL_LIFECYCLE_RESULT)"

print-v11j-bridge-holder-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_dual_mem_bridge_holder_semantic))))

v11j-bridge-holder-self-test:
	@$(PYTHON) scripts/test_run_v11j_bridge_holder_semantic.py -q

v11j-bridge-holder-semantic: v11j-bridge-holder-self-test
	@$(PYTHON) $(V11J_BRIDGE_HOLDER_RUNNER) \
	  --result-dir "$(V11J_BRIDGE_HOLDER_RESULT)"

print-v11k-miq-holder-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_dual_mem_inflight_queue_semantic))))

print-v11k-miq-holder-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_mem_inflight_queue=,$(abspath $(sort $(TB_SRCS_tb_ooo_mem_inflight_queue))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_dual_mem_inflight_queue_semantic=,$(abspath $(sort $(TB_SRCS_tb_ooo_dual_mem_inflight_queue_semantic))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11k-miq-holder-self-test:
	@$(PYTHON) scripts/test_run_v11k_miq_holder_semantic.py -q

v11k-miq-holder-semantic: v11k-miq-holder-self-test
	@$(PYTHON) $(V11K_MIQ_HOLDER_RUNNER) \
	  --result-dir "$(V11K_MIQ_HOLDER_RESULT)"

print-v11l-memory-retry-holder-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))

print-v11l-memory-retry-holder-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v9r_sq_retry_c0=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v9r_sq_retry_c0))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11l-memory-retry-holder-self-test:
	@$(PYTHON) scripts/test_run_v11l_memory_retry_holder_semantic.py -q

v11l-memory-retry-holder-semantic: v11l-memory-retry-holder-self-test
	@$(PYTHON) $(V11L_MEMORY_RETRY_HOLDER_RUNNER) \
	  --result-dir "$(V11L_MEMORY_RETRY_HOLDER_RESULT)"

print-v11m-memory-reservation-holder-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11m_memory_reservation_holder))))

print-v11m-memory-reservation-holder-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11m-memory-reservation-holder-self-test:
	@$(PYTHON) scripts/test_run_v11m_memory_reservation_holder_semantic.py -q

v11m-memory-reservation-holder-semantic: v11m-memory-reservation-holder-self-test
	@$(PYTHON) $(V11M_MEMORY_RESERVATION_HOLDER_RUNNER) \
	  --result-dir "$(V11M_MEMORY_RESERVATION_HOLDER_RESULT)"

print-v11n-memory-pending-holder-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11n_memory_pending_holder))))

print-v11n-memory-pending-holder-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11n-memory-pending-holder-self-test:
	@$(PYTHON) scripts/test_run_v11n_memory_pending_holder_semantic.py -q

v11n-memory-pending-holder-semantic: v11n-memory-pending-holder-self-test
	@$(PYTHON) $(V11N_MEMORY_PENDING_HOLDER_RUNNER) \
	  --result-dir "$(V11N_MEMORY_PENDING_HOLDER_RESULT)"

print-v11o-memory-buffer-token-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11o_memory_buffer_token))))

print-v11o-memory-buffer-token-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11o-memory-buffer-token-self-test:
	@$(PYTHON) scripts/test_run_v11o_memory_buffer_token_semantic.py -q

v11o-memory-buffer-token-semantic: v11o-memory-buffer-token-self-test
	@$(PYTHON) $(V11O_MEMORY_BUFFER_TOKEN_RUNNER) \
	  --result-dir "$(V11O_MEMORY_BUFFER_TOKEN_RESULT)"

print-v11p-checkpoint-irrevocable-write-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11p_checkpoint_irrevocable_write))))

print-v11p-checkpoint-irrevocable-write-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11p-checkpoint-irrevocable-write-self-test:
	@$(PYTHON) scripts/test_run_v11p_checkpoint_irrevocable_write_semantic.py -q

v11p-checkpoint-irrevocable-write-semantic: v11p-checkpoint-irrevocable-write-self-test
	@$(PYTHON) $(V11P_CHECKPOINT_IRREVOCABLE_WRITE_RUNNER) \
	  --result-dir "$(V11P_CHECKPOINT_IRREVOCABLE_WRITE_RESULT)"

print-v11q-int-lane0-packet-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11q_int_lane0_packet))))

print-v11q-int-lane0-packet-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11q-int-lane0-packet-self-test:
	@$(PYTHON) scripts/test_run_v11q_int_lane0_packet_semantic.py -q

v11q-int-lane0-packet-semantic: v11q-int-lane0-packet-self-test
	@$(PYTHON) $(V11Q_INT_LANE0_PACKET_RUNNER) \
	  --result-dir "$(V11Q_INT_LANE0_PACKET_RESULT)"

print-v11r-int-lane1-packet-context:
	@printf '%s\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11r_int_lane1_packet))))

print-v11r-int-lane1-packet-regression-context:
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11l_memory_retry_holder=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11l_memory_retry_holder))))
	@printf '%s\n' $(addprefix REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))
	@printf '%s\n' $(addprefix REGRESSION_COMMON=,$(abspath common/tb_common.svh common/rv32_encode.svh $(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))

v11r-int-lane1-packet-self-test:
	@$(PYTHON) scripts/test_run_v11r_int_lane1_packet_semantic.py -q

v11r-int-lane1-packet-semantic: v11r-int-lane1-packet-self-test
	@$(PYTHON) $(V11R_INT_LANE1_PACKET_RUNNER) \
	  --result-dir "$(V11R_INT_LANE1_PACKET_RESULT)"

axi-dpi-sized:
	@AXI_DPI_SIZED_BUILD_DIR="$(abspath $(BUILD_DIR)/axi-dpi-sized)" \
	  $(abspath scripts/run_axi_dpi_sized.sh)

ifu-access-assert-negative:
	@$(abspath scripts/run_ifu_access_assert_negative.sh) \
	  "$(abspath $(BUILD_DIR)/ifu-access-assert-negative)"

ifu-icache-coherence-contract:
	@$(PYTHON) $(IFU_ICACHE_COHERENCE_CHECKER)


arch-gates-self-test:
	@$(PYTHON) -m unittest discover \
	  -s $(ARCH_GATE_TEST_DIR) \
	  -p 'test_architecture_hard_gates.py' -v

arch-gates: arch-gates-self-test
	@mkdir -p $(dir $(ARCH_GATE_RESULT))
	@$(PYTHON) $(ARCH_GATE_CHECKER) \
	  --evidence-manifest $(ARCH_GATE_EVIDENCE) \
	  --output $(ARCH_GATE_RESULT)


run: ifu-icache-coherence-contract $(TESTS:%=$(LOG_DIR)/%.log) summary
	@cat $(RESULT_DIR)/summary.txt

define RUN_TEST
$(LOG_DIR)/$(1).log: $$(sort $$(TB_SRCS_$(1))) $$(TB_DEPS_$(1)) common/tb_common.svh common/rv32_encode.svh $$(TB_RESULT_CHECKER) Makefile
	@mkdir -p $(BUILD_DIR) $(LOG_DIR)
	@tmp="$$@.tmp"; \
	echo "[TEST] $(1)" > "$$$$tmp"; \
	echo "[COMPILE] $(IVERILOG) $(IVFLAGS) $$(TB_IVFLAGS_$(1)) -s $$(if $$(TB_TOP_$(1)),$$(TB_TOP_$(1)),$(1)) -o $(BUILD_DIR)/$(1).vvp $$(sort $$(TB_SRCS_$(1)))" >> "$$$$tmp"; \
	$(IVERILOG) $(IVFLAGS) $$(TB_IVFLAGS_$(1)) -s $$(if $$(TB_TOP_$(1)),$$(TB_TOP_$(1)),$(1)) -o $(BUILD_DIR)/$(1).vvp $$(sort $$(TB_SRCS_$(1))) >> "$$$$tmp" 2>&1; \
	compile_rc=$$$$?; \
	sim_rc=0; \
	if [ "$$$$compile_rc" -eq 0 ]; then \
	  $(VVP) $(BUILD_DIR)/$(1).vvp >> "$$$$tmp" 2>&1; \
	  sim_rc=$$$$?; \
	fi; \
	$(PYTHON) $(TB_RESULT_CHECKER) \
	  --test "$(1)" \
	  --source "$$(firstword $$(TB_SRCS_$(1)))" \
	  --log "$$$$tmp" \
	  --compile-rc "$$$$compile_rc" \
	  --sim-rc "$$$$sim_rc" >> "$$$$tmp" 2>&1; \
	status=$$$$?; \
	if [ -n "$(strip $(RTL_EVIDENCE_SHA))" ]; then \
	  echo "[RTL-DESIGN-ID] sha256:$(RTL_EVIDENCE_SHA)" >> "$$$$tmp"; \
	fi; \
	if [ "$$$$status" -eq 0 ]; then \
	  echo "[RESULT] PASS" >> "$$$$tmp"; \
	  mv "$$$$tmp" "$$@"; \
	else \
	  echo "[RESULT] FAIL status=$$$$status" >> "$$$$tmp"; \
	  mv "$$$$tmp" "$$@"; \
	  exit $$$$status; \
	fi
endef

$(foreach t,$(TESTS) $(EXTRA_TESTS),$(eval $(call RUN_TEST,$(t))))

v8x-backend-bridge-recovery: $(LOG_DIR)/tb_ooo_int_backend_v8x_backend_bridge_recovery.log
	@grep -E '\[V8X-|\[PASS\]|\[RESULT\]' $<

v11n-memory-pending-holder-focused: $(LOG_DIR)/tb_ooo_int_backend_v11n_memory_pending_holder.log
	@grep -E '\[V11N-|\[PASS\]|\[RESULT\]' $<

v11o-memory-buffer-token-focused: $(LOG_DIR)/tb_ooo_int_backend_v11o_memory_buffer_token.log
	@grep -E '\[V11O-|\[PASS\]|\[RESULT\]' $<

v11p-checkpoint-irrevocable-write-focused: $(LOG_DIR)/tb_ooo_int_backend_v11p_checkpoint_irrevocable_write.log
	@grep -E '\[V11P-|\[PASS\]|\[RESULT\]' $<

v11q-int-lane0-packet-focused: $(LOG_DIR)/tb_ooo_int_backend_v11q_int_lane0_packet.log
	@grep -E '\[V11Q-|\[PASS\]|\[RESULT\]' $<

v11r-int-lane1-packet-focused: $(LOG_DIR)/tb_ooo_int_backend_v11r_int_lane1_packet.log
	@grep -E '\[V11R-|\[PASS\]|\[RESULT\]' $<

v9r-sq-retry-c0-handoff: \
  $(LOG_DIR)/tb_ooo_int_backend_v9r_sq_retry_c0.log \
  $(LOG_DIR)/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log
	@grep -E '\[V9R-|\[PASS\]|\[RESULT\]' $^

v13p-store-b-fusion-focused: \
  $(LOG_DIR)/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log \
  $(LOG_DIR)/tb_ooo_int_backend_v13p_store_b_fusion.log
	@grep -E '\[V13P-B-FUSION-|\[PASS\]|\[RESULT\]' $<
	@grep -E '\[V13P-BACKEND-B-FUSION|\[PASS\]|\[RESULT\]' $(word 2,$^)

v13q-store-b-error-backpressure-focused: \
  $(LOG_DIR)/tb_ooo_int_backend_v13q_store_b_error_backpressure.log
	@grep -E '\[V13Q-BACKEND-B-|\[PASS\]|\[RESULT\]' $<

.PHONY: print-v13r-store-b-source-closure
print-v13r-store-b-source-closure:
	@printf '%s\n' $(sort \
	  $(TB_SRCS_tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold) \
	  $(TB_DEPS_tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold) \
	  $(TB_SRCS_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold) \
	  $(TB_DEPS_tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold) \
	  $(RTL_DEFINE) \
	  common/tb_common.svh common/rv32_encode.svh \
	  $(TB_RESULT_CHECKER) Makefile)

v13r-store-b-multicycle-retire-hold-focused: \
  $(LOG_DIR)/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log \
  $(LOG_DIR)/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log
	@grep -E '\[V13R-B-FUSION-MULTICYCLE|\[PASS\]|\[RESULT\]' $<
	@grep -E '\[V13R-BACKEND-|\[V13Q-BACKEND-B-CASE|\[PASS\]|\[RESULT\]' $(word 2,$^)

v8y-speculation-recovery: $(LOG_DIR)/tb_ooo_int_backend_v8y_speculation_recovery.log
	@grep -E '\[V8Y-|\[V8D-|\[V8X-|\[PASS\]|\[RESULT\]' $<

v8z-frontend-ii1: $(LOG_DIR)/tb_ooo_core_top_glue_v8z_frontend_ii1.log
	@grep -E '\[V8Z-FRONTEND-II1-|\[PASS\]|\[RESULT\]' $<

v9a-width-continuity: $(LOG_DIR)/tb_ooo_core_top_glue_v9a_width_continuity.log
	@grep -E '\[V9A-DI2-|\[PASS\]|\[RESULT\]' $<

v8x-backend-bridge-regressions: \
  $(LOG_DIR)/tb_ooo_int_backend_v8w_memory_recovery.log \
  $(LOG_DIR)/tb_ooo_mem_axi_bridge.log \
  $(LOG_DIR)/tb_ooo_dual_mem_bridge_wrapper.log
	@grep -E '\[V8W-|\[PASS\]|\[RESULT\]' $(LOG_DIR)/tb_ooo_int_backend_v8w_memory_recovery.log
	@grep -E '\[PASS\]|\[RESULT\]' $(LOG_DIR)/tb_ooo_mem_axi_bridge.log
	@grep -E '\[PASS\]|\[RESULT\]' $(LOG_DIR)/tb_ooo_dual_mem_bridge_wrapper.log

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

.PHONY: run summary clean v8z-frontend-ii1 v8y-speculation-recovery \
        v9r-sq-retry-c0-handoff \
        v11i-terminal-lifecycle \
        v8x-backend-bridge-recovery \
        v8x-backend-bridge-regressions
