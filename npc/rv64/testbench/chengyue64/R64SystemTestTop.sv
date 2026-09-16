// Simulation-only registered retirement and CSR observation.
`ifdef R64_TENSOR
`define R64_SYSTEM_HIER system.system
module R64TensorTestTop(
`else
`define R64_SYSTEM_HIER system
module R64SystemTestTop(
`endif
 input clk_i,
 input rst_i,
 input run_i,
`ifdef R64_TENSOR
 output gmem_req_valid_o,
 input gmem_req_ready_i,
 output gmem_req_write_o,
 output [63:0] gmem_req_addr_o,
 output [63:0] gmem_req_wdata_o,
 output [7:0] gmem_req_wstrb_o,
 output [8:0] gmem_req_tag_o,
 input gmem_rsp_valid_i,
 output gmem_rsp_ready_o,
 input [63:0] gmem_rsp_rdata_i,
 input gmem_rsp_error_i,
 input [8:0] gmem_rsp_tag_i,
`else
 input dma_invalidate_i,
 output tensor_cmd_valid_o,
 input tensor_cmd_ready_i,
 output [8:0] tensor_cmd_tag_o,
 output [63:0] tensor_cmd_o,
 output [63:0] tensor_operand_o,
 output tensor_pair_o,
 output [7:0] tensor_class_o,
 input tensor_terminal_valid_i,
 output tensor_terminal_ready_o,
 input [8:0] tensor_terminal_tag_i,
 input tensor_error_i,
 input [7:0] tensor_error_code_i,
`endif
 input [1:0] trace_ready_i,
 output reg [1:0] trace_valid_o,
 output reg [127:0] trace_pc_o,
 output reg [127:0] trace_raw_o,
 output reg [127:0] trace_npc_o,
 output reg [127:0] trace_data_o,
 output reg [7:0] trace_length_o,
 output reg [1:0] trace_rd_write_o,
 output reg [1:0] trace_rd_fp_o,
 output reg [9:0] trace_rd_arch_o,
 output reg [9:0] trace_fflags_o,
 output reg [15:0] trace_kind_o,
 output reg trap_valid_o,
 output reg trap_interrupt_o,
 output reg [5:0] trap_cause_o,
 output reg [63:0] trap_pc_o,
 output reg [63:0] trap_tval_o,
 output reg [63:0] trap_raw_o,
 output reg [63:0] trap_target_o,
 output reg [3:0] trap_length_o,
 output [1:0] privilege_o,
 output [63:0] mstatus_o,
 output [63:0] satp_o,
 output [5:0] rob_count_o,
 output [3:0] ext_arvalid_o,
 input [3:0] ext_arready_i,
 output [255:0] ext_araddr_o,
 output [11:0] ext_arsize_o,
 output [11:0] ext_arprot_o,
 input [3:0] ext_rvalid_i,
 output [3:0] ext_rready_o,
 input [255:0] ext_rdata_i,
 input [7:0] ext_rresp_i,
 output [3:0] ext_awvalid_o,
 input [3:0] ext_awready_i,
 output [255:0] ext_awaddr_o,
 output [11:0] ext_awsize_o,
 output [3:0] ext_wvalid_o,
 input [3:0] ext_wready_i,
 output [255:0] ext_wdata_o,
 output [31:0] ext_wstrb_o,
 input [3:0] ext_bvalid_i,
 output [3:0] ext_bready_o,
 input [7:0] ext_bresp_i,
 input uart_rx_valid_i,
 input [7:0] uart_rx_data_i,
 output uart_rx_ready_o,
 output uart_tx_valid_o,
 output [7:0] uart_tx_data_o,
 input [31:0] external_irq_sources_i,
 output syscon_valid_o,
 output [31:0] syscon_value_o,
 output [63:0] time_o,
 output protocol_error_o,
 output [1727:0] csr_snapshot_o
);
 wire [1:0] event_trace_valid_o;
 wire [127:0] event_trace_pc_o;
 wire [127:0] event_trace_raw_o;
 wire [127:0] event_trace_npc_o;
 wire [127:0] event_trace_data_o;
 wire [7:0] event_trace_length_o;
 wire [1:0] event_trace_rd_write_o;
 wire [1:0] event_trace_rd_fp_o;
 wire [9:0] event_trace_rd_arch_o;
 wire [9:0] event_trace_fflags_o;
 wire [15:0] event_trace_kind_o;
 wire [0:0] event_trap_valid_o;
 wire [0:0] event_trap_interrupt_o;
 wire [5:0] event_trap_cause_o;
 wire [63:0] event_trap_pc_o;
 wire [63:0] event_trap_tval_o;
 wire [63:0] event_trap_raw_o;
 wire [63:0] event_trap_target_o;
 wire [3:0] event_trap_length_o;
`ifdef R64_TENSOR
 R64TensorSystemTop system(
`else
 R64SystemTop system(
`endif
  .clk_i(clk_i),
  .rst_i(rst_i),
  .run_i(run_i),
`ifdef R64_TENSOR
  .gmem_req_valid_o(gmem_req_valid_o),
  .gmem_req_ready_i(gmem_req_ready_i),
  .gmem_req_write_o(gmem_req_write_o),
  .gmem_req_addr_o(gmem_req_addr_o),
  .gmem_req_wdata_o(gmem_req_wdata_o),
  .gmem_req_wstrb_o(gmem_req_wstrb_o),
  .gmem_req_tag_o(gmem_req_tag_o),
  .gmem_rsp_valid_i(gmem_rsp_valid_i),
  .gmem_rsp_ready_o(gmem_rsp_ready_o),
  .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
  .gmem_rsp_error_i(gmem_rsp_error_i),
  .gmem_rsp_tag_i(gmem_rsp_tag_i),
`else
  .dma_invalidate_i(dma_invalidate_i),
  .tensor_cmd_valid_o(tensor_cmd_valid_o),
  .tensor_cmd_ready_i(tensor_cmd_ready_i),
  .tensor_cmd_tag_o(tensor_cmd_tag_o),
  .tensor_cmd_o(tensor_cmd_o),
  .tensor_operand_o(tensor_operand_o),
  .tensor_pair_o(tensor_pair_o),
  .tensor_class_o(tensor_class_o),
  .tensor_terminal_valid_i(tensor_terminal_valid_i),
  .tensor_terminal_ready_o(tensor_terminal_ready_o),
  .tensor_terminal_tag_i(tensor_terminal_tag_i),
  .tensor_error_i(tensor_error_i),
  .tensor_error_code_i(tensor_error_code_i),
`endif
  .trace_ready_i(trace_ready_i),
  .trace_valid_o(event_trace_valid_o),
  .trace_pc_o(event_trace_pc_o),
  .trace_raw_o(event_trace_raw_o),
  .trace_npc_o(event_trace_npc_o),
  .trace_data_o(event_trace_data_o),
  .trace_length_o(event_trace_length_o),
  .trace_rd_write_o(event_trace_rd_write_o),
  .trace_rd_fp_o(event_trace_rd_fp_o),
  .trace_rd_arch_o(event_trace_rd_arch_o),
  .trace_fflags_o(event_trace_fflags_o),
  .trace_kind_o(event_trace_kind_o),
  .trap_valid_o(event_trap_valid_o),
  .trap_interrupt_o(event_trap_interrupt_o),
  .trap_cause_o(event_trap_cause_o),
  .trap_pc_o(event_trap_pc_o),
  .trap_tval_o(event_trap_tval_o),
  .trap_raw_o(event_trap_raw_o),
  .trap_target_o(event_trap_target_o),
  .trap_length_o(event_trap_length_o),
  .privilege_o(privilege_o),
  .mstatus_o(mstatus_o),
  .satp_o(satp_o),
  .rob_count_o(rob_count_o),
  .ext_arvalid_o(ext_arvalid_o),
  .ext_arready_i(ext_arready_i),
  .ext_araddr_o(ext_araddr_o),
  .ext_arsize_o(ext_arsize_o),
  .ext_arprot_o(ext_arprot_o),
  .ext_rvalid_i(ext_rvalid_i),
  .ext_rready_o(ext_rready_o),
  .ext_rdata_i(ext_rdata_i),
  .ext_rresp_i(ext_rresp_i),
  .ext_awvalid_o(ext_awvalid_o),
  .ext_awready_i(ext_awready_i),
  .ext_awaddr_o(ext_awaddr_o),
  .ext_awsize_o(ext_awsize_o),
  .ext_wvalid_o(ext_wvalid_o),
  .ext_wready_i(ext_wready_i),
  .ext_wdata_o(ext_wdata_o),
  .ext_wstrb_o(ext_wstrb_o),
  .ext_bvalid_i(ext_bvalid_i),
  .ext_bready_o(ext_bready_o),
  .ext_bresp_i(ext_bresp_i),
  .uart_rx_valid_i(uart_rx_valid_i),
  .uart_rx_data_i(uart_rx_data_i),
  .uart_rx_ready_o(uart_rx_ready_o),
  .uart_tx_valid_o(uart_tx_valid_o),
  .uart_tx_data_o(uart_tx_data_o),
  .external_irq_sources_i(external_irq_sources_i),
  .syscon_valid_o(syscon_valid_o),
  .syscon_value_o(syscon_value_o),
  .time_o(time_o),
  .protocol_error_o(protocol_error_o)
 );
 assign csr_snapshot_o[0+:64]=`R64_SYSTEM_HIER.core.mstatus_o;
 assign csr_snapshot_o[64+:64]={`R64_SYSTEM_HIER.core.csr.mepc_q,1'b0};
 assign csr_snapshot_o[128+:64]=`R64_SYSTEM_HIER.core.csr.mcause_q;
 assign csr_snapshot_o[192+:64]=`R64_SYSTEM_HIER.core.csr.mtvec_q;
 assign csr_snapshot_o[256+:64]=`R64_SYSTEM_HIER.core.csr.mtval_q;
 assign csr_snapshot_o[320+:64]=`R64_SYSTEM_HIER.core.csr.mscratch_q;
 assign csr_snapshot_o[384+:64]={`R64_SYSTEM_HIER.core.csr.sepc_q,1'b0};
 assign csr_snapshot_o[448+:64]=`R64_SYSTEM_HIER.core.csr.scause_q;
 assign csr_snapshot_o[512+:64]=`R64_SYSTEM_HIER.core.csr.stvec_q;
 assign csr_snapshot_o[576+:64]=`R64_SYSTEM_HIER.core.csr.stval_q;
 assign csr_snapshot_o[640+:64]=`R64_SYSTEM_HIER.core.csr.sscratch_q;
 assign csr_snapshot_o[704+:64]={48'b0,`R64_SYSTEM_HIER.core.csr.exception_delegation_q};
 assign csr_snapshot_o[768+:64]={52'b0,`R64_SYSTEM_HIER.core.csr.delegation_w};
 assign csr_snapshot_o[832+:64]=`R64_SYSTEM_HIER.core.satp_o;
 assign csr_snapshot_o[896+:64]={61'b0,`R64_SYSTEM_HIER.core.csr.mcounter_q};
 assign csr_snapshot_o[960+:64]={61'b0,`R64_SYSTEM_HIER.core.csr.scounter_q};
 assign csr_snapshot_o[1024+:64]={62'b0,`R64_SYSTEM_HIER.core.privilege_o};
 assign csr_snapshot_o[1088+:64]={52'b0,`R64_SYSTEM_HIER.core.csr.enable_q};
 assign csr_snapshot_o[1152+:64]={52'b0,`R64_SYSTEM_HIER.core.csr.pending_w};
 assign csr_snapshot_o[1216+:64]=`R64_SYSTEM_HIER.core.csr.cycle_q;
 assign csr_snapshot_o[1280+:64]=`R64_SYSTEM_HIER.core.csr.retired_q;
 assign csr_snapshot_o[1344+:64]={59'b0,`R64_SYSTEM_HIER.core.csr.flags_q};
 assign csr_snapshot_o[1408+:64]={61'b0,`R64_SYSTEM_HIER.core.csr.rounding_q};
 assign csr_snapshot_o[1472+:64]=0;
 assign csr_snapshot_o[1536+:64]=`R64_SYSTEM_HIER.core.csr.trigger_control_w;
 assign csr_snapshot_o[1600+:64]=`R64_SYSTEM_HIER.core.trigger_address;
 assign csr_snapshot_o[1664+:64]=64'h1008044;
 always @(posedge clk_i)begin
  if(rst_i)begin trace_valid_o<=0;trap_valid_o<=0;end
  else begin
   trace_valid_o<=event_trace_valid_o;
   trace_pc_o<=event_trace_pc_o;
   trace_raw_o<=event_trace_raw_o;
   trace_npc_o<=event_trace_npc_o;
   trace_data_o<=event_trace_data_o;
   trace_length_o<=event_trace_length_o;
   trace_rd_write_o<=event_trace_rd_write_o;
   trace_rd_fp_o<=event_trace_rd_fp_o;
   trace_rd_arch_o<=event_trace_rd_arch_o;
   trace_fflags_o<=event_trace_fflags_o;
   trace_kind_o<=event_trace_kind_o;
   trap_valid_o<=event_trap_valid_o;
   trap_interrupt_o<=event_trap_interrupt_o;
   trap_cause_o<=event_trap_cause_o;
   trap_pc_o<=event_trap_pc_o;
   trap_tval_o<=event_trap_tval_o;
   trap_raw_o<=event_trap_raw_o;
   trap_target_o<=event_trap_target_o;
   trap_length_o<=event_trap_length_o;
  end
 end
 always @(posedge clk_i)if(!rst_i&&$test$plusargs("bus-debug"))begin
  if(`R64_SYSTEM_HIER.arvalid&&`R64_SYSTEM_HIER.arready)$display("AR time=%0d addr=%h size=%0d id=%0d",time_o,`R64_SYSTEM_HIER.araddr,`R64_SYSTEM_HIER.arsize,`R64_SYSTEM_HIER.arid);
  if(`R64_SYSTEM_HIER.rvalid&&`R64_SYSTEM_HIER.rready)$display("R time=%0d data=%h resp=%d id=%0d",time_o,`R64_SYSTEM_HIER.rdata,`R64_SYSTEM_HIER.rresp,`R64_SYSTEM_HIER.rid);
  if(`R64_SYSTEM_HIER.platform.av[0]&&`R64_SYSTEM_HIER.platform.ar[0])$display("CLINT AR addr=%h time=%0d",`R64_SYSTEM_HIER.platform.aa[63:0],time_o);
 end
 integer debug_cycle=0,debug_index;
 always @(posedge clk_i)begin
  debug_cycle<=rst_i?0:debug_cycle+1;
  if(!rst_i&&debug_cycle==20000&&$test$plusargs("memory-debug"))begin
   $display("BACKEND readv=%b readready=%b tags=%h classes=%h issue=%b credit=%b localv=%b wb=%b recover=%b",
    `R64_SYSTEM_HIER.core.backend.read_valid_w,`R64_SYSTEM_HIER.core.backend.execute_ready_w,`R64_SYSTEM_HIER.core.backend.read_tag_w,
    `R64_SYSTEM_HIER.core.backend.read_class_w,`R64_SYSTEM_HIER.core.backend.issue_fire_w,`R64_SYSTEM_HIER.core.backend.read_credit_w,
    `R64_SYSTEM_HIER.core.backend.local_valid_w,`R64_SYSTEM_HIER.core.backend.wb_accept_w,`R64_SYSTEM_HIER.core.backend.recover_o);
   for(debug_index=0;debug_index<16;debug_index=debug_index+1)
    if(`R64_SYSTEM_HIER.core.backend.issue.valid_q[debug_index])
     $display("IQ slot=%d tag=%h class=%d ready=%b used=%b common=%b eligible0=%b",
      debug_index,`R64_SYSTEM_HIER.core.backend.issue.tag_q[debug_index],`R64_SYSTEM_HIER.core.backend.issue.class_q[debug_index],
      `R64_SYSTEM_HIER.core.backend.issue.ready_q[debug_index],`R64_SYSTEM_HIER.core.backend.issue.used_q[debug_index],
      `R64_SYSTEM_HIER.core.backend.issue.common_w[debug_index],`R64_SYSTEM_HIER.core.backend.issue.eligible0_w[debug_index]);
   $display("MEM head=%h kill=%h tv=%b tr=%b rv=%b rr=%b pv=%b pr=%b prv=%b av=%b ar=%b arv=%b",
    `R64_SYSTEM_HIER.core.head_tag,`R64_SYSTEM_HIER.core.kill_mask,`R64_SYSTEM_HIER.core.memory.tv,`R64_SYSTEM_HIER.core.memory.tr,
    `R64_SYSTEM_HIER.core.memory.protected_valid,`R64_SYSTEM_HIER.core.memory.rr,`R64_SYSTEM_HIER.core.memory.pv,`R64_SYSTEM_HIER.core.memory.pr,
    `R64_SYSTEM_HIER.core.memory.prv,`R64_SYSTEM_HIER.core.memory.av,`R64_SYSTEM_HIER.core.memory.ar,`R64_SYSTEM_HIER.core.memory.arv);
   $display("SERVICE valid=%b busy=%b out=%b CACHE state=%d stage=%b",
    `R64_SYSTEM_HIER.core.memory.unit.service.valid_q,`R64_SYSTEM_HIER.core.memory.unit.service.busy_q,
    `R64_SYSTEM_HIER.core.memory.unit.service.out_valid_q,`R64_SYSTEM_HIER.core.memory.unit.cache.state_q,
    `R64_SYSTEM_HIER.core.memory.unit.cache.stage_valid_q);
   for(debug_index=0;debug_index<18;debug_index=debug_index+1)
    if(`R64_SYSTEM_HIER.core.memory.unit.lsu.state_q[debug_index]!=0)
     $display("LSU slot=%d state=%d alive=%b tag=%h va=%h pa=%h xsent=%b msent=%b",
      debug_index,`R64_SYSTEM_HIER.core.memory.unit.lsu.state_q[debug_index],`R64_SYSTEM_HIER.core.memory.unit.lsu.alive_q[debug_index],
      `R64_SYSTEM_HIER.core.memory.unit.lsu.tag_q[debug_index],`R64_SYSTEM_HIER.core.memory.unit.lsu.va_q[debug_index],
      `R64_SYSTEM_HIER.core.memory.unit.lsu.pa_q[debug_index],`R64_SYSTEM_HIER.core.memory.unit.lsu.tr_issued_q[debug_index],
      `R64_SYSTEM_HIER.core.memory.unit.lsu.mem_issued_q[debug_index]);
   $display("TRANS s0=%d s1=%d valid0=%b valid1=%b walk0=%d walk1=%d",
    `R64_SYSTEM_HIER.core.memory.g_translation[0].translation.g_data.unit.outcome_state_q,`R64_SYSTEM_HIER.core.memory.g_translation[1].translation.g_data.unit.outcome_state_q,
    `R64_SYSTEM_HIER.core.memory.g_translation[0].translation.g_data.unit.lookup_valid_q,`R64_SYSTEM_HIER.core.memory.g_translation[1].translation.g_data.unit.lookup_valid_q,
    `R64_SYSTEM_HIER.core.memory.g_translation[0].translation.g_data.unit.u_walk.state_q,`R64_SYSTEM_HIER.core.memory.g_translation[1].translation.g_data.unit.u_walk.state_q);
  end
 end
`include "R64CpiProfile.svh"
endmodule

`undef R64_SYSTEM_HIER
