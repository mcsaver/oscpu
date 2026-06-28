NPC_SINGLE_HOME := $(abspath ..)
VSRCDIR := $(NPC_SINGLE_HOME)/vsrc
include $(VSRCDIR)/filelist.mk
BUILD_DIR ?= build
RESULT_TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
RESULT_DIR ?= ../perf/results/$(RESULT_TIMESTAMP)/module-testbench
LOG_DIR := $(RESULT_DIR)/logs
PIPE_RESULT_DIR ?= ../perf/results/$(RESULT_TIMESTAMP)/pipe-test
PIPE_LOG_DIR := $(PIPE_RESULT_DIR)/logs
PIPE_EXPECT_LOAD_HIT_ZERO ?= 0
PIPE_EXPECT_FRONTEND_HIT_ZERO ?= 0
PIPE_EXPECT_ARG := $(if $(filter 1,$(PIPE_EXPECT_LOAD_HIT_ZERO)),+EXPECT_LOAD_HIT_ZERO,)
PIPE_EXPECT_FRONTEND_ARG := $(if $(filter 1,$(PIPE_EXPECT_FRONTEND_HIT_ZERO)),+EXPECT_FRONTEND_HIT_ZERO,)

IVERILOG ?= iverilog
# 当前 PATH 里可能先命中不完整 oss-cad-suite 的 vvp；优先使用系统 Icarus vvp，保证模块级 testbench 可独立复跑。
VVP ?= $(if $(wildcard /usr/bin/vvp),/usr/bin/vvp,vvp)
IVFLAGS ?= -g2012 -Wall -I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) -Icommon

TESTS := \
  tb_alu \
  tb_compare \
  tb_immgen \
  tb_wbu \
  tb_lsu_control \
  tb_lsu_datapath \
  tb_lsu \
  tb_uart \
  tb_axi_lite_to_uart \
  tb_axi_lite_clint \
  tb_axi_lite_plic \
  tb_axi_lite_xbar \
  tb_csr_file \
  tb_decode_unit \
  tb_decode_stage \
  tb_register_file \
  tb_ooo_rename_map \
  tb_ooo_free_list \
  tb_ooo_rob \
  tb_ooo_phys_reg_file \
  tb_ooo_fp_reg_file \
  tb_ooo_busy_table \
  tb_ooo_int_issue_queue \
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
  tb_ooo_fp_mem_access_gate \
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
  tb_ooo_stop_pending_sequencer \
  tb_ooo_csr_access_request_mux \
  tb_ooo_csr_trap_request_mux \
  tb_ooo_pending_lane1_capture_gate \
  tb_ooo_pending_dispatch_arbiter \
  tb_ooo_pending_system_sequencer \
  tb_ooo_pending_trap_exit_sequencer \
  tb_ooo_trap_exit_event_mux \
  tb_ooo_trap_exit_output_sequencer \
  tb_ooo_synthetic_lane1_ret_sequencer \
  tb_ooo_frontend_uop_safety \
  tb_ooo_frontend_dispatch_gate \
  tb_ooo_frontend_backend_dispatch_mux \
  tb_ooo_direct_branch_resolve_gate \
  tb_ooo_branch_resolve_recovery_gate \
  tb_ooo_pending_control_resolve_gate \
  tb_ooo_pending_branch_sequencer \
  tb_ooo_pending_jump_sequencer \
  tb_ooo_pending_fp_sequencer \
  tb_ooo_branch_append_dispatch_gate \
  tb_ooo_branch_bpu_update_gate \
  tb_ooo_branch_target_cache_control_gate \
  tb_ooo_memory_request_gate \
  tb_ooo_pending_memory_sequencer \
  tb_ooo_frontend_run_gate \
  tb_ooo_frontend_action_gate \
  tb_ooo_fetch_request_mux \
  tb_ooo_branch_prefetch_source_gate \
  tb_ooo_branch_prefetch_request_gate \
  tb_ooo_branch_prefetch_status_gate \
  tb_ooo_jalr_prefetch_status_gate \
  tb_ooo_branch_prefetch_buffer \
  tb_ooo_direct_branch_wait_buffer \
  tb_ooo_backend_drain_tracker \
  tb_ooo_fetch_packet_hit_mux \
  tb_ooo_fetch_packet_head_mux \
  tb_ooo_fetch_packet_seed_mux \
  tb_ooo_fetch_packet_decode \
  tb_ooo_fetch_packet_fifo \
  tb_ooo_fetch_flow_control \
  tb_ooo_fetch_head_pair_gate \
  tb_ooo_fetch_head_classify_gate \
  tb_ooo_fetch_packet_cache \
  tb_ooo_data_word_cache \
  tb_ooo_branch_target_cache \
  tb_ooo_branch_target_capture_buffer \
  tb_ooo_fetch_axi_bridge \
  tb_ooo_fetch_trap_gate \
  tb_ooo_priv_system \
  tb_ooo_sv39_boot \
  tb_ooo_mem_axi_bridge \
  tb_pipe_regs \
  tb_cache_control \
  tb_memory_stage_control \
  tb_memory_stage \
  tb_pipeline_control \
  tb_multiplier \
  tb_divider \
  tb_branch_predictor \
  tb_icache \
  tb_dcache \
  tb_if_stage \
  tb_npc_core_smoke \
  tb_npc_core_mcycle \
  tb_npc_core_interrupt

TB_SRCS_tb_alu := tests/tb_alu.sv $(RTL_ALU)
TB_SRCS_tb_compare := tests/tb_compare.sv $(RTL_COMPARE_UNIT)
TB_SRCS_tb_immgen := tests/tb_immgen.sv $(RTL_IMM_GEN)
TB_SRCS_tb_wbu := tests/tb_wbu.sv $(RTL_WBU)
TB_SRCS_tb_lsu_control := tests/tb_lsu_control.sv $(RTL_LSU_CONTROL)
TB_SRCS_tb_lsu_datapath := tests/tb_lsu_datapath.sv $(RTL_LSU_DATAPATH)
TB_SRCS_tb_lsu := tests/tb_lsu.sv $(RTL_LSU_CONTROL) $(RTL_LSU_DATAPATH) $(RTL_LSU)
TB_SRCS_tb_uart := tests/tb_uart.sv $(RTL_UART)
TB_SRCS_tb_axi_lite_to_uart := tests/tb_axi_lite_to_uart.sv $(RTL_UART) $(RTL_AXI_LITE_TO_UART)
TB_SRCS_tb_axi_lite_clint := tests/tb_axi_lite_clint.sv $(RTL_AXI_LITE_CLINT)
TB_SRCS_tb_axi_lite_plic := tests/tb_axi_lite_plic.sv $(RTL_AXI_LITE_PLIC)
TB_SRCS_tb_axi_lite_xbar := tests/tb_axi_lite_xbar.sv $(RTL_AXI_LITE_XBAR)
TB_SRCS_tb_csr_file := tests/tb_csr_file.sv $(RTL_CSR_FILE)
TB_SRCS_tb_decode_unit := tests/tb_decode_unit.sv $(RTL_DECODE_UNIT)
TB_SRCS_tb_decode_stage := tests/tb_decode_stage.sv $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(RTL_DECODE_STAGE)
TB_SRCS_tb_register_file := tests/tb_register_file.sv $(RTL_REGISTER_FILE)
TB_SRCS_tb_ooo_rename_map := tests/tb_ooo_rename_map.sv $(RTL_OOO_RENAME_MAP)
TB_SRCS_tb_ooo_free_list := tests/tb_ooo_free_list.sv $(RTL_OOO_FREE_LIST)
TB_SRCS_tb_ooo_rob := tests/tb_ooo_rob.sv $(RTL_OOO_ROB)
TB_SRCS_tb_ooo_phys_reg_file := tests/tb_ooo_phys_reg_file.sv $(RTL_OOO_PHYS_REG_FILE)
TB_SRCS_tb_ooo_fp_reg_file := tests/tb_ooo_fp_reg_file.sv $(RTL_OOO_FP_REG_FILE)
TB_SRCS_tb_ooo_busy_table := tests/tb_ooo_busy_table.sv $(RTL_OOO_BUSY_TABLE)
TB_SRCS_tb_ooo_int_issue_queue := tests/tb_ooo_int_issue_queue.sv $(RTL_OOO_INT_ISSUE_QUEUE)
TB_SRCS_tb_ooo_dispatch_backend := tests/tb_ooo_dispatch_backend.sv $(RTL_OOO_DISPATCH_BACKEND) $(RTL_OOO_RENAME_MAP) $(RTL_OOO_FREE_LIST) $(RTL_OOO_BUSY_TABLE) $(RTL_OOO_ROB) $(RTL_OOO_INT_ISSUE_QUEUE)
TB_SRCS_tb_ooo_muldiv_unit := tests/tb_ooo_muldiv_unit.sv $(RTL_OOO_MULDIV_UNIT)
TB_SRCS_tb_ooo_clmul_unit := tests/tb_ooo_clmul_unit.sv $(RTL_OOO_CLMUL_UNIT)
TB_OOO_INT_BACKEND_SRCS := $(RTL_OOO_MULDIV_UNIT) $(RTL_OOO_CLMUL_UNIT) $(RTL_OOO_INT_BACKEND) $(RTL_OOO_BITMANIP_GATE) $(RTL_OOO_AMO_GATE) $(RTL_OOO_DISPATCH_BACKEND) $(RTL_OOO_RENAME_MAP) $(RTL_OOO_FREE_LIST) $(RTL_OOO_BUSY_TABLE) $(RTL_OOO_ROB) $(RTL_OOO_INT_ISSUE_QUEUE) $(RTL_OOO_PHYS_REG_FILE) $(RTL_ALU) $(RTL_COMPARE_UNIT) $(RTL_LSU_CONTROL) $(RTL_LSU_DATAPATH) $(RTL_LSU) $(RTL_WBU)
TB_SRCS_tb_ooo_int_backend := tests/tb_ooo_int_backend.sv $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_bitmanip_gate := tests/tb_ooo_bitmanip_gate.sv $(RTL_OOO_BITMANIP_GATE)
TB_SRCS_tb_ooo_amo_gate := tests/tb_ooo_amo_gate.sv $(RTL_OOO_AMO_GATE)
TB_SRCS_tb_ooo_alu_decode_backend := tests/tb_ooo_alu_decode_backend.sv $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_alu_core_slice := tests/tb_ooo_alu_core_slice.sv $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_core_top_glue := tests/tb_ooo_core_top_glue.sv $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_fp_iter := tests/tb_ooo_fp_iter.sv $(RTL_OOO_FP_DIV_ITER) $(RTL_OOO_FP_SQRT_ITER)
TB_SRCS_tb_ooo_fp_mem_access_gate := tests/tb_ooo_fp_mem_access_gate.sv $(RTL_OOO_FP_MEM_ACCESS_GATE)
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
TB_SRCS_tb_ooo_stop_pending_sequencer := tests/tb_ooo_stop_pending_sequencer.sv $(RTL_OOO_STOP_PENDING_SEQUENCER)
TB_SRCS_tb_ooo_csr_access_request_mux := tests/tb_ooo_csr_access_request_mux.sv $(RTL_OOO_CSR_ACCESS_REQUEST_MUX)
TB_SRCS_tb_ooo_csr_trap_request_mux := tests/tb_ooo_csr_trap_request_mux.sv $(RTL_OOO_CSR_TRAP_REQUEST_MUX)
TB_SRCS_tb_ooo_pending_lane1_capture_gate := tests/tb_ooo_pending_lane1_capture_gate.sv $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE)
TB_SRCS_tb_ooo_pending_dispatch_arbiter := tests/tb_ooo_pending_dispatch_arbiter.sv $(RTL_OOO_PENDING_LANE1_CAPTURE_GATE) $(RTL_OOO_PENDING_DISPATCH_ARBITER)
TB_SRCS_tb_ooo_pending_system_sequencer := tests/tb_ooo_pending_system_sequencer.sv $(RTL_OOO_PENDING_SYSTEM_SEQUENCER)
TB_SRCS_tb_ooo_pending_trap_exit_sequencer := tests/tb_ooo_pending_trap_exit_sequencer.sv $(RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER)
TB_SRCS_tb_ooo_trap_exit_event_mux := tests/tb_ooo_trap_exit_event_mux.sv $(RTL_OOO_TRAP_EXIT_EVENT_MUX)
TB_SRCS_tb_ooo_trap_exit_output_sequencer := tests/tb_ooo_trap_exit_output_sequencer.sv $(RTL_OOO_TRAP_EXIT_OUTPUT_SEQUENCER)
TB_SRCS_tb_ooo_synthetic_lane1_ret_sequencer := tests/tb_ooo_synthetic_lane1_ret_sequencer.sv $(RTL_OOO_SYNTHETIC_LANE1_RET_SEQUENCER)
TB_SRCS_tb_ooo_frontend_uop_safety := tests/tb_ooo_frontend_uop_safety.sv $(RTL_OOO_FRONTEND_UOP_SAFETY)
TB_SRCS_tb_ooo_frontend_dispatch_gate := tests/tb_ooo_frontend_dispatch_gate.sv $(RTL_OOO_FRONTEND_DISPATCH_GATE)
TB_SRCS_tb_ooo_frontend_backend_dispatch_mux := tests/tb_ooo_frontend_backend_dispatch_mux.sv $(RTL_OOO_FRONTEND_BACKEND_DISPATCH_MUX)
TB_SRCS_tb_ooo_direct_branch_resolve_gate := tests/tb_ooo_direct_branch_resolve_gate.sv $(RTL_OOO_DIRECT_BRANCH_RESOLVE_GATE)
TB_SRCS_tb_ooo_branch_resolve_recovery_gate := tests/tb_ooo_branch_resolve_recovery_gate.sv $(RTL_OOO_BRANCH_RESOLVE_RECOVERY_GATE)
TB_SRCS_tb_ooo_pending_control_resolve_gate := tests/tb_ooo_pending_control_resolve_gate.sv $(RTL_OOO_PENDING_CONTROL_RESOLVE_GATE)
TB_SRCS_tb_ooo_pending_branch_sequencer := tests/tb_ooo_pending_branch_sequencer.sv $(RTL_OOO_PENDING_BRANCH_SEQUENCER)
TB_SRCS_tb_ooo_pending_jump_sequencer := tests/tb_ooo_pending_jump_sequencer.sv $(RTL_OOO_PENDING_JUMP_SEQUENCER)
TB_SRCS_tb_ooo_pending_fp_sequencer := tests/tb_ooo_pending_fp_sequencer.sv $(RTL_OOO_PENDING_FP_SEQUENCER)
TB_SRCS_tb_ooo_branch_append_dispatch_gate := tests/tb_ooo_branch_append_dispatch_gate.sv $(RTL_OOO_BRANCH_APPEND_DISPATCH_GATE)
TB_SRCS_tb_ooo_branch_bpu_update_gate := tests/tb_ooo_branch_bpu_update_gate.sv $(RTL_OOO_BRANCH_BPU_UPDATE_GATE)
TB_SRCS_tb_ooo_branch_target_cache_control_gate := tests/tb_ooo_branch_target_cache_control_gate.sv $(RTL_OOO_BRANCH_TARGET_CACHE_CONTROL_GATE)
TB_SRCS_tb_ooo_memory_request_gate := tests/tb_ooo_memory_request_gate.sv $(RTL_OOO_MEMORY_REQUEST_GATE)
TB_SRCS_tb_ooo_pending_memory_sequencer := tests/tb_ooo_pending_memory_sequencer.sv $(RTL_OOO_PENDING_MEMORY_SEQUENCER)
TB_SRCS_tb_ooo_frontend_run_gate := tests/tb_ooo_frontend_run_gate.sv $(RTL_OOO_FRONTEND_RUN_GATE)
TB_SRCS_tb_ooo_frontend_action_gate := tests/tb_ooo_frontend_action_gate.sv $(RTL_OOO_FRONTEND_ACTION_GATE)
TB_SRCS_tb_ooo_fetch_request_mux := tests/tb_ooo_fetch_request_mux.sv $(RTL_OOO_FETCH_REQUEST_MUX)
TB_SRCS_tb_ooo_branch_prefetch_source_gate := tests/tb_ooo_branch_prefetch_source_gate.sv $(RTL_OOO_BRANCH_PREFETCH_SOURCE_GATE)
TB_SRCS_tb_ooo_branch_prefetch_request_gate := tests/tb_ooo_branch_prefetch_request_gate.sv $(RTL_OOO_BRANCH_PREFETCH_REQUEST_GATE)
TB_SRCS_tb_ooo_branch_prefetch_status_gate := tests/tb_ooo_branch_prefetch_status_gate.sv $(RTL_OOO_BRANCH_PREFETCH_STATUS_GATE)
TB_SRCS_tb_ooo_jalr_prefetch_status_gate := tests/tb_ooo_jalr_prefetch_status_gate.sv $(RTL_OOO_JALR_PREFETCH_STATUS_GATE)
TB_SRCS_tb_ooo_branch_prefetch_buffer := tests/tb_ooo_branch_prefetch_buffer.sv $(RTL_OOO_BRANCH_PREFETCH_BUFFER)
TB_SRCS_tb_ooo_direct_branch_wait_buffer := tests/tb_ooo_direct_branch_wait_buffer.sv $(RTL_OOO_DIRECT_BRANCH_WAIT_BUFFER)
TB_SRCS_tb_ooo_backend_drain_tracker := tests/tb_ooo_backend_drain_tracker.sv $(RTL_OOO_BACKEND_DRAIN_TRACKER)
TB_SRCS_tb_ooo_fetch_packet_hit_mux := tests/tb_ooo_fetch_packet_hit_mux.sv $(RTL_OOO_FETCH_PACKET_HIT_MUX)
TB_SRCS_tb_ooo_fetch_packet_head_mux := tests/tb_ooo_fetch_packet_head_mux.sv $(RTL_OOO_FETCH_PACKET_HEAD_MUX)
TB_SRCS_tb_ooo_fetch_packet_seed_mux := tests/tb_ooo_fetch_packet_seed_mux.sv $(RTL_OOO_FETCH_PACKET_SEED_MUX)
TB_SRCS_tb_ooo_fetch_packet_decode := tests/tb_ooo_fetch_packet_decode.sv $(RTL_OOO_RVC_DECOMPRESSOR) $(RTL_OOO_FETCH_PACKET_DECODE)
TB_SRCS_tb_ooo_fetch_packet_fifo := tests/tb_ooo_fetch_packet_fifo.sv $(RTL_OOO_FETCH_PACKET_FIFO)
TB_SRCS_tb_ooo_fetch_flow_control := tests/tb_ooo_fetch_flow_control.sv $(RTL_OOO_FETCH_FLOW_CONTROL)
TB_SRCS_tb_ooo_fetch_head_pair_gate := tests/tb_ooo_fetch_head_pair_gate.sv $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE) $(RTL_OOO_FETCH_HEAD_PAIR_GATE)
TB_SRCS_tb_ooo_fetch_head_classify_gate := tests/tb_ooo_fetch_head_classify_gate.sv $(RTL_OOO_FP_DECODE) $(RTL_OOO_FETCH_HEAD_CLASSIFY_GATE)
TB_SRCS_tb_ooo_fetch_packet_cache := tests/tb_ooo_fetch_packet_cache.sv $(RTL_OOO_FETCH_PACKET_CACHE)
TB_SRCS_tb_ooo_data_word_cache := tests/tb_ooo_data_word_cache.sv $(RTL_OOO_DATA_WORD_CACHE)
TB_SRCS_tb_ooo_branch_target_cache := tests/tb_ooo_branch_target_cache.sv $(RTL_OOO_BRANCH_TARGET_CACHE)
TB_SRCS_tb_ooo_branch_target_capture_buffer := tests/tb_ooo_branch_target_capture_buffer.sv $(RTL_OOO_BRANCH_TARGET_CAPTURE_BUFFER)
TB_SRCS_tb_ooo_fetch_axi_bridge := tests/tb_ooo_fetch_axi_bridge.sv $(RTL_PMP_CHECKER) $(RTL_OOO_FETCH_PACKET_CACHE) $(RTL_OOO_SV39_TLB) $(RTL_OOO_FETCH_AXI_BRIDGE)
TB_SRCS_tb_ooo_fetch_trap_gate := tests/tb_ooo_fetch_trap_gate.sv $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_priv_system := tests/tb_ooo_priv_system.sv $(RTL_OOO_FRONTEND_HELPERS) $(RTL_OOO_CORE_TOP_GLUE) $(RTL_CSR_FILE) $(RTL_OOO_ALU_CORE_SLICE) $(RTL_OOO_ARCH_REG_FILE) $(RTL_OOO_ALU_DECODE_BACKEND) $(RTL_DECODE_STAGE) $(RTL_DECODE_UNIT) $(RTL_IMM_GEN) $(TB_OOO_INT_BACKEND_SRCS)
TB_SRCS_tb_ooo_sv39_boot := tests/tb_ooo_sv39_boot.sv $(RTL_CORE_SRCS)
TB_SRCS_tb_ooo_mem_axi_bridge := tests/tb_ooo_mem_axi_bridge.sv $(RTL_PMP_CHECKER) $(RTL_OOO_DATA_WORD_CACHE) $(RTL_OOO_SV39_TLB) $(RTL_OOO_MEM_AXI_BRIDGE)
TB_SRCS_tb_pipe_regs := tests/tb_pipe_regs.sv $(RTL_IF_ID_PIPE_REG) $(RTL_ID_EX_PIPE_REG) $(RTL_EX_MEM_PIPE_REG) $(RTL_MEM_WB_PIPE_REG)
TB_SRCS_tb_cache_control := tests/tb_cache_control.sv $(RTL_CACHE_CONTROL)
TB_SRCS_tb_memory_stage_control := tests/tb_memory_stage_control.sv $(RTL_MEMORY_STAGE_CONTROL)
TB_SRCS_tb_memory_stage := tests/tb_memory_stage.sv $(RTL_LSU_CONTROL) $(RTL_LSU_DATAPATH) $(RTL_LSU) $(RTL_MEMORY_STAGE_CONTROL) $(RTL_MEMORY_STAGE)
TB_SRCS_tb_pipeline_control := tests/tb_pipeline_control.sv $(RTL_PIPELINE_CONTROL)
TB_SRCS_tb_multiplier := tests/tb_multiplier.sv $(RTL_RV32_MULTIPLIER)
TB_SRCS_tb_divider := tests/tb_divider.sv $(RTL_RV32_DIVIDER)
TB_SRCS_tb_branch_predictor := tests/tb_branch_predictor.sv $(RTL_BRANCH_PREDICTOR)
TB_SRCS_tb_icache := tests/tb_icache.sv $(RTL_SRAM2R1W) $(RTL_ICACHE)
TB_SRCS_tb_dcache := tests/tb_dcache.sv $(RTL_SRAM1RW) $(RTL_DCACHE)
TB_SRCS_tb_if_stage := tests/tb_if_stage.sv $(RTL_BRANCH_PREDICTOR) $(RTL_IF_STAGE)
TB_SRCS_tb_npc_core_smoke := tests/tb_npc_core_smoke.sv \
  $(RTL_ALU) \
  $(RTL_BRANCH_PREDICTOR) \
  $(RTL_CACHE_CONTROL) \
  $(RTL_COMPARE_UNIT) \
  $(RTL_CSR_FILE) \
  $(RTL_DCACHE) \
  $(RTL_DECODE_STAGE) \
  $(RTL_DECODE_UNIT) \
  $(RTL_ICACHE) \
  $(RTL_IF_STAGE) \
  $(RTL_IMM_GEN) \
  $(RTL_IF_ID_PIPE_REG) \
  $(RTL_ID_EX_PIPE_REG) \
  $(RTL_EX_MEM_PIPE_REG) \
  $(RTL_LSU_CONTROL) \
  $(RTL_LSU_DATAPATH) \
  $(RTL_LSU) \
  $(RTL_MEM_WB_PIPE_REG) \
  $(RTL_MEMORY_STAGE_CONTROL) \
  $(RTL_MEMORY_STAGE) \
  $(RTL_PIPELINE_CONTROL) \
  $(RTL_REGISTER_FILE) \
  $(RTL_RV32_MULTIPLIER) \
  $(RTL_RV32_DIVIDER) \
  $(RTL_SRAM1RW) \
  $(RTL_SRAM2R1W) \
  $(RTL_WBU) \
  $(RTL_NPC_CORE)

TB_SRCS_tb_npc_core_mcycle := tests/tb_npc_core_mcycle.sv \
  $(RTL_ALU) \
  $(RTL_BRANCH_PREDICTOR) \
  $(RTL_CACHE_CONTROL) \
  $(RTL_COMPARE_UNIT) \
  $(RTL_CSR_FILE) \
  $(RTL_DCACHE) \
  $(RTL_DECODE_STAGE) \
  $(RTL_DECODE_UNIT) \
  $(RTL_ICACHE) \
  $(RTL_IF_STAGE) \
  $(RTL_IMM_GEN) \
  $(RTL_IF_ID_PIPE_REG) \
  $(RTL_ID_EX_PIPE_REG) \
  $(RTL_EX_MEM_PIPE_REG) \
  $(RTL_LSU_CONTROL) \
  $(RTL_LSU_DATAPATH) \
  $(RTL_LSU) \
  $(RTL_MEM_WB_PIPE_REG) \
  $(RTL_MEMORY_STAGE_CONTROL) \
  $(RTL_MEMORY_STAGE) \
  $(RTL_PIPELINE_CONTROL) \
  $(RTL_REGISTER_FILE) \
  $(RTL_RV32_MULTIPLIER) \
  $(RTL_RV32_DIVIDER) \
  $(RTL_SRAM1RW) \
  $(RTL_SRAM2R1W) \
  $(RTL_WBU) \
  $(RTL_NPC_CORE)

TB_SRCS_tb_npc_core_interrupt := tests/tb_npc_core_interrupt.sv \
  $(RTL_ALU) \
  $(RTL_BRANCH_PREDICTOR) \
  $(RTL_CACHE_CONTROL) \
  $(RTL_COMPARE_UNIT) \
  $(RTL_CSR_FILE) \
  $(RTL_DCACHE) \
  $(RTL_DECODE_STAGE) \
  $(RTL_DECODE_UNIT) \
  $(RTL_ICACHE) \
  $(RTL_IF_STAGE) \
  $(RTL_IMM_GEN) \
  $(RTL_IF_ID_PIPE_REG) \
  $(RTL_ID_EX_PIPE_REG) \
  $(RTL_EX_MEM_PIPE_REG) \
  $(RTL_LSU_CONTROL) \
  $(RTL_LSU_DATAPATH) \
  $(RTL_LSU) \
  $(RTL_MEM_WB_PIPE_REG) \
  $(RTL_MEMORY_STAGE_CONTROL) \
  $(RTL_MEMORY_STAGE) \
  $(RTL_PIPELINE_CONTROL) \
  $(RTL_REGISTER_FILE) \
  $(RTL_RV32_MULTIPLIER) \
  $(RTL_RV32_DIVIDER) \
  $(RTL_SRAM1RW) \
  $(RTL_SRAM2R1W) \
  $(RTL_WBU) \
  $(RTL_NPC_CORE)

PIPE_TEST_SRCS := tests/pipe_test.sv \
  $(RTL_LSU_CONTROL) \
  $(RTL_LSU_DATAPATH) \
  $(RTL_LSU) \
  $(RTL_MEMORY_STAGE_CONTROL) \
  $(RTL_MEMORY_STAGE) \
  $(RTL_SRAM1RW) \
  $(RTL_DCACHE) \
  $(RTL_PIPELINE_CONTROL)

STAGE_PIPE_TEST_SRCS := tests/stage_pipe_test.sv \
  $(RTL_BRANCH_PREDICTOR) \
  $(RTL_IF_STAGE) \
  $(RTL_IF_ID_PIPE_REG) \
  $(RTL_SRAM2R1W) \
  $(RTL_ICACHE) \
  $(RTL_LSU_CONTROL) \
  $(RTL_LSU_DATAPATH) \
  $(RTL_LSU) \
  $(RTL_MEMORY_STAGE_CONTROL) \
  $(RTL_MEMORY_STAGE) \
  $(RTL_SRAM1RW) \
  $(RTL_DCACHE) \
  $(RTL_PIPELINE_CONTROL)

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
