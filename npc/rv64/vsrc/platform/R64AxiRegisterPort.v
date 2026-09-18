// Registered AXI-Lite register endpoint. Address and write data are independent
// owners; a write becomes one native access only after both are captured.
module R64AxiRegisterPort(
 input clk_i,input rst_i,
 input arvalid_i,output arready_o,input [11:0] araddr_i,input [2:0] arsize_i,
 output reg rvalid_o,input rready_i,output reg [63:0] rdata_o,output reg [1:0] rresp_o,
 input awvalid_i,output awready_o,input [11:0] awaddr_i,input [2:0] awsize_i,
 input wvalid_i,output wready_o,input [63:0] wdata_i,input [7:0] wstrb_i,
 output reg bvalid_o,input bready_i,output reg [1:0] bresp_o,
 output read_o,output [11:0] read_addr_o,output [2:0] read_size_o,
 input [63:0] read_data_i,input read_error_i,
 output write_o,output [11:0] write_addr_o,output [2:0] write_size_o,
 output [63:0] write_data_o,output [7:0] write_strb_o,input write_error_i
);
 reg read_pending_q,address_pending_q,data_pending_q;
 reg [11:0] read_addr_q,write_addr_q;
 reg [2:0] read_size_q,write_size_q;
 reg [63:0] write_data_q;reg [7:0] write_strb_q;
 // READY may remain high during reset; the reset-prioritized state block
 // discards requests, while each response VALID is cleared.
 assign arready_o=!read_pending_q&&!rvalid_o;
 assign awready_o=!address_pending_q&&!bvalid_o;
 assign wready_o=!data_pending_q&&!bvalid_o;
 assign read_o=read_pending_q&&!rvalid_o&&!rst_i;
 assign write_o=address_pending_q&&data_pending_q&&!bvalid_o&&!rst_i;
 assign read_addr_o=read_addr_q;assign read_size_o=read_size_q;
 assign write_addr_o=write_addr_q;assign write_size_o=write_size_q;
 assign write_data_o=write_data_q;assign write_strb_o=write_strb_q;
 always @(posedge clk_i)begin
  if(rst_i)begin
   read_pending_q<=0;address_pending_q<=0;data_pending_q<=0;rvalid_o<=0;bvalid_o<=0;
  end else begin
   if(rvalid_o&&rready_i)rvalid_o<=0;
   if(bvalid_o&&bready_i)bvalid_o<=0;
   if(arvalid_i&&arready_o)begin read_pending_q<=1;read_addr_q<=araddr_i;read_size_q<=arsize_i;end
   if(awvalid_i&&awready_o)begin address_pending_q<=1;write_addr_q<=awaddr_i;write_size_q<=awsize_i;end
   if(wvalid_i&&wready_o)begin data_pending_q<=1;write_data_q<=wdata_i;write_strb_q<=wstrb_i;end
   if(read_o)begin read_pending_q<=0;rvalid_o<=1;rdata_o<=read_data_i;rresp_o<=read_error_i?2'b10:2'b00;end
   if(write_o)begin address_pending_q<=0;data_pending_q<=0;bvalid_o<=1;bresp_o<=write_error_i?2'b10:2'b00;end
  end
 end
endmodule
