// Native fetch transport. Every accepted cache request reserves one packet slot.
// Redirect marks old requests stale; it never withdraws a held request or
// forgets an accepted response. Requests and responses are ordered by the cache.
module R64FetchStream #(
  parameter integer DEPTH = 4,
  parameter integer PTR_W = 2,
  parameter integer EARLY_PREDICT = 0,
  parameter [63:0] RESET_PC = 64'h80000000
) (
  input clk_i,
  input rst_i,
  input run_i,
  input redirect_i,
  input [63:4] redirect_block_i,
  input [2:0] redirect_offset_i,
  input invalidate_i,
  input learn_i,input [63:0] learn_pc_i,input [3:0] learn_length_i,input [63:0] learn_target_i,
  input resolve_i,input [63:0] resolve_pc_i,input resolve_taken_i,input [63:0] resolve_target_i,
  input repair_i,input [63:0] repair_block_i,
  output req_valid_o,
  input req_ready_i,
  output [63:0] req_pc_o,
  input rsp_valid_i,
  output rsp_ready_o,
  input [127:0] rsp_data_i,
  input rsp_fault_i,
  input [4:0] rsp_cause_i,
  input [7:0] rsp_access_mask_i,
  output packet_valid_o,
  input packet_ready_i,
  output [63:0] packet_pc_o,
  output [127:0] packet_data_o,
  output packet_fault_o,
  output [4:0] packet_cause_o,
  output [7:0] packet_access_mask_o,
  output packet_plan_valid_o,output [2:0] packet_plan_offset_o,
  output packet_plan_word_o,output [62:0] packet_plan_target_o
);
  // The lookup sees next_pc_q only. A redirect first registers its target;
  // Align decode/target arithmetic never cascades through this table to req D.
  reg [31:0] target_valid_q;
  reg [15:0] target_tag_q[0:31];
  reg [2:0] target_offset_q[0:31];
  reg [31:0] target_word_q;
  reg [62:0] target_pc_q[0:31];
  wire [4:0] query_index_w=next_pc_q[8:4],learn_index_w=learn_pc_i[8:4];
  wire [4:0] resolve_index_w=resolve_pc_i[8:4];
  wire query_hit_w=EARLY_PREDICT!=0&&target_valid_q[query_index_w]&&
    target_tag_q[query_index_w]==next_pc_q[24:9]&&
    target_offset_q[query_index_w]>=next_pc_q[3:1]&&!invalidate_i;
  wire [4:0] learn_end_w={1'b0,learn_pc_i[3:0]}+{1'b0,learn_length_i};
  // Each physical table entry owns its write qualification. Resolve does
  // not first read a 32-way selected tag/offset and then distribute permission.
  // All comparisons use this entry's old Q, including learn/resolve collisions.
  wire learn_complete_w=learn_i&&(learn_length_i==2||learn_length_i==4)&&learn_end_w<=16;
  genvar entry;
  generate for(entry=0;entry<32;entry=entry+1)begin:g_target_owner
    localparam [4:0] ENTRY=entry[4:0];
    wire learn_owner_w=learn_complete_w&&learn_index_w==ENTRY;
    wire resolve_owner_w=resolve_i&&resolve_index_w==ENTRY&&target_valid_q[entry]&&
      target_tag_q[entry]==resolve_pc_i[24:9]&&target_offset_q[entry]==resolve_pc_i[3:1];
    wire repair_owner_w=repair_i&&repair_block_i[8:4]==ENTRY;
    always @(posedge clk_i)begin
      if(rst_i||invalidate_i)target_valid_q[entry]<=0;
      else if(EARLY_PREDICT!=0)begin
        if(learn_owner_w)begin
          target_valid_q[entry]<=1;
          target_tag_q[entry]<=learn_pc_i[24:9];
          target_offset_q[entry]<=learn_pc_i[3:1];
          target_word_q[entry]<=learn_length_i==4;
          target_pc_q[entry]<=learn_target_i[63:1];
        end
        if(resolve_owner_w)begin
          if(!resolve_taken_i)target_valid_q[entry]<=0;
          else target_pc_q[entry]<=resolve_target_i[63:1];
        end
        if(repair_owner_w)target_valid_q[entry]<=0;
      end
    end
  end endgenerate
  reg req_valid_q, req_stale_q;
  reg [67:0] req_plan_q;
  reg [67:0] owner_plan_q[0:DEPTH-1];
  reg [67:0] packet_plan_q[0:DEPTH-1];
  reg [63:0] req_pc_q, next_pc_q;
  reg [63:0] owner_pc_q [0:DEPTH-1];
  reg [DEPTH-1:0] owner_stale_q;
  reg [PTR_W-1:0] owner_head_q, owner_tail_q;
  reg [PTR_W:0] owner_count_q;

  reg [63:0] packet_pc_q [0:DEPTH-1];
  reg [127:0] packet_data_q [0:DEPTH-1];
  reg [DEPTH-1:0] packet_fault_q;
  reg [4:0] packet_cause_q [0:DEPTH-1];
  reg [7:0] packet_access_mask_q [0:DEPTH-1];
  reg [PTR_W-1:0] packet_head_q, packet_tail_q;
  reg [PTR_W:0] packet_count_q;

  wire req_fire_w = req_valid_o && req_ready_i;
  wire rsp_fire_w = rsp_valid_i && rsp_ready_o;
  wire pop_w = packet_valid_o && packet_ready_i;
  wire stale_w = redirect_i || owner_stale_q[owner_head_q];
  wire push_w = rsp_fire_w && !stale_w;
  wire [PTR_W+1:0] reserved_w =
      {1'b0,owner_count_q} + {1'b0,packet_count_q} + {{(PTR_W+1){1'b0}},req_valid_q};
  wire stage_free_w = !req_valid_q || req_fire_w;
  // A request reserves capacity from registered owners only. A consumed or
  // cancelled packet releases its credit at the edge; new admission uses that
  // credit next cycle. Redirect and alignment length never traverse this path.
  wire credit_w = reserved_w < DEPTH[PTR_W+1:0];

  assign req_valid_o = req_valid_q && !rst_i;
  assign req_pc_o = {req_pc_q[63:4],4'b0};
  assign rsp_ready_o = owner_count_q != 0 && !rst_i;
  assign packet_valid_o = packet_count_q != 0 && !rst_i && !redirect_i;
  assign packet_pc_o = packet_pc_q[packet_head_q];
  assign packet_data_o = packet_data_q[packet_head_q];
  assign packet_fault_o = packet_fault_q[packet_head_q];
  assign packet_cause_o = packet_cause_q[packet_head_q];
  assign packet_access_mask_o = packet_access_mask_q[packet_head_q];
  assign {packet_plan_valid_o,packet_plan_offset_o,packet_plan_word_o,packet_plan_target_o}=
    EARLY_PREDICT!=0?packet_plan_q[packet_head_q]:68'b0;

  always @(posedge clk_i) begin
    if (rst_i) begin
      req_valid_q <= 1'b0;
      req_stale_q <= 1'b0;
      req_pc_q <= 64'b0;
      next_pc_q <= EARLY_PREDICT!=0?RESET_PC:{RESET_PC[63:4],4'b0};
      req_plan_q<=0;
    end else begin
      if (redirect_i) begin
        next_pc_q <= {redirect_block_i,(EARLY_PREDICT!=0?redirect_offset_i:3'b0),1'b0};
        if (req_valid_q && !req_fire_w) req_stale_q <= 1'b1;
      end
      if (stage_free_w) begin
        req_valid_q <= run_i && credit_w && !(EARLY_PREDICT!=0&&redirect_i);
        if (run_i && credit_w && !(EARLY_PREDICT!=0&&redirect_i)) begin
          req_stale_q <= 1'b0;
          if(EARLY_PREDICT!=0)begin
            // A redirect cannot admit a new request in this mode. Its target
            // is written above, separately from sequential block arithmetic.
            req_pc_q<=next_pc_q;
            req_plan_q<={query_hit_w,target_offset_q[query_index_w],target_word_q[query_index_w],target_pc_q[query_index_w]};
            next_pc_q<=query_hit_w?{target_pc_q[query_index_w],1'b0}:
                {next_pc_q[63:4]+60'd1,4'b0};
          end else begin
            req_pc_q<=redirect_i?{redirect_block_i,4'b0}:next_pc_q;
            req_plan_q<=0;
            next_pc_q<=redirect_i?{redirect_block_i+60'd1,4'b0}:
                {next_pc_q[63:4]+60'd1,4'b0};
          end
        end
      end
    end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      owner_head_q <= 0;
      owner_tail_q <= 0;
      owner_count_q <= 0;
      owner_stale_q <= 0;
    end else begin
      if (redirect_i) owner_stale_q <= {DEPTH{1'b1}};
      if (req_fire_w) begin
        owner_pc_q[owner_tail_q] <= req_pc_q;
        owner_plan_q[owner_tail_q]<=req_plan_q;
        owner_stale_q[owner_tail_q] <= req_stale_q || redirect_i;
        owner_tail_q <= owner_tail_q + 1'b1;
      end
      if (rsp_fire_w) owner_head_q <= owner_head_q + 1'b1;
      case ({req_fire_w,rsp_fire_w})
        2'b10: owner_count_q <= owner_count_q + 1'b1;
        2'b01: owner_count_q <= owner_count_q - 1'b1;
        default: begin end
      endcase
    end
  end

  // Payload RAMs do not reset: valid/count are their only authority.
  always @(posedge clk_i) begin
    if (rst_i || redirect_i) begin
      packet_head_q <= 0;
      packet_tail_q <= 0;
      packet_count_q <= 0;
    end else begin
      if (push_w) begin
        packet_pc_q[packet_tail_q] <= owner_pc_q[owner_head_q];
        packet_plan_q[packet_tail_q]<=owner_plan_q[owner_head_q];
        packet_data_q[packet_tail_q] <= rsp_data_i;
        packet_fault_q[packet_tail_q] <= rsp_fault_i;
        packet_cause_q[packet_tail_q] <= rsp_cause_i;
        packet_access_mask_q[packet_tail_q] <= rsp_access_mask_i;
        packet_tail_q <= packet_tail_q + 1'b1;
      end
      if (pop_w) packet_head_q <= packet_head_q + 1'b1;
      case ({push_w,pop_w})
        2'b10: packet_count_q <= packet_count_q + 1'b1;
        2'b01: packet_count_q <= packet_count_q - 1'b1;
        default: begin end
      endcase
    end
  end

  wire unused_prediction_address_w=|{learn_pc_i[63:25],learn_target_i[0],
    resolve_pc_i[63:25],resolve_pc_i[0],resolve_target_i[0],repair_block_i[63:9],repair_block_i[3:0]};
`ifdef R64_ASSERT
  initial begin
    if (DEPTH != (1 << PTR_W) || DEPTH < 2)
      $fatal(1,"R64FetchStream needs power-of-two DEPTH >= 2");
  end
  always @(posedge clk_i) if (!rst_i) begin
    if (reserved_w > DEPTH[PTR_W+1:0]) $fatal(1,"fetch credit overflow");
    if (push_w && packet_count_q == DEPTH[PTR_W:0] && !pop_w)
      $fatal(1,"fetch packet overwrite");
  end
`endif
endmodule
