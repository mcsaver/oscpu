// Four independently owned AXI4 read streams. ID is the client index and is
// reserved from command acceptance through delivery of that transaction's last
// beat. Clients keep their architectural transaction tags in their own holders.
// AR and R each cross a register boundary; no AXI input drives an AXI output.
module R64AxiRead #(
  parameter integer CLIENTS = 4,
  parameter integer CLIENT_W = 2,
  parameter integer ID_W = 4
) (
  input clk_i, input rst_i,
  input [CLIENTS-1:0] cmd_valid_i,
  output reg [CLIENTS-1:0] cmd_ready_o,
  input [CLIENTS*64-1:0] cmd_addr_i,
  input [CLIENTS*8-1:0] cmd_len_i,
  input [CLIENTS*3-1:0] cmd_size_i,
  input [CLIENTS*3-1:0] cmd_prot_i,
  output [CLIENTS-1:0] rsp_valid_o,
  input [CLIENTS-1:0] rsp_ready_i,
  output [CLIENTS*64-1:0] rsp_data_o,
  output [CLIENTS*2-1:0] rsp_resp_o,
  output [CLIENTS-1:0] rsp_last_o,
  output arvalid_o, input arready_i,
  output [ID_W-1:0] arid_o,
  output [63:0] araddr_o,
  output [7:0] arlen_o,
  output [2:0] arsize_o, output [2:0] arprot_o,
  output [1:0] arburst_o,
  input rvalid_i, output rready_o,
  input [ID_W-1:0] rid_i,
  input [63:0] rdata_i,
  input [1:0] rresp_i,
  input rlast_i,
  output reg protocol_error_o
);
  reg [CLIENTS-1:0] busy_q, sent_q;
  reg [8:0] beats_q [0:CLIENTS-1];
  reg [CLIENT_W-1:0] rr_q;
  reg arvalid_q;
  reg [CLIENT_W-1:0] arclient_q;
  reg [63:0] araddr_q;
  reg [7:0] arlen_q;
  reg [2:0] arsize_q,arprot_q;

  reg [63:0] data_q [0:1];
  reg [1:0] resp_q [0:1];
  reg [1:0] last_q;
  reg [CLIENT_W-1:0] client_q [0:1];
  reg head_q,tail_q;
  reg [1:0] count_q;

  assign arvalid_o=arvalid_q&&!rst_i;
  assign arid_o={{(ID_W-CLIENT_W){1'b0}},arclient_q};
  assign araddr_o=araddr_q;
  assign arlen_o=arlen_q;
  assign arsize_o=arsize_q;
  assign arprot_o=arprot_q;
  assign arburst_o=2'b01;
  assign rready_o=count_q<2&&!rst_i;
  wire ar_fire_w=arvalid_o&&arready_i;
  wire r_fire_w=rvalid_i&&rready_o;
  wire response_pop_w=count_q!=0&&rsp_ready_i[client_q[head_q]];
  wire response_done_w=response_pop_w&&last_q[head_q];
  wire id_range_w=!(|(rid_i >> CLIENT_W));
  wire [CLIENT_W-1:0] rid_w=rid_i[CLIENT_W-1:0];
  wire live_response_w=id_range_w&&busy_q[rid_w]&&
      (sent_q[rid_w]||(ar_fire_w&&arclient_q==rid_w))&&beats_q[rid_w]!=0;
  wire push_w=r_fire_w&&live_response_w;

  integer k;
  reg [CLIENT_W-1:0] which_r;
  reg found_r;
  reg [CLIENT_W-1:0] grant_r;
  always @(*) begin
    cmd_ready_o=0;found_r=0;grant_r=0;which_r=0;
    for(k=0;k<CLIENTS;k=k+1) begin
      which_r=rr_q+k[CLIENT_W-1:0];
      if(!found_r&&cmd_valid_i[which_r]&&!busy_q[which_r]) begin
        grant_r=which_r;
        found_r=1;
      end
    end
    if(!rst_i&&(!arvalid_q||ar_fire_w)&&found_r) cmd_ready_o[grant_r]=1'b1;
  end
  wire cmd_fire_w=|(cmd_valid_i&cmd_ready_o);
  genvar c;
  generate for(c=0;c<CLIENTS;c=c+1) begin : gen_response
    assign rsp_valid_o[c]=count_q!=0&&client_q[head_q]==c&&!rst_i;
    assign rsp_data_o[c*64+:64]=data_q[head_q];
    assign rsp_resp_o[c*2+:2]=resp_q[head_q];
    assign rsp_last_o[c]=last_q[head_q];
  end endgenerate

  always @(posedge clk_i) begin
    if(rst_i) begin
      busy_q<=0;sent_q<=0;rr_q<=0;arvalid_q<=0;
      arclient_q<=0;araddr_q<=0;arlen_q<=0;arsize_q<=0;arprot_q<=0;
      head_q<=0;tail_q<=0;count_q<=0;protocol_error_o<=0;
    end else begin
      if(ar_fire_w) begin arvalid_q<=0;sent_q[arclient_q]<=1;end
      if(cmd_fire_w) begin
        arvalid_q<=1;
        arclient_q<=grant_r;
        araddr_q<=cmd_addr_i[grant_r*64+:64];
        arlen_q<=cmd_len_i[grant_r*8+:8];
        arsize_q<=cmd_size_i[grant_r*3+:3];
        arprot_q<=cmd_prot_i[grant_r*3+:3];
        busy_q[grant_r]<=1;
        sent_q[grant_r]<=0;
        beats_q[grant_r]<={1'b0,cmd_len_i[grant_r*8+:8]}+9'd1;
        rr_q<=grant_r+1'b1;
      end
      if(r_fire_w) begin
        if(!live_response_w) protocol_error_o<=1;
        else begin
          beats_q[rid_w]<=beats_q[rid_w]-1'b1;
          if(rlast_i!=(beats_q[rid_w]==1)) protocol_error_o<=1;
        end
      end
      if(push_w) begin
        data_q[tail_q]<=rdata_i;resp_q[tail_q]<=rresp_i;
        last_q[tail_q]<=rlast_i;client_q[tail_q]<=rid_w;
        tail_q<=!tail_q;
      end
      if(response_pop_w) head_q<=!head_q;
      if(response_done_w) begin
        busy_q[client_q[head_q]]<=0;
        sent_q[client_q[head_q]]<=0;
      end
      case({push_w,response_pop_w})
        2'b10: count_q<=count_q+1'b1;
        2'b01: count_q<=count_q-1'b1;
        default: begin end
      endcase
    end
  end
`ifdef R64_ASSERT
  initial if(CLIENTS!=(1<<CLIENT_W)||ID_W<CLIENT_W)
    $fatal(1,"R64AxiRead parameter mismatch");
  always @(posedge clk_i) if(!rst_i&&protocol_error_o)
    $fatal(1,"AXI read response has no owner or incorrect RLAST");
`endif
endmodule
