`include "define.v"

// PLIC-like 最小外部中断控制器。rootfs 路线需要 UART 与 virtio-blk
// 同时可中断，因此这里按标准 bitmap 形态支持 source 1..31。
module AxiPlic #(
  parameter ADDR_W = `XLEN,
  parameter DATA_W = `XLEN,
  parameter STRB_W = DATA_W / 8,
  parameter SOURCE_NUM = 32,
  parameter PRIORITY_BITS = 3
) (
  input clk,
  input rst,

  input s_axi_arvalid_i,
  output s_axi_arready_o,
  input [ADDR_W-1:0] s_axi_araddr_i,
  input [2:0] s_axi_arsize_i,
  output reg s_axi_rvalid_o,
  input s_axi_rready_i,
  output reg [DATA_W-1:0] s_axi_rdata_o,
  output reg [1:0] s_axi_rresp_o,

  input s_axi_awvalid_i,
  output s_axi_awready_o,
  input [ADDR_W-1:0] s_axi_awaddr_i,
  input [2:0] s_axi_awsize_i,
  input s_axi_wvalid_i,
  output s_axi_wready_o,
  input [DATA_W-1:0] s_axi_wdata_i,
  input [STRB_W-1:0] s_axi_wstrb_i,
  output reg s_axi_bvalid_o,
  input s_axi_bready_i,
  output reg [1:0] s_axi_bresp_o,

  input [SOURCE_NUM-1:0] source_irq_i,
  output reg external_irq_o,
  output reg machine_irq_o,supervisor_irq_o
);

  localparam integer LANE_BITS = $clog2(STRB_W);
  localparam integer SOURCE_BITS = $clog2(SOURCE_NUM);

  localparam [21:0] PLIC_PRIORITY_BASE = 22'h000000;
  localparam [21:0] PLIC_PENDING_OFFSET = 22'h001000;
  localparam [21:0] PLIC_M_ENABLE_OFFSET = 22'h002000;
  localparam [21:0] PLIC_S_ENABLE_OFFSET = 22'h002080;
  localparam [21:0] PLIC_M_THRESH_OFFSET = 22'h200000;
  localparam [21:0] PLIC_M_CLAIM_OFFSET = 22'h200004;
  localparam [21:0] PLIC_S_THRESH_OFFSET = 22'h201000;
  localparam [21:0] PLIC_S_CLAIM_OFFSET = 22'h201004;

  reg ar_pending_q;
  reg read_result_q,read_claim_q,read_context_q;
  reg [4:0] read_claim_id_q;
  reg [21:0] araddr_low_q;
  reg [2:0] arsize_q;
  reg ar_legal_q;
  reg [21:0] awaddr_low_q;
  reg [2:0] awsize_q;
  reg aw_legal_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;

  reg [PRIORITY_BITS-1:0] priority_q [0:SOURCE_NUM-1];
  reg [SOURCE_NUM-1:0] pending_q;
  reg [SOURCE_NUM-1:0] in_service_q;
  reg [SOURCE_NUM-1:0] service_context_q;
  reg [SOURCE_NUM-1:0] enable_m_q;
  reg [SOURCE_NUM-1:0] enable_s_q;
  reg [PRIORITY_BITS-1:0] threshold_m_q;
  reg [PRIORITY_BITS-1:0] threshold_s_q;

  wire [4:0] m_claim_id_r;
  wire [4:0] s_claim_id_r;
  reg [SOURCE_NUM-1:0] pending_next_r;
  reg [SOURCE_NUM-1:0] in_service_next_r;
  integer i;

  // The native register width is 32 bits. Also preserve the platform's
  // aligned 64-bit paired-word accesses; bytes, halfwords, misalignment and
  // accesses outside the implemented aperture must not mutate MMIO state.
  function access_legal;
    input [ADDR_W-1:0] addr;
    input [2:0] size;
    begin
      access_legal = 1'b0;
      if (addr >= `NPC_AXI_PLIC_BASE &&
          addr < (`NPC_AXI_PLIC_BASE + 64'h0040_0000)) begin
        case ({size,addr[2:0]})
          6'b010000, 6'b010100: access_legal = 1'b1;
          6'b011000: access_legal = (DATA_W >= 64);
          default: access_legal = 1'b0;
        endcase
      end
    end
  endfunction

  wire read_legal_w = ar_legal_q;
  wire read_apply_w = ar_pending_q && !read_result_q && !s_axi_rvalid_o;
  wire read_complete_w = read_result_q && !s_axi_rvalid_o;
  wire [2:0] write_size_w = awsize_q;
  wire write_legal_w = aw_legal_q;
  wire write_apply_w = write_done_w && write_legal_w;
  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  // AW and W independently capture a complete transaction before register
  // side effects. This cuts fabric launch/ready from priority, enable and
  // completion decode, and makes one held pair the only write owner.
  wire write_done_w = !s_axi_bvalid_o && aw_seen_q && w_seen_q;
  wire [21:0] read_addr_low_w = araddr_low_q;
  wire [21:0] write_addr_low_w = awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = wdata_q;
  wire [STRB_W-1:0] write_strb_w = wstrb_q;
  wire [LANE_BITS-1:0] write_lane_w = write_addr_low_w[LANE_BITS-1:0];
  wire [LANE_BITS-1:0] read_lane_w = araddr_low_q[LANE_BITS-1:0];
  wire [5:0] write_lane_shift_w = write_lane_w * 6'd8;
  wire [5:0] read_lane_shift_w = read_lane_w * 6'd8;
  wire [DATA_W-1:0] native_write_data_w = write_data_w >> write_lane_shift_w;
  wire [STRB_W-1:0] native_write_strb_w = write_strb_w >> write_lane_w;
  wire [63:0] write_data_pad_w;
  wire [7:0] write_strb_pad_w;
  wire m_claim_addr_w =
      (read_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
      ((arsize_q == 3'd3) &&
       (read_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8)));
  wire s_claim_addr_w =
      (read_addr_low_w == PLIC_S_CLAIM_OFFSET) ||
      ((arsize_q == 3'd3) &&
       (read_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8)));
  wire claim_read_w = read_complete_w && read_claim_q;
  wire [4:0] claim_id_w = read_claim_id_q;
  wire complete_low_w =
      ((write_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
       (write_addr_low_w == PLIC_S_CLAIM_OFFSET)) &&
      write_strb_pad_w[0] &&
      (write_data_pad_w[4:0] != 5'd0) &&
      ({1'b0,write_data_pad_w[4:0]} < SOURCE_NUM[5:0]);
  wire complete_high_w =
      ((write_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8)) ||
       (write_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8))) &&
      write_strb_pad_w[4] &&
      (write_data_pad_w[36:32] != 5'd0) &&
      ({1'b0,write_data_pad_w[36:32]} < SOURCE_NUM[5:0]);
  wire complete_write_w = write_apply_w && (complete_low_w || complete_high_w);
  wire [21:0] priority_index0_w = {2'b0,write_addr_low_w[21:2]};
  wire [21:0] priority_index1_w = priority_index0_w + 22'd1;
  wire [4:0] complete_id_w = complete_high_w ? write_data_pad_w[36:32] : write_data_pad_w[4:0];
  wire [31:0] enable_m_write_bitmap_w =
      apply_wstrb32_lane(bitmap32(enable_m_q), write_data_pad_w[31:0], write_strb_pad_w[3:0]);
  wire [31:0] enable_s_write_bitmap_w =
      apply_wstrb32_lane(bitmap32(enable_s_q), write_data_pad_w[31:0], write_strb_pad_w[3:0]);
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:22],
      s_axi_awaddr_i[ADDR_W-1:22],
      PLIC_PRIORITY_BASE,
      s_axi_arsize_i,
      s_axi_awsize_i
  };

  assign s_axi_arready_o = !ar_pending_q && !read_result_q && !s_axi_rvalid_o;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  // Interrupt notification is registered. Claim selection and gateway update
  // are separate stages: no second read can enter before this R completes.
  wire [1:0] notify_w;
  wire external_irq_next_w = |notify_w;
  assign write_data_pad_w[31:0] = native_write_data_w[31:0];
  assign write_strb_pad_w[3:0] = native_write_strb_w[3:0];

  generate
    if (DATA_W >= 64) begin : gen_write_data_hi
      assign write_data_pad_w[63:32] = native_write_data_w[63:32];
    end else begin : gen_write_data_hi_zero
      assign write_data_pad_w[63:32] = 32'h0;
    end
    if (STRB_W >= 8) begin : gen_write_strb_hi
      assign write_strb_pad_w[7:4] = (write_size_w == 3'd3) ?
          native_write_strb_w[7:4] : 4'b0;
    end else begin : gen_write_strb_hi_zero
      assign write_strb_pad_w[7:4] = 4'h0;
    end
  endgenerate

  // For the three-bit PLIC priorities, resolve each priority class in
  // parallel, then select the highest nonempty class. Equal-priority sources
  // keep the lowest ID; priority zero and source zero remain ineligible.
  function automatic [4:0] first_source(input [31:0] request);
    reg [4:0] id;
    integer source_index;
    begin
      id=0;
      for(source_index=1;source_index<32;source_index=source_index+1)
        id=id|({5{request[source_index]&&
          !(|(request&((32'b1<<source_index)-1)))}}&5'(source_index));
      first_source=id;
    end
  endfunction
  wire [4:0] claim_id_w_by_context [0:1];
  genvar ctx,source,node,priority_class;
  generate if(PRIORITY_BITS<=3)begin:gen_priority_classes
    localparam CLASS_COUNT=(1<<PRIORITY_BITS);
    for(ctx=0;ctx<2;ctx=ctx+1)begin:gen_context
      wire [SOURCE_NUM-1:0] enables=(ctx==0)?enable_m_q:enable_s_q;
      wire [PRIORITY_BITS-1:0] threshold=(ctx==0)?threshold_m_q:threshold_s_q;
      wire [CLASS_COUNT-1:0] nonempty,selected,notifies;
      wire [4:0] class_id[0:CLASS_COUNT-1];
      assign nonempty[0]=0;assign selected[0]=0;
      assign notifies[0]=0;assign class_id[0]=0;
      for(priority_class=1;priority_class<CLASS_COUNT;priority_class=priority_class+1)begin:gen_class
        wire [31:0] members;
        for(source=0;source<32;source=source+1)begin:gen_source
          if(source>0&&source<SOURCE_NUM)begin:gen_present
            assign members[source]=pending_q[source]&&enables[source]&&
              !in_service_q[source]&&priority_q[source]==PRIORITY_BITS'(priority_class);
          end else assign members[source]=0;
        end
        assign nonempty[priority_class]=|members;
        assign selected[priority_class]=nonempty[priority_class]&&
          !(|(nonempty>>(priority_class+1)));
        assign class_id[priority_class]=first_source(members);
        // Claim ignores threshold; notification tests it independently.
        assign notifies[priority_class]=nonempty[priority_class]&&
          PRIORITY_BITS'(priority_class)>threshold;
      end
      reg [4:0] claim;
      integer pc;
      always @* begin
        claim=0;
        for(pc=1;pc<CLASS_COUNT;pc=pc+1)
          claim=claim|({5{selected[pc]}}&class_id[pc]);
      end
      assign claim_id_w_by_context[ctx]=claim;
      assign notify_w[ctx]=|notifies;
    end
  end else begin:gen_priority_tournament
    for (ctx = 0; ctx < 2; ctx = ctx + 1) begin : gen_context_claim
      wire [SOURCE_NUM-1:0] enable_w = (ctx == 0) ? enable_m_q : enable_s_q;
      wire [PRIORITY_BITS-1:0] threshold_w =
          (ctx == 0) ? threshold_m_q : threshold_s_q;
      wire [PRIORITY_BITS+4:0] level0_w [0:31];
      wire [PRIORITY_BITS+4:0] level1_w [0:15];
      wire [PRIORITY_BITS+4:0] level2_w [0:7];
      wire [PRIORITY_BITS+4:0] level3_w [0:3];
      wire [PRIORITY_BITS+4:0] level4_w [0:1];
      wire [PRIORITY_BITS+4:0] level5_w [0:0];
      for (source = 0; source < 32; source = source + 1) begin : gen_leaf
        if (source > 0 && source < SOURCE_NUM) begin : gen_implemented
          wire eligible_w = pending_q[source] && enable_w[source] &&
              !in_service_q[source] && priority_q[source] != 0;
          assign level0_w[source] = eligible_w ?
              {priority_q[source],source[4:0]} : {(PRIORITY_BITS+5){1'b0}};
        end else begin : gen_absent
          assign level0_w[source] = {(PRIORITY_BITS+5){1'b0}};
        end
      end
      for (node = 0; node < 16; node = node + 1) begin : gen_level1
        assign level1_w[node] =
            (level0_w[2*node+1][PRIORITY_BITS+4:5] > level0_w[2*node][PRIORITY_BITS+4:5]) ?
            level0_w[2*node+1] : level0_w[2*node];
      end
      for (node = 0; node < 8; node = node + 1) begin : gen_level2
        assign level2_w[node] =
            (level1_w[2*node+1][PRIORITY_BITS+4:5] > level1_w[2*node][PRIORITY_BITS+4:5]) ?
            level1_w[2*node+1] : level1_w[2*node];
      end
      for (node = 0; node < 4; node = node + 1) begin : gen_level3
        assign level3_w[node] =
            (level2_w[2*node+1][PRIORITY_BITS+4:5] > level2_w[2*node][PRIORITY_BITS+4:5]) ?
            level2_w[2*node+1] : level2_w[2*node];
      end
      for (node = 0; node < 2; node = node + 1) begin : gen_level4
        assign level4_w[node] =
            (level3_w[2*node+1][PRIORITY_BITS+4:5] > level3_w[2*node][PRIORITY_BITS+4:5]) ?
            level3_w[2*node+1] : level3_w[2*node];
      end
      for (node = 0; node < 1; node = node + 1) begin : gen_level5
        assign level5_w[node] =
            (level4_w[2*node+1][PRIORITY_BITS+4:5] > level4_w[2*node][PRIORITY_BITS+4:5]) ?
            level4_w[2*node+1] : level4_w[2*node];
      end
      assign claim_id_w_by_context[ctx] = level5_w[0][4:0];
      // Claim ignores threshold (PLIC 1.0 section 7.1). The already selected
      // highest priority only needs one final comparison for notification.
      assign notify_w[ctx]=level5_w[0][PRIORITY_BITS+4:5]>threshold_w;
    end
  end endgenerate
  assign m_claim_id_r = claim_id_w_by_context[0];
  assign s_claim_id_r = claim_id_w_by_context[1];

  function [DATA_W-1:0] pack_u32_pair;
    input [31:0] low;
    input [31:0] high;
    begin
      pack_u32_pair = {high, low};
    end
  endfunction

  function [31:0] apply_wstrb32_lane;
    input [31:0] old_value;
    input [31:0] new_value;
    input [3:0] strb;
    begin
      apply_wstrb32_lane[7:0] = strb[0] ? new_value[7:0] : old_value[7:0];
      apply_wstrb32_lane[15:8] = strb[1] ? new_value[15:8] : old_value[15:8];
      apply_wstrb32_lane[23:16] = strb[2] ? new_value[23:16] : old_value[23:16];
      apply_wstrb32_lane[31:24] = strb[3] ? new_value[31:24] : old_value[31:24];
    end
  endfunction

  // Priority and threshold are 32-bit WARL MMIO fields.  The implemented
  // low bits remain byte-strobe merged; unimplemented high bits read zero and
  // ignore writes.  Keeping the merge in a 32-bit view also makes a legal
  // PRIORITY_BITS=32 configuration exactly preserve the former behavior.
  function [31:0] priority_to_u32;
    input [PRIORITY_BITS-1:0] value;
    begin
      priority_to_u32 = 32'h0;
      priority_to_u32[PRIORITY_BITS-1:0] = value;
    end
  endfunction

  function [PRIORITY_BITS-1:0] apply_priority_wstrb;
    input [PRIORITY_BITS-1:0] old_value;
    input [31:0] new_value;
    input [3:0] strb;
    reg [31:0] merged;
    begin
      merged = apply_wstrb32_lane(priority_to_u32(old_value), new_value, strb);
      apply_priority_wstrb = merged[PRIORITY_BITS-1:0];
    end
  endfunction

  wire [SOURCE_NUM*PRIORITY_BITS-1:0] priorities_w;
  genvar priority_source;
  generate for(priority_source=0;priority_source<SOURCE_NUM;priority_source=priority_source+1) begin : gen_priority_read
    assign priorities_w[priority_source*PRIORITY_BITS+:PRIORITY_BITS]=priority_q[priority_source];
  end endgenerate

  function [31:0] priority_at;
    input [21:0] word_index;
    input [SOURCE_NUM*PRIORITY_BITS-1:0] priorities;
    begin
      // PLIC source 0 is architecturally reserved and hardwired to priority 0.
      if ((word_index != 22'd0) && (word_index < SOURCE_NUM[21:0]))
        priority_at = priority_to_u32(priorities[word_index[SOURCE_BITS-1:0]*PRIORITY_BITS+:PRIORITY_BITS]);
      else
        priority_at = 32'h0;
    end
  endfunction

  function [31:0] bitmap32;
    input [SOURCE_NUM-1:0] bits;
    begin
      bitmap32 = 32'h0;
      bitmap32[SOURCE_NUM-1:0] = bits;
    end
  endfunction

  // PLIC 读 decode 组合块(结果在 AXI 读时序块寄存到 s_axi_rdata_o)
  reg [DATA_W-1:0] read_plic_word_r;
  always @(*) begin : read_plic_word_blk
    reg [21:0] addr_low;
    begin
      addr_low = read_addr_low_w;
      read_plic_word_r = 0;
      if (addr_low < PLIC_PENDING_OFFSET) begin
        // Priority 区域按 32-bit word 编址；64-bit beat 同时返回相邻两个 source。
        read_plic_word_r = pack_u32_pair(priority_at({2'b0,addr_low[21:2]},priorities_w),
                                       priority_at({2'b0,addr_low[21:2]} + 22'd1,priorities_w));
      end else begin
        case (addr_low)
          PLIC_PENDING_OFFSET:
            read_plic_word_r = pack_u32_pair(bitmap32(pending_q), 32'h0);
          PLIC_M_ENABLE_OFFSET:
            read_plic_word_r = pack_u32_pair(bitmap32(enable_m_q), 32'h0);
          PLIC_S_ENABLE_OFFSET:
            read_plic_word_r = pack_u32_pair(bitmap32(enable_s_q), 32'h0);
          PLIC_M_THRESH_OFFSET:
            read_plic_word_r = pack_u32_pair(priority_to_u32(threshold_m_q),
                                             32'h0);
          PLIC_S_THRESH_OFFSET:
            read_plic_word_r = pack_u32_pair(priority_to_u32(threshold_s_q),
                                             32'h0);
          PLIC_M_CLAIM_OFFSET:
            read_plic_word_r = pack_u32_pair(32'h0, 32'h0);
          PLIC_S_CLAIM_OFFSET:
            read_plic_word_r = pack_u32_pair(32'h0, 32'h0);
          default:
            read_plic_word_r = {DATA_W{1'b0}};
        endcase
      end
    end
  end

  // Each gateway owns its pending/in-service bits. Match the claim and
  // completion ID locally; never read a 32-entry bitmap through that ID
  // only to route the result back into the same bitmap.
  integer gateway;
  always @(*) begin
    pending_next_r=0;in_service_next_r=0;
    for(gateway=1;gateway<SOURCE_NUM;gateway=gateway+1) begin
      pending_next_r[gateway]=pending_q[gateway]|
          (source_irq_i[gateway]&~in_service_q[gateway]);
      in_service_next_r[gateway]=in_service_q[gateway];
      if(claim_read_w&&claim_id_w==gateway[4:0]) begin
        pending_next_r[gateway]=0;in_service_next_r[gateway]=1;
      end
      // Complete requires an old in-service owner in the writing context.
      // Same-edge claim/complete keeps the original claim-then-complete order.
      if(complete_write_w&&complete_id_w==gateway[4:0]&&
          in_service_q[gateway]&&
          service_context_q[gateway]==write_addr_low_w[12]&&
          (write_addr_low_w[12]?enable_s_q[gateway]:enable_m_q[gateway])) begin
        in_service_next_r[gateway]=0;
        if(source_irq_i[gateway]) pending_next_r[gateway]=1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ar_pending_q <= 1'b0; araddr_low_q <= 0; arsize_q <= 0; ar_legal_q <= 0;
      read_result_q<=0;read_claim_q<=0;read_claim_id_q<=0;read_context_q<=0;
      s_axi_rvalid_o <= 1'b0;
      s_axi_rresp_o <= 2'b00;
      s_axi_bresp_o <= 2'b00;
      awsize_q <= 3'b0;
      aw_legal_q <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_bvalid_o <= 1'b0;
      awaddr_low_q <= 22'h0;
      aw_seen_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_seen_q <= 1'b0;
      pending_q <= {SOURCE_NUM{1'b0}};
      in_service_q <= {SOURCE_NUM{1'b0}};service_context_q<=0;
      enable_m_q <= {SOURCE_NUM{1'b0}};
      enable_s_q <= {SOURCE_NUM{1'b0}};
      threshold_m_q <= {PRIORITY_BITS{1'b0}};
      threshold_s_q <= {PRIORITY_BITS{1'b0}};
      external_irq_o <= 1'b0;machine_irq_o<=0;supervisor_irq_o<=0;
      for (i = 0; i < SOURCE_NUM; i = i + 1)
        priority_q[i] <= {PRIORITY_BITS{1'b0}};
    end else begin
      pending_q <= pending_next_r;
      in_service_q <= in_service_next_r;
      for(i=1;i<SOURCE_NUM;i=i+1)
        if(claim_read_w&&claim_id_w==i[4:0]) service_context_q[i]<=read_context_q;
      external_irq_o <= external_irq_next_w;
      machine_irq_o<=notify_w[0];supervisor_irq_o<=notify_w[1];

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w) begin
        ar_pending_q <= 1'b1;
        araddr_low_q <= s_axi_araddr_i[21:0];
        arsize_q <= s_axi_arsize_i;
        ar_legal_q <= access_legal(s_axi_araddr_i, s_axi_arsize_i);
      end

      // Select one snapshot of the pending/priority state. A chosen pending
      // source cannot be consumed by another claim while this read owns AR.
      // Gateway mutation follows one edge later, with the matching RVALID.
      // The output data register itself holds the snapshot; no duplicate
      // wide response queue is needed.
      if (read_apply_w) begin
        ar_pending_q <= 1'b0;
        read_result_q <= 1'b1;
        read_claim_q <= read_legal_w && (m_claim_addr_w || s_claim_addr_w);
        read_claim_id_q <= m_claim_addr_w ? m_claim_id_r : s_claim_id_r;
        read_context_q <= s_claim_addr_w;
        s_axi_rresp_o <= read_legal_w ? 2'b00 : 2'b10;
        s_axi_rdata_o <= !read_legal_w ? {DATA_W{1'b0}} :
            ((arsize_q == 3'd2) ?
             ({{(DATA_W-32){1'b0}},read_plic_word_r[31:0]} << read_lane_shift_w) :
             read_plic_word_r);
      end

      if (read_complete_w) begin
        read_result_q <= 1'b0;
        s_axi_rvalid_o <= 1'b1;
        // Compose the snapshotted claim ID at the existing gateway/R edge.
        // Priority selection ends at read_claim_id_q; register-word decoding
        // and lane packing no longer follow that tournament in the same cycle.
        if(read_claim_q)
          s_axi_rdata_o <= s_axi_rdata_o |
            ({{(DATA_W-5){1'b0}},read_claim_id_q} << ((DATA_W>=64)?32:0));
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[21:0];
        awsize_q <= s_axi_awsize_i;
        aw_legal_q <= access_legal(s_axi_awaddr_i, s_axi_awsize_i);
        aw_seen_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_seen_q <= 1'b1;
      end

      if (write_done_w) begin
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= write_legal_w ? 2'b00 : 2'b10;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;

        if (write_legal_w && write_addr_low_w < PLIC_PENDING_OFFSET) begin
          if (write_strb_pad_w[3:0] != 4'h0 &&
              (priority_index0_w != 22'd0) &&
              (priority_index0_w < SOURCE_NUM[21:0])) begin
            priority_q[priority_index0_w[SOURCE_BITS-1:0]] <=
                apply_priority_wstrb(priority_q[priority_index0_w[SOURCE_BITS-1:0]],
                                     write_data_pad_w[31:0],
                                     write_strb_pad_w[3:0]);
          end
          if (write_strb_pad_w[7:4] != 4'h0 &&
              ((priority_index1_w) != 22'd0) &&
              ((priority_index1_w) < SOURCE_NUM[21:0])) begin
            priority_q[priority_index1_w[SOURCE_BITS-1:0]] <=
                apply_priority_wstrb(priority_q[priority_index1_w[SOURCE_BITS-1:0]],
                                     write_data_pad_w[63:32],
                                     write_strb_pad_w[7:4]);
          end
        end else if (write_legal_w) begin
          case (write_addr_low_w)
            PLIC_M_ENABLE_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                enable_m_q <= enable_m_write_bitmap_w[SOURCE_NUM-1:0] & {{(SOURCE_NUM-1){1'b1}},1'b0};
            PLIC_S_ENABLE_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                enable_s_q <= enable_s_write_bitmap_w[SOURCE_NUM-1:0] & {{(SOURCE_NUM-1){1'b1}},1'b0};
            PLIC_M_THRESH_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                threshold_m_q <= apply_priority_wstrb(threshold_m_q,
                                                      write_data_pad_w[31:0],
                                                      write_strb_pad_w[3:0]);
            PLIC_S_THRESH_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                threshold_s_q <= apply_priority_wstrb(threshold_s_q,
                                                      write_data_pad_w[31:0],
                                                      write_strb_pad_w[3:0]);
            default: begin end
          endcase
        end
      end
    end
  end

endmodule
