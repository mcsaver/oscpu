// Real AXI/device A/B oracle preserves publication timing across reset.
// The baseline retains the original local-reset output clamp.
`timescale 1ns/1ps
module tb_r64_platform_reset;
reg  clk_i=0;
reg  rst_i=0;
reg  arvalid_i=0;
wire  a_arready_o,b_arready_o;
reg [3:0] arid_i=0;
reg [63:0] araddr_i=0;
reg [7:0] arlen_i=0;
reg [2:0] arsize_i=0;
reg [2:0] arprot_i=0;
reg [1:0] arburst_i=0;
wire  a_rvalid_o,b_rvalid_o;
reg  rready_i=0;
wire [3:0] a_rid_o,b_rid_o;
wire [63:0] a_rdata_o,b_rdata_o;
wire [1:0] a_rresp_o,b_rresp_o;
wire  a_rlast_o,b_rlast_o;
reg  awvalid_i=0;
wire  a_awready_o,b_awready_o;
reg [3:0] awid_i=0;
reg [63:0] awaddr_i=0;
reg [7:0] awlen_i=0;
reg [2:0] awsize_i=0;
reg [1:0] awburst_i=0;
reg  wvalid_i=0;
wire  a_wready_o,b_wready_o;
reg [63:0] wdata_i=0;
reg [7:0] wstrb_i=0;
reg  wlast_i=0;
wire  a_bvalid_o,b_bvalid_o;
reg  bready_i=0;
wire [3:0] a_bid_o,b_bid_o;
wire [1:0] a_bresp_o,b_bresp_o;
wire [3:0] a_ext_arvalid_o,b_ext_arvalid_o;
reg [3:0] ext_arready_i=0;
wire [255:0] a_ext_araddr_o,b_ext_araddr_o;
wire [11:0] a_ext_arsize_o,b_ext_arsize_o;
wire [11:0] a_ext_arprot_o,b_ext_arprot_o;
reg [3:0] ext_rvalid_i=0;
wire [3:0] a_ext_rready_o,b_ext_rready_o;
reg [255:0] ext_rdata_i=0;
reg [7:0] ext_rresp_i=0;
wire [3:0] a_ext_awvalid_o,b_ext_awvalid_o;
reg [3:0] ext_awready_i=0;
wire [255:0] a_ext_awaddr_o,b_ext_awaddr_o;
wire [11:0] a_ext_awsize_o,b_ext_awsize_o;
wire [3:0] a_ext_wvalid_o,b_ext_wvalid_o;
reg [3:0] ext_wready_i=0;
wire [255:0] a_ext_wdata_o,b_ext_wdata_o;
wire [31:0] a_ext_wstrb_o,b_ext_wstrb_o;
reg [3:0] ext_bvalid_i=0;
wire [3:0] a_ext_bready_o,b_ext_bready_o;
reg [7:0] ext_bresp_i=0;
reg  uart_rx_valid_i=0;
reg [7:0] uart_rx_data_i=0;
wire  a_uart_rx_ready_o,b_uart_rx_ready_o;
wire  a_uart_tx_valid_o,b_uart_tx_valid_o;
wire [7:0] a_uart_tx_data_o,b_uart_tx_data_o;
reg [31:0] external_irq_sources_i=0;
wire  a_timer_wait_o,b_timer_wait_o;
wire [63:0] a_time_o,b_time_o;
wire  a_irq_software_o,b_irq_software_o;
wire  a_irq_timer_o,b_irq_timer_o;
wire  a_irq_external_o,b_irq_external_o;
wire  a_irq_supervisor_external_o,b_irq_supervisor_external_o;
wire  a_syscon_valid_o,b_syscon_valid_o;
wire [31:0] a_syscon_value_o,b_syscon_value_o;
wire  a_protocol_error_o,b_protocol_error_o;
R64AxiPlatformBaseline a(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .arvalid_i(arvalid_i),
  .arready_o(a_arready_o),
  .arid_i(arid_i),
  .araddr_i(araddr_i),
  .arlen_i(arlen_i),
  .arsize_i(arsize_i),
  .arprot_i(arprot_i),
  .arburst_i(arburst_i),
  .rvalid_o(a_rvalid_o),
  .rready_i(rready_i),
  .rid_o(a_rid_o),
  .rdata_o(a_rdata_o),
  .rresp_o(a_rresp_o),
  .rlast_o(a_rlast_o),
  .awvalid_i(awvalid_i),
  .awready_o(a_awready_o),
  .awid_i(awid_i),
  .awaddr_i(awaddr_i),
  .awlen_i(awlen_i),
  .awsize_i(awsize_i),
  .awburst_i(awburst_i),
  .wvalid_i(wvalid_i),
  .wready_o(a_wready_o),
  .wdata_i(wdata_i),
  .wstrb_i(wstrb_i),
  .wlast_i(wlast_i),
  .bvalid_o(a_bvalid_o),
  .bready_i(bready_i),
  .bid_o(a_bid_o),
  .bresp_o(a_bresp_o),
  .ext_arvalid_o(a_ext_arvalid_o),
  .ext_arready_i(ext_arready_i),
  .ext_araddr_o(a_ext_araddr_o),
  .ext_arsize_o(a_ext_arsize_o),
  .ext_arprot_o(a_ext_arprot_o),
  .ext_rvalid_i(ext_rvalid_i),
  .ext_rready_o(a_ext_rready_o),
  .ext_rdata_i(ext_rdata_i),
  .ext_rresp_i(ext_rresp_i),
  .ext_awvalid_o(a_ext_awvalid_o),
  .ext_awready_i(ext_awready_i),
  .ext_awaddr_o(a_ext_awaddr_o),
  .ext_awsize_o(a_ext_awsize_o),
  .ext_wvalid_o(a_ext_wvalid_o),
  .ext_wready_i(ext_wready_i),
  .ext_wdata_o(a_ext_wdata_o),
  .ext_wstrb_o(a_ext_wstrb_o),
  .ext_bvalid_i(ext_bvalid_i),
  .ext_bready_o(a_ext_bready_o),
  .ext_bresp_i(ext_bresp_i),
  .uart_rx_valid_i(uart_rx_valid_i),
  .uart_rx_data_i(uart_rx_data_i),
  .uart_rx_ready_o(a_uart_rx_ready_o),
  .uart_tx_valid_o(a_uart_tx_valid_o),
  .uart_tx_data_o(a_uart_tx_data_o),
  .external_irq_sources_i(external_irq_sources_i),
  .timer_wait_o(a_timer_wait_o),
  .time_o(a_time_o),
  .irq_software_o(a_irq_software_o),
  .irq_timer_o(a_irq_timer_o),
  .irq_external_o(a_irq_external_o),
  .irq_supervisor_external_o(a_irq_supervisor_external_o),
  .syscon_valid_o(a_syscon_valid_o),
  .syscon_value_o(a_syscon_value_o),
  .protocol_error_o(a_protocol_error_o));
R64AxiPlatform b(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .arvalid_i(arvalid_i),
  .arready_o(b_arready_o),
  .arid_i(arid_i),
  .araddr_i(araddr_i),
  .arlen_i(arlen_i),
  .arsize_i(arsize_i),
  .arprot_i(arprot_i),
  .arburst_i(arburst_i),
  .rvalid_o(b_rvalid_o),
  .rready_i(rready_i),
  .rid_o(b_rid_o),
  .rdata_o(b_rdata_o),
  .rresp_o(b_rresp_o),
  .rlast_o(b_rlast_o),
  .awvalid_i(awvalid_i),
  .awready_o(b_awready_o),
  .awid_i(awid_i),
  .awaddr_i(awaddr_i),
  .awlen_i(awlen_i),
  .awsize_i(awsize_i),
  .awburst_i(awburst_i),
  .wvalid_i(wvalid_i),
  .wready_o(b_wready_o),
  .wdata_i(wdata_i),
  .wstrb_i(wstrb_i),
  .wlast_i(wlast_i),
  .bvalid_o(b_bvalid_o),
  .bready_i(bready_i),
  .bid_o(b_bid_o),
  .bresp_o(b_bresp_o),
  .ext_arvalid_o(b_ext_arvalid_o),
  .ext_arready_i(ext_arready_i),
  .ext_araddr_o(b_ext_araddr_o),
  .ext_arsize_o(b_ext_arsize_o),
  .ext_arprot_o(b_ext_arprot_o),
  .ext_rvalid_i(ext_rvalid_i),
  .ext_rready_o(b_ext_rready_o),
  .ext_rdata_i(ext_rdata_i),
  .ext_rresp_i(ext_rresp_i),
  .ext_awvalid_o(b_ext_awvalid_o),
  .ext_awready_i(ext_awready_i),
  .ext_awaddr_o(b_ext_awaddr_o),
  .ext_awsize_o(b_ext_awsize_o),
  .ext_wvalid_o(b_ext_wvalid_o),
  .ext_wready_i(ext_wready_i),
  .ext_wdata_o(b_ext_wdata_o),
  .ext_wstrb_o(b_ext_wstrb_o),
  .ext_bvalid_i(ext_bvalid_i),
  .ext_bready_o(b_ext_bready_o),
  .ext_bresp_i(ext_bresp_i),
  .uart_rx_valid_i(uart_rx_valid_i),
  .uart_rx_data_i(uart_rx_data_i),
  .uart_rx_ready_o(b_uart_rx_ready_o),
  .uart_tx_valid_o(b_uart_tx_valid_o),
  .uart_tx_data_o(b_uart_tx_data_o),
  .external_irq_sources_i(external_irq_sources_i),
  .timer_wait_o(b_timer_wait_o),
  .time_o(b_time_o),
  .irq_software_o(b_irq_software_o),
  .irq_timer_o(b_irq_timer_o),
  .irq_external_o(b_irq_external_o),
  .irq_supervisor_external_o(b_irq_supervisor_external_o),
  .syscon_valid_o(b_syscon_valid_o),
  .syscon_value_o(b_syscon_value_o),
  .protocol_error_o(b_protocol_error_o));
always #5 clk_i=~clk_i;
reg armed=0;integer events=0,bytes=0,resets=0;
always @(posedge clk_i)begin #1;if(armed)begin
if((1)&&(a_arready_o!==b_arready_o))$fatal(1,"reset A/B mismatch arready_o");
if((1)&&(a_rvalid_o!==b_rvalid_o))$fatal(1,"reset A/B mismatch rvalid_o");
if((a_rvalid_o)&&(a_rid_o!==b_rid_o))$fatal(1,"reset A/B mismatch rid_o");
if((a_rvalid_o)&&(a_rdata_o!==b_rdata_o))$fatal(1,"reset A/B mismatch rdata_o");
if((a_rvalid_o)&&(a_rresp_o!==b_rresp_o))$fatal(1,"reset A/B mismatch rresp_o");
if((a_rvalid_o)&&(a_rlast_o!==b_rlast_o))$fatal(1,"reset A/B mismatch rlast_o");
if((1)&&(a_awready_o!==b_awready_o))$fatal(1,"reset A/B mismatch awready_o");
if((1)&&(a_wready_o!==b_wready_o))$fatal(1,"reset A/B mismatch wready_o");
if((1)&&(a_bvalid_o!==b_bvalid_o))$fatal(1,"reset A/B mismatch bvalid_o");
if((a_bvalid_o)&&(a_bid_o!==b_bid_o))$fatal(1,"reset A/B mismatch bid_o");
if((a_bvalid_o)&&(a_bresp_o!==b_bresp_o))$fatal(1,"reset A/B mismatch bresp_o");
if((1)&&(a_ext_arvalid_o!==b_ext_arvalid_o))$fatal(1,"reset A/B mismatch ext_arvalid_o");
if(((|a_ext_arvalid_o))&&(a_ext_araddr_o!==b_ext_araddr_o))$fatal(1,"reset A/B mismatch ext_araddr_o");
if(((|a_ext_arvalid_o))&&(a_ext_arsize_o!==b_ext_arsize_o))$fatal(1,"reset A/B mismatch ext_arsize_o");
if(((|a_ext_arvalid_o))&&(a_ext_arprot_o!==b_ext_arprot_o))$fatal(1,"reset A/B mismatch ext_arprot_o");
if((1)&&(a_ext_rready_o!==b_ext_rready_o))$fatal(1,"reset A/B mismatch ext_rready_o");
if((1)&&(a_ext_awvalid_o!==b_ext_awvalid_o))$fatal(1,"reset A/B mismatch ext_awvalid_o");
if(((|a_ext_awvalid_o))&&(a_ext_awaddr_o!==b_ext_awaddr_o))$fatal(1,"reset A/B mismatch ext_awaddr_o");
if(((|a_ext_awvalid_o))&&(a_ext_awsize_o!==b_ext_awsize_o))$fatal(1,"reset A/B mismatch ext_awsize_o");
if((1)&&(a_ext_wvalid_o!==b_ext_wvalid_o))$fatal(1,"reset A/B mismatch ext_wvalid_o");
if(((|a_ext_wvalid_o))&&(a_ext_wdata_o!==b_ext_wdata_o))$fatal(1,"reset A/B mismatch ext_wdata_o");
if(((|a_ext_wvalid_o))&&(a_ext_wstrb_o!==b_ext_wstrb_o))$fatal(1,"reset A/B mismatch ext_wstrb_o");
if((1)&&(a_ext_bready_o!==b_ext_bready_o))$fatal(1,"reset A/B mismatch ext_bready_o");
if((1)&&(a_uart_rx_ready_o!==b_uart_rx_ready_o))$fatal(1,"reset A/B mismatch uart_rx_ready_o");
if((1)&&(a_uart_tx_valid_o!==b_uart_tx_valid_o))$fatal(1,"reset A/B mismatch uart_tx_valid_o");
if((a_uart_tx_valid_o)&&(a_uart_tx_data_o!==b_uart_tx_data_o))$fatal(1,"reset A/B mismatch uart_tx_data_o");
if((1)&&(a_timer_wait_o!==b_timer_wait_o))$fatal(1,"reset A/B mismatch timer_wait_o");
if((1)&&(a_time_o!==b_time_o))$fatal(1,"reset A/B mismatch time_o");
if((1)&&(a_irq_software_o!==b_irq_software_o))$fatal(1,"reset A/B mismatch irq_software_o");
if((1)&&(a_irq_timer_o!==b_irq_timer_o))$fatal(1,"reset A/B mismatch irq_timer_o");
if((1)&&(a_irq_external_o!==b_irq_external_o))$fatal(1,"reset A/B mismatch irq_external_o");
if((1)&&(a_irq_supervisor_external_o!==b_irq_supervisor_external_o))$fatal(1,"reset A/B mismatch irq_supervisor_external_o");
if((1)&&(a_syscon_valid_o!==b_syscon_valid_o))$fatal(1,"reset A/B mismatch syscon_valid_o");
if((a_syscon_valid_o)&&(a_syscon_value_o!==b_syscon_value_o))$fatal(1,"reset A/B mismatch syscon_value_o");
if((1)&&(a_protocol_error_o!==b_protocol_error_o))$fatal(1,"reset A/B mismatch protocol_error_o");
if(a_syscon_valid_o)events=events+1;
if(a_uart_tx_valid_o)bytes=bytes+1;
end end
task start_write(input [63:0] address,data,input [2:0] size);
 begin
  fork
   begin
    @(negedge clk_i);awvalid_i=1;awaddr_i=address;awsize_i=size;awburst_i=1;
    @(posedge clk_i);while(!a_awready_o)@(posedge clk_i);
    @(negedge clk_i);awvalid_i=0;
   end
   begin
    @(negedge clk_i);wvalid_i=1;wdata_i=data;wstrb_i=size==0?8'h1:8'hf;wlast_i=1;
    @(posedge clk_i);while(!a_wready_o)@(posedge clk_i);
    @(negedge clk_i);wvalid_i=0;
   end
  join
 end
endtask
task reset_now;
 begin
  #1;rst_i=1;#1;
  if(a_uart_tx_valid_o||b_uart_tx_valid_o||a_syscon_valid_o||b_syscon_valid_o)
   $fatal(1,"reset did not suppress an event immediately");
  @(posedge clk_i);#1;rst_i=0;
  #1;
  if(a_syscon_valid_o||b_syscon_valid_o||a_uart_tx_valid_o||b_uart_tx_valid_o)
   $fatal(1,"reset release exposed an old event before the next clock");
  repeat(4)begin @(posedge clk_i);#2;
   if(a_syscon_valid_o||b_syscon_valid_o||a_uart_tx_valid_o||b_uart_tx_valid_o)
    $fatal(1,"sampled reset leaked stale publication");
  end
  resets=resets+1;
 end
endtask
integer i;
initial begin
 rst_i=1;bready_i=1;rready_i=1;
 repeat(4)@(negedge clk_i);rst_i=0;armed=1;
 repeat(4)@(negedge clk_i);
 for(i=0;i<6;i=i+1)begin
  start_write(64'h100000,64'h12340000+i,2);
  wait(a_syscon_valid_o);@(negedge clk_i);
  if(i[0])reset_now();
  else begin wait(a_bvalid_o);@(negedge clk_i);repeat(3)@(negedge clk_i);end
 end
 for(i=0;i<6;i=i+1)begin
  start_write(64'h10000000,64'h41+i,0);
  wait(a_uart_tx_valid_o);@(negedge clk_i);
  if(i[0])reset_now();
  else repeat(12)@(negedge clk_i);
 end
 // Reset a request after only AW and then only W have been accepted.
 @(negedge clk_i);awvalid_i=1;awaddr_i=64'h100000;awsize_i=2;
 @(posedge clk_i);while(!a_awready_o)@(posedge clk_i);
 @(negedge clk_i);awvalid_i=0;reset_now();
 @(negedge clk_i);wvalid_i=1;wdata_i=64'h5678;wstrb_i=8'hf;wlast_i=1;
 @(posedge clk_i);while(!a_wready_o)@(posedge clk_i);
 @(negedge clk_i);wvalid_i=0;reset_now();
 start_write(64'h100000,64'habcddcba,2);
 wait(a_syscon_valid_o);@(negedge clk_i);repeat(8)@(negedge clk_i);
 if(events!=7||bytes!=6||resets!=8)$fatal(1,"reset coverage missing");
 // Sweep the reset edge through physical device acceptance/publication.
 // Resetting only after a visible event can miss a stale Q captured on reset.
 for(i=0;i<10;i=i+1)begin
  start_write(64'h100000,64'hc000+i,2);
  repeat(i)@(negedge clk_i);
  reset_now();
  start_write(64'h10000000,64'h61+i,0);
  repeat(i)@(negedge clk_i);
  reset_now();
 end
 if(resets!=28)$fatal(1,"reset phase sweep missing");
 $display("[PASS] tb_r64_platform_reset events=%0d bytes=%0d resets=%0d",events,bytes,resets);
 $finish;
end
initial begin #300000;$fatal(1,"platform reset timeout");end
endmodule
