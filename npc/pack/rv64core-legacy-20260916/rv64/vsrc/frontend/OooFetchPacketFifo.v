`include "define.v"
`include "common/OooSlotFacts.v"

// Front-end fetch packet FIFO storage primitive.
// Redirect, bypass and outstanding-response policy stay in OooCoreTopGlue.
module OooFetchPacketFifo #(
  parameter FETCH_PACKET_COUNT_W = `OOO_FETCH_PACKET_COUNT_W,
  parameter FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1
) (
  input clk,
  input rst,

  input clear_i,

  input enqueue_i,
  input [`XLEN-1:0] enqueue_pc0_i,
  input [`XLEN-1:0] enqueue_pc1_i,
  input [`XLEN-1:0] enqueue_next_pc0_i,
  input [`XLEN-1:0] enqueue_next_pc1_i,
  input [`XLEN-1:0] enqueue_packet_next_pc_i,
  input [`XLEN-1:0] enqueue_fault_tval_i,
  input [`INST_W-1:0] enqueue_inst0_i,
  input [`INST_W-1:0] enqueue_inst1_i,
  input [`CTRL_BUS_W-1:0] enqueue_ctrl0_i,
  input [`CTRL_BUS_W-1:0] enqueue_ctrl1_i,
  input [`OOO_SLOT_STATIC_FACTS_W-1:0] enqueue_static_facts0_i,
  input [`OOO_SLOT_STATIC_FACTS_W-1:0] enqueue_static_facts1_i,
  input [`REG_ADDR_W-1:0] enqueue_rs1_0_i,
  input [`REG_ADDR_W-1:0] enqueue_rs2_0_i,
  input [`REG_ADDR_W-1:0] enqueue_rd0_i,
  input [`XLEN-1:0] enqueue_imm0_i,
  input [`REG_ADDR_W-1:0] enqueue_rs1_1_i,
  input [`REG_ADDR_W-1:0] enqueue_rs2_1_i,
  input [`REG_ADDR_W-1:0] enqueue_rd1_i,
  input [`XLEN-1:0] enqueue_imm1_i,
  input [1:0] enqueue_resp0_i,
  input [1:0] enqueue_resp1_i,
  input enqueue_pred_taken0_i,
  input enqueue_pred_taken1_i,
  input [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx0_i,
  input [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx1_i,
  input enqueue_bht_valid0_i,
  input enqueue_bht_valid1_i,
  input enqueue_slot1_valid_i,

  input pop_i,

  output head_valid_o,
  output [`XLEN-1:0] head_pc0_o,
  output [`XLEN-1:0] head_pc1_o,
  output [`XLEN-1:0] head_next_pc0_o,
  output [`XLEN-1:0] head_next_pc1_o,
  output [`XLEN-1:0] head_packet_next_pc_o,
  output [`XLEN-1:0] head_fault_tval_o,
  output [`INST_W-1:0] head_inst0_o,
  output [`INST_W-1:0] head_inst1_o,
  output [`CTRL_BUS_W-1:0] head_ctrl0_o,
  output [`CTRL_BUS_W-1:0] head_ctrl1_o,
  output [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts0_o,
  output [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts1_o,
  output [`REG_ADDR_W-1:0] head_rs1_0_o,
  output [`REG_ADDR_W-1:0] head_rs2_0_o,
  output [`REG_ADDR_W-1:0] head_rd0_o,
  output [`XLEN-1:0] head_imm0_o,
  output [`REG_ADDR_W-1:0] head_rs1_1_o,
  output [`REG_ADDR_W-1:0] head_rs2_1_o,
  output [`REG_ADDR_W-1:0] head_rd1_o,
  output [`XLEN-1:0] head_imm1_o,
  output [1:0] head_resp0_o,
  output [1:0] head_resp1_o,
  output head_pred_taken0_o,
  output head_pred_taken1_o,
  output [`BPU_BHT_INDEX_W-1:0] head_bht_idx0_o,
  output [`BPU_BHT_INDEX_W-1:0] head_bht_idx1_o,
  output head_bht_valid0_o,
  output head_bht_valid1_o,
  output head_slot1_valid_o,
  // 【B2 S2】head1_pc0_o(下一 entry pc0, F2 pred_npc 哨兵源)已删——pred_npc 改从包内
  // pred_next_pc(packet_next_pc 字段改造承载)直取, count<2 哨兵缺口随之消灭。
  output [FETCH_COUNT_W-1:0] count_o
);

  localparam FETCH_PACKET_COUNT = (1 << FETCH_PACKET_COUNT_W);
  localparam [FETCH_PACKET_COUNT_W-1:0] FIFO_PTR_ZERO =
      {FETCH_PACKET_COUNT_W{1'b0}};
  localparam [FETCH_PACKET_COUNT_W-1:0] FIFO_PTR_ONE =
      {{(FETCH_PACKET_COUNT_W-1){1'b0}}, 1'b1};
  localparam [FETCH_COUNT_W-1:0] FIFO_COUNT_ZERO = {FETCH_COUNT_W{1'b0}};
  localparam [FETCH_COUNT_W-1:0] FIFO_COUNT_ONE =
      {{(FETCH_COUNT_W-1){1'b0}}, 1'b1};
  localparam IMM_LOW_W = 32;
  localparam IMM_SIGN_COPIES = 4;
  localparam IMM_SIGN_GROUP_W = (`XLEN - IMM_LOW_W) / IMM_SIGN_COPIES;
  localparam IMM_STORED_W = IMM_LOW_W + IMM_SIGN_COPIES;
  localparam HEAD_PACKET_W =
      (6 * `XLEN) + (2 * IMM_STORED_W) + (2 * `INST_W) + (2 * `CTRL_BUS_W) +
      (2 * `OOO_SLOT_STATIC_FACTS_W) + (6 * `REG_ADDR_W) + 4 + 2 +
      (2 * `BPU_BHT_INDEX_W) + 3;

  reg [FETCH_PACKET_COUNT_W-1:0] head_q;
  reg [FETCH_PACKET_COUNT_W-1:0] tail_q;
  reg [FETCH_COUNT_W-1:0] count_q;
  // T4B: 与 occupancy 事件同沿维护 head presence，切断 count 零比较到
  // classify/dispatch 的组合锥；count_q 仍是占用量真源，二者由断言守等价。
  reg head_valid_q;
  reg [`XLEN-1:0] pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] next_pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] next_pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] packet_next_pc_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] fault_tval_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] inst0_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] inst1_q [0:FETCH_PACKET_COUNT-1];
  // T3V: DecodeStage is a pure function of the instruction.  Store its result
  // with the packet so dispatch never rebuilds decode/imm behind the FIFO read
  // mux and then feeds backend ready back into the same frontend cycle.
  reg [`CTRL_BUS_W-1:0] ctrl0_q [0:FETCH_PACKET_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl1_q [0:FETCH_PACKET_COUNT-1];
  reg [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts0_q [0:FETCH_PACKET_COUNT-1];
  reg [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts1_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rs1_0_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rs2_0_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rd0_q [0:FETCH_PACKET_COUNT-1];
  reg [IMM_STORED_W-1:0] imm0_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rs1_1_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rs2_1_q [0:FETCH_PACKET_COUNT-1];
  reg [`REG_ADDR_W-1:0] rd1_q [0:FETCH_PACKET_COUNT-1];
  reg [IMM_STORED_W-1:0] imm1_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] resp0_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] resp1_q [0:FETCH_PACKET_COUNT-1];
  reg pred_taken0_q [0:FETCH_PACKET_COUNT-1];
  reg pred_taken1_q [0:FETCH_PACKET_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx0_q [0:FETCH_PACKET_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx1_q [0:FETCH_PACKET_COUNT-1];
  reg bht_valid0_q [0:FETCH_PACKET_COUNT-1];
  reg bht_valid1_q [0:FETCH_PACKET_COUNT-1];
  reg slot1_valid_q [0:FETCH_PACKET_COUNT-1];

  // T3W: present the complete oldest packet from one registered owner.  The
  // ring remains the four-entry canonical queue; this shadow cuts the
  // head-pointer/read-mux cone from all head-time classify, RAS, backend-ready
  // and fetch-flow decisions without adding a visible FIFO cycle.
  reg [HEAD_PACKET_W-1:0] head_packet_q;
  wire [IMM_STORED_W-1:0] enqueue_imm0_stored_w =
      {{IMM_SIGN_COPIES{enqueue_imm0_i[IMM_LOW_W-1]}}, enqueue_imm0_i[IMM_LOW_W-1:0]};
  wire [IMM_STORED_W-1:0] enqueue_imm1_stored_w =
      {{IMM_SIGN_COPIES{enqueue_imm1_i[IMM_LOW_W-1]}}, enqueue_imm1_i[IMM_LOW_W-1:0]};
  wire [IMM_STORED_W-1:0] head_imm0_stored_w;
  wire [IMM_STORED_W-1:0] head_imm1_stored_w;

  integer reset_idx;

  function [FETCH_PACKET_COUNT_W-1:0] ptr_inc;
    input [FETCH_PACKET_COUNT_W-1:0] ptr;
    begin
      ptr_inc = ptr + FIFO_PTR_ONE;
    end
  endfunction

  assign head_valid_o = head_valid_q;
  assign {
    head_pc0_o,
    head_pc1_o,
    head_next_pc0_o,
    head_next_pc1_o,
    head_packet_next_pc_o,
    head_fault_tval_o,
    head_inst0_o,
    head_inst1_o,
    head_ctrl0_o,
    head_ctrl1_o,
    head_static_facts0_o,
    head_static_facts1_o,
    head_rs1_0_o,
    head_rs2_0_o,
    head_rd0_o,
    head_imm0_stored_w,
    head_rs1_1_o,
    head_rs2_1_o,
    head_rd1_o,
    head_imm1_stored_w,
    head_resp0_o,
    head_resp1_o,
    head_pred_taken0_o,
    head_pred_taken1_o,
    head_bht_idx0_o,
    head_bht_idx1_o,
    head_bht_valid0_o,
    head_bht_valid1_o,
    head_slot1_valid_o
  } = head_packet_q;
  assign head_imm0_o = {
    {IMM_SIGN_GROUP_W{head_imm0_stored_w[IMM_LOW_W+3]}},
    {IMM_SIGN_GROUP_W{head_imm0_stored_w[IMM_LOW_W+2]}},
    {IMM_SIGN_GROUP_W{head_imm0_stored_w[IMM_LOW_W+1]}},
    {IMM_SIGN_GROUP_W{head_imm0_stored_w[IMM_LOW_W]}},
    head_imm0_stored_w[IMM_LOW_W-1:0]
  };
  assign head_imm1_o = {
    {IMM_SIGN_GROUP_W{head_imm1_stored_w[IMM_LOW_W+3]}},
    {IMM_SIGN_GROUP_W{head_imm1_stored_w[IMM_LOW_W+2]}},
    {IMM_SIGN_GROUP_W{head_imm1_stored_w[IMM_LOW_W+1]}},
    {IMM_SIGN_GROUP_W{head_imm1_stored_w[IMM_LOW_W]}},
    head_imm1_stored_w[IMM_LOW_W-1:0]
  };
  assign count_o = count_q;

  always @(posedge clk) begin
    if (rst) begin
      head_q <= FIFO_PTR_ZERO;
      tail_q <= FIFO_PTR_ZERO;
      count_q <= FIFO_COUNT_ZERO;
      head_valid_q <= 1'b0;
      head_packet_q <= {HEAD_PACKET_W{1'b0}};
      for (reset_idx = 0; reset_idx < FETCH_PACKET_COUNT;
           reset_idx = reset_idx + 1) begin
        pc0_q[reset_idx] <= {`XLEN{1'b0}};
        pc1_q[reset_idx] <= {`XLEN{1'b0}};
        next_pc0_q[reset_idx] <= {`XLEN{1'b0}};
        next_pc1_q[reset_idx] <= {`XLEN{1'b0}};
        packet_next_pc_q[reset_idx] <= {`XLEN{1'b0}};
        fault_tval_q[reset_idx] <= {`XLEN{1'b0}};
        inst0_q[reset_idx] <= {`INST_W{1'b0}};
        inst1_q[reset_idx] <= {`INST_W{1'b0}};
        ctrl0_q[reset_idx] <= {`CTRL_BUS_W{1'b0}};
        ctrl1_q[reset_idx] <= {`CTRL_BUS_W{1'b0}};
        static_facts0_q[reset_idx] <= {`OOO_SLOT_STATIC_FACTS_W{1'b0}};
        static_facts1_q[reset_idx] <= {`OOO_SLOT_STATIC_FACTS_W{1'b0}};
        rs1_0_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        rs2_0_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        rd0_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        imm0_q[reset_idx] <= {IMM_STORED_W{1'b0}};
        rs1_1_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        rs2_1_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        rd1_q[reset_idx] <= {`REG_ADDR_W{1'b0}};
        imm1_q[reset_idx] <= {IMM_STORED_W{1'b0}};
        resp0_q[reset_idx] <= 2'b00;
        resp1_q[reset_idx] <= 2'b00;
        pred_taken0_q[reset_idx] <= 1'b0;
        pred_taken1_q[reset_idx] <= 1'b0;
        bht_idx0_q[reset_idx] <= {`BPU_BHT_INDEX_W{1'b0}};
        bht_idx1_q[reset_idx] <= {`BPU_BHT_INDEX_W{1'b0}};
        bht_valid0_q[reset_idx] <= 1'b0;
        bht_valid1_q[reset_idx] <= 1'b0;
        slot1_valid_q[reset_idx] <= 1'b1;
      end
    end else if (clear_i) begin
      head_q <= FIFO_PTR_ZERO;
      tail_q <= FIFO_PTR_ZERO;
      count_q <= FIFO_COUNT_ZERO;
      head_valid_q <= 1'b0;
    end else begin
      if (enqueue_i) begin
        pc0_q[tail_q] <= enqueue_pc0_i;
        pc1_q[tail_q] <= enqueue_pc1_i;
        next_pc0_q[tail_q] <= enqueue_next_pc0_i;
        next_pc1_q[tail_q] <= enqueue_next_pc1_i;
        packet_next_pc_q[tail_q] <= enqueue_packet_next_pc_i;
        fault_tval_q[tail_q] <= enqueue_fault_tval_i;
        inst0_q[tail_q] <= enqueue_inst0_i;
        inst1_q[tail_q] <= enqueue_inst1_i;
        ctrl0_q[tail_q] <= enqueue_ctrl0_i;
        ctrl1_q[tail_q] <= enqueue_ctrl1_i;
        static_facts0_q[tail_q] <= enqueue_static_facts0_i;
        static_facts1_q[tail_q] <= enqueue_static_facts1_i;
        rs1_0_q[tail_q] <= enqueue_rs1_0_i;
        rs2_0_q[tail_q] <= enqueue_rs2_0_i;
        rd0_q[tail_q] <= enqueue_rd0_i;
        imm0_q[tail_q] <= enqueue_imm0_stored_w;
        rs1_1_q[tail_q] <= enqueue_rs1_1_i;
        rs2_1_q[tail_q] <= enqueue_rs2_1_i;
        rd1_q[tail_q] <= enqueue_rd1_i;
        imm1_q[tail_q] <= enqueue_imm1_stored_w;
        resp0_q[tail_q] <= enqueue_resp0_i;
        resp1_q[tail_q] <= enqueue_resp1_i;
        pred_taken0_q[tail_q] <= enqueue_pred_taken0_i;
        pred_taken1_q[tail_q] <= enqueue_pred_taken1_i;
        bht_idx0_q[tail_q] <= enqueue_bht_idx0_i;
        bht_idx1_q[tail_q] <= enqueue_bht_idx1_i;
        bht_valid0_q[tail_q] <= enqueue_bht_valid0_i;
        bht_valid1_q[tail_q] <= enqueue_bht_valid1_i;
        slot1_valid_q[tail_q] <= enqueue_slot1_valid_i;
        tail_q <= ptr_inc(tail_q);
      end

      if (pop_i) begin
        head_q <= ptr_inc(head_q);
      end

      // Empty enqueue and one-entry pop+enqueue cannot read the new ring word
      // in this edge, so source the new head directly from the enqueue bundle.
      // For every other pop, the old ring word at head+1 is already stable.
      if (enqueue_i && ((count_q == FIFO_COUNT_ZERO) ||
                        (pop_i && (count_q == FIFO_COUNT_ONE)))) begin
        head_packet_q <= {
          enqueue_pc0_i,
          enqueue_pc1_i,
          enqueue_next_pc0_i,
          enqueue_next_pc1_i,
          enqueue_packet_next_pc_i,
          enqueue_fault_tval_i,
          enqueue_inst0_i,
          enqueue_inst1_i,
          enqueue_ctrl0_i,
          enqueue_ctrl1_i,
          enqueue_static_facts0_i,
          enqueue_static_facts1_i,
          enqueue_rs1_0_i,
          enqueue_rs2_0_i,
          enqueue_rd0_i,
          enqueue_imm0_stored_w,
          enqueue_rs1_1_i,
          enqueue_rs2_1_i,
          enqueue_rd1_i,
          enqueue_imm1_stored_w,
          enqueue_resp0_i,
          enqueue_resp1_i,
          enqueue_pred_taken0_i,
          enqueue_pred_taken1_i,
          enqueue_bht_idx0_i,
          enqueue_bht_idx1_i,
          enqueue_bht_valid0_i,
          enqueue_bht_valid1_i,
          enqueue_slot1_valid_i
        };
      end else if (pop_i && (count_q > FIFO_COUNT_ONE)) begin
        head_packet_q <= {
          pc0_q[ptr_inc(head_q)],
          pc1_q[ptr_inc(head_q)],
          next_pc0_q[ptr_inc(head_q)],
          next_pc1_q[ptr_inc(head_q)],
          packet_next_pc_q[ptr_inc(head_q)],
          fault_tval_q[ptr_inc(head_q)],
          inst0_q[ptr_inc(head_q)],
          inst1_q[ptr_inc(head_q)],
          ctrl0_q[ptr_inc(head_q)],
          ctrl1_q[ptr_inc(head_q)],
          static_facts0_q[ptr_inc(head_q)],
          static_facts1_q[ptr_inc(head_q)],
          rs1_0_q[ptr_inc(head_q)],
          rs2_0_q[ptr_inc(head_q)],
          rd0_q[ptr_inc(head_q)],
          imm0_q[ptr_inc(head_q)],
          rs1_1_q[ptr_inc(head_q)],
          rs2_1_q[ptr_inc(head_q)],
          rd1_q[ptr_inc(head_q)],
          imm1_q[ptr_inc(head_q)],
          resp0_q[ptr_inc(head_q)],
          resp1_q[ptr_inc(head_q)],
          pred_taken0_q[ptr_inc(head_q)],
          pred_taken1_q[ptr_inc(head_q)],
          bht_idx0_q[ptr_inc(head_q)],
          bht_idx1_q[ptr_inc(head_q)],
          bht_valid0_q[ptr_inc(head_q)],
          bht_valid1_q[ptr_inc(head_q)],
          slot1_valid_q[ptr_inc(head_q)]
        };
      end

      case ({enqueue_i, pop_i})
        2'b10: begin
          count_q <= count_q + FIFO_COUNT_ONE;
          head_valid_q <= 1'b1;
        end
        2'b01: begin
          count_q <= count_q - FIFO_COUNT_ONE;
          head_valid_q <= (count_q > FIFO_COUNT_ONE);
        end
        default: begin
          count_q <= count_q;
          head_valid_q <= head_valid_q;
        end
      endcase
    end
  end

`ifdef OOO_ASSERT
  // ── 契约② 反压/无溢出（architecture-first 立即断言，见 interface-contract-first.instructions.md）──
  // 不变量：fetch packet FIFO 占用 count_q 永不超过物理深度 FETCH_PACKET_COUNT。
  // 证据：count_q(第62行) 更新仅 ±1(第148/149行)，物理深度 = 1<<OOO_FETCH_PACKET_COUNT_W = 4。
  // 立即断言（过程式 $error，Verilator/iverilog 双仿真器通吃，非 SVA），仅在 +define+OOO_ASSERT 时编入，synth 不含。
  always @(posedge clk) begin
    if (!rst &&
        !(((clear_i === 1'b0) || (clear_i === 1'b1)) &&
          ((enqueue_i === 1'b0) || (enqueue_i === 1'b1)) &&
          ((pop_i === 1'b0) || (pop_i === 1'b1)))) begin
      $error("[CONTRACT-FIFO-CONTROL-KNOWN] FIFO action control contains X/Z");
      $fatal;
    end
    if (!rst && !clear_i && enqueue_i &&
        ((enqueue_imm0_i[`XLEN-1:IMM_LOW_W] !==
          {(`XLEN-IMM_LOW_W){enqueue_imm0_i[IMM_LOW_W-1]}}) ||
         (enqueue_imm1_i[`XLEN-1:IMM_LOW_W] !==
          {(`XLEN-IMM_LOW_W){enqueue_imm1_i[IMM_LOW_W-1]}}))) begin
      $error("[IFU-R2P4-IMM-CANONICAL] enqueue immediate is not an RV64 sign extension");
      $fatal;
    end
    if (!rst && (count_q > FETCH_PACKET_COUNT[FETCH_COUNT_W-1:0])) begin
      $error("[CONTRACT-FIFO-OVFL] OooFetchPacketFifo count_q=%0d exceeds depth=%0d",
             count_q, FETCH_PACKET_COUNT);
      $fatal;
    end
    if (!rst && !clear_i && pop_i && (count_q == FIFO_COUNT_ZERO)) begin
      $error("[CONTRACT-FIFO-UNDERFLOW] OooFetchPacketFifo pop while empty");
      $fatal;
    end
    if (!rst && !clear_i && enqueue_i && !pop_i &&
        (count_q == FETCH_PACKET_COUNT[FETCH_COUNT_W-1:0])) begin
      $error("[CONTRACT-FIFO-OVFL-REQUEST] OooFetchPacketFifo enqueue while full");
      $fatal;
    end
    if (!rst && (head_valid_q !== (count_q != FIFO_COUNT_ZERO))) begin
      $error("[T4B-FIFO-HEAD-PRESENCE] registered presence differs from occupancy");
      $fatal;
    end
    if (!rst && (count_q != FIFO_COUNT_ZERO) &&
        (head_packet_q !== {
          pc0_q[head_q],
          pc1_q[head_q],
          next_pc0_q[head_q],
          next_pc1_q[head_q],
          packet_next_pc_q[head_q],
          fault_tval_q[head_q],
          inst0_q[head_q],
          inst1_q[head_q],
          ctrl0_q[head_q],
          ctrl1_q[head_q],
          static_facts0_q[head_q],
          static_facts1_q[head_q],
          rs1_0_q[head_q],
          rs2_0_q[head_q],
          rd0_q[head_q],
          imm0_q[head_q],
          rs1_1_q[head_q],
          rs2_1_q[head_q],
          rd1_q[head_q],
          imm1_q[head_q],
          resp0_q[head_q],
          resp1_q[head_q],
          pred_taken0_q[head_q],
          pred_taken1_q[head_q],
          bht_idx0_q[head_q],
          bht_idx1_q[head_q],
          bht_valid0_q[head_q],
          bht_valid1_q[head_q],
          slot1_valid_q[head_q]
        })) begin
      $error("[T3W-FIFO-HEAD-SHADOW] registered head differs from ring owner");
      $fatal;
    end
  end
`endif

endmodule
