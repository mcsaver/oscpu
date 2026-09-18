`timescale 1ns/1ps
module tb_r64_fabric_reset;
  localparam integer S=3;
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
  wire [S-1:0] s_arvalid_o;reg [S-1:0] s_arready_i=0;
  wire [S*64-1:0] s_araddr_o;wire [S*3-1:0] s_arsize_o,s_arprot_o;
  reg [S-1:0] s_rvalid_i=0;wire [S-1:0] s_rready_o;
  reg [S*64-1:0] s_rdata_i=0;reg [S*2-1:0] s_rresp_i=0;
  wire [S-1:0] s_awvalid_o;reg [S-1:0] s_awready_i=0;
  wire [S*64-1:0] s_awaddr_o;wire [S*3-1:0] s_awsize_o;
  wire [S-1:0] s_wvalid_o;reg [S-1:0] s_wready_i=0;
  wire [S*64-1:0] s_wdata_o;wire [S*8-1:0] s_wstrb_o;
  reg [S-1:0] s_bvalid_i=0;wire [S-1:0] s_bready_o;
  reg [S*2-1:0] s_bresp_i=0;wire protocol_error_o;
  R64AxiFabric #(.SLAVES(S),.SLAVE_W(2),
    .BASE({64'h10000000,64'ha0000000,64'h80000000}),
    .MASK({64'hfffffffffffff000,64'hfffffffff0000000,64'hfffffffff0000000}),
    .MEMORY(3'b011),.EXECUTABLE(3'b011)) dut(.*);


  // The endpoint model shares reset with Fabric, as R64AxiPlatform does.
  // Reset cancels all bus owners, including responses held by either side.
  reg endpoint_enable=0;
  reg [S-1:0] got_aw=0,got_w=0;
  reg [63:0] ep_addr[0:S-1],ep_data[0:S-1];
  integer reads=0,writes=0,rreturns=0,breturns=0,j,timeout_count;
  reg [63:0] expected_read=0,expected_write=0,expected_address=0;
  reg observe=0;
  always @(*) begin
    s_arready_i={S{endpoint_enable}}&~s_rvalid_i;
    s_awready_i={S{endpoint_enable}}&~got_aw&~s_bvalid_i;
    s_wready_i={S{endpoint_enable}}&~got_w&~s_bvalid_i;
  end
  always @(posedge clk_i) begin
    if(rst_i) begin
      s_rvalid_i<=0;s_bvalid_i<=0;got_aw<=0;got_w<=0;
      reads<=0;writes<=0;rreturns<=0;breturns<=0;
    end else begin
      for(j=0;j<S;j=j+1) begin
        if(s_rvalid_i[j]&&s_rready_o[j])s_rvalid_i[j]<=0;
        if(s_arvalid_o[j]&&s_arready_i[j]) begin
          s_rvalid_i[j]<=1;
          s_rdata_i[j*64+:64]<=s_araddr_o[j*64+:64]^64'h891234567abcdef0;
          reads<=reads+1;
        end
        if(s_bvalid_i[j]&&s_bready_o[j])s_bvalid_i[j]<=0;
        if(s_awvalid_o[j]&&s_awready_i[j]) begin
          got_aw[j]<=1;ep_addr[j]<=s_awaddr_o[j*64+:64];
        end
        if(s_wvalid_o[j]&&s_wready_i[j]) begin
          got_w[j]<=1;ep_data[j]<=s_wdata_o[j*64+:64];
        end
        if(got_aw[j]&&got_w[j]&&!s_bvalid_i[j])begin
          if(observe&&(ep_addr[j]!==expected_address||ep_data[j]!==expected_write))
            $fatal(1,"reset leaked old AW/W payload into new owner");
          writes<=writes+1;got_aw[j]<=0;got_w[j]<=0;s_bvalid_i[j]<=1;
        end
      end
      if(observe&&rvalid_o&&rready_i)begin
        if(rid_o!==4'd1||rdata_o!==expected_read||rresp_o!==0||!rlast_o)
          $fatal(1,"reset leaked old R owner/data");
        rreturns<=rreturns+1;
      end
      if(observe&&bvalid_o&&bready_i)begin
        if(bid_o!==4'd1||bresp_o!==0)$fatal(1,"reset leaked old B owner");
        breturns<=breturns+1;
      end
      if(protocol_error_o)$fatal(1,"protocol error after reset");
    end
  end

  task send_read;
    input [3:0] id;input [63:0] address;
    begin
      @(negedge clk_i);arvalid_i=1;arid_i=id;araddr_i=address;arsize_i=3;
      do @(posedge clk_i);while(!arready_o);
      @(negedge clk_i);arvalid_i=0;araddr_i=64'hdeadbeef;
    end
  endtask
  task send_write;
    input [3:0] id;input [63:0] address,data;
    begin
      // W first deliberately leaves data queued without an AW owner.
      @(negedge clk_i);wvalid_i=1;wdata_i=data;wstrb_i=8'hff;wlast_i=1;
      do @(posedge clk_i);while(!wready_o);
      @(negedge clk_i);wvalid_i=0;wdata_i=64'hdeaddead;
      awvalid_i=1;awid_i=id;awaddr_i=address;awsize_i=3;
      do @(posedge clk_i);while(!awready_o);
      @(negedge clk_i);awvalid_i=0;awaddr_i=64'hbeefdead;
    end
  endtask
  task reset_bus;
    input integer reset_cycles;
    begin
      @(negedge clk_i);rst_i=1;observe=0;
      // READY may stay high in reset. These apparent transfers must not
      // modify any owner queue in a reset-prioritized sequential block.
      arvalid_i=1;awvalid_i=1;wvalid_i=1;rready_i=1;bready_i=1;
      #1;
      if({rvalid_o,bvalid_o,s_arvalid_o,s_awvalid_o,s_wvalid_o}!==0)
        $fatal(1,"VALID visible during reset");
      repeat(reset_cycles)begin
        @(posedge clk_i);#1;
        if({rvalid_o,bvalid_o,s_arvalid_o,s_awvalid_o,s_wvalid_o}!==0)
          $fatal(1,"reset-edge transfer survived");
      end
      @(negedge clk_i);arvalid_i=0;awvalid_i=0;wvalid_i=0;rst_i=0;
      repeat(12)begin
        @(posedge clk_i);#1;
        if({rvalid_o,bvalid_o,s_arvalid_o,s_awvalid_o,s_wvalid_o}!==0)
          $fatal(1,"pre-reset owner reappeared");
      end
      if(reads!=0||writes!=0)$fatal(1,"reset generated a physical side effect");
    end
  endtask
  initial begin
    repeat(3)@(negedge clk_i);rst_i=0;
    send_read(1,64'h80000080);
    send_write(1,64'h80000088,64'h1122334455667788);
    repeat(5)@(negedge clk_i);
    if(!s_arvalid_o[0]||!s_awvalid_o[0]||!s_wvalid_o[0])
      $fatal(1,"missing stalled physical address/data coverage");
    reset_bus(1);

    endpoint_enable=1;rready_i=0;bready_i=0;
    send_read(1,64'ha0000010);
    send_write(1,64'ha0000018,64'hfedcba9876543210);
    timeout_count=0;
    while(!rvalid_o||!bvalid_o)begin
      @(negedge clk_i);timeout_count=timeout_count+1;
      if(timeout_count>60)$fatal(1,"missing held response coverage");
    end
    if(reads!=1||writes!=1)$fatal(1,"physical transactions did not complete");
    reset_bus(3);

    // Reuse exactly the same IDs after reset; old payloads differ in every
    // field that the independent endpoint and upstream scoreboards inspect.
    expected_address=64'h80000200;
    expected_read=expected_address^64'h891234567abcdef0;
    expected_write=64'h55aaccee12345678;observe=1;
    send_read(1,expected_address);
    send_write(1,expected_address,expected_write);
    timeout_count=0;
    while(rreturns!=1||breturns!=1)begin
      @(negedge clk_i);timeout_count=timeout_count+1;
      if(timeout_count>60)$fatal(1,"new owner did not complete after reset");
    end
    repeat(10)@(negedge clk_i);
    if(reads!=1||writes!=1||rreturns!=1||breturns!=1)
      $fatal(1,"duplicate completion across reset");
    $display("[PASS] tb_r64_fabric_reset");
    $finish;
  end
  initial begin #20000;$fatal(1,"reset test timed out");end
endmodule
