// Fixed payload slots, age from the single ROB ring; no moving uop array.
// issue_fire_o is an admission pulse into RegRead, not a held VALID.
// Memory age and capacity belong to the LSQ from dispatch birth. Issue only
// selects ready operand owners; accepted WB events are the normal wakeups.
module R64Issue #(
  parameter PREPARED_CANCEL=0, parameter SLOT_W=4, parameter N=(1<<SLOT_W),
  parameter ROB_W=5, parameter TAG_W=9, parameter PREG_W=6,
  parameter DEFER_READY=0, parameter MDU_RESOURCE_PAIR=0, parameter PAYLOAD_W=128, parameter MEM_WIDTH=2, parameter LSQ_W=5
) (
  input clk, input rst, input flush_i,
  input [(1<<ROB_W)-1:0] kill_mask_i,
  input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
  input [ROB_W-1:0] rob_head_i,
  input barrier_valid_i, input [ROB_W-1:0] barrier_slot_i,
  input [(1<<ROB_W)-1:0] serial_active_i,serial_release_i,
  input [1:0] enq_valid_i, output [1:0] enq_ready_o,
  input [2*TAG_W-1:0] enq_tag_i,
  input [2*LSQ_W-1:0] enq_mem_slot_i,
  input [2*PAYLOAD_W-1:0] enq_payload_i,
  input [5:0] enq_class_i,
  input [2*PREG_W-1:0] enq_gpr_dst_i,
  input [6*PREG_W-1:0] enq_src_preg_i,
  input [5:0] enq_src_fp_i, input [5:0] enq_src_used_i,
  input [5:0] enq_src_ready_i,
  output [6*PREG_W-1:0] ready_query_preg_o,output [5:0] ready_query_fp_o,
  input [5:0] ready_query_ready_i,
  input [1:0] wake_valid_i, input [1:0] wake_fp_i,
  input [2*PREG_W-1:0] wake_preg_i,
  input [1:0] early_valid_i,input [2*PREG_W-1:0] early_preg_i,
  input [5:0] fu_allow_i, input serial_allow_i,
  input [1:0] issue_ready_i,
  output [1:0] issue_fire_o,
  output [2*TAG_W-1:0] issue_tag_o,
  output [2*LSQ_W-1:0] issue_mem_slot_o,
  output [2*PAYLOAD_W-1:0] issue_payload_o,
  output [5:0] issue_class_o,
  output [2*PREG_W-1:0] issue_gpr_dst_o,
  output [6*PREG_W-1:0] issue_src_preg_o,
  output [5:0] issue_src_fp_o, output [5:0] issue_src_used_o,
  output [2*(3*PREG_W+8)-1:0] issue_fp_plan_o,
  output [SLOT_W:0] count_o
);
  // Select this registered owner's candidate bit before applying the late
  // redirect enable. The ordinary mask remains the default module contract.
  function cancel_selected;
    input [ROB_W-1:0] slot;
    input [(1<<ROB_W)-1:0] candidates,mask;
    input active;
    begin cancel_selected=PREPARED_CANCEL ?
        (active&&candidates[slot]):mask[slot];end
  endfunction

  localparam C_ALU=0,C_BRANCH=1,C_MDU=2,C_FP=3,C_MEM=4,C_SERIAL=5;
  reg [N-1:0] valid_q;
  // Admission order is immutable until slot reuse. Selecting by this relation
  // avoids a ROB-head subtract and cascaded age-comparator trees on every issue.
  reg [N-1:0] older_q[0:N-1];
  wire [N*N-1:0] older_flat_w;
  wire [N-1:0] select0_mask_w,select1_mask_w;

  reg [TAG_W-1:0] tag_q[0:N-1];
  reg [LSQ_W-1:0] mem_slot_q[0:N-1];
  reg [PAYLOAD_W-1:0] payload_q[0:N-1];
  reg [2:0] class_q[0:N-1],resource_q[0:N-1];
  wire [5:0] enq_resource_w;
  function [2:0] resource_class;
    input [2:0] cls;input [1:0] subunit;
    begin
      resource_class=MDU_RESOURCE_PAIR&&cls==C_MDU ?
          (subunit[1]?3'd7:subunit[0]?3'd6:3'd2):cls;
    end
  endfunction
  genvar resource_lane;
  generate for(resource_lane=0;resource_lane<2;resource_lane=resource_lane+1)begin:g_resource
    if(PAYLOAD_W>=200)begin:g_native
      assign enq_resource_w[resource_lane*3+:3]=resource_class(
          enq_class_i[resource_lane*3+:3],enq_payload_i[resource_lane*PAYLOAD_W+198+:2]);
    end else begin:g_generic
      assign enq_resource_w[resource_lane*3+:3]=enq_class_i[resource_lane*3+:3];
    end
  end endgenerate
  reg [PREG_W-1:0] gpr_dst_q[0:N-1];
  reg [3*PREG_W-1:0] src_q[0:N-1];
  reg [2:0] fp_q[0:N-1], used_q[0:N-1], ready_q[0:N-1];
  wire [N-1:0] live_w, free_w, pick0_w, pick1_w;
  wire [ROB_W-1:0] barrier_age_w=barrier_slot_i-rob_head_i;
  wire [ROB_W-1:0] age_w[0:N-1];
  wire [2:0] fp_count_w[0:N-1], gp_count_w[0:N-1];
  // Resource footprints are immutable during an owner's lifetime. Store
  // pair compatibility at birth instead of selecting a wide footprint and
  // performing another budget adder after the first age selection.
  reg [N-1:0] compatible_q[0:N-1];
  // A birth records older serial owners only. Explicit release clears old
  // ownership before reuse; later serial births never enter resident masks.
  reg [(1<<ROB_W)-1:0] serial_dependency_q[0:N-1];
  wire [N-1:0] common_w,eligible0_w,fallback1_w;
  function compatible;
    input [2:0] ca,cb,fa,fb,ua,ub;
    reg [2:0] na,nb;
    begin
      na={2'b0,(fa[0]&ua[0])}+{2'b0,(fa[1]&ua[1])}+{2'b0,(fa[2]&ua[2])};
      nb={2'b0,(fb[0]&ub[0])}+{2'b0,(fb[1]&ub[1])}+{2'b0,(fb[2]&ub[2])};
      compatible=(ca!=cb||ca==C_ALU||ca==C_MEM)&&na+nb<=3;
    end
  endfunction
  wire sel0_valid_w, sel1_valid_w;
  wire [SLOT_W-1:0] sel0_slot_w,sel1_slot_w;
  assign free_w=~valid_q;
  wire free_any_w,free_two_w;
  R64FreeSelect #(.N(N)) free_select(.free_i(free_w),.first_o(pick0_w),.second_o(pick1_w),
      .any_o(free_any_w),.two_o(free_two_w));
  wire credit0_w=!rst&&!flush_i&&free_any_w;
  wire credit1_w=credit0_w&&free_two_w;
  assign enq_ready_o={credit1_w,credit0_w};
  wire [1:0] enq_fire_w=enq_valid_i&enq_ready_o;
  // Birth owns the fixed IQ row and canonical preg before this stage.
  wire [N-1:0] init0_w,init1_w;
  generate if(DEFER_READY!=0)begin:g_ready_stage
    reg [6*PREG_W-1:0] preg_q;
    reg [5:0] fp_q;
    reg [N-1:0] init0_q,init1_q;
    assign ready_query_preg_o=preg_q;assign ready_query_fp_o=fp_q;
    assign init0_w=init0_q;assign init1_w=init1_q;
    always @(posedge clk)begin
      // Unowned query data is not a transaction.
      preg_q<=enq_src_preg_i;fp_q<=enq_src_fp_i;
      if(rst||flush_i)begin init0_q<=0;init1_q<=0;end
      else begin
        init0_q<=pick0_w&{N{enq_fire_w[0]}};
        init1_q<=pick1_w&{N{enq_fire_w[1]}};
      end
    end
  end else begin:g_direct_ready
    assign ready_query_preg_o=0;assign ready_query_fp_o=0;
    assign init0_w=0;assign init1_w=0;
  end endgenerate
  genvar s;
  generate for(s=0;s<N;s=s+1) begin:gen_eligibility
    assign live_w[s]=valid_q[s]&&!cancel_selected(tag_q[s][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i)&&!flush_i&&!rst;
    assign age_w[s]=tag_q[s][ROB_W-1:0]-rob_head_i;
    assign fp_count_w[s]={2'b0,(used_q[s][0]&fp_q[s][0])}+
        {2'b0,(used_q[s][1]&fp_q[s][1])}+{2'b0,(used_q[s][2]&fp_q[s][2])};
    assign gp_count_w[s]={2'b0,(used_q[s][0]&~fp_q[s][0])}+
        {2'b0,(used_q[s][1]&~fp_q[s][1])}+{2'b0,(used_q[s][2]&~fp_q[s][2])};
    wire operands_w=&(ready_q[s]|~used_q[s]);
    // Selection uses resident Q-state. Cancellation is checked once on the
    // final admission mask, instead of traversing both selector rounds.
    assign common_w[s]=valid_q[s]&&!init0_w[s]&&!init1_w[s]&&operands_w&&fu_allow_i[class_q[s]]&&
        !(|(serial_dependency_q[s]&serial_active_i))&&
        (class_q[s]!=C_SERIAL||(serial_allow_i&&tag_q[s][ROB_W-1:0]==rob_head_i));
    // The LSQ owner and memory age were established at actual birth.
    // Operand-ready MEM may bind out of order; LSQ enforces unknown-store,
    // IO and atomic ordering using all reserved owners.
    assign eligible0_w[s]=issue_ready_i[0]&&common_w[s];
    assign fallback1_w[s]=issue_ready_i[1]&&common_w[s];
  end endgenerate
  wire unused_select0_second;
  wire [SLOT_W-1:0] unused_select0_slot;
  wire [N-1:0] unused_select0_mask;
  generate for(s=0;s<N;s=s+1) begin:gen_order_flat
    assign older_flat_w[s*N+:N]=older_q[s];
  end endgenerate
  R64LsuOrderSelect #(.N(N),.SLOT_W(SLOT_W)) select0(
    .valid_i(eligible0_w),.older_i(older_flat_w),
    .first_valid_o(sel0_valid_w),.first_slot_o(sel0_slot_w),.first_mask_o(select0_mask_w),
    .second_valid_o(unused_select0_second),.second_slot_o(unused_select0_slot),.second_mask_o(unused_select0_mask));
  wire [N-1:0] fallback_mask_w;
  wire fallback_valid_w;
  R64LsuOrderSelect #(.N(N),.SLOT_W(SLOT_W)) fallback_select(
    .valid_i(fallback1_w),.older_i(older_flat_w),
    .first_valid_o(fallback_valid_w),.first_slot_o(),
    .first_mask_o(fallback_mask_w),.second_valid_o(),.second_slot_o(),.second_mask_o());
  wire [N*N-1:0] pair_second_w;
  genvar first,second;
  generate for(first=0;first<N;first=first+1)begin:gen_pair_select
    wire [N-1:0] candidate_w,chosen_w;
    for(second=0;second<N;second=second+1)begin:gen_candidate
      assign candidate_w[second]=issue_ready_i[1]&&common_w[second]&&
          first!=second&&compatible_q[first][second]&&
          (MEM_WIDTH>1||class_q[first]!=C_MEM||class_q[second]!=C_MEM);
    end
    R64LsuOrderSelect #(.N(N),.SLOT_W(SLOT_W)) second_select(
      .valid_i(candidate_w),.older_i(older_flat_w),
      .first_valid_o(),.first_slot_o(),.first_mask_o(chosen_w),
      .second_valid_o(),.second_slot_o(),.second_mask_o());
    assign pair_second_w[first*N+:N]=chosen_w&{N{select0_mask_w[first]}};
  end endgenerate
  reg [N-1:0] select1_r;reg [SLOT_W-1:0] select1_slot_r;
  integer merge;
  always_comb begin
    select1_r=fallback_mask_w&{N{!sel0_valid_w}};
    for(merge=0;merge<N;merge=merge+1)
      select1_r=select1_r|pair_second_w[merge*N+:N];
    select1_slot_r=0;
    for(merge=0;merge<N;merge=merge+1)
      select1_slot_r=select1_slot_r|(merge[SLOT_W-1:0]&{SLOT_W{select1_r[merge]}});
  end
  assign select1_mask_w=select1_r;
  assign sel1_valid_w=|select1_r;
  assign sel1_slot_w=select1_slot_r;
  wire [1:0] actual_fire_w={
    sel1_valid_w&&!rst&&!flush_i&&!(|(select1_mask_w&~live_w)),
    sel0_valid_w&&!rst&&!flush_i&&!(|(select0_mask_w&~live_w))};
  assign issue_fire_o=actual_fire_w;
  // The selectors already produce one-hot grants. Do not encode, decode,
  // then select each wide payload again; use a balanced masked-OR tree.
  localparam FP_PLAN_W=3*PREG_W+8;
  wire [FP_PLAN_W-1:0] row_fp_plan_w[0:N-1];
  genvar fp_row;
  generate for(fp_row=0;fp_row<N;fp_row=fp_row+1)begin:g_fp_row
    R64FpReadCompact #(.PREG_W(PREG_W)) compact(
      .preg_i(src_q[fp_row]),.used_i(used_q[fp_row]),.fp_i(fp_q[fp_row]),
      .plan_o(row_fp_plan_w[fp_row]));
  end endgenerate
  localparam PACK_W=TAG_W+PAYLOAD_W+3+4*PREG_W+6+LSQ_W+FP_PLAN_W;
  genvar l,t;
  generate for(l=0;l<2;l=l+1) begin:gen_output
    wire [N-1:0] grant_w=l==0?select0_mask_w:select1_mask_w;
    for(t=1;t<2*N;t=t+1)begin:tree
      wire [PACK_W-1:0] data_w;
      if(t>=N)begin:leaf
        assign data_w={PACK_W{grant_w[t-N]}}&
          {row_fp_plan_w[t-N],mem_slot_q[t-N],tag_q[t-N],payload_q[t-N],class_q[t-N],gpr_dst_q[t-N],
           src_q[t-N],fp_q[t-N],used_q[t-N]};
      end else begin:merge
        assign data_w=tree[2*t].data_w|tree[2*t+1].data_w;
      end
    end
    assign {issue_fp_plan_o[l*FP_PLAN_W+:FP_PLAN_W],issue_mem_slot_o[l*LSQ_W+:LSQ_W],issue_tag_o[l*TAG_W+:TAG_W],issue_payload_o[l*PAYLOAD_W+:PAYLOAD_W],
      issue_class_o[l*3+:3],issue_gpr_dst_o[l*PREG_W+:PREG_W],
      issue_src_preg_o[l*3*PREG_W+:3*PREG_W],issue_src_fp_o[l*3+:3],
      issue_src_used_o[l*3+:3]}=tree[1].data_w;
  end endgenerate
  // A static row owns each age vector. Births clear reused columns; a new
  // row takes the current live set, with lane zero older than lane one.
  wire [N-1:0] born_rows_w=({N{enq_fire_w[0]}}&pick0_w)|
      ({N{enq_fire_w[1]}}&pick1_w);
  genvar age_row;
  generate for(age_row=0;age_row<N;age_row=age_row+1)begin:g_age_row
    always @(posedge clk)begin
      if(rst||flush_i)older_q[age_row]<=0;
      else if(enq_fire_w[1]&&pick1_w[age_row])
        older_q[age_row]<=live_w|({N{enq_fire_w[0]}}&pick0_w);
      else if(enq_fire_w[0]&&pick0_w[age_row])older_q[age_row]<=live_w;
      else older_q[age_row]<=older_q[age_row]&~born_rows_w;
    end
  end endgenerate
  genvar cr,cc;
  generate for(cr=0;cr<N;cr=cr+1)begin:gen_compat_row
    for(cc=0;cc<N;cc=cc+1)begin:gen_compat_col
    always @(posedge clk)begin
    if(rst||flush_i)compatible_q[cr][cc]<=0;
    else begin
      if(enq_fire_w[0]&&pick0_w[cr])
        compatible_q[cr][cc]<=compatible(enq_resource_w[0+:3],resource_q[cc],enq_src_fp_i[0+:3],fp_q[cc],enq_src_used_i[0+:3],used_q[cc]);
      if(enq_fire_w[0]&&pick0_w[cc])
        compatible_q[cr][cc]<=compatible(resource_q[cr],enq_resource_w[0+:3],fp_q[cr],enq_src_fp_i[0+:3],used_q[cr],enq_src_used_i[0+:3]);
      if(enq_fire_w[1]&&pick1_w[cr])
        compatible_q[cr][cc]<=compatible(enq_resource_w[3+:3],resource_q[cc],enq_src_fp_i[3+:3],fp_q[cc],enq_src_used_i[3+:3],used_q[cc]);
      if(enq_fire_w[1]&&pick1_w[cc])
        compatible_q[cr][cc]<=compatible(resource_q[cr],enq_resource_w[3+:3],fp_q[cr],enq_src_fp_i[3+:3],used_q[cr],enq_src_used_i[3+:3]);
      if(enq_fire_w==2'b11&&((pick0_w[cr]&&pick1_w[cc])||(pick1_w[cr]&&pick0_w[cc])))
        compatible_q[cr][cc]<=compatible(enq_resource_w[0+:3],enq_resource_w[3+:3],enq_src_fp_i[0+:3],enq_src_fp_i[3+:3],enq_src_used_i[0+:3],enq_src_used_i[3+:3]);
      if(cr==cc)compatible_q[cr][cc]<=0;
    end
    end
  end end endgenerate
  integer ci,total;
  always @(*) begin
    total=0;
    for(ci=0;ci<N;ci=ci+1) total=total+{{31{1'b0}},valid_q[ci]};
  end
  assign count_o=total[SLOT_W:0];
  generate for(s=0;s<N;s=s+1) begin:gen_slot_state
    // Current free physical rows may prepare metadata and payload before
    // global ROB/Rename/LSQ birth permission. Only valid_q grants ownership.
    always @(posedge clk)begin
      if(pick0_w[s])begin
            tag_q[s]<=enq_tag_i[0*TAG_W+:TAG_W];
            mem_slot_q[s]<=enq_mem_slot_i[0*LSQ_W+:LSQ_W];
            payload_q[s]<=enq_payload_i[0*PAYLOAD_W+:PAYLOAD_W];
            class_q[s]<=enq_class_i[0*3+:3];
            resource_q[s]<=enq_resource_w[0*3+:3];
            gpr_dst_q[s]<=enq_gpr_dst_i[0*PREG_W+:PREG_W];
            src_q[s]<=enq_src_preg_i[0*3*PREG_W+:3*PREG_W];
            fp_q[s]<=enq_src_fp_i[0*3+:3];
            used_q[s]<=enq_src_used_i[0*3+:3];
      end else if(pick1_w[s])begin
            tag_q[s]<=enq_tag_i[1*TAG_W+:TAG_W];
            mem_slot_q[s]<=enq_mem_slot_i[1*LSQ_W+:LSQ_W];
            payload_q[s]<=enq_payload_i[1*PAYLOAD_W+:PAYLOAD_W];
            class_q[s]<=enq_class_i[1*3+:3];
            resource_q[s]<=enq_resource_w[1*3+:3];
            gpr_dst_q[s]<=enq_gpr_dst_i[1*PREG_W+:PREG_W];
            src_q[s]<=enq_src_preg_i[1*3*PREG_W+:3*PREG_W];
            fp_q[s]<=enq_src_fp_i[1*3+:3];
            used_q[s]<=enq_src_used_i[1*3+:3];
      end
    end
    integer j,w,lane;
    reg [2:0] new_ready;
    always @(posedge clk) begin
      if(rst||flush_i)begin valid_q[s]<=0;serial_dependency_q[s]<=0;end
      else begin
        serial_dependency_q[s]<=serial_dependency_q[s]&~serial_release_i;
        if(valid_q[s]) begin
          if(!live_w[s]||select0_mask_w[s]||select1_mask_w[s]) valid_q[s]<=0;
          if(DEFER_READY!=0)begin
            if(init0_w[s])ready_q[s]<=ready_query_ready_i[0+:3]|~used_q[s];
            if(init1_w[s])ready_q[s]<=ready_query_ready_i[3+:3]|~used_q[s];
          end
          for(j=0;j<3;j=j+1)
            for(w=0;w<2;w=w+1)
              if(wake_valid_i[w]&&fp_q[s][j]==wake_fp_i[w]&&
                  src_q[s][j*PREG_W+:PREG_W]==wake_preg_i[w*PREG_W+:PREG_W])
                ready_q[s][j]<=1'b1;
          // Only a real short-ALU execute acceptance may wake early. The
          // producer result is held/bypassable before the consumer reads.
          for(j=0;j<2;j=j+1)
            for(w=0;w<2;w=w+1)
              if(early_valid_i[w]&&!fp_q[s][j]&&
                  src_q[s][j*PREG_W+:PREG_W]==early_preg_i[w*PREG_W+:PREG_W])
                ready_q[s][j]<=1'b1;
        end
        for(lane=0;lane<2;lane=lane+1)
          if(enq_fire_w[lane]&&(lane==0?pick0_w[s]:pick1_w[s])) begin
            valid_q[s]<=1;
            serial_dependency_q[s]<=serial_active_i&~serial_release_i;
            if(lane==1&&enq_fire_w[0]&&enq_class_i[0+:3]==C_SERIAL)
              serial_dependency_q[s][enq_tag_i[0+:ROB_W]]<=1;
            new_ready=~enq_src_used_i[lane*3+:3];
            if(DEFER_READY==0)begin
            new_ready=new_ready|enq_src_ready_i[lane*3+:3];
            for(j=0;j<3;j=j+1)
              for(w=0;w<2;w=w+1)
                if(wake_valid_i[w]&&enq_src_fp_i[lane*3+j]==wake_fp_i[w]&&
                    enq_src_preg_i[(lane*3+j)*PREG_W+:PREG_W]==wake_preg_i[w*PREG_W+:PREG_W])
                  new_ready[j]=1'b1;
            for(j=0;j<2;j=j+1)
              for(w=0;w<2;w=w+1)
                if(early_valid_i[w]&&!enq_src_fp_i[lane*3+j]&&
                    enq_src_preg_i[(lane*3+j)*PREG_W+:PREG_W]==early_preg_i[w*PREG_W+:PREG_W])
                  new_ready[j]=1'b1;
            end
            ready_q[s]<=new_ready;
          end
      end
    end
  end endgenerate
`ifdef R64_ASSERT
  wire [N*3-1:0] reference_resource_w;
  generate for(genvar rr=0;rr<N;rr=rr+1)begin:g_resource_contract
    if(PAYLOAD_W>=200)begin:g_native
      assign reference_resource_w[rr*3+:3]=resource_class(class_q[rr],payload_q[rr][198+:2]);
    end else begin:g_generic
      assign reference_resource_w[rr*3+:3]=class_q[rr];
    end
    always @(posedge clk)if(!rst&&!flush_i&&valid_q[rr]&&
        resource_q[rr]!=reference_resource_w[rr*3+:3])
      $fatal(1,"IQ resource projection separated from its resident instruction");
  end endgenerate
  integer lane;
  always @(posedge clk) if(!rst&&!flush_i) begin
    if(DEFER_READY!=0)begin
      if((init0_w&init1_w)!=0)$fatal(1,"R64 ready stage owns one IQ row twice");
      if(((init0_w|init1_w)&~valid_q)!=0)
        $fatal(1,"R64 ready initialization lost its reserved IQ row");
      if(((init0_w|init1_w)&(select0_mask_w|select1_mask_w))!=0)
        $fatal(1,"R64 IQ issued before its readiness initialization");
      for(integer row=0;row<N;row=row+1)begin
        if(init0_w[row]&&{src_q[row],fp_q[row]}!==
          {ready_query_preg_o[0+:3*PREG_W],ready_query_fp_o[0+:3]})
          $fatal(1,"R64 ready lane0 changed its physical owner");
        if(init1_w[row]&&{src_q[row],fp_q[row]}!==
          {ready_query_preg_o[3*PREG_W+:3*PREG_W],ready_query_fp_o[3+:3]})
          $fatal(1,"R64 ready lane1 changed its physical owner");
      end
    end
    if(enq_valid_i[1]&&!enq_valid_i[0]) $fatal(1,"R64 issue enqueue not dense");
    for(integer a=0;a<N;a=a+1)for(integer b=0;b<N;b=b+1)
      if(live_w[a]&&live_w[b]&&a!=b&&compatible_q[a][b]!=compatible(reference_resource_w[a*3+:3],reference_resource_w[b*3+:3],fp_q[a],fp_q[b],used_q[a],used_q[b]))
        $fatal(1,"R64 issue registered resource pair mismatch");
      else if(live_w[a]&&live_w[b]&&older_q[a][b]!=(age_w[b]<age_w[a]))
        $fatal(1,"R64 issue order matrix disagrees with live ROB age");
    for(integer owner=0;owner<N;owner=owner+1)
      if((select0_mask_w[owner]||select1_mask_w[owner])&&live_w[owner]&&
          barrier_valid_i&&age_w[owner]>barrier_age_w)
        $fatal(1,"R64 serial dependency admitted beyond the canonical barrier");
    if(sel0_valid_w&&sel1_valid_w&&sel0_slot_w==sel1_slot_w)
      $fatal(1,"R64 issue duplicate slot selection");
    for(lane=0;lane<2;lane=lane+1) if(enq_fire_w[lane]) begin
      if(enq_class_i[lane*3+:3]>C_SERIAL) $fatal(1,"R64 issue unknown class");
      if(enq_src_used_i[lane*3+2]&&!enq_src_fp_i[lane*3+2])
        $fatal(1,"R64 third integer source exceeds four-read-port contract");
    end
  end
`endif
`ifdef R64_ASSERT
  generate if(PREPARED_CANCEL)begin:gen_cancel_contract
    always @(posedge clk)if(!rst)
      if(kill_mask_i!==({(1<<ROB_W){cancel_active_i}}&cancel_candidates_i))
        $fatal(1,"prepared cancellation does not match canonical kill mask");
  end endgenerate
`endif
endmodule

module R64AgeSelect #(
  parameter SLOT_W=4, parameter AGE_W=5, parameter N=(1<<SLOT_W)
) (
  input [N-1:0] valid_i, input [N*AGE_W-1:0] age_i,
  output valid_o, output [SLOT_W-1:0] slot_o
);
  genvar n;
  generate for(n=1;n<2*N;n=n+1) begin:tree
    wire valid_w;
    wire [AGE_W-1:0] age_w;
    wire [SLOT_W-1:0] slot_w;
    if(n>=N) begin:leaf
      assign valid_w=valid_i[n-N];
      assign age_w=age_i[(n-N)*AGE_W+:AGE_W];
      localparam integer LEAF_NUMBER=n-N;
      localparam [SLOT_W-1:0] LEAF_SLOT=LEAF_NUMBER[SLOT_W-1:0];
      assign slot_w=LEAF_SLOT;
    end else begin:node
      wire left_w=tree[2*n].valid_w&&
          (!tree[2*n+1].valid_w||tree[2*n].age_w<=tree[2*n+1].age_w);
      assign valid_w=tree[2*n].valid_w|tree[2*n+1].valid_w;
      assign age_w=left_w?tree[2*n].age_w:tree[2*n+1].age_w;
      assign slot_w=left_w?tree[2*n].slot_w:tree[2*n+1].slot_w;
    end
  end endgenerate
  assign valid_o=tree[1].valid_w;
  assign slot_o=tree[1].slot_w;
endmodule
