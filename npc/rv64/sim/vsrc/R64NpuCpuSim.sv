// Simulation ABI for the existing NPU runtime. Real CPU: R64SystemTop.
// Only external memory and retirement observation use DPI.
import "DPI-C" function void npc_commit_event(input longint unsigned pc,
 input int unsigned inst,input longint unsigned next_pc,input int unsigned rd_en,
 input int unsigned rd_addr,input longint unsigned rd_data,input int unsigned is_fp);
import "DPI-C" function void npc_trap_event(input int unsigned cause,
 input longint unsigned pc,input longint unsigned tval);
import "DPI-C" function void npc_exit_event(input int unsigned is_ebreak,
 input int unsigned is_ecall,input int unsigned is_system_reset,
 input longint unsigned code,input longint unsigned pc);
module R64NpuCpuSim(
 input logic clk,rst,
 output logic tensor_cmd_valid_o,input logic tensor_cmd_ready_i,
 output logic [63:0] tensor_cmd_bits_o,tensor_cmd_rs_value_o,
 output logic [7:0] tensor_cmd_producer_id_o,
 output logic tensor_cmd_is_64_o,tensor_cmd_required_o,
 output logic [7:0] tensor_cmd_opclass_o,
 input logic tensor_terminal_valid_i,output logic tensor_terminal_ready_o,
 input logic [7:0] tensor_terminal_producer_id_i,
 input logic tensor_terminal_error_i,input logic [7:0] tensor_terminal_error_code_i,
 output logic tensor_serialize_o,output logic [63:0] debug_pc_o,
 output logic commit0_valid_o,output logic [63:0] commit0_pc_o,
 output logic [31:0] commit0_inst_o,output logic commit0_rd_en_o,commit0_exception_o
);
 logic [8:0] owner_tag_q;
 logic owner_valid_q;
 wire terminal_fire=tensor_terminal_valid_i&&tensor_terminal_ready_o;
 logic [8:0] tensor_cmd_tag_o;
 logic [1:0] trace_valid_o;
 logic [127:0] trace_pc_o;
 logic [127:0] trace_raw_o;
 logic [127:0] trace_npc_o;
 logic [127:0] trace_data_o;
 logic [7:0] trace_length_o;
 logic [1:0] trace_rd_write_o;
 logic [1:0] trace_rd_fp_o;
 logic [9:0] trace_rd_arch_o;
 logic [9:0] trace_fflags_o;
 logic [15:0] trace_kind_o;
 logic trap_valid_o;
 logic trap_interrupt_o;
 logic [5:0] trap_cause_o;
 logic [63:0] trap_pc_o;
 logic [63:0] trap_tval_o;
 logic [63:0] trap_raw_o;
 logic [63:0] trap_target_o;
 logic [3:0] trap_length_o;
 logic [1:0] privilege_o;
 logic [63:0] mstatus_o;
 logic [63:0] satp_o;
 logic [5:0] rob_count_o;
 logic [3:0] ext_arvalid_o;
 logic [3:0] ext_arready_i;
 logic [255:0] ext_araddr_o;
 logic [11:0] ext_arsize_o;
 logic [11:0] ext_arprot_o;
 logic [3:0] ext_rvalid_i;
 logic [3:0] ext_rready_o;
 logic [255:0] ext_rdata_i;
 logic [7:0] ext_rresp_i;
 logic [3:0] ext_awvalid_o;
 logic [3:0] ext_awready_i;
 logic [255:0] ext_awaddr_o;
 logic [11:0] ext_awsize_o;
 logic [3:0] ext_wvalid_o;
 logic [3:0] ext_wready_i;
 logic [255:0] ext_wdata_o;
 logic [31:0] ext_wstrb_o;
 logic [3:0] ext_bvalid_i;
 logic [3:0] ext_bready_o;
 logic [7:0] ext_bresp_i;
 logic uart_rx_ready_o;
 logic uart_tx_valid_o;
 logic [7:0] uart_tx_data_o;
 logic syscon_valid_o;
 logic [31:0] syscon_value_o;
 logic [63:0] time_o;
 logic protocol_error_o;
 assign tensor_cmd_producer_id_o=tensor_cmd_tag_o[7:0];
 assign tensor_cmd_required_o=tensor_cmd_is_64_o;
 assign tensor_serialize_o=system.core.serial_irrevocable;
 assign commit0_valid_o=trace_valid_o[0]||trap_valid_o;
 assign commit0_pc_o=trap_valid_o?trap_pc_o:trace_pc_o[63:0];
 assign commit0_inst_o=trap_valid_o?trap_raw_o[31:0]:trace_raw_o[31:0];
 assign commit0_rd_en_o=!trap_valid_o&&trace_rd_write_o[0];
 assign commit0_exception_o=trap_valid_o; // Legacy completion observation includes faults.
 // The DPI retirement stream below remains fault-free and counts real retirees.
 // The NPU ABI has eight-bit IDs and one serial head command. Retain the
 // full CPU identity until its real terminal; no live tag is truncated.
 always_ff @(posedge clk)begin
  if(rst)begin owner_valid_q<=0;owner_tag_q<=0;debug_pc_o<=64'h80000000;end
  else begin
   if(tensor_cmd_valid_o&&tensor_cmd_ready_i)begin
    if(owner_valid_q)$fatal(1,"NPU CPU adapter has two command owners");
    owner_valid_q<=1;owner_tag_q<=tensor_cmd_tag_o;
   end
   if(terminal_fire)begin
    if(!owner_valid_q||tensor_terminal_producer_id_i!=owner_tag_q[7:0])
     $fatal(1,"NPU CPU adapter terminal identity mismatch");
    owner_valid_q<=0;
   end
   for(integer lane=0;lane<2;lane=lane+1)if(trace_valid_o[lane])begin
    npc_commit_event(trace_pc_o[lane*64+:64],trace_raw_o[lane*64+:32],trace_npc_o[lane*64+:64],
     {31'b0,trace_rd_write_o[lane]},{27'b0,trace_rd_arch_o[lane*5+:5]},
     trace_data_o[lane*64+:64],{31'b0,trace_rd_fp_o[lane]});
    debug_pc_o<=trace_npc_o[lane*64+:64];
   end
   if(trap_valid_o)begin
    npc_trap_event({25'b0,trap_interrupt_o,trap_cause_o},trap_pc_o,trap_tval_o);
    debug_pc_o<=trap_target_o;
   end
   if(syscon_valid_o)npc_exit_event(0,0,1,{32'b0,syscon_value_o},debug_pc_o);
   if(protocol_error_o)$fatal(1,"native NPU CPU AXI protocol error");
  end
 end
 // Invalidate on all accepted terminals, including partially written error
 // paths, before the CPU can publish the result or resume dependent loads.
 R64SystemTop system(
  .clk_i(clk),
  .rst_i(rst),
  .run_i(1'b1),
  .dma_invalidate_i(terminal_fire),
  .tensor_cmd_valid_o(tensor_cmd_valid_o),
  .tensor_cmd_ready_i(tensor_cmd_ready_i),
  .tensor_cmd_tag_o(tensor_cmd_tag_o),
  .tensor_cmd_o(tensor_cmd_bits_o),
  .tensor_operand_o(tensor_cmd_rs_value_o),
  .tensor_pair_o(tensor_cmd_is_64_o),
  .tensor_class_o(tensor_cmd_opclass_o),
  .tensor_terminal_valid_i(tensor_terminal_valid_i),
  .tensor_terminal_ready_o(tensor_terminal_ready_o),
  .tensor_terminal_tag_i(owner_tag_q),
  .tensor_error_i(tensor_terminal_error_i),
  .tensor_error_code_i(tensor_terminal_error_code_i),
  .trace_ready_i(2'b11),
  .trace_valid_o(trace_valid_o),
  .trace_pc_o(trace_pc_o),
  .trace_raw_o(trace_raw_o),
  .trace_npc_o(trace_npc_o),
  .trace_data_o(trace_data_o),
  .trace_length_o(trace_length_o),
  .trace_rd_write_o(trace_rd_write_o),
  .trace_rd_fp_o(trace_rd_fp_o),
  .trace_rd_arch_o(trace_rd_arch_o),
  .trace_fflags_o(trace_fflags_o),
  .trace_kind_o(trace_kind_o),
  .trap_valid_o(trap_valid_o),
  .trap_interrupt_o(trap_interrupt_o),
  .trap_cause_o(trap_cause_o),
  .trap_pc_o(trap_pc_o),
  .trap_tval_o(trap_tval_o),
  .trap_raw_o(trap_raw_o),
  .trap_target_o(trap_target_o),
  .trap_length_o(trap_length_o),
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
  .uart_rx_valid_i(1'b0),
  .uart_rx_data_i(8'b0),
  .uart_rx_ready_o(uart_rx_ready_o),
  .uart_tx_valid_o(uart_tx_valid_o),
  .uart_tx_data_o(uart_tx_data_o),
  .external_irq_sources_i(32'b0),
  .syscon_valid_o(syscon_valid_o),
  .syscon_value_o(syscon_value_o),
  .time_o(time_o),
  .protocol_error_o(protocol_error_o)
 );
 for(genvar p=0;p<4;p=p+1)begin: memory_port
  AxiDpiSlave memory(
   .clk(clk),
   .rst(rst),
   .s_axi_arvalid_i(ext_arvalid_o[p]),
   .s_axi_arready_o(ext_arready_i[p]),
   .s_axi_araddr_i(ext_araddr_o[p*64+:64]),
   .s_axi_arsize_i(ext_arsize_o[p*3+:3]),
   .s_axi_arprot_i(ext_arprot_o[p*3+:3]),
   .s_axi_rvalid_o(ext_rvalid_i[p]),
   .s_axi_rready_i(ext_rready_o[p]),
   .s_axi_rdata_o(ext_rdata_i[p*64+:64]),
   .s_axi_rresp_o(ext_rresp_i[p*2+:2]),
   .s_axi_awvalid_i(ext_awvalid_o[p]),
   .s_axi_awready_o(ext_awready_i[p]),
   .s_axi_awaddr_i(ext_awaddr_o[p*64+:64]),
   .s_axi_awsize_i(ext_awsize_o[p*3+:3]),
   .s_axi_wvalid_i(ext_wvalid_o[p]),
   .s_axi_wready_o(ext_wready_i[p]),
   .s_axi_wdata_i(ext_wdata_o[p*64+:64]),
   .s_axi_wstrb_i(ext_wstrb_o[p*8+:8]),
   .s_axi_bvalid_o(ext_bvalid_i[p]),
   .s_axi_bready_i(ext_bready_o[p]),
   .s_axi_bresp_o(ext_bresp_i[p*2+:2])
  );
 end
endmodule
