`timescale 1ns/1ps
module tb_r64_fabric #(parameter [2:0] READ_MEMORY_MASK=0);
  localparam integer N=96,M=64,S=3;
  reg clk_i=0;always #5 clk_i=~clk_i;
  reg bad_last;initial bad_last=$test$plusargs("bad-last");
  reg [1023:0] outputs_before;
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
  R64AxiFabric #(.SLAVES(S),.SLAVE_W(2),.READ_MEMORY_MASK(READ_MEMORY_MASK),
    .BASE({64'h10000000,64'ha0000000,64'h80000000}),
    .MASK({64'hfffffffffffff000,64'hfffffffff0000000,64'hfffffffff0000000}),
    .MEMORY(3'b011),.EXECUTABLE(3'b011)) dut(.*);

  reg [63:0] addr[0:N-1];
  reg [7:0] len[0:N-1];
  reg [2:0] size[0:N-1],prot[0:N-1];
  reg [1:0] burst[0:N-1];
  reg bad[0:N-1];
  integer rseq[0:3],rbeat[0:3],wseq[0:1];
  reg [3:0] rbusy=0;reg [1:0] wbusy=0;
  integer sentr=0,sentw=0,data_seq=0,data_beat=0;
  integer read_done=0,write_done=0,read_beats=0,write_beats=0;
  integer lite_reads=0,lite_writes=0,expect_reads=0,expect_writes=0;
  integer cycles=0,dual_rw=0,interleave=0,last_rid=-1,rstall=0,wstall=0;
  integer awfirst=0,wfirst=0,max_live=0,live_count=0;
  reg arf=0,awf=0,wf=0;
  reg [31:0] rand_q=32'h514aa731;
  reg [S-1:0] seen_aw=0,seen_w=0;
  reg [63:0] awaddr[0:S-1],wdata[0:S-1];
  reg [2:0] awsize[0:S-1];
  reg [7:0] wstrb[0:S-1];
  reg [S-1:0] hold_ar=0,hold_aw=0,hold_w=0;
  reg [69:0] prev_ar[0:S-1];
  reg [66:0] prev_aw[0:S-1];
  reg [71:0] prev_w[0:S-1];
  reg hold_r=0,hold_b=0;reg [70:0] prev_r;reg [5:0] prev_b;
  integer i,j,k,seq,beat;
  reg [63:0] ea;
  reg [1:0] er;
  function [63:0] pattern;
    input [63:0] a;
    begin pattern=64'hd9a463072c8105ef^a^(a<<17);end
  endfunction
  function [63:0] beataddr;
    input integer t;input integer b;
    begin beataddr=addr[t]+(burst[t]==0?64'd0:(64'(b)<<size[t]));end
  endfunction
  function [7:0] mask;
    input [63:0] a;input [2:0] sz;
    begin mask=8'(((1<<(1<<sz))-1)<<a[2:0]);end
  endfunction
  initial begin
    for(i=0;i<N;i=i+1) begin
      addr[i]=64'h80000000+64'(i*64);
      len[i]=7;size[i]=3;prot[i]=0;burst[i]=1;bad[i]=0;
      // Legal final beat exactly at the page edge; adjacent case 5 rejects
      // crossing it. Independent beataddr() still computes the full 64-bit sum.
      if(i%12==0)addr[i]=64'h80000fc0+64'((i/12)*4096);
      case(i%12)
        1:begin addr[i]=64'ha0000000+64'(i*64);len[i]=3;end
        2:begin addr[i]=64'h10000000+64'((i*8)%4096);len[i]=0;size[i]=3'(i%4);end
        3:begin addr[i]=64'h10000000;len[i]=3;bad[i]=1;end
        4:begin addr[i]=64'h50000000;len[i]=1;bad[i]=1;end
        5:begin addr[i]=64'h80000ff8;len[i]=3;bad[i]=1;end
        6:begin addr[i]=64'h80000200;len[i]=2;size[i]=4;bad[i]=1;end
        7:begin addr[i]=64'ha0000000+64'(i*64);len[i]=5;burst[i]=0;end
        8:begin addr[i]=64'h80000000+64'(i*64);len[i]=3;size[i]=1;end
        9:begin addr[i]=64'h10000000;len[i]=0;prot[i]=4;bad[i]=1;end
        10:begin addr[i]=64'h80000301;len[i]=0;bad[i]=1;end
        11:begin addr[i]=64'h80000400;len[i]=3;burst[i]=2;bad[i]=1;end
      endcase
      if(!bad[i]) expect_reads+=int'(len[i])+1;
      // AW has no executable protection; this read-only invalidity is legal AW.
      if(i<M&&(!bad[i]||i%12==9)) expect_writes+=int'(len[i])+1;
    end
    for(i=0;i<4;i=i+1) begin rseq[i]=0;rbeat[i]=0;end
    for(i=0;i<2;i=i+1) wseq[i]=0;
    repeat(4) @(negedge clk_i);rst_i=0;
  end
  always @(negedge clk_i) if(!rst_i) begin
    outputs_before={arready_o,rvalid_o,rid_o,rdata_o,rresp_o,rlast_o,awready_o,wready_o,bvalid_o,bid_o,bresp_o,s_arvalid_o,s_araddr_o,s_arsize_o,s_arprot_o,s_rready_o,s_awvalid_o,s_awaddr_o,s_awsize_o,s_wvalid_o,s_wdata_o,s_wstrb_o,s_bready_o};
    rand_q={rand_q[30:0],rand_q[31]^rand_q[21]^rand_q[1]^rand_q[0]};
    rready_i=rand_q[0]|rand_q[3];bready_i=rand_q[2]|rand_q[7];
    for(j=0;j<S;j=j+1) begin
      s_arready_i[j]=!s_rvalid_i[j]&&rand_q[j+5];
      s_awready_i[j]=!seen_aw[j]&&!s_bvalid_i[j]&&rand_q[j+12];
      s_wready_i[j]=!seen_w[j]&&!s_bvalid_i[j]&&rand_q[j+18];
    end
    if(!arvalid_i||arf) begin
      arvalid_i=0;
      if(sentr<N&&!rbusy[sentr%4]&&rand_q[22]) begin
        arvalid_i=1;arid_i=4'(sentr%4);araddr_i=addr[sentr];arlen_i=len[sentr];
        arsize_i=size[sentr];arprot_i=prot[sentr];arburst_i=burst[sentr];
      end
    end
    if(!awvalid_i||awf) begin
      awvalid_i=0;
      if(sentw<M&&!wbusy[sentw%2]&&rand_q[23]) begin
        awvalid_i=1;awid_i=4'(sentw%2);awaddr_i=addr[sentw];
        awlen_i=len[sentw];awsize_i=size[sentw];awburst_i=burst[sentw];
      end
    end
    if(!wvalid_i||wf) begin
      wvalid_i=0;
      if(data_seq<M&&rand_q[24]) begin
        wvalid_i=1;wdata_i=pattern(beataddr(data_seq,data_beat));
        wstrb_i=mask(beataddr(data_seq,data_beat),size[data_seq]);
        wlast_i=(data_beat==int'(len[data_seq]))||(bad_last&&data_seq==0&&data_beat==0);
      end
    end
    #1;
    if(cycles!=0&&outputs_before!==1024'({arready_o,rvalid_o,rid_o,rdata_o,rresp_o,rlast_o,awready_o,wready_o,bvalid_o,bid_o,bresp_o,s_arvalid_o,s_araddr_o,s_arsize_o,s_arprot_o,s_rready_o,s_awvalid_o,s_awaddr_o,s_awsize_o,s_wvalid_o,s_wdata_o,s_wstrb_o,s_bready_o})) $fatal(1,"AXI input-to-output combinational path");
  end
  always @(posedge clk_i) if(!rst_i) begin
    cycles+=1;
    arf=arvalid_i&&arready_o;awf=awvalid_i&&awready_o;wf=wvalid_i&&wready_o;
    if(arf) begin
      if(rbusy[arid_i]) $fatal(1,"read owner reused");
      rbusy[arid_i]=1;rseq[arid_i]=sentr;rbeat[arid_i]=0;sentr+=1;
    end
    if(awf) begin wbusy[awid_i]=1;wseq[awid_i]=sentw;sentw+=1;end
    if(wf) begin
      write_beats+=1;
      if(data_beat==int'(len[data_seq])) begin data_seq+=1;data_beat=0;end
      else data_beat+=1;
    end
    if(hold_r&&(!rvalid_o||{rid_o,rdata_o,rresp_o,rlast_o}!==prev_r))
      $fatal(1,"R unstable under backpressure");
    hold_r=rvalid_o&&!rready_i;prev_r={rid_o,rdata_o,rresp_o,rlast_o};
    if(hold_b&&(!bvalid_o||{bid_o,bresp_o}!==prev_b)) $fatal(1,"B unstable");
    hold_b=bvalid_o&&!bready_i;prev_b={bid_o,bresp_o};
    if(rvalid_o&&!rready_i) rstall+=1;
    if(wvalid_i&&!wready_o) wstall+=1;
    if(rvalid_o&&rready_i) begin
      if(rid_o>3||!rbusy[rid_o]) $fatal(1,"R without live owner");
      seq=rseq[rid_o];beat=rbeat[rid_o];ea=beataddr(seq,beat);
      er=bad[seq]?2'b11:(ea[8]?2'b10:2'b00);
      if(rresp_o!==er||rdata_o!==(bad[seq]?64'd0:pattern(ea))||
          rlast_o!==(beat==int'(len[seq])))
        $fatal(1,"read mismatch seq=%0d beat=%0d data=%h expected=%h resp=%b expected=%b last=%b",
          seq,beat,rdata_o,bad[seq]?64'd0:pattern(ea),rresp_o,er,rlast_o);
      read_beats+=1;
      if(last_rid!=-1&&last_rid!=int'(rid_o)) interleave+=1;
      last_rid=int'(rid_o);
      rbeat[rid_o]+=1;
      if(rlast_o) begin read_done+=1;rbusy[rid_o]=0;end
    end
    if(bvalid_o&&bready_i) begin
      if(bid_o>1||!wbusy[bid_o]) $fatal(1,"B without owner");
      seq=wseq[bid_o];er=0;
      if(bad[seq]&&seq%12!=9) er=3;
      else for(k=0;k<=int'(len[seq]);k=k+1) begin
        ea=beataddr(seq,k);if(ea[8]) er=2;
      end
      if(bresp_o!==er) $fatal(1,"B mismatch seq=%0d resp=%b expected=%b",seq,bresp_o,er);
      write_done+=1;wbusy[bid_o]=0;
    end
    for(j=0;j<S;j=j+1) begin
      if(hold_ar[j]&&(!s_arvalid_o[j]||
          {s_araddr_o[j*64+:64],s_arsize_o[j*3+:3],s_arprot_o[j*3+:3]}!==prev_ar[j]))
        $fatal(1,"slave AR unstable");
      hold_ar[j]=s_arvalid_o[j]&&!s_arready_i[j];
      prev_ar[j]={s_araddr_o[j*64+:64],s_arsize_o[j*3+:3],s_arprot_o[j*3+:3]};
      if(hold_aw[j]&&(!s_awvalid_o[j]||
          {s_awaddr_o[j*64+:64],s_awsize_o[j*3+:3]}!==prev_aw[j])) $fatal(1,"slave AW unstable");
      hold_aw[j]=s_awvalid_o[j]&&!s_awready_i[j];
      prev_aw[j]={s_awaddr_o[j*64+:64],s_awsize_o[j*3+:3]};
      if(hold_w[j]&&(!s_wvalid_o[j]||
          {s_wdata_o[j*64+:64],s_wstrb_o[j*8+:8]}!==prev_w[j])) $fatal(1,"slave W unstable");
      hold_w[j]=s_wvalid_o[j]&&!s_wready_i[j];
      prev_w[j]={s_wdata_o[j*64+:64],s_wstrb_o[j*8+:8]};
      if(s_rvalid_i[j]&&s_rready_o[j]) s_rvalid_i[j]<=0;
      if(s_arvalid_o[j]&&s_arready_i[j]) begin
        lite_reads+=1;ea=s_araddr_o[j*64+:64];
        if(j==2&&s_arprot_o[j*3+2]) $fatal(1,"fetch leaked to MMIO");
        if(s_arsize_o[j*3+:3]>3) $fatal(1,"invalid size leaked");
        s_rvalid_i[j]<=1;s_rdata_i[j*64+:64]<=pattern(ea);
        s_rresp_i[j*2+:2]<=ea[8]?2'b10:2'b00;
      end
      if(s_bvalid_i[j]&&s_bready_o[j]) s_bvalid_i[j]<=0;
      if(seen_aw[j]&&seen_w[j]&&!s_bvalid_i[j]) begin
        if(wdata[j]!==pattern(awaddr[j])||wstrb[j]!==mask(awaddr[j],awsize[j]))
          $fatal(1,"write address/data pairing wrong slave=%0d addr=%h data=%h",j,awaddr[j],wdata[j]);
        lite_writes+=1;s_bvalid_i[j]<=1;s_bresp_i[j*2+:2]<=awaddr[j][8]?2'b10:2'b00;
        seen_aw[j]<=0;seen_w[j]<=0;
      end
      if(s_awvalid_o[j]&&s_awready_i[j]) begin
        if(!seen_w[j]) awfirst+=1;
        seen_aw[j]<=1;awaddr[j]<=s_awaddr_o[j*64+:64];awsize[j]<=s_awsize_o[j*3+:3];
      end
      if(s_wvalid_o[j]&&s_wready_i[j]) begin
        if(!seen_aw[j]) wfirst+=1;
        seen_w[j]<=1;wdata[j]<=s_wdata_o[j*64+:64];wstrb[j]<=s_wstrb_o[j*8+:8];
      end
    end
    if((|s_arvalid_o)&&(|s_wvalid_o)) dual_rw+=1;
    live_count=$countones(rbusy)+$countones(wbusy);
    if(live_count>max_live) max_live=live_count;
    if(protocol_error_o) $fatal(1,"fabric protocol error");
    if(read_done==N&&write_done==M) begin
      if(lite_reads!=expect_reads||lite_writes!=expect_writes)
        $fatal(1,"side effect count read=%0d/%0d write=%0d/%0d",lite_reads,expect_reads,lite_writes,expect_writes);
      if(interleave<20||dual_rw==0||awfirst==0||wfirst==0||max_live<5) $fatal(1,"coverage gap");
      $display("[PASS] tb_r64_fabric");
      $display("cycles=%0d read_tx=%0d read_beats=%0d write_tx=%0d write_beats=%0d lite_read=%0d lite_write=%0d RID_changes=%0d overlapping_RW=%0d max_owners=%0d AW_first=%0d W_first=%0d Rstall=%0d Wstall=%0d",
        cycles,read_done,read_beats,write_done,write_beats,lite_reads,lite_writes,interleave,dual_rw,max_live,awfirst,wfirst,rstall,wstall);
      $finish;
    end
    if(cycles>20000) $fatal(1,"timeout read=%0d write=%0d AWsent=%0d Wsent=%0d",read_done,write_done,sentw,data_seq);
  end
endmodule
