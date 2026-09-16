`timescale 1ns/1ps
module tb_r64_fabric_read_continue;
  parameter READ_CONTINUE=1,EARLY_RETURN=1;
  localparam integer S=2;
  reg clk_i=0;always #5 clk_i=~clk_i;
  reg rst_i=1;
  reg arvalid_i=0;wire arready_o;reg [3:0] arid_i=0;
  reg [63:0] araddr_i=0;reg [7:0] arlen_i=0;
  reg [2:0] arsize_i=0,arprot_i=0;reg [1:0] arburst_i=1;
  wire rvalid_o;reg rready_i=0;wire [3:0] rid_o;
  wire [63:0] rdata_o;wire [1:0] rresp_o;wire rlast_o;
  wire awvalid_i;wire awready_o;wire [3:0] awid_i;
  wire [63:0] awaddr_i;wire [7:0] awlen_i;
  wire [2:0] awsize_i;wire [1:0] awburst_i;
  wire wvalid_i;wire wready_o;wire [63:0] wdata_i;
  wire [7:0] wstrb_i;wire wlast_i;
  wire bvalid_o;wire bready_i;wire [3:0] bid_o;wire [1:0] bresp_o;
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
    .READ_CONTINUE(READ_CONTINUE),.EARLY_RETURN(EARLY_RETURN),
    .BASE({64'ha0000000,64'h80000000}),
    .MASK({64'hfffffffff0000000,64'hfffffffff0000000}),
    .MEMORY(2'b11),.EXECUTABLE(2'b11)) dut(.*);


  assign awvalid_i=0;assign awid_i=0;assign awaddr_i=0;assign awlen_i=0;
  assign awsize_i=0;assign awburst_i=1;assign wvalid_i=0;assign wdata_i=0;
  assign wstrb_i=0;assign wlast_i=0;assign bready_i=1;
  integer cycle=0,submitted=0,completed=0,physical=0;
  integer begin_cycle=0,end_cycle=0,first_gap=0,last_ar=-1;
  integer remaining[0:15],total[0:15];reg [63:0] next_addr[0:15];
  reg [15:0] live=0;reg [1:0] hold_ar=0;reg [63:0] held_ar[0:1];
  reg hold_r=0;reg [70:0] held_r;
  integer owner_log[0:127],log_count=0,n,id;
  reg measuring=0;
  function [63:0] value(input [63:0] a);value=a^64'h2a9f1287354bcdef;endfunction
  function [1:0] error_for(input [63:0] a);error_for=a[5:3]==4?2'b10:0;endfunction
  always @(posedge clk_i)begin
    cycle=cycle+1;
    if(!rst_i)begin
      if(protocol_error_o)$fatal(1,"protocol error");
      for(n=0;n<S;n=n+1)begin
        if(hold_ar[n]&&(!s_arvalid_o[n]||s_araddr_o[n*64+:64]!==held_ar[n]))
          $fatal(1,"AR payload changed while blocked");
        hold_ar[n]=s_arvalid_o[n]&&!s_arready_i[n];held_ar[n]=s_araddr_o[n*64+:64];
        if(s_rvalid_i[n]&&s_rready_o[n])s_rvalid_i[n]<=0;
        if(s_arvalid_o[n]&&s_arready_i[n])begin
          if(s_rvalid_i[n])$fatal(1,"next Lite beat launched before previous R drain");
          s_rvalid_i[n]<=1;s_rdata_i[n*64+:64]<=value(s_araddr_o[n*64+:64]);
          s_rresp_i[n*2+:2]<=error_for(s_araddr_o[n*64+:64]);
          physical=physical+1;
          owner_log[log_count]=s_araddr_o[n*64+:64]>=64'h80000100 ? 1 : 0;log_count=log_count+1;
          if(measuring&&last_ar>=0)begin
            first_gap=cycle-last_ar;
            if(first_gap!=(READ_CONTINUE?(EARLY_RETURN?2:3):(EARLY_RETURN?4:5)))
              $fatal(1,"continuation gap %0d",first_gap);
          end
          last_ar=cycle;
        end
      end
      if(hold_r&&(!rvalid_o||{rid_o,rdata_o,rresp_o,rlast_o}!==held_r))
        $fatal(1,"AXI R output unstable");
      hold_r=rvalid_o&&!rready_i;held_r={rid_o,rdata_o,rresp_o,rlast_o};
      if(arvalid_i&&arready_o)begin
        if(live[arid_i])$fatal(1,"live ID reused");
        live[arid_i]=1;next_addr[arid_i]=araddr_i;remaining[arid_i]=arlen_i+1;
        total[arid_i]=arlen_i+1;submitted=submitted+1;begin_cycle=cycle;
      end
      if(rvalid_o&&rready_i)begin
        id=rid_o;
        if(!live[id]||rdata_o!==value(next_addr[id])||rresp_o!==error_for(next_addr[id])||
          rlast_o!=(remaining[id]==1))$fatal(1,"read owner/data/error/last mismatch id=%0d",id);
        remaining[id]=remaining[id]-1;next_addr[id]=next_addr[id]+8;
        if(rlast_o)begin live[id]=0;completed=completed+1;end_cycle=cycle;end
      end
    end
  end
  task send(input [3:0] i,input [63:0] a,input [7:0] len);
    begin
      @(negedge clk_i);arvalid_i=1;arid_i=i;araddr_i=a;arlen_i=len;arsize_i=3;
      do @(posedge clk_i);while(!arready_o);
      @(negedge clk_i);arvalid_i=0;
    end
  endtask
  integer x,start_physical,waited;
  initial begin
    repeat(4)@(negedge clk_i);rst_i=0;
    repeat(2)@(negedge clk_i);s_arready_i=3;rready_i=1;
    measuring=1;send(0,64'h80000000,7);wait(live==0);@(negedge clk_i);
    $display("READ_LATENCY continue=%0d early=%0d eight_beats=%0d gap=%0d",READ_CONTINUE,EARLY_RETURN,end_cycle-begin_cycle,first_gap);
    if(end_cycle-begin_cycle!=(EARLY_RETURN?6:7)+7*(READ_CONTINUE?(EARLY_RETURN?2:3):(EARLY_RETURN?4:5)))
      $fatal(1,"read total latency");
    measuring=0;log_count=0;last_ar=-1;
    // A pending same-target owner must receive service before the old burst
    // finishes, even when continuation would otherwise be available.
    send(0,64'h80000000,7);send(1,64'h80000100,0);
    wait(live==0);@(negedge clk_i);
    waited=0;for(x=0;x<log_count;x=x+1)if(owner_log[x]==1)waited=x;
    if(waited==0||waited>=8)$fatal(1,"same-target contender starved pos=%0d",waited);
    // A held launch and a full R output queue must retain their exact owner.
    rready_i=0;s_arready_i=0;start_physical=physical;
    send(0,64'h80000000,7);send(1,64'ha0000100,3);
    repeat(10)@(negedge clk_i);
    if(physical!=start_physical)$fatal(1,"blocked AR was treated as a launch");
    s_arready_i=3;repeat(20)@(negedge clk_i);rready_i=1;
    wait(live==0);repeat(4)@(negedge clk_i);
    if(submitted!=5||completed!=5||physical!=29)$fatal(1,"coverage %0d %0d %0d",submitted,completed,physical);
    $display("[PASS] tb_r64_fabric_read_continue same-target fairness, delayed AR, full R FIFO, beat errors");$finish;
  end
  initial begin #100000;$fatal(1,"read continuation timeout");end
endmodule
