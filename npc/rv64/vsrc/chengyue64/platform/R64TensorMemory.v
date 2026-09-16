// Registers the NPU raw-byte GMEM aperture. There is one request owner, including
// its full CPU tag, from NPU admission through NPU response delivery. Raw data is
// a low byte window at addr, not AXI lane-positioned data.
module R64TensorMemory(
 input clk_i,input rst_i,input [8:0] owner_tag_i,
 input nreq_valid_i,output nreq_ready_o,input nreq_write_i,
 input [63:0] nreq_addr_i,nreq_wdata_i,input [7:0] nreq_wstrb_i,
 output nrsp_valid_o,input nrsp_ready_i,output [63:0] nrsp_rdata_o,output nrsp_error_o,
 output req_valid_o,input req_ready_i,output req_write_o,
 output [63:0] req_addr_o,req_wdata_o,output [7:0] req_wstrb_o,output [8:0] req_tag_o,
 input rsp_valid_i,output rsp_ready_o,input [63:0] rsp_rdata_i,input rsp_error_i,input [8:0] rsp_tag_i,
 output write_admitted_o,output idle_o,output reg protocol_error_o
);
 localparam [1:0] IDLE=0,SEND=1,WAIT=2,RESULT=3;
 reg [1:0] state_q;
 reg [8:0] tag_q;reg write_q,error_q;reg [63:0] addr_q,data_q;reg [7:0] strb_q;
 assign nreq_ready_o=state_q==IDLE&&!rst_i;
 assign req_valid_o=state_q==SEND&&!rst_i;
 assign req_tag_o=tag_q;assign req_write_o=write_q;assign req_addr_o=addr_q;
 assign req_wdata_o=data_q;assign req_wstrb_o=strb_q;
 assign rsp_ready_o=state_q==WAIT&&!rst_i;
 assign nrsp_valid_o=state_q==RESULT&&!rst_i;assign nrsp_rdata_o=data_q;assign nrsp_error_o=error_q;
 assign write_admitted_o=nreq_valid_i&&nreq_ready_o&&nreq_write_i&&(|nreq_wstrb_i);
 assign idle_o=state_q==IDLE;
 always @(posedge clk_i)begin
  if(rst_i)begin state_q<=IDLE;protocol_error_o<=0;end
  else begin
   if(nreq_valid_i&&nreq_ready_o)begin
    state_q<=SEND;tag_q<=owner_tag_i;write_q<=nreq_write_i;
    addr_q<=nreq_addr_i;data_q<=nreq_wdata_i;strb_q<=nreq_wstrb_i;error_q<=0;
   end
   if(req_valid_o&&req_ready_i)state_q<=WAIT;
   if(rsp_valid_i&&rsp_ready_o)begin
    state_q<=RESULT;error_q<=rsp_error_i||rsp_tag_i!=tag_q;
    data_q<=rsp_tag_i==tag_q?rsp_rdata_i:64'd0;
    if(rsp_tag_i!=tag_q)protocol_error_o<=1;
   end
   if(nrsp_valid_o&&nrsp_ready_i)state_q<=IDLE;
  end
 end
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i&&rsp_valid_i&&rsp_ready_o&&rsp_tag_i!=tag_q)
  $fatal(1,"Tensor GMEM response owner mismatch");
`endif
endmodule
