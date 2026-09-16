`include "R64Uop.vh"
// Native two-wide RV64 core. Architectural state lives in Rename/ROB/CSR;
// external owners live in the LSU and serial unit until their true terminal.
// The public memory interface is AXI4 including response IDs and last-beat.
module R64CoreTop #(parameter [63:0] RESET_PC=64'h80000000,parameter ISSUE_SLOTS=16)(
 input clk_i,input rst_i,input run_i,input [63:0] time_i,
 input irq_software_i,irq_timer_i,irq_external_i,irq_supervisor_external_i,input dma_invalidate_i,input wfi_wait_i,
 output arvalid_o,input arready_i,output [3:0] arid_o,output [63:0] araddr_o,
 output [7:0] arlen_o,output [2:0] arsize_o,arprot_o,output [1:0] arburst_o,
 input rvalid_i,output rready_o,input [3:0] rid_i,input [63:0] rdata_i,
 input [1:0] rresp_i,input rlast_i,
 output awvalid_o,input awready_i,output [3:0] awid_o,output [63:0] awaddr_o,
 output [7:0] awlen_o,output [2:0] awsize_o,awprot_o,output [1:0] awburst_o,
 output wvalid_o,input wready_i,output [63:0] wdata_o,output [7:0] wstrb_o,output wlast_o,
 input bvalid_i,output bready_o,input [3:0] bid_i,input [1:0] bresp_i,
 output tensor_cmd_valid_o,input tensor_cmd_ready_i,
 output [8:0] tensor_cmd_tag_o,output [63:0] tensor_cmd_o,tensor_operand_o,
 output tensor_pair_o,output [7:0] tensor_class_o,
 input tensor_terminal_valid_i,output tensor_terminal_ready_o,input [8:0] tensor_terminal_tag_i,
 input tensor_error_i,input [7:0] tensor_error_code_i,
 // Combinational architectural events, accepted on this clock edge. A simulator
 // may register observations outside the hardware core. READY throttles retire.
 input [1:0] trace_ready_i,output [1:0] trace_valid_o,
 output [127:0] trace_pc_o,trace_raw_o,trace_npc_o,trace_data_o,
 output [7:0] trace_length_o,output [1:0] trace_rd_write_o,trace_rd_fp_o,
 output [9:0] trace_rd_arch_o,trace_fflags_o,output [15:0] trace_kind_o,
 output trap_valid_o,trap_interrupt_o,output [5:0] trap_cause_o,
 output [63:0] trap_pc_o,trap_tval_o,trap_raw_o,trap_target_o,
 output [3:0] trap_length_o,
 output [1:0] privilege_o,output [63:0] mstatus_o,satp_o,
 output [5:0] rob_count_o,output protocol_error_o
);
 localparam U=`R64_UOP_W,M=`R64_META_W,R=`R64_RESULT_W;
 wire stop_birth,full_flush,control_redirect,effect_allow,serial_allow;
 wire head_serial,head_exception_raw;wire [1:0] rob_serial;
 wire [63:0] control_target;
 wire backend_redirect,recover,resolve,resolve_conditional,resolve_indirect,resolve_taken;
 wire [63:0] backend_target,resolve_pc,resolve_npc;
 wire [31:0] memory_cancel_candidates;wire memory_cancel_active;
 wire [8:0] head_tag,resolve_tag;wire [31:0] kill_mask,lsu_reuse,serial_reuse;
 wire [65:0] fetch_canonical;wire [69:0] fetch_control;wire [127:0] fetch_sequential_npc;
 wire [1:0] fetch_valid,fetch_ready,fetch_fault;
 wire [127:0] fetch_pc,fetch_raw,fetch_pred,fetch_tval;
 wire [7:0] fetch_length;wire [9:0] fetch_cause;
 wire [1:0] fetch_take=fetch_valid&fetch_ready;
 wire [1:0] fetch_consume={1'b0,fetch_take[0]}+{1'b0,fetch_take[1]};
 wire redirect=control_redirect||backend_redirect;
 wire [63:0] redirect_target=control_redirect?control_target:backend_target;
 wire [1:0] rob_valid,rob_ready,retire_fire,rob_exception,rob_write,rob_fp;
 wire [17:0] rob_tag;wire [2*M-1:0] rob_meta;
 wire [127:0] rob_data,rob_tval,retire_npc;
 wire [11:0] rob_cause;wire [9:0] rob_arch,rob_flags;
 wire commit1_allow,serial_commit;wire [8:0] serial_commit_tag;
 wire [1:0] retired_count;wire fp_dirty;wire [4:0] fp_flags;
 wire trap,trap_interrupt,trap_prepare;wire csr_query,csr_query_valid,return_prepare;wire [5:0] trap_cause;
 wire [63:0] trap_pc,trap_tval,trap_target;
 wire irq_pending,wfi_wake;wire [5:0] irq_cause;
 wire [2:0] frm;wire pbmt_enable;
 wire [127:0] pmp_config;wire [863:0] pmp_address;
 wire [15:0] pmp_active;wire [895:0] pmp_lower,pmp_upper;wire [63:0] pmp_permission;
 wire [63:0] fetch_protect_addr;wire [1:0] fetch_protect_priv;
 wire [7:0] fetch_protect_mask;wire fetch_uncached;
 wire [129:0] fetch_protect_facts;
 assign fetch_protect_mask=0;
 wire [1:0] lsu_ready,lsu_fire;wire [17:0] lsu_tag;wire [2*U-1:0] lsu_uop;
 wire [383:0] lsu_operand;wire lsu_irrevocable,memory_idle,memory_owner_idle;
 wire fp_ready,fp_fire;wire [8:0] fp_tag;wire [U-1:0] fp_uop;wire [191:0] fp_operand;
 wire serial_ready,serial_fire;wire [8:0] serial_tag;wire [U-1:0] serial_uop;wire [191:0] serial_operand;
 wire serial_irrevocable,serial_idle;
 wire [1:0] memory_request_hint;
 wire [3:0] external_valid,external_ready;wire [35:0] external_tag;wire [4*R-1:0] external_result;
 wire [2:0] trigger_enable;
 wire [63:0] trigger_address;
 wire [1:0] execute_breakpoint={
     trigger_enable[2]&&fetch_pc[127:64]==trigger_address,
     trigger_enable[2]&&fetch_pc[63:0]==trigger_address};
 wire [11:0] frontend_exception_cause={
     execute_breakpoint[1]?6'd3:{1'b0,fetch_cause[9:5]},
     execute_breakpoint[0]?6'd3:{1'b0,fetch_cause[4:0]}};
 wire [127:0] frontend_exception_tval={
     execute_breakpoint[1]?fetch_pc[127:64]:fetch_tval[127:64],
     execute_breakpoint[0]?fetch_pc[63:0]:fetch_tval[63:0]};
 wire [63:0] csr_select;
 wire [11:0] csr_address;wire [2:0] csr_operation;wire [4:0] csr_rs1;
 wire [63:0] csr_operand,csr_read,csr_write_value,return_target;
 wire csr_commit,csr_illegal,return_supervisor;wire [1:0] return_commit;
 wire icache_invalidate,tlb_invalidate,tlb_all_vaddr,tlb_all_asid;
 wire [26:0] tlb_vpn;wire [15:0] tlb_asid;
 wire pte_valid,pte_ready,pte_compare_or,pte_rsp_valid,pte_rsp_ready,pte_error,pte_compare;
 wire [55:0] pte_addr;wire [63:0] pte_expected,pte_mask,pte_data;
 wire [1:0] read_valid,read_ready,read_rsp_valid,read_rsp_ready,read_last;
 wire [127:0] read_addr,read_data;wire [15:0] read_len;wire [5:0] read_size;wire [3:0] read_resp;
 wire write_valid,write_ready,write_data_valid,write_data_ready,write_rsp_valid,write_rsp_ready;
 wire [63:0] write_addr,write_data;wire [2:0] write_size;wire [7:0] write_strb;wire [1:0] write_resp;
 wire read_error,write_error;
 assign protocol_error_o=read_error||write_error;

 R64PmpDecode pmp_decode(.config_i(pmp_config),.address_i(pmp_address),.active_o(pmp_active),
  .lower_o(pmp_lower),.upper_o(pmp_upper),.permission_o(pmp_permission));
 R64FetchProtectionPrepare fetch_protection(.address_i(fetch_protect_addr),.privilege_i(fetch_protect_priv),
  .pmp_active_i(pmp_active),.pmp_lower_i(pmp_lower),.pmp_upper_i(pmp_upper),
  .pmp_permission_i(pmp_permission),.facts_o(fetch_protect_facts),.uncached_o(fetch_uncached));
 R64Frontend #(.PREPARED_PROTECTION(1),.RESET_PC(RESET_PC)) frontend(
  .clk_i(clk_i),.rst_i(rst_i),.run_i(run_i&&!stop_birth),
  .redirect_i(redirect),.redirect_pc_i(redirect_target),.priv_i(privilege_o),
  .mstatus_i(mstatus_o),.satp_i(satp_o),.pbmt_enable_i(pbmt_enable),
  .icache_invalidate_i(icache_invalidate||dma_invalidate_i),
  .tlb_invalidate_i(tlb_invalidate),.tlb_all_vaddr_i(tlb_all_vaddr),.tlb_all_asid_i(tlb_all_asid),
  .tlb_vpn_i(tlb_vpn),.tlb_asid_i(tlb_asid),
  .canonical_o(fetch_canonical),.control_o(fetch_control),.sequential_npc_o(fetch_sequential_npc),.valid_o(fetch_valid),.consume_i(fetch_consume),.pc_o(fetch_pc),.raw_o(fetch_raw),
  .length_o(fetch_length),.predicted_npc_o(fetch_pred),.fault_o(fetch_fault),
  .cause_o(fetch_cause),.tval_o(fetch_tval),.prediction_update_i(resolve),
  .prediction_pc_i(resolve_pc),.prediction_conditional_i(resolve_conditional),
  .prediction_indirect_i(resolve_indirect),.prediction_taken_i(resolve_taken),.prediction_target_i(resolve_npc),
  .protect_paddr_o(fetch_protect_addr),.protect_priv_o(fetch_protect_priv),
  .protect_fault_mask_i(fetch_protect_mask),.protect_facts_i(fetch_protect_facts),.protect_uncached_i(fetch_uncached),
  .cache_cmd_valid_o(read_valid[0]),.cache_cmd_ready_i(read_ready[0]),
  .cache_cmd_addr_o(read_addr[63:0]),.cache_cmd_len_o(read_len[7:0]),.cache_cmd_size_o(read_size[2:0]),
  .cache_beat_valid_i(read_rsp_valid[0]),.cache_beat_ready_o(read_rsp_ready[0]),
  .cache_beat_data_i(read_data[63:0]),.cache_beat_resp_i(read_resp[1:0]),.cache_beat_last_i(read_last[0]),
  .pte_valid_o(pte_valid),.pte_ready_i(pte_ready),.pte_compare_or_o(pte_compare_or),
  .pte_addr_o(pte_addr),.pte_expected_o(pte_expected),.pte_or_mask_o(pte_mask),
  .pte_rsp_valid_i(pte_rsp_valid),.pte_rsp_ready_o(pte_rsp_ready),
  .pte_rdata_i(pte_data),.pte_error_i(pte_error),.pte_compare_ok_i(pte_compare));
 // Dispatch allocates the LSQ owner together with ROB/rename/IQ.
 // Operand execution later binds the same slot and full tag.
 wire [1:0] lsu_reserve_want,lsu_reserve_fire,lsu_reserve_ready;
 wire [17:0] lsu_reserve_tag;
 wire [15:0] lsu_reserve_func;
 wire [9:0] lsu_reserve_amo,lsu_reserve_slot,lsu_slot;
 wire store_done_valid,store_done_ready,store_done_error;
 wire [8:0] store_done_tag;wire [63:0] store_done_tval;
 R64Backend #(.WB_REQUEST_HINTS(1),.ISSUE_SLOTS(ISSUE_SLOTS),.DIRECT_MEM_BIND(1),.PREDECODED(1),.PREPARED_NPC(1),.PRECONTROLLED(1)) backend(
  .fetch_canonical_i(fetch_canonical),.fetch_control_i(fetch_control),.fetch_sequential_npc_i(fetch_sequential_npc),
  .store_done_valid_i(store_done_valid),.store_done_ready_o(store_done_ready),
  .store_done_tag_i(store_done_tag),.store_done_error_i(store_done_error),.store_done_tval_i(store_done_tval),
  .clk(clk_i),.rst(rst_i),.flush_i(full_flush),.stop_i(stop_birth||!run_i),
  .serial_allow_i(serial_allow),.reuse_block_i(lsu_reuse|serial_reuse),
  .fetch_valid_i(fetch_valid),.fetch_ready_o(fetch_ready),
  .fetch_pc_i(fetch_pc),.fetch_raw_i(fetch_raw),.fetch_pred_npc_i(fetch_pred),.fetch_length_i(fetch_length),
  .fetch_exception_i(fetch_fault|execute_breakpoint),.fetch_cause_i(frontend_exception_cause),.fetch_tval_i(frontend_exception_tval),
  .commit_ready_i(rob_ready),.commit1_allow_i(commit1_allow),.commit_valid_o(rob_valid),.commit_serial_o(rob_serial),
  .commit_tag_o(rob_tag),.commit_meta_o(rob_meta),.commit_data_o(rob_data),
  .commit_exception_o(rob_exception),.commit_cause_o(rob_cause),.commit_tval_o(rob_tval),
  .commit_fflags_o(rob_flags),.commit_rd_write_o(rob_write),.commit_rd_fp_o(rob_fp),.commit_rd_arch_o(rob_arch),
  .redirect_valid_o(backend_redirect),.redirect_pc_o(backend_target),
  .resolve_valid_o(resolve),.resolve_tag_o(resolve_tag),.resolve_pc_o(resolve_pc),.resolve_npc_o(resolve_npc),
  .resolve_conditional_o(resolve_conditional),.resolve_indirect_o(resolve_indirect),.resolve_taken_o(resolve_taken),
  .kill_mask_o(kill_mask),.cancel_candidates_o(memory_cancel_candidates),.cancel_active_o(memory_cancel_active),.head_tag_o(head_tag),.head_serial_o(head_serial),.head_exception_o(head_exception_raw),.rob_count_o(rob_count_o),.recover_o(recover),
  .lsu_ready_i(lsu_ready),.lsu_slot_o(lsu_slot),
  .lsu_reserve_want_o(lsu_reserve_want),.lsu_reserve_fire_o(lsu_reserve_fire),
  .lsu_reserve_ready_i(lsu_reserve_ready),.lsu_reserve_slot_i(lsu_reserve_slot),
  .lsu_reserve_tag_o(lsu_reserve_tag),.lsu_reserve_func_o(lsu_reserve_func),
  .lsu_reserve_amo_o(lsu_reserve_amo),
  .lsu_fire_o(lsu_fire),.lsu_tag_o(lsu_tag),.lsu_uop_o(lsu_uop),.lsu_operand_o(lsu_operand),
  .fp_ready_i(fp_ready),.fp_fire_o(fp_fire),.fp_tag_o(fp_tag),.fp_uop_o(fp_uop),.fp_operand_o(fp_operand),
  .serial_ready_i(serial_ready),.serial_fire_o(serial_fire),.serial_tag_o(serial_tag),.serial_uop_o(serial_uop),.serial_operand_o(serial_operand),
  .external_request_i({2'b0,memory_request_hint}),.external_valid_i(external_valid),.external_ready_o(external_ready),
  .external_tag_i(external_tag),.external_result_i(external_result));
 R64FpExecute #(.Q_CREDIT_INGRESS(1),.RAW_FAST_DISPATCH(1),.RAW_FMA_DISPATCH(1)) fp(
  .clk(clk_i),.rst(rst_i),.flush_i(full_flush),.kill_mask_i(kill_mask),
  .in_fire_i(fp_fire),.in_ready_o(fp_ready),.in_tag_i(fp_tag),.in_uop_i(fp_uop),.in_operand_i(fp_operand),
  .fp_enabled_i(mstatus_o[14:13]!=0),.frm_i(frm),
  .out_valid_o(external_valid[2]),.out_ready_i(external_ready[2]),
  .out_tag_o(external_tag[18+:9]),.out_result_o(external_result[2*R+:R]));
 R64Serial serial(
  .csr_query_o(csr_query),.csr_query_valid_i(csr_query_valid),.return_prepare_o(return_prepare),
  .clk_i(clk_i),.rst_i(rst_i),.flush_i(full_flush),.kill_mask_i(kill_mask),
  .fire_i(serial_fire),.ready_o(serial_ready),.tag_i(serial_tag),.head_tag_i(head_tag),
  .uop_i(serial_uop),.operand_i(serial_operand),.memory_idle_i(memory_idle),.wfi_wake_i(!wfi_wait_i||wfi_wake||irq_timer_i),
  .result_valid_o(external_valid[3]),.result_ready_i(external_ready[3]),
  .result_tag_o(external_tag[27+:9]),.result_o(external_result[3*R+:R]),
  .commit_i(serial_commit),.commit_tag_i(serial_commit_tag),.privilege_i(privilege_o),.mstatus_i(mstatus_o),
  .csr_address_o(csr_address),.csr_select_o(csr_select),.csr_operation_o(csr_operation),.csr_rs1_o(csr_rs1),
  .csr_operand_o(csr_operand),.csr_commit_o(csr_commit),.csr_read_i(csr_read),
  .csr_write_value_i(csr_write_value),.csr_illegal_i(csr_illegal),
  .return_supervisor_o(return_supervisor),.return_commit_o(return_commit),.return_target_i(return_target),
  .icache_invalidate_o(icache_invalidate),.tlb_invalidate_o(tlb_invalidate),
  .tlb_all_vaddr_o(tlb_all_vaddr),.tlb_all_asid_o(tlb_all_asid),.tlb_vpn_o(tlb_vpn),.tlb_asid_o(tlb_asid),
  .tensor_cmd_valid_o(tensor_cmd_valid_o),.tensor_cmd_ready_i(tensor_cmd_ready_i),
  .tensor_cmd_tag_o(tensor_cmd_tag_o),.tensor_cmd_o(tensor_cmd_o),.tensor_operand_o(tensor_operand_o),
  .tensor_pair_o(tensor_pair_o),.tensor_class_o(tensor_class_o),
  .tensor_terminal_valid_i(tensor_terminal_valid_i),.tensor_terminal_ready_o(tensor_terminal_ready_o),
  .tensor_terminal_tag_i(tensor_terminal_tag_i),.tensor_error_i(tensor_error_i),.tensor_error_code_i(tensor_error_code_i),
  .irrevocable_o(serial_irrevocable),.reuse_block_o(serial_reuse),.idle_o(serial_idle));
 R64Csr csr(
  .query_i(csr_query),.query_valid_o(csr_query_valid),.trap_prepare_i(trap_prepare),.return_prepare_i(return_prepare),
  .clk_i(clk_i),.rst_i(rst_i),.count_enable_i(run_i),.time_i(time_i),.retired_i(retired_count),
  .address_i(csr_address),.select_i(csr_select),.operation_i(csr_operation),.rs1_i(csr_rs1),.operand_i(csr_operand),
  .commit_i(csr_commit),.read_o(csr_read),.illegal_o(csr_illegal),
  .fp_dirty_i(fp_dirty),.fp_flags_i(fp_flags),
  .trap_i(trap),.trap_interrupt_i(trap_interrupt),.trap_cause_i(trap_cause),
  .trap_pc_i(trap_pc),.trap_tval_i(trap_tval),.return_i(return_commit),.return_target_o(return_target),
  .irq_software_i(irq_software_i),.irq_timer_i(irq_timer_i),.irq_external_i(irq_external_i),.irq_supervisor_external_i(irq_supervisor_external_i),
  .wfi_wake_o(wfi_wake),.irq_pending_o(irq_pending),.irq_cause_o(irq_cause),.trap_target_o(trap_target),
  .privilege_o(privilege_o),.mstatus_o(mstatus_o),.satp_o(satp_o),.frm_o(frm),.pbmt_enable_o(pbmt_enable),
  .pmp_config_o(pmp_config),.pmp_address_o(pmp_address),.write_value_o(csr_write_value),
  .commit_value_i(csr_operand),.return_supervisor_i(return_supervisor),
  .trigger_enable_o(trigger_enable),.trigger_address_o(trigger_address));
 R64Commit #(.SCRATCH_READ_RESUME(1),.RESET_PC(RESET_PC),.HEAD_SERIAL_ISSUE(1),.HEAD_SERIAL_STOP(1),.HEAD_EXCEPTION_STOP(1),.HEAD_SERIAL_CLASS(1)) commit(
  .trap_prepare_o(trap_prepare),
  .clk_i(clk_i),.rst_i(rst_i),.rob_valid_i(rob_valid),.rob_serial_i(rob_serial),.rob_ready_o(rob_ready),.commit1_allow_o(commit1_allow),
  .rob_tag_i(rob_tag),.rob_meta_i(rob_meta),.rob_data_i(rob_data),.rob_exception_i(rob_exception),
  .rob_cause_i(rob_cause),.rob_tval_i(rob_tval),.rob_rd_write_i(rob_write),.rob_rd_fp_i(rob_fp),
  .rob_fflags_i(rob_flags),.retire_ready_i(trace_ready_i),.rob_empty_i(rob_count_o==0),
  .head_serial_i(head_serial),.head_exception_i(head_exception_raw),.recover_i(recover),.lsu_irrevocable_i(lsu_irrevocable),.serial_irrevocable_i(serial_irrevocable),
  .irq_pending_i(irq_pending),.irq_cause_i(irq_cause),.trap_target_i(trap_target),
  .retire_fire_o(retire_fire),.retire_npc_o(retire_npc),.retired_count_o(retired_count),
  .fp_dirty_o(fp_dirty),.fp_flags_o(fp_flags),.serial_commit_o(serial_commit),.serial_tag_o(serial_commit_tag),
  .trap_o(trap),.trap_interrupt_o(trap_interrupt),.trap_cause_o(trap_cause),.trap_pc_o(trap_pc),.trap_tval_o(trap_tval),
  .stop_birth_o(stop_birth),.full_flush_o(full_flush),.redirect_o(control_redirect),
  .redirect_target_o(control_target),.effect_allow_o(effect_allow),.serial_allow_o(serial_allow));
 R64Memory #(.HEAD_AUTHORIZED_QUERY(1),.PREPARED_CANCEL(1)) memory(
  .trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),
  .store_done_valid_o(store_done_valid),.store_done_ready_i(store_done_ready),
  .store_done_tag_o(store_done_tag),.store_done_error_o(store_done_error),.store_done_tval_o(store_done_tval),
  .clk_i(clk_i),.rst_i(rst_i),.flush_i(full_flush),.invalidate_i(dma_invalidate_i),.kill_mask_i(kill_mask),
  .cancel_candidates_i(memory_cancel_candidates),.cancel_active_i(memory_cancel_active),
  .head_valid_i(rob_count_o!=0),.head_tag_i(head_tag),.effect_allow_i(effect_allow),
  .commit_fire_i(retire_fire),.commit_tag_i(rob_tag),
  .in_fire_i(lsu_fire),.in_ready_o(lsu_ready),.in_slot_i(lsu_slot),
  .reserve_want_i(lsu_reserve_want),.reserve_fire_i(lsu_reserve_fire),
  .reserve_ready_o(lsu_reserve_ready),.reserve_slot_o(lsu_reserve_slot),
  .reserve_tag_i(lsu_reserve_tag),.reserve_func_i(lsu_reserve_func),
  .reserve_amo_i(lsu_reserve_amo),
  .in_tag_i(lsu_tag),.in_uop_i(lsu_uop),.in_operand_i(lsu_operand),
  .out_request_o(memory_request_hint),.out_valid_o(external_valid[1:0]),.out_ready_i(external_ready[1:0]),
  .out_tag_o(external_tag[17:0]),.out_result_o(external_result[2*R-1:0]),
  .reuse_block_o(lsu_reuse),.irrevocable_o(lsu_irrevocable),.idle_o(memory_owner_idle),.drain_idle_o(memory_idle),
  .privilege_i(privilege_o),.mstatus_i(mstatus_o),.satp_i(satp_o),.pbmt_enable_i(pbmt_enable),
  .pmp_active_i(pmp_active),.pmp_lower_i(pmp_lower),.pmp_upper_i(pmp_upper),.pmp_permission_i(pmp_permission),
  .tlb_invalidate_i(tlb_invalidate),.tlb_all_vaddr_i(tlb_all_vaddr),.tlb_all_asid_i(tlb_all_asid),
  .tlb_vpn_i(tlb_vpn),.tlb_asid_i(tlb_asid),
  .pte_valid_i(pte_valid),.pte_ready_o(pte_ready),.pte_compare_or_i(pte_compare_or),
  .pte_addr_i(pte_addr),.pte_expected_i(pte_expected),.pte_or_mask_i(pte_mask),
  .pte_rsp_valid_o(pte_rsp_valid),.pte_rsp_ready_i(pte_rsp_ready),
  .pte_data_o(pte_data),.pte_error_o(pte_error),.pte_compare_o(pte_compare),
  .read_valid_o(read_valid[1]),.read_ready_i(read_ready[1]),.read_addr_o(read_addr[127:64]),
  .read_len_o(read_len[15:8]),.read_size_o(read_size[5:3]),
  .beat_valid_i(read_rsp_valid[1]),.beat_ready_o(read_rsp_ready[1]),
  .beat_data_i(read_data[127:64]),.beat_resp_i(read_resp[3:2]),.beat_last_i(read_last[1]),
  .write_valid_o(write_valid),.write_ready_i(write_ready),.write_addr_o(write_addr),.write_size_o(write_size),
  .write_data_valid_o(write_data_valid),.write_data_ready_i(write_data_ready),
  .write_data_o(write_data),.write_strb_o(write_strb),.write_rsp_valid_i(write_rsp_valid),
  .write_rsp_ready_o(write_rsp_ready),.write_resp_i(write_resp));
 R64AxiRead #(.CLIENTS(2),.CLIENT_W(1)) read_bus(
  .clk_i(clk_i),.rst_i(rst_i),.cmd_valid_i(read_valid),.cmd_ready_o(read_ready),
  .cmd_addr_i(read_addr),.cmd_len_i(read_len),.cmd_size_i(read_size),.cmd_prot_i({3'b000,3'b100}),
  .rsp_valid_o(read_rsp_valid),.rsp_ready_i(read_rsp_ready),.rsp_data_o(read_data),
  .rsp_resp_o(read_resp),.rsp_last_o(read_last),
  .arvalid_o(arvalid_o),.arready_i(arready_i),.arid_o(arid_o),.araddr_o(araddr_o),
  .arlen_o(arlen_o),.arsize_o(arsize_o),.arprot_o(arprot_o),.arburst_o(arburst_o),
  .rvalid_i(rvalid_i),.rready_o(rready_o),.rid_i(rid_i),.rdata_i(rdata_i),
  .rresp_i(rresp_i),.rlast_i(rlast_i),.protocol_error_o(read_error));
 wire [1:0] unused_write_credit,unused_data_credit,unused_write_response;
 wire [3:0] write_responses;
 assign write_ready=unused_write_credit[0];assign write_data_ready=unused_data_credit[0];
 assign write_rsp_valid=unused_write_response[0];assign write_resp=write_responses[1:0];
 R64AxiWrite #(.B_BYPASS(1)) write_bus(
  .clk_i(clk_i),.rst_i(rst_i),.cmd_valid_i({1'b0,write_valid}),.cmd_ready_o(unused_write_credit),
  .cmd_addr_i({64'b0,write_addr}),.cmd_len_i(16'b0),.cmd_size_i({3'b0,write_size}),.cmd_prot_i(6'b0),
  .data_valid_i({1'b0,write_data_valid}),.data_ready_o(unused_data_credit),.data_i({64'b0,write_data}),.strb_i({8'b0,write_strb}),
  .rsp_valid_o(unused_write_response),.rsp_ready_i({1'b1,write_rsp_ready}),.rsp_resp_o(write_responses),
  .awvalid_o(awvalid_o),.awready_i(awready_i),.awid_o(awid_o),.awaddr_o(awaddr_o),
  .awlen_o(awlen_o),.awsize_o(awsize_o),.awprot_o(awprot_o),.awburst_o(awburst_o),
  .wvalid_o(wvalid_o),.wready_i(wready_i),.wdata_o(wdata_o),.wstrb_o(wstrb_o),.wlast_o(wlast_o),
  .bvalid_i(bvalid_i),.bready_o(bready_o),.bid_i(bid_i),.bresp_i(bresp_i),.protocol_error_o(write_error));
 assign trace_valid_o=retire_fire;
 assign trace_npc_o=retire_npc;assign trace_data_o=rob_data;
 assign trace_rd_write_o=rob_write;assign trace_rd_fp_o=rob_fp;
 assign trace_rd_arch_o=rob_arch;assign trace_fflags_o=rob_flags;
 genvar lane;
 generate for(lane=0;lane<2;lane=lane+1)begin:g_trace
  assign trace_pc_o[lane*64+:64]=rob_meta[lane*M+:64];
  assign trace_raw_o[lane*64+:64]=rob_meta[lane*M+64+:64];
  assign trace_length_o[lane*4+:4]=rob_meta[lane*M+192+:4];
  assign trace_kind_o[lane*8+:8]=rob_meta[lane*M+196+:8];
 end endgenerate
 assign trap_valid_o=trap;assign trap_interrupt_o=trap_interrupt;assign trap_cause_o=trap_cause;
 assign trap_pc_o=trap_pc;assign trap_tval_o=trap_tval;assign trap_target_o=trap_target;
 assign trap_raw_o=trap_interrupt?64'b0:rob_meta[127:64];
 assign trap_length_o=trap_interrupt?4'b0:rob_meta[195:192];
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
   if(rob_valid[0]&&rob_exception[0]&&!head_exception_raw)
     $fatal(1,"head exception certificate lost a canonical completion");
   if(!(full_flush||backend_redirect||recover)&&
       head_exception_raw!==(rob_valid[0]&&rob_exception[0]))
     $fatal(1,"head exception certificate disagrees outside freeze");
   if(head_exception_raw&&(full_flush||backend_redirect||recover)&&backend.birth_w!=0)
     $fatal(1,"frozen head exception allowed younger birth");
 end

 // Keep the original authority predicate observable on every actual command.
 // Permission without an unfinished canonical owner is never a transaction.
 always @(posedge clk_i)if(serial_fire)begin
   if(rst_i||full_flush||!effect_allow||serial_tag!=head_tag||
      !backend.rob.valid_q[serial_tag[4:0]]||
      backend.rob.generation_q[serial_tag[4:0]]!=serial_tag[8:5]||
      backend.rob.done_q[serial_tag[4:0]]||
      backend.registers.serial_owner_count!=1)
     $fatal(1,"Core serial issue certificate violated original authority");
 end
`endif
 wire unused_diagnostics=serial_idle||memory_owner_idle||(|resolve_tag)||unused_write_credit[1]||
   unused_data_credit[1]||unused_write_response[1]||(|write_responses[3:2]);
endmodule
