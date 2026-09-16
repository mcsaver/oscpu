// Physical protection boundary for one coherent page-table walker.
// A denied request completes locally with an access error. An accepted service
// request is never cancelled by a CPU redirect: its owner drains to terminal.
module R64PtePort(
 input clk_i,input rst_i,
 input req_valid_i,output req_ready_o,input req_compare_or_i,
 input [55:0] req_addr_i,input [63:0] req_expected_i,req_or_mask_i,
 output rsp_valid_o,input rsp_ready_i,output [63:0] rsp_data_o,
 output rsp_error_o,rsp_compare_o,
 input [15:0] pmp_active_i,input [895:0] pmp_lower_i,pmp_upper_i,
 input [63:0] pmp_permission_i,
 output service_valid_o,input service_ready_i,
 output [63:0] service_addr_o,service_data_o,service_expected_o,
 output [1:0] service_op_o,output service_cache_o,
 input service_rsp_valid_i,output service_rsp_ready_o,
 input [63:0] service_rsp_data_i,input service_rsp_error_i,service_rsp_compare_i,
 output idle_o
);
 localparam [1:0] IDLE=0,SEND=1,WAIT=2,FAULT=3;
 reg [1:0] state_q;
 reg [55:0] address_q;
 reg [63:0] expected_q,mask_q;
 reg compare_q,cached_q;
 wire pmp_fault_w,pma_fault_w;
 wire [1:0] pma_class_w;
 R64PmpCheck protection(
  .address_i({8'b0,req_addr_i}),.size_i(5'd8),.privilege_i(2'd1),
  .access_i({1'b0,req_compare_or_i,1'b1}),.active_i(pmp_active_i),
  .lower_i(pmp_lower_i),.upper_i(pmp_upper_i),.permission_i(pmp_permission_i),
  .fault_o(pmp_fault_w));
 R64Pma attributes(.address_i({8'b0,req_addr_i}),.size_i(5'd8),
  .fault_o(pma_fault_w),.class_o(pma_class_w));
 assign idle_o=state_q==IDLE;
 assign req_ready_o=state_q==IDLE&&!rst_i;
 assign service_valid_o=state_q==SEND&&!rst_i;
 assign service_addr_o={8'b0,address_q};
 assign service_expected_o=expected_q;assign service_data_o=mask_q;
 assign service_op_o=compare_q?2'd2:2'd0;assign service_cache_o=cached_q;
 assign rsp_valid_o=!rst_i&&(state_q==FAULT||(state_q==WAIT&&service_rsp_valid_i));
 assign rsp_data_o=state_q==FAULT?64'b0:service_rsp_data_i;
 assign rsp_error_o=state_q==FAULT||service_rsp_error_i;
 assign rsp_compare_o=state_q!=FAULT&&service_rsp_compare_i;
 assign service_rsp_ready_o=state_q==WAIT&&rsp_ready_i&&!rst_i;
 // The idle slot prepares payload; only the state transition admits a PTE.
 // SEND/WAIT/FAULT freeze the accepted address and compare-and-OR operands.
 always @(posedge clk_i)if(state_q==IDLE)begin
  address_q<=req_addr_i;expected_q<=req_expected_i;mask_q<=req_or_mask_i;
  compare_q<=req_compare_or_i;cached_q<=pma_class_w==0;
 end
 always @(posedge clk_i)begin
  if(rst_i)state_q<=IDLE;
  else begin
   if(req_valid_i&&req_ready_o)begin
    state_q<=pmp_fault_w||pma_fault_w||pma_class_w==2||(|req_addr_i[2:0])?FAULT:SEND;

   end
   if(service_valid_o&&service_ready_i)state_q<=WAIT;
   if(rsp_valid_o&&rsp_ready_i)state_q<=IDLE;
  end
 end
endmodule
