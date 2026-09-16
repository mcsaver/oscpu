// Simulation observation only; the real core exposes no duplicate architectural registers.
module R64CoreTestTop(
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
 // Observation occurs after the accepting edge. READY throttles architectural
 // retirement; no trace data is fed back into execution or architectural state.
 input [1:0] trace_ready_i,output reg [1:0] trace_valid_o,
 output reg [127:0] trace_pc_o,trace_raw_o,trace_npc_o,trace_data_o,
 output reg [7:0] trace_length_o,output reg [1:0] trace_rd_write_o,trace_rd_fp_o,
 output reg [9:0] trace_rd_arch_o,trace_fflags_o,output reg [15:0] trace_kind_o,
 output reg trap_valid_o,trap_interrupt_o,output reg [5:0] trap_cause_o,
 output reg [63:0] trap_pc_o,trap_tval_o,trap_raw_o,trap_target_o,
 output reg [3:0] trap_length_o,
 output [1:0] privilege_o,output [63:0] mstatus_o,satp_o,
 output [5:0] rob_count_o,output protocol_error_o,
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
 R64CoreTop core(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .run_i(run_i),
  .time_i(time_i),
  .irq_software_i(irq_software_i),
  .irq_timer_i(irq_timer_i),
  .irq_external_i(irq_external_i),.irq_supervisor_external_i(irq_supervisor_external_i),
  .dma_invalidate_i(dma_invalidate_i),.wfi_wait_i(wfi_wait_i),
  .arvalid_o(arvalid_o),
  .arready_i(arready_i),
  .arid_o(arid_o),
  .araddr_o(araddr_o),
  .arlen_o(arlen_o),
  .arsize_o(arsize_o),
  .arprot_o(arprot_o),
  .arburst_o(arburst_o),
  .rvalid_i(rvalid_i),
  .rready_o(rready_o),
  .rid_i(rid_i),
  .rdata_i(rdata_i),
  .rresp_i(rresp_i),
  .rlast_i(rlast_i),
  .awvalid_o(awvalid_o),
  .awready_i(awready_i),
  .awid_o(awid_o),
  .awaddr_o(awaddr_o),
  .awlen_o(awlen_o),
  .awsize_o(awsize_o),
  .awprot_o(awprot_o),
  .awburst_o(awburst_o),
  .wvalid_o(wvalid_o),
  .wready_i(wready_i),
  .wdata_o(wdata_o),
  .wstrb_o(wstrb_o),
  .wlast_o(wlast_o),
  .bvalid_i(bvalid_i),
  .bready_o(bready_o),
  .bid_i(bid_i),
  .bresp_i(bresp_i),
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
  .protocol_error_o(protocol_error_o)
 );
 assign csr_snapshot_o[0+:64]=core.mstatus_o;
 assign csr_snapshot_o[64+:64]={core.csr.mepc_q,1'b0};
 assign csr_snapshot_o[128+:64]=core.csr.mcause_q;
 assign csr_snapshot_o[192+:64]=core.csr.mtvec_q;
 assign csr_snapshot_o[256+:64]=core.csr.mtval_q;
 assign csr_snapshot_o[320+:64]=core.csr.mscratch_q;
 assign csr_snapshot_o[384+:64]={core.csr.sepc_q,1'b0};
 assign csr_snapshot_o[448+:64]=core.csr.scause_q;
 assign csr_snapshot_o[512+:64]=core.csr.stvec_q;
 assign csr_snapshot_o[576+:64]=core.csr.stval_q;
 assign csr_snapshot_o[640+:64]=core.csr.sscratch_q;
 assign csr_snapshot_o[704+:64]={48'b0,core.csr.exception_delegation_q};
 assign csr_snapshot_o[768+:64]={52'b0,core.csr.delegation_w};
 assign csr_snapshot_o[832+:64]=core.satp_o;
 assign csr_snapshot_o[896+:64]={61'b0,core.csr.mcounter_q};
 assign csr_snapshot_o[960+:64]={61'b0,core.csr.scounter_q};
 assign csr_snapshot_o[1024+:64]={62'b0,core.privilege_o};
 assign csr_snapshot_o[1088+:64]={52'b0,core.csr.enable_q};
 assign csr_snapshot_o[1152+:64]={52'b0,core.csr.pending_w};
 assign csr_snapshot_o[1216+:64]=core.csr.cycle_q;
 assign csr_snapshot_o[1280+:64]=core.csr.retired_q;
 assign csr_snapshot_o[1344+:64]={59'b0,core.csr.flags_q};
 assign csr_snapshot_o[1408+:64]={61'b0,core.csr.rounding_q};
 assign csr_snapshot_o[1472+:64]=0;
 assign csr_snapshot_o[1536+:64]=core.csr.trigger_control_w;
 assign csr_snapshot_o[1600+:64]=core.trigger_address;
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
endmodule
