`include "define.v"

// Front-end fetch packet FIFO storage primitive.
// Redirect, bypass and outstanding-response policy stay in OooCoreTopGlue.
module OooFetchPacketFifo #(
  parameter FETCH_PACKET_COUNT_W = `OOO_FETCH_PACKET_COUNT_W,
  parameter FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1
) (
  input clk,
  input rst,

  input clear_i,
  input seed_valid_i,
  input [`XLEN-1:0] seed_pc0_i,
  input [`XLEN-1:0] seed_pc1_i,
  input [`XLEN-1:0] seed_next_pc0_i,
  input [`XLEN-1:0] seed_next_pc1_i,
  input [`XLEN-1:0] seed_packet_next_pc_i,
  input [`INST_W-1:0] seed_inst0_i,
  input [`INST_W-1:0] seed_inst1_i,
  input [1:0] seed_resp0_i,
  input [1:0] seed_resp1_i,
  // 【B2 S1】per-slot 预测位(resp 拍 BPU lookup 一次定格, 随包存储;
  // dispatch 拍只消费存储位, 活查询口物理断开——F2 #105 两点查询分歧教训)。
  input seed_pred_taken0_i,
  input seed_pred_taken1_i,
  input [`BPU_BHT_INDEX_W-1:0] seed_bht_idx0_i,
  input [`BPU_BHT_INDEX_W-1:0] seed_bht_idx1_i,
  input seed_bht_valid0_i,
  input seed_bht_valid1_i,
  // 【B2 S2】slot1 截断位: slot0 预测 taken 时包内截断(slot1=wrong-path, 随包存 0),
  // head1 谓词族在 OooFetchHeadPairGate facts 生成处单点门控。
  input seed_slot1_valid_i,

  input enqueue_i,
  input [`XLEN-1:0] enqueue_pc0_i,
  input [`XLEN-1:0] enqueue_pc1_i,
  input [`XLEN-1:0] enqueue_next_pc0_i,
  input [`XLEN-1:0] enqueue_next_pc1_i,
  input [`XLEN-1:0] enqueue_packet_next_pc_i,
  input [`INST_W-1:0] enqueue_inst0_i,
  input [`INST_W-1:0] enqueue_inst1_i,
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
  output [`INST_W-1:0] head_inst0_o,
  output [`INST_W-1:0] head_inst1_o,
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

  reg [FETCH_PACKET_COUNT_W-1:0] head_q;
  reg [FETCH_PACKET_COUNT_W-1:0] tail_q;
  reg [FETCH_COUNT_W-1:0] count_q;
  reg [`XLEN-1:0] pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] next_pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] next_pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] packet_next_pc_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] inst0_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] inst1_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] resp0_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] resp1_q [0:FETCH_PACKET_COUNT-1];
  reg pred_taken0_q [0:FETCH_PACKET_COUNT-1];
  reg pred_taken1_q [0:FETCH_PACKET_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx0_q [0:FETCH_PACKET_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx1_q [0:FETCH_PACKET_COUNT-1];
  reg bht_valid0_q [0:FETCH_PACKET_COUNT-1];
  reg bht_valid1_q [0:FETCH_PACKET_COUNT-1];
  reg slot1_valid_q [0:FETCH_PACKET_COUNT-1];

  integer reset_idx;

  function [FETCH_PACKET_COUNT_W-1:0] ptr_inc;
    input [FETCH_PACKET_COUNT_W-1:0] ptr;
    begin
      ptr_inc = ptr + FIFO_PTR_ONE;
    end
  endfunction

  assign head_valid_o = (count_q != FIFO_COUNT_ZERO);
  assign head_pc0_o = pc0_q[head_q];
  assign head_pc1_o = pc1_q[head_q];
  assign head_next_pc0_o = next_pc0_q[head_q];
  assign head_next_pc1_o = next_pc1_q[head_q];
  assign head_packet_next_pc_o = packet_next_pc_q[head_q];
  assign head_inst0_o = inst0_q[head_q];
  assign head_inst1_o = inst1_q[head_q];
  assign head_resp0_o = resp0_q[head_q];
  assign head_resp1_o = resp1_q[head_q];
  assign head_pred_taken0_o = pred_taken0_q[head_q];
  assign head_pred_taken1_o = pred_taken1_q[head_q];
  assign head_bht_idx0_o = bht_idx0_q[head_q];
  assign head_bht_idx1_o = bht_idx1_q[head_q];
  assign head_bht_valid0_o = bht_valid0_q[head_q];
  assign head_bht_valid1_o = bht_valid1_q[head_q];
  assign head_slot1_valid_o = slot1_valid_q[head_q];
  assign count_o = count_q;

  always @(posedge clk) begin
    if (rst) begin
      head_q <= FIFO_PTR_ZERO;
      tail_q <= FIFO_PTR_ZERO;
      count_q <= FIFO_COUNT_ZERO;
      for (reset_idx = 0; reset_idx < FETCH_PACKET_COUNT;
           reset_idx = reset_idx + 1) begin
        pc0_q[reset_idx] <= {`XLEN{1'b0}};
        pc1_q[reset_idx] <= {`XLEN{1'b0}};
        next_pc0_q[reset_idx] <= {`XLEN{1'b0}};
        next_pc1_q[reset_idx] <= {`XLEN{1'b0}};
        packet_next_pc_q[reset_idx] <= {`XLEN{1'b0}};
        inst0_q[reset_idx] <= {`INST_W{1'b0}};
        inst1_q[reset_idx] <= {`INST_W{1'b0}};
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
    end else if (seed_valid_i) begin
      head_q <= FIFO_PTR_ZERO;
      tail_q <= FIFO_PTR_ONE;
      count_q <= FIFO_COUNT_ONE;
      pc0_q[FIFO_PTR_ZERO] <= seed_pc0_i;
      pc1_q[FIFO_PTR_ZERO] <= seed_pc1_i;
      next_pc0_q[FIFO_PTR_ZERO] <= seed_next_pc0_i;
      next_pc1_q[FIFO_PTR_ZERO] <= seed_next_pc1_i;
      packet_next_pc_q[FIFO_PTR_ZERO] <= seed_packet_next_pc_i;
      inst0_q[FIFO_PTR_ZERO] <= seed_inst0_i;
      inst1_q[FIFO_PTR_ZERO] <= seed_inst1_i;
      resp0_q[FIFO_PTR_ZERO] <= seed_resp0_i;
      resp1_q[FIFO_PTR_ZERO] <= seed_resp1_i;
      pred_taken0_q[FIFO_PTR_ZERO] <= seed_pred_taken0_i;
      pred_taken1_q[FIFO_PTR_ZERO] <= seed_pred_taken1_i;
      bht_idx0_q[FIFO_PTR_ZERO] <= seed_bht_idx0_i;
      bht_idx1_q[FIFO_PTR_ZERO] <= seed_bht_idx1_i;
      bht_valid0_q[FIFO_PTR_ZERO] <= seed_bht_valid0_i;
      bht_valid1_q[FIFO_PTR_ZERO] <= seed_bht_valid1_i;
      slot1_valid_q[FIFO_PTR_ZERO] <= seed_slot1_valid_i;
    end else begin
      if (enqueue_i) begin
        pc0_q[tail_q] <= enqueue_pc0_i;
        pc1_q[tail_q] <= enqueue_pc1_i;
        next_pc0_q[tail_q] <= enqueue_next_pc0_i;
        next_pc1_q[tail_q] <= enqueue_next_pc1_i;
        packet_next_pc_q[tail_q] <= enqueue_packet_next_pc_i;
        inst0_q[tail_q] <= enqueue_inst0_i;
        inst1_q[tail_q] <= enqueue_inst1_i;
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

      case ({enqueue_i, pop_i})
        2'b10: count_q <= count_q + FIFO_COUNT_ONE;
        2'b01: count_q <= count_q - FIFO_COUNT_ONE;
        default: count_q <= count_q;
      endcase
    end
  end

`ifdef OOO_ASSERT
  // ── 契约② 反压/无溢出（architecture-first 立即断言，见 interface-contract-first.instructions.md）──
  // 不变量：fetch packet FIFO 占用 count_q 永不超过物理深度 FETCH_PACKET_COUNT。
  // 证据：count_q(第62行) 更新仅 ±1(第148/149行)，物理深度 = 1<<OOO_FETCH_PACKET_COUNT_W = 4。
  // 立即断言（过程式 $error，Verilator/iverilog 双仿真器通吃，非 SVA），仅在 +define+OOO_ASSERT 时编入，synth 不含。
  always @(posedge clk) begin
    if (!rst && (count_q > FETCH_PACKET_COUNT[FETCH_COUNT_W-1:0])) begin
      $error("[CONTRACT-FIFO-OVFL] OooFetchPacketFifo count_q=%0d exceeds depth=%0d",
             count_q, FETCH_PACKET_COUNT);
      $fatal;
    end
  end
`endif

endmodule
