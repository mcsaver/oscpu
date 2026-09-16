// One physical read service group. Transaction descriptors stay in Fabric's
// shared four-owner table; only endpoint reservation, launch and return
// selection live here. Each endpoint has at most one active Lite read beat.
module R64AxiReadService #(
  parameter integer SLAVES=16,SLAVE_W=4,
  parameter [SLAVES-1:0] GROUP_MASK={SLAVES{1'b1}},
  parameter integer ACCEPT_BAD=1,READ_CONTINUE=1,EARLY_RETURN=1
)(
  input clk_i,input rst_i,input reset_i,
  input [3:0] live_i,waiting_i,terminal_i,bad_i,fixed_i,
  input [255:0] addr_i,input [31:0] len_i,
  input [11:0] size_i,prot_i,input [4*SLAVE_W-1:0] target_i,
  input admit_i,input consume_i,input continue_credit_i,
  input [SLAVES-1:0] arready_i,rvalid_i,
  input [SLAVES*64-1:0] rdata_i,input [SLAVES*2-1:0] rresp_i,
  output [SLAVES-1:0] arvalid_o,return_mask_o,busy_o,
  output [63:0] araddr_o,output [2:0] arsize_o,arprot_o,
  output arfire_o,output [1:0] arid_o,
  output return_occupied_o,return_valid_o,output [1:0] return_id_o,
  output [63:0] return_data_o,output [1:0] return_resp_o
);
  wire [63:0] ra[0:3];wire [7:0] rn[0:3];
  wire [2:0] rs[0:3],rp[0:3];wire [SLAVE_W-1:0] rt[0:3];
  reg [SLAVES-1:0] busy_q,launch_mask_q,return_mask_q;
  reg [1:0] plan_id_q[0:1];
  reg plan_head_q,plan_tail_q;reg [1:0] plan_count_q;
  reg launch_q;reg [1:0] launch_id_q,launch_rr_q;
  reg [63:0] launch_addr_q;reg [2:0] launch_size_q,launch_prot_q;
  reg return_q;reg [1:0] return_id_q,return_rr_q;
  wire [3:0] member,launch_eligible,return_eligible,contender;
  genvar g;
  generate for(g=0;g<4;g=g+1)begin:gen_owner
    assign ra[g]=addr_i[g*64+:64];assign rn[g]=len_i[g*8+:8];
    assign rs[g]=size_i[g*3+:3];assign rp[g]=prot_i[g*3+:3];assign rt[g]=target_i[g*SLAVE_W+:SLAVE_W];
    assign member[g]=bad_i[g]?(ACCEPT_BAD!=0):GROUP_MASK[rt[g]];
    assign launch_eligible[g]=member[g]&&live_i[g]&&!waiting_i[g]&&
      !terminal_i[g]&&!bad_i[g]&&!busy_q[rt[g]]&&!(launch_q&&launch_id_q==g);
    assign return_eligible[g]=member[g]&&live_i[g]&&!terminal_i[g]&&
      (bad_i[g]||waiting_i[g])&&!(return_q&&return_id_q==g);
    assign contender[g]=live_i[g]&&!terminal_i[g]&&!bad_i[g]&&g!=return_id_q&&rt[g]==rt[return_id_q];
  end endgenerate
  reg next_launch,next_return;reg [1:0] launch_id,return_id,lc,rc;
  reg [3:0] launch_grant;
  integer k;
  always @*begin
    next_launch=0;next_return=0;launch_id=0;return_id=0;lc=0;rc=0;launch_grant=0;
    for(k=0;k<4;k=k+1)begin
      lc=launch_rr_q+k[1:0];rc=return_rr_q+k[1:0];
      if(!next_launch&&launch_eligible[lc])begin next_launch=1;launch_id=lc;launch_grant[lc]=1;end
      if(!next_return&&return_eligible[rc])begin next_return=1;return_id=rc;end
    end
  end
  wire plan_push=next_launch&&plan_count_q<2;
  wire plan_pop=plan_count_q!=0&&(!launch_q||arfire_o);
  wire [1:0] planned=plan_id_q[plan_head_q];
  wire [63:0] next_addr={ra[return_id_q][63:12],ra[return_id_q][11:0]+
    (fixed_i[return_id_q]?12'd0:(12'd1<<rs[return_id_q]))};
  wire continuation=READ_CONTINUE!=0&&consume_i&&!bad_i[return_id_q]&&
    rn[return_id_q]!=0&&continue_credit_i&&plan_count_q==0&&!next_launch&&
    (!launch_q||arfire_o)&&!(|contender)&&!admit_i;
  wire early_return=EARLY_RETURN!=0&&!return_q&&!next_return&&arfire_o;
  assign arvalid_o=launch_mask_q;assign araddr_o=launch_addr_q;
  assign arsize_o=launch_size_q;assign arprot_o=launch_prot_q;
  assign arfire_o=|(launch_mask_q&arready_i);assign arid_o=launch_id_q;
  assign return_mask_o=return_mask_q;assign busy_o=busy_q;
  assign return_occupied_o=return_q;assign return_id_o=return_id_q;
  assign return_valid_o=return_q&&(bad_i[return_id_q]||(|(return_mask_q&rvalid_i)));
  // The constant group mask partitions the physical data fan-in before the
  // final two-group merge. Inactive endpoints do not enter this mux.
  reg [63:0] selected_data;reg [1:0] selected_resp;
  integer endpoint;
  always @*begin
    selected_data=0;selected_resp=0;
    for(endpoint=0;endpoint<SLAVES;endpoint=endpoint+1)begin
      if(GROUP_MASK[endpoint])begin
        selected_data=selected_data|(rdata_i[endpoint*64+:64]&{64{return_mask_q[endpoint]}});
        selected_resp=selected_resp|(rresp_i[endpoint*2+:2]&{2{return_mask_q[endpoint]}});
      end
    end
  end
  assign return_data_o=selected_data;
  assign return_resp_o=bad_i[return_id_q]?2'b11:selected_resp;
  integer n;
  always @(posedge clk_i)begin
    if(reset_i)begin
      busy_q<=0;launch_mask_q<=0;return_mask_q<=0;
      plan_head_q<=0;plan_tail_q<=0;plan_count_q<=0;
      launch_q<=0;launch_id_q<=0;launch_rr_q<=0;
      return_q<=0;return_id_q<=0;return_rr_q<=0;
    end else begin
      if(plan_push)begin
        plan_id_q[plan_tail_q]<=launch_id;plan_tail_q<=~plan_tail_q;
        launch_rr_q<=launch_id+1'b1;
        for(n=0;n<SLAVES;n=n+1)
          if((launch_grant[0]&&rt[0]==n[SLAVE_W-1:0])||(launch_grant[1]&&rt[1]==n[SLAVE_W-1:0])||
             (launch_grant[2]&&rt[2]==n[SLAVE_W-1:0])||(launch_grant[3]&&rt[3]==n[SLAVE_W-1:0]))busy_q[n]<=1;
      end
      if(plan_pop)plan_head_q<=~plan_head_q;
      case({plan_push,plan_pop})
        2'b10:plan_count_q<=plan_count_q+1'b1;
        2'b01:plan_count_q<=plan_count_q-1'b1;
        default:begin end
      endcase
      if(!launch_q||arfire_o)begin
        launch_q<=plan_count_q!=0;launch_mask_q<=0;
        if(plan_pop)begin
          launch_id_q<=planned;launch_addr_q<=ra[planned];
          launch_size_q<=rs[planned];launch_prot_q<=rp[planned];
          launch_mask_q<=({{(SLAVES-1){1'b0}},1'b1}<<rt[planned]);
        end
      end
      if(continuation)begin
        launch_q<=1;launch_id_q<=return_id_q;launch_addr_q<=next_addr;
        launch_size_q<=rs[return_id_q];launch_prot_q<=rp[return_id_q];
        launch_mask_q<=return_mask_q;launch_rr_q<=return_id_q+1'b1;
      end
      if(!return_q||consume_i||(!bad_i[return_id_q]&&!(|(return_mask_q&rvalid_i))))begin
        return_q<=next_return;return_mask_q<=0;
        if(next_return)begin
          return_id_q<=return_id;return_rr_q<=return_id+1'b1;
          if(!bad_i[return_id])return_mask_q<=({{(SLAVES-1){1'b0}},1'b1}<<rt[return_id]);
        end
      end
      if(early_return)begin
        return_q<=1;return_id_q<=launch_id_q;return_mask_q<=launch_mask_q;return_rr_q<=launch_id_q+1'b1;
      end
      if(consume_i&&!bad_i[return_id_q])busy_q[rt[return_id_q]]<=continuation;
    end
    if(rst_i)launch_mask_q<=0;
  end
`ifdef R64_ASSERT
  always @(posedge clk_i)if(!rst_i&&!reset_i)begin
    if(launch_q&&{launch_addr_q,launch_size_q,launch_prot_q}!=={ra[launch_id_q],rs[launch_id_q],rp[launch_id_q]})
      $fatal(1,"fabric AR payload disagrees with selected physical owner");
    if(launch_mask_q!==(launch_q?({{(SLAVES-1){1'b0}},1'b1}<<rt[launch_id_q]):{SLAVES{1'b0}}))
      $fatal(1,"Fabric registered AR route disagrees with owner");
    if(return_mask_q!==((return_q&&!bad_i[return_id_q])?({{(SLAVES-1){1'b0}},1'b1}<<rt[return_id_q]):{SLAVES{1'b0}}))
      $fatal(1,"Fabric registered R route disagrees with owner");
    if(plan_count_q!=0&&(!live_i[planned]||!busy_q[rt[planned]]))
      $fatal(1,"fabric prepared AR lost its live endpoint reservation");
    if(plan_count_q>2)$fatal(1,"fabric read plan queue capacity exceeded");
    if(consume_i&&!return_valid_o)$fatal(1,"fabric group consumed absent return");
    if((|(launch_mask_q&~GROUP_MASK))||(|(return_mask_q&~GROUP_MASK)))
      $fatal(1,"fabric group crossed endpoint partition");
  end
`endif
endmodule
