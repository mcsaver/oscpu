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

endmodule
