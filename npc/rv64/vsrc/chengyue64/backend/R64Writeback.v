// Two registered completion lanes decouple FU result selection from ROB tag
// validation and PRF fanout. Sources hold VALID/payload until READY. A rotating
// pointer gives long FUs bounded service even while both ALUs remain active.
// Stale completions drain: ROB's accepted event alone authorizes state updates.
module R64Writeback #(
  parameter SOURCES=6, parameter SOURCE_W=3,
  parameter ROB_W=5, parameter TAG_W=9, parameter RESULT_W=140,
  parameter OWNER_CERTIFICATE=0,parameter PREG_W=6,parameter DEFER_REQUEST=1,parameter REQUEST_HINTS=0,
  parameter OWNER_BANKS=1<<((ROB_W>2)?2:0)
) (
  input clk, input rst, input flush_i,
  input [(1<<ROB_W)-1:0] kill_mask_i,
  input [SOURCES-1:0] source_valid_i,source_request_i,
  output reg [SOURCES-1:0] source_ready_o,
  input [SOURCES*TAG_W-1:0] source_tag_i,
  input [SOURCES*RESULT_W-1:0] source_result_i,
  output [2*TAG_W-1:0] owner_query_tag_o,
  input [2*OWNER_BANKS*(PREG_W+3)-1:0] owner_query_cert_i,
  output [2*(PREG_W+3)-1:0] wb_owner_cert_o,
  output [1:0] wb_valid_o,
  output [2*TAG_W-1:0] wb_tag_o,
  output [2*RESULT_W-1:0] wb_result_o
);
  // Grants allocate source ports for the next cycle, not a snapshot of an
  // owner. Only the real VALID/READY edge captures the current tag and data.
  // This breaks FU ready -> round-robin -> FU ready combinational propagation.
  // Every source owns cancellation locally and drops its killed token at the
  // clock edge, even without READY. WB refuses that token at the same edge.
  // A grant may remain asserted for an empty/cancelled source; it is not an
  // owner reservation and can never authorize a capture without live VALID.
  reg [SOURCES-1:0] grant0_q,grant1_q,after_q,request_q;
  // Acceptance is registered per source and four ROB-slot banks. Each bank
  // performs an eight-slot kill query; high slot bits only choose the bank.
  // Reduction happens after the acceptance edge. This shortens late tag/kill
  // arrival without weakening cancellation or adding a completion cycle.
  localparam BANK_BITS=(ROB_W>2)?2:0,LOCAL_BITS=ROB_W-BANK_BITS;
  localparam BANKS=1<<BANK_BITS,LOCAL_SLOTS=1<<LOCAL_BITS;
  reg [SOURCES*BANKS-1:0] accepted0_q,accepted1_q;
  wire [1:0] valid_q={|accepted1_q,|accepted0_q};
  reg [2*TAG_W-1:0] tag_q;
  reg [2*RESULT_W-1:0] result_q;
  genvar src,lane,t,bank;
  wire [SOURCES*BANKS-1:0] accept0_w,accept1_w;
  generate for(src=0;src<SOURCES;src=src+1)begin:gen_source
    for(bank=0;bank<BANKS;bank=bank+1)begin:gen_bank
      wire in_bank_w;
      if(BANK_BITS==0)assign in_bank_w=1'b1;
      else assign in_bank_w=source_tag_i[src*TAG_W+LOCAL_BITS+:BANK_BITS]==bank;
      wire [LOCAL_SLOTS-1:0] local_kill_w=kill_mask_i[bank*LOCAL_SLOTS+:LOCAL_SLOTS];
      wire accept_w=source_valid_i[src]&&in_bank_w&&
          !local_kill_w[source_tag_i[src*TAG_W+:LOCAL_BITS]];
      assign accept0_w[src*BANKS+bank]=grant0_q[src]&&accept_w;
      assign accept1_w[src*BANKS+bank]=grant1_q[src]&&accept_w;
    end
  end endgenerate
  // Sample demand before arbitration. These bits are scheduling hints, never
  // owners: a result is captured only from current VALID and a granted port.
  // Persistent sources retain II=1; a newly requesting port takes one extra
  // scheduling cycle, removing external VALID arrival from the selector cone.
  // Evaluate both rotating ranks in parallel. after_q is a thermometer
  // describing the upper segment of the circular source order.
  // The optional direct-demand path selects only next-cycle registered
  // grants. It never changes this cycle's READY or wide result selection.
  // Source VALID must describe a held owner independently of READY; native
  // FU/LSU completion holders satisfy that contract. Compare mapped timing
  // against DEFER_REQUEST before choosing the integrated implementation.
  // Hints reserve next-cycle ports only. Numerical capture and ROB owner
  // certification still require current source_valid_i, grant and !kill.
  wire [SOURCES-1:0] demand_w=source_valid_i|
      (REQUEST_HINTS!=0?source_request_i:{SOURCES{1'b0}});
  wire [SOURCES-1:0] request_w=DEFER_REQUEST ? request_q:demand_w;
  wire [SOURCES-1:0] select0_w,select1_w;
  localparam RANK_LEAVES=1<<SOURCE_W;
  genvar rank,leaf;
  generate for(rank=0;rank<SOURCES;rank=rank+1)begin:gen_rank
    for(leaf=1;leaf<2*RANK_LEAVES;leaf=leaf+1)begin:tree
      wire any_w,two_w;
      if(leaf>=RANK_LEAVES)begin:entry
        if(leaf-RANK_LEAVES<SOURCES&&leaf-RANK_LEAVES!=rank)begin:present
          localparam OTHER=leaf-RANK_LEAVES;
          wire older_w=(after_q[rank]==after_q[OTHER])?
              (OTHER<rank):after_q[OTHER];
          assign any_w=request_w[OTHER]&&older_w;
        end else begin:absent
          assign any_w=0;
        end
        assign two_w=0;
      end else begin:merge
        assign any_w=tree[2*leaf].any_w|tree[2*leaf+1].any_w;
        assign two_w=tree[2*leaf].two_w|tree[2*leaf+1].two_w|
            (tree[2*leaf].any_w&tree[2*leaf+1].any_w);
      end
    end
    // Cancellation belongs to actual capture below. It does not participate
    // in future grants, which reserve ports rather than numerical owners.
    assign select0_w[rank]=request_w[rank]&&!tree[1].any_w;
    assign select1_w[rank]=request_w[rank]&&tree[1].any_w&&!tree[1].two_w;
  end endgenerate
  // Advance the priority phase by two ports when a new port requests
  // service, independently of the selected source identities. This removes VALID -> two grants -> next-phase feedback.
  // With all sources persistent each receives two grants per SOURCES cycles.
  wire [SOURCES-1:0] next_after_w;
  generate for(src=0;src<SOURCES;src=src+1)begin:gen_rotation
    if(SOURCES==2)assign next_after_w[src]=1'b1;
    else if(src==0)assign next_after_w[src]=after_q[SOURCES-2]&&!after_q[SOURCES-3];
    else if(src==1)assign next_after_w[src]=!after_q[SOURCES-3];
    else assign next_after_w[src]=after_q[src-2]||!after_q[SOURCES-3];
  end endgenerate
  wire new_request_w=|(request_w&~(grant0_q|grant1_q));

  localparam LEAVES=1<<SOURCE_W,PACK_W=TAG_W+RESULT_W;
  generate for(lane=0;lane<2;lane=lane+1)begin:gen_result
    // Physical completion lanes stay attached to their registered grant.
    // Cancellation only suppresses valid; it never selects a different wide
    // result. The ROB accepts each lane independently, including lane1-only.
    wire [SOURCES-1:0] mask_w=lane==0?grant0_q:grant1_q;

    for(t=1;t<2*LEAVES;t=t+1)begin:tree
      wire [PACK_W-1:0] data_w;
      if(t>=LEAVES)begin:leaf
        if(t-LEAVES<SOURCES)begin:present
          assign data_w={PACK_W{mask_w[t-LEAVES]}}&
            {source_tag_i[(t-LEAVES)*TAG_W+:TAG_W],source_result_i[(t-LEAVES)*RESULT_W+:RESULT_W]};
        end else begin:pad
          assign data_w=0;
        end
      end else begin:merge
        assign data_w=tree[2*t].data_w|tree[2*t+1].data_w;
      end
    end
    assign owner_query_tag_o[lane*TAG_W+:TAG_W]=OWNER_CERTIFICATE!=0?
      tree[1].data_w[RESULT_W+:TAG_W]:{TAG_W{1'b0}};
    // Raw completion: ROB current generation/kill checks alone authorize
    // writes, canonical wakeups and architectural completion.
    assign wb_valid_o[lane]=valid_q[lane];
    // Payload may be sampled without an accepted owner. Only accepted*_q
    // makes those bits a completion; canceled data can never become valid.
    always @(posedge clk)
      {tag_q[lane*TAG_W+:TAG_W],result_q[lane*RESULT_W+:RESULT_W]}<=tree[1].data_w;
  end endgenerate
  localparam CERT_W=PREG_W+3;
  generate if(OWNER_CERTIFICATE!=0)begin:g_owner_certificate
    // Destination/authorization is sampled at the original result edge. A
    // bank-local certificate is published only by the bank's actual accepted
    // source, using the existing source/kill masks captured at that same edge.
    for(lane=0;lane<2;lane=lane+1)begin:g_lane
      wire [BANKS*CERT_W-1:0] qualified_w;
      for(bank=0;bank<BANKS;bank=bank+1)begin:g_bank
        reg [CERT_W-1:0] cert_q;
        wire [SOURCES-1:0] accepted_w;
        for(src=0;src<SOURCES;src=src+1)begin:g_source
          assign accepted_w[src]=lane==0?
              accepted0_q[src*BANKS+bank]:accepted1_q[src*BANKS+bank];
        end
        always @(posedge clk)
          cert_q<=owner_query_cert_i[(lane*BANKS+bank)*CERT_W+:CERT_W];
        assign qualified_w[bank*CERT_W+:CERT_W]=cert_q&{CERT_W{|accepted_w}};
      end
      reg [CERT_W-1:0] merged_r;
      integer merge_bank;
      always @(*)begin
        merged_r=0;
        for(merge_bank=0;merge_bank<BANKS;merge_bank=merge_bank+1)
          merged_r=merged_r|qualified_w[merge_bank*CERT_W+:CERT_W];
      end
      assign wb_owner_cert_o[lane*CERT_W+:CERT_W]=merged_r;
    end
  end else begin:g_no_owner_certificate
    assign wb_owner_cert_o=0;
  end endgenerate
  // READY names registered port grants. Reset/flush kill local state at the
  // edge and all sources own their cancellation; neither is an async drain.
  always @(*)source_ready_o=grant0_q|grant1_q;
  assign wb_tag_o=tag_q;
  assign wb_result_o=result_q;
  always @(posedge clk)begin
    if(rst)begin
      accepted0_q<=0;accepted1_q<=0;request_q<=0;after_q<=~{{(SOURCES-2){1'b0}},2'b11};
      grant0_q<={{(SOURCES-1){1'b0}},1'b1};
      grant1_q<={{(SOURCES-2){1'b0}},2'b10};
    end else if(flush_i)begin accepted0_q<=0;accepted1_q<=0;request_q<=0;grant0_q<=0;grant1_q<=0;end
    else begin
      request_q<=demand_w;
      accepted0_q<=accept0_w;accepted1_q<=accept1_w;
      if(new_request_w)begin grant0_q<=select0_w;grant1_q<=select1_w;end
      if(new_request_w)after_q<=next_after_w;
    end
  end

`ifdef R64_ASSERT
  always @(posedge clk) if(!rst) begin
    if((grant0_q&grant1_q)!=0) $fatal(1,"R64 writeback duplicate source grant");
    if((grant0_q&(grant0_q-1'b1))!=0||(grant1_q&(grant1_q-1'b1))!=0)
      $fatal(1,"R64 writeback grant is not one-hot");
  end
`endif
endmodule
