`timescale 1ns/1ps
module tb_r64_fabric_devices;
  localparam integer S=1;
  reg clk_i=0;always #5 clk_i=~clk_i;
  reg rst_i=1;
  reg arvalid_i=0;wire arready_o;reg [3:0] arid_i=0;
  reg [63:0] araddr_i=0;reg [7:0] arlen_i=0;
  reg [2:0] arsize_i=0,arprot_i=0;reg [1:0] arburst_i=1;
  wire rvalid_o;reg rready_i=0;wire [3:0] rid_o;
  wire [63:0] rdata_o;wire [1:0] rresp_o;wire rlast_o;
  reg awvalid_i=0;wire awready_o;reg [3:0] awid_i=0;
  reg [63:0] awaddr_i=0;reg [7:0] awlen_i=0;
  reg [2:0] awsize_i=0;reg [1:0] awburst_i=1;
  reg wvalid_i=0;wire wready_o;reg [63:0] wdata_i=0;
  reg [7:0] wstrb_i=0;reg wlast_i=0;
  wire bvalid_o;reg bready_i=0;wire [3:0] bid_o;wire [1:0] bresp_o;
  wire [S-1:0] s_arvalid_o;wire [S-1:0] s_arready_i;
  wire [S*64-1:0] s_araddr_o;wire [S*3-1:0] s_arsize_o,s_arprot_o;
  wire [S-1:0] s_rvalid_i;wire [S-1:0] s_rready_o;
  wire [S*64-1:0] s_rdata_i;wire [S*2-1:0] s_rresp_i;
  wire [S-1:0] s_awvalid_o;wire [S-1:0] s_awready_i;
  wire [S*64-1:0] s_awaddr_o;wire [S*3-1:0] s_awsize_o;
  wire [S-1:0] s_wvalid_o;wire [S-1:0] s_wready_i;
  wire [S*64-1:0] s_wdata_o;wire [S*8-1:0] s_wstrb_o;
  wire [S-1:0] s_bvalid_i;wire [S-1:0] s_bready_o;
  wire [S*2-1:0] s_bresp_i;wire protocol_error_o;

  R64AxiFabric #(.SLAVES(S),.SLAVE_W(1),.BASE(64'h02000000),
    .MASK(64'hffffffffffff0000),.MEMORY(1'b0),.EXECUTABLE(1'b0)) dut(.*);
  wire [63:0] mtime;wire msip,mtip;
  AxiClint #(.ADDR_W(64),.DATA_W(64),.STRB_W(8),.MTIME_DIVISOR(10)) clint(
    .clk(clk_i),.rst(rst_i),
    .s_axi_arvalid_i(s_arvalid_o),.s_axi_arready_o(s_arready_i),
    .s_axi_araddr_i(s_araddr_o),.s_axi_arsize_i(s_arsize_o),
    .s_axi_rvalid_o(s_rvalid_i),.s_axi_rready_i(s_rready_o),
    .s_axi_rdata_o(s_rdata_i),.s_axi_rresp_o(s_rresp_i),
    .s_axi_awvalid_i(s_awvalid_o),.s_axi_awready_o(s_awready_i),
    .s_axi_awaddr_i(s_awaddr_o),.s_axi_awsize_i(s_awsize_o),
    .s_axi_wvalid_i(s_wvalid_o),.s_axi_wready_o(s_wready_i),
    .s_axi_wdata_i(s_wdata_o),.s_axi_wstrb_i(s_wstrb_o),
    .s_axi_bvalid_o(s_bvalid_i),.s_axi_bready_i(s_bready_o),.s_axi_bresp_o(s_bresp_i),
    .mtime_o(mtime),.msip_irq_o(msip),.mtip_irq_o(mtip));
  integer reads=0,writes=0,device_reads=0,device_writes=0;
  always @(posedge clk_i) if(!rst_i) begin
    if(s_arvalid_o&&s_arready_i) device_reads+=1;
    if(s_awvalid_o&&s_awready_i) device_writes+=1;
    if(protocol_error_o) $fatal(1,"protocol error");
  end
  task write_access(input [63:0] a,input [63:0] d,input [7:0] strb,
      input [2:0] sz,input integer beats,input bit data_first,input [1:0] expected);
    integer n;
    begin
      fork
        begin
          if(data_first) repeat(3) @(negedge clk_i);
          @(negedge clk_i);awvalid_i=1;awaddr_i=a;awlen_i=8'(beats-1);awsize_i=sz;awid_i=4'ha;
          @(posedge clk_i);while(!awready_o) @(posedge clk_i);
          @(negedge clk_i);awvalid_i=0;
        end
        begin
          if(!data_first) repeat(3) @(negedge clk_i);
          for(n=0;n<beats;n=n+1) begin
            @(negedge clk_i);wvalid_i=1;wdata_i=d;wstrb_i=strb;wlast_i=n==beats-1;
            @(posedge clk_i);while(!wready_o) @(posedge clk_i);
            @(negedge clk_i);wvalid_i=0;
          end
        end
      join
      wait(bvalid_o);
      repeat(3) @(posedge clk_i);
      if(bid_o!=4'ha||bresp_o!==expected) $fatal(1,"device B mismatch");
      @(negedge clk_i);bready_i=1;
      @(posedge clk_i);
      @(negedge clk_i);bready_i=0;writes+=1;
    end
  endtask
  task read_access(input [63:0] a,input [2:0] sz,input integer beats,
      input bit fetch,input [63:0] expected,input [1:0] resp);
    integer n;
    begin
      @(negedge clk_i);arvalid_i=1;araddr_i=a;arsize_i=sz;
      arlen_i=8'(beats-1);arprot_i=fetch?3'b100:3'b000;arid_i=4'hd;
      @(posedge clk_i);while(!arready_o) @(posedge clk_i);
      @(negedge clk_i);arvalid_i=0;
      repeat(4) @(negedge clk_i);rready_i=1;
      for(n=0;n<beats;n=n+1) begin
        @(posedge clk_i);while(!rvalid_o) @(posedge clk_i);
        if(rid_o!=4'hd||rdata_o!==expected||rresp_o!==resp||rlast_o!==(n==beats-1))
          $fatal(1,"device read mismatch addr=%h data=%h expected=%h resp=%h",a,rdata_o,expected,rresp_o);
      end
      @(negedge clk_i);rready_i=0;reads+=1;
    end
  endtask
  initial begin
    repeat(4) @(negedge clk_i);rst_i=0;
    write_access(64'h02004000,64'h1234567887654321,8'hff,3,1,1,0);
    read_access(64'h02004000,3,1,0,64'h1234567887654321,0);
    write_access(64'h02004004,64'habcd012300000000,8'hf0,2,1,0,0);
    read_access(64'h02004000,3,1,0,64'habcd012387654321,0);
    read_access(64'h02004004,2,1,0,64'habcd012300000000,0);
    write_access(64'h02004000,64'h11223344,8'h0f,2,1,1,0);
    read_access(64'h02004000,3,1,0,64'habcd012311223344,0);
    write_access(64'h02000000,64'd1,8'h0f,2,1,0,0);
    read_access(64'h02000000,2,1,0,64'd1,0);
    if(!msip) $fatal(1,"MSIP missing");
    write_access(64'h02000000,64'd0,8'h0f,2,1,1,0);
    read_access(64'h02000000,2,1,0,64'd0,0);
    read_access(64'h02004000,3,4,0,64'd0,3);
    write_access(64'h02004000,64'd0,8'hff,3,4,1,3);
    read_access(64'h02004000,3,1,0,64'habcd012311223344,0);
    read_access(64'h02000000,2,1,1,64'd0,3);
    read_access(64'h50000000,3,1,0,64'd0,3);
    if(device_reads!=7||device_writes!=5) $fatal(1,"forbidden device side effect");
    $display("[PASS] tb_r64_fabric_devices");
    $display("CLINT 64/32-bit readback PASS; reads=%0d writes=%0d device_reads=%0d device_writes=%0d",
      reads,writes,device_reads,device_writes);
    $finish;
  end
  initial begin #100000;$fatal(1,"timeout");end
endmodule
