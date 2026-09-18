// AXI4 write transport. AW descriptors and the W ordering queue are independent.
// Two clients can each own one transaction. W follows command admission order;
// neither AW backpressure nor delayed B for one ID withdraws another channel.
// The single W output register sustains one beat/cycle without buffering lines.
module R64AxiWrite #(
  parameter integer CLIENTS=2,
  parameter integer CLIENT_W=1,
  parameter integer ID_W=4,
  parameter integer B_BYPASS=0
) (
  input clk_i,input rst_i,
  input [CLIENTS-1:0] cmd_valid_i,
  output reg [CLIENTS-1:0] cmd_ready_o,
  input [CLIENTS*64-1:0] cmd_addr_i,
  input [CLIENTS*8-1:0] cmd_len_i,
  input [CLIENTS*3-1:0] cmd_size_i,
  input [CLIENTS*3-1:0] cmd_prot_i,
  input [CLIENTS-1:0] data_valid_i,
  output [CLIENTS-1:0] data_ready_o,
  input [CLIENTS*64-1:0] data_i,
  input [CLIENTS*8-1:0] strb_i,
  output [CLIENTS-1:0] rsp_valid_o,
  input [CLIENTS-1:0] rsp_ready_i,
  output [CLIENTS*2-1:0] rsp_resp_o,
  output awvalid_o,input awready_i,
  output [ID_W-1:0] awid_o,
  output [63:0] awaddr_o,
  output [7:0] awlen_o,
  output [2:0] awsize_o,output [2:0] awprot_o,
  output [1:0] awburst_o,
  output wvalid_o,input wready_i,
  output [63:0] wdata_o,
  output [7:0] wstrb_o,
  output wlast_o,
  input bvalid_i,output bready_o,
  input [ID_W-1:0] bid_i,
  input [1:0] bresp_i,
  output reg protocol_error_o
);
  reg [CLIENTS-1:0] busy_q,aw_sent_q,w_sent_q,b_seen_q;
  reg [CLIENT_W-1:0] rr_q;
  reg [63:0] awaddr_q [0:1];
  reg [7:0] awlen_q [0:1];
  reg [2:0] awsize_q [0:1],awprot_q [0:1];
  reg [CLIENT_W-1:0] awclient_q [0:1],wclient_q [0:1];
  reg [8:0] remaining_q [0:1];
  reg awhead_q,awtail_q,whead_q,wtail_q;
  reg [1:0] awcount_q,wcount_q;
  reg wvalid_q,wlast_q;
  reg [63:0] wdata_q;
  reg [7:0] wstrb_q;
  reg [CLIENT_W-1:0] wstage_client_q;
  reg [CLIENT_W-1:0] bclient_q [0:1];
  reg [1:0] bresp_q [0:1];
  reg bhead_q,btail_q;
  reg [1:0] bcount_q;

  assign awvalid_o=awcount_q!=0&&!rst_i;
  assign awid_o={{(ID_W-CLIENT_W){1'b0}},awclient_q[awhead_q]};
  assign awaddr_o=awaddr_q[awhead_q];
  assign awlen_o=awlen_q[awhead_q];
  assign awsize_o=awsize_q[awhead_q];
  assign awprot_o=awprot_q[awhead_q];
  assign awburst_o=2'b01;
  assign wvalid_o=wvalid_q&&!rst_i;
  assign wdata_o=wdata_q;assign wstrb_o=wstrb_q;assign wlast_o=wlast_q;
  assign bready_o=bcount_q<2&&!rst_i;
  wire aw_fire_w=awvalid_o&&awready_i;
  wire w_fire_w=wvalid_o&&wready_i;
  wire b_fire_w=bvalid_i&&bready_o;
  wire data_take_w=wcount_q!=0&&(!wvalid_q||w_fire_w)&&
                   data_valid_i[wclient_q[whead_q]]&&!rst_i;
  wire wowner_pop_w=data_take_w&&remaining_q[whead_q]==1;
  wire bpop_w=bcount_q!=0&&rsp_ready_i[bclient_q[bhead_q]];
  wire [CLIENT_W-1:0] bid_w=bid_i[CLIENT_W-1:0];
  wire bid_valid_w=!(|(bid_i>>CLIENT_W))&&busy_q[bid_w]&&!b_seen_q[bid_w]&&
      (aw_sent_q[bid_w]||(aw_fire_w&&awclient_q[awhead_q]==bid_w))&&
      (w_sent_q[bid_w]||(w_fire_w&&wlast_q&&wstage_client_q==bid_w));
  // Empty-queue fall-through is only on the internal response side. Physical
  // BREADY still depends exclusively on registered FIFO capacity.
  wire bdirect_w=B_BYPASS!=0&&bcount_q==0&&b_fire_w&&bid_valid_w;
  wire bdirect_pop_w=bdirect_w&&rsp_ready_i[bid_w];
  wire bpush_w=b_fire_w&&bid_valid_w&&!bdirect_pop_w;

  integer k;
  reg [CLIENT_W-1:0] which_r,grant_r;
  reg found_r;
  always @(*) begin
    cmd_ready_o=0;which_r=0;grant_r=0;found_r=0;
    for(k=0;k<CLIENTS;k=k+1) begin
      which_r=rr_q+k[CLIENT_W-1:0];
      if(!found_r&&cmd_valid_i[which_r]&&!busy_q[which_r]) begin
        found_r=1;grant_r=which_r;
      end
    end
    if(!rst_i&&found_r&&awcount_q<2&&wcount_q<2)
      cmd_ready_o[grant_r]=1'b1;
  end
  wire cmd_fire_w=|(cmd_valid_i&cmd_ready_o);
  genvar c;
  generate for(c=0;c<CLIENTS;c=c+1) begin : gen_client
    assign data_ready_o[c]=wcount_q!=0&&wclient_q[whead_q]==c&&
                           (!wvalid_q||w_fire_w)&&!rst_i;
    assign rsp_valid_o[c]=((bcount_q!=0&&bclient_q[bhead_q]==c)||
      (bdirect_w&&bid_w==c))&&!rst_i;
    assign rsp_resp_o[c*2+:2]=bcount_q!=0?bresp_q[bhead_q]:bresp_i;
  end endgenerate

  always @(posedge clk_i) begin
    if(rst_i) begin
      busy_q<=0;aw_sent_q<=0;w_sent_q<=0;b_seen_q<=0;rr_q<=0;
      awhead_q<=0;awtail_q<=0;awcount_q<=0;
      whead_q<=0;wtail_q<=0;wcount_q<=0;
      bhead_q<=0;btail_q<=0;bcount_q<=0;
      wvalid_q<=0;wdata_q<=0;wstrb_q<=0;wlast_q<=0;wstage_client_q<=0;
      protocol_error_o<=0;
    end else begin
      if(cmd_fire_w) begin
        busy_q[grant_r]<=1;aw_sent_q[grant_r]<=0;
        w_sent_q[grant_r]<=0;b_seen_q[grant_r]<=0;
        rr_q<=grant_r+1'b1;
        awaddr_q[awtail_q]<=cmd_addr_i[grant_r*64+:64];
        awlen_q[awtail_q]<=cmd_len_i[grant_r*8+:8];
        awsize_q[awtail_q]<=cmd_size_i[grant_r*3+:3];
        awprot_q[awtail_q]<=cmd_prot_i[grant_r*3+:3];
        awclient_q[awtail_q]<=grant_r;awtail_q<=!awtail_q;
        wclient_q[wtail_q]<=grant_r;
        remaining_q[wtail_q]<={1'b0,cmd_len_i[grant_r*8+:8]}+9'd1;
        wtail_q<=!wtail_q;
      end
      if(aw_fire_w) begin
        awhead_q<=!awhead_q;aw_sent_q[awclient_q[awhead_q]]<=1;
      end
      if(w_fire_w) begin
        wvalid_q<=0;
        if(wlast_q) w_sent_q[wstage_client_q]<=1;
      end
      if(data_take_w) begin
        wvalid_q<=1;wstage_client_q<=wclient_q[whead_q];
        wdata_q<=data_i[wclient_q[whead_q]*64+:64];
        wstrb_q<=strb_i[wclient_q[whead_q]*8+:8];
        wlast_q<=remaining_q[whead_q]==1;
        remaining_q[whead_q]<=remaining_q[whead_q]-1'b1;
      end
      if(wowner_pop_w) whead_q<=!whead_q;
      if(b_fire_w&&!bid_valid_w) protocol_error_o<=1;
      if(bpush_w) begin
        bclient_q[btail_q]<=bid_w;bresp_q[btail_q]<=bresp_i;
        btail_q<=!btail_q;b_seen_q[bid_w]<=1;
      end
      if(bdirect_pop_w)begin busy_q[bid_w]<=0;b_seen_q[bid_w]<=1;end
      if(bpop_w) begin
        bhead_q<=!bhead_q;busy_q[bclient_q[bhead_q]]<=0;
      end
      case({cmd_fire_w,aw_fire_w})
        2'b10: awcount_q<=awcount_q+1'b1;
        2'b01: awcount_q<=awcount_q-1'b1;
        default: begin end
      endcase
      case({cmd_fire_w,wowner_pop_w})
        2'b10: wcount_q<=wcount_q+1'b1;
        2'b01: wcount_q<=wcount_q-1'b1;
        default: begin end
      endcase
      case({bpush_w,bpop_w})
        2'b10: bcount_q<=bcount_q+1'b1;
        2'b01: bcount_q<=bcount_q-1'b1;
        default: begin end
      endcase
    end
  end
`ifdef R64_ASSERT
  initial if(CLIENTS!=(1<<CLIENT_W)||ID_W<CLIENT_W)
    $fatal(1,"R64AxiWrite parameter mismatch");
  always @(posedge clk_i) if(!rst_i&&protocol_error_o)
    $fatal(1,"AXI B response has no completed AW/W owner");
`endif
endmodule
