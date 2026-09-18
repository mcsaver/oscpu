`timescale 1ns/1ps
module tb_r64_fabric_latency;
  parameter EXPECT_EARLY=1;
  parameter B_BYPASS=0;
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
    .BASE({64'ha0000000,64'h80000000}),
    .MASK({64'hfffffffff0000000,64'hfffffffff0000000}),
    .MEMORY(2'b11),.EXECUTABLE(2'b11)) dut(.*);


  reg [1:0] cmd_valid=0,data_valid=0,rsp_ready=0;
  wire [1:0] cmd_ready,data_ready,rsp_valid;
  reg [127:0] cmd_addr=0,data=0;
  reg [15:0] cmd_len=0,strb=0;
  reg [5:0] cmd_size=0;
  wire [3:0] rsp_resp;wire writer_error;wire [2:0] awprot;
  R64AxiWrite #(.B_BYPASS(B_BYPASS)) writer(
    .clk_i(clk_i),.rst_i(rst_i),.cmd_valid_i(cmd_valid),.cmd_ready_o(cmd_ready),
    .cmd_addr_i(cmd_addr),.cmd_len_i(cmd_len),.cmd_size_i(cmd_size),.cmd_prot_i(6'b0),
    .data_valid_i(data_valid),.data_ready_o(data_ready),.data_i(data),.strb_i(strb),
    .rsp_valid_o(rsp_valid),.rsp_ready_i(rsp_ready),.rsp_resp_o(rsp_resp),
    .awvalid_o(awvalid_i),.awready_i(awready_o),.awid_o(awid_i),.awaddr_o(awaddr_i),
    .awlen_o(awlen_i),.awsize_o(awsize_i),.awprot_o(awprot),.awburst_o(awburst_i),
    .wvalid_o(wvalid_i),.wready_i(wready_o),.wdata_o(wdata_i),.wstrb_o(wstrb_i),.wlast_o(wlast_i),
    .bvalid_i(bvalid_o),.bready_o(bready_i),.bid_i(bid_o),.bresp_i(bresp_o),.protocol_error_o(writer_error));
  integer cycle=0,cmd_cycle=-1,data_cycle=-1,return_cycle=-1,case_id=0;
  integer lite_beats=0,both_return=0,expected_beats=1,error_beat=-1,error_code=2;
  integer awc=-1,wc=-1,lc=-1,lbc=-1,bc=-1;
  reg [1:0] seen_aw=0,seen_w=0,joined=0;
  reg [63:0] address[0:1],payload[0:1];
  reg [7:0] strobes[0:1];
  reg release_together=0;
  reg [1:0] parked_resp=0;
  integer n;
  always @(negedge clk_i) if(!rst_i)begin
    s_awready_i=~seen_aw&~s_bvalid_i&~joined;
    s_wready_i=~seen_w&~s_bvalid_i&~joined;
  end
  always @(posedge clk_i)begin
    cycle=cycle+1;
    if(rst_i)begin
      seen_aw<=0;seen_w<=0;joined<=0;s_bvalid_i<=0;s_bresp_i<=0;
    end else begin
      if(protocol_error_o||writer_error)$fatal(1,"transport protocol error");
      if(cmd_valid[0]&&cmd_ready[0])cmd_cycle=cycle;
      if(data_valid[0]&&data_ready[0])data_cycle=cycle;
      if(rsp_valid[0]&&rsp_ready[0])return_cycle=cycle;
      if(awvalid_i&&awready_o)awc=cycle;
      if(wvalid_i&&wready_o)wc=cycle;
      if(bvalid_o&&bready_i)bc=cycle;
      if((&s_bvalid_i)&&(&s_bready_o))both_return=both_return+1;
      for(n=0;n<S;n=n+1)begin
        if(s_bvalid_i[n]&&s_bready_o[n])s_bvalid_i[n]<=0;
        if(s_awvalid_o[n]&&s_awready_i[n])begin
          seen_aw[n]<=1;address[n]<=s_awaddr_o[n*64+:64];
        end
        if(s_wvalid_o[n]&&s_wready_i[n])begin
          seen_w[n]<=1;payload[n]<=s_wdata_o[n*64+:64];strobes[n]<=s_wstrb_o[n*8+:8];
        end
        // Model a real registered endpoint: a simultaneous AW/W pair is
        // committed at this edge and B appears for the following cycle.
        if((seen_aw[n]||(s_awvalid_o[n]&&s_awready_i[n]))&&
           (seen_w[n]||(s_wvalid_o[n]&&s_wready_i[n])))begin
          seen_aw[n]<=0;seen_w[n]<=0;joined[n]<=release_together;
          if(!release_together)s_bvalid_i[n]<=1;
          s_bresp_i[n*2+:2]<=lite_beats==error_beat?2'(error_code):2'b00;
          lite_beats=lite_beats+1;lc=cycle;
        end
        if(s_bvalid_i[n]&&s_bready_o[n])lbc=cycle;
      end
      if(release_together&&(&joined))begin joined<=0;s_bvalid_i<=2'b11;end
    end
  end
  task reset_case;
    begin
      @(negedge clk_i);rst_i=1;cmd_valid=0;data_valid=0;rsp_ready=0;
      repeat(3)@(negedge clk_i);
      rst_i=0;lite_beats=0;cmd_cycle=-1;data_cycle=-1;return_cycle=-1;
      awc=-1;wc=-1;lc=-1;lbc=-1;bc=-1;case_id=case_id+1;
    end
  endtask
  task automatic send(input integer client,input integer beats,input [63:0] a);
    integer beat;bit cf,df;
    begin
      beat=0;cf=0;
      @(negedge clk_i);cmd_valid[client]=1;data_valid[client]=1;
      cmd_addr[client*64+:64]=a;cmd_len[client*8+:8]=8'(beats-1);
      cmd_size[client*3+:3]=3;data[client*64+:64]=64'h123456789abcdef0;
      strb[client*8+:8]=8'hff;
      while(!cf||beat<beats)begin
        @(posedge clk_i);
        if(cmd_valid[client]&&cmd_ready[client])cf=1;
        df=data_valid[client]&&data_ready[client];
        if(df)beat=beat+1;
        @(negedge clk_i);
        if(cf)cmd_valid[client]=0;
        if(beat==beats)data_valid[client]=0;
      end
    end
  endtask
  task latency_case(input integer beats,input integer errat,input [1:0] er);
    integer result;
    begin
      reset_case();error_beat=errat;error_code=int'(er);rsp_ready=1;
      send(0,beats,64'h80000000);
      wait(rsp_valid[0]);
      if(rsp_resp[1:0]!==er)$fatal(1,"error aggregation case=%0d resp=%b expected=%b",case_id,rsp_resp[1:0],er);
      @(negedge clk_i);
      if(return_cycle<0)@(negedge clk_i);
      result=return_cycle-cmd_cycle;
      if(result!=((EXPECT_EARLY?6+2*(beats-1):8+3*(beats-1))-B_BYPASS))
        $fatal(1,"unexpected command-to-return case=%0d beats=%0d measured=%0d",case_id,beats,result);
      if(lite_beats!=beats)$fatal(1,"missing/extra device side effect");
      $display("LATENCY case=%0d beats=%0d cmd_to_B=%0d tail_data_to_B=%0d AXIaw=%0d AXIw=%0d lastLite=%0d lastLiteB=%0d AXIB=%0d clientB=%0d",
        case_id,beats,result,return_cycle-data_cycle,awc-cmd_cycle,wc-cmd_cycle,lc-cmd_cycle,lbc-cmd_cycle,bc-cmd_cycle,result);
    end
  endtask
  initial begin
    latency_case(1,-1,0);
    latency_case(4,-1,0);
    latency_case(8,0,2);
    latency_case(8,3,2);
    latency_case(8,7,3);
    reset_case();release_together=1;error_beat=-1;
    fork send(0,1,64'h80000000);send(1,1,64'ha0000000);join
    wait(&s_bvalid_i);repeat(8)@(negedge clk_i);
    if(both_return!=1||lite_beats!=2)$fatal(1,"simultaneous terminal responses not exercised");
    if(!writer.busy_q[0]||!writer.busy_q[1])$fatal(1,"ID freed before client delivery");
    cmd_valid=3;repeat(4)begin @(negedge clk_i);if(cmd_ready!=0)$fatal(1,"blocked response ID reused");end
    cmd_valid=0;rsp_ready=3;
    wait(writer.busy_q==0);repeat(3)@(negedge clk_i);
    $display("[PASS] tb_r64_fabric_latency early=%0d simultaneous_final_B=%0d",EXPECT_EARLY,both_return);$finish;
  end
  initial begin #200000;$fatal(1,"timeout");end
endmodule
