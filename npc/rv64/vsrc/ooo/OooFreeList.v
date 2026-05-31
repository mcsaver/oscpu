`include "define.v"

// 物理寄存器 freelist 先作为 OoO 后端的独立环形队列验证。
// 释放项下一拍再可分配，避免和 ROB commit/rename 的时序边界过早耦合。
module OooFreeList #(
  parameter PHY_REG_COUNT = 64,
  parameter PHY_REG_ADDR_W = 6,
  parameter ARCH_REG_COUNT = 32,
  parameter FREE_COUNT_W = 7
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,

  input alloc0_valid_i,
  output alloc0_ready_o,
  output [PHY_REG_ADDR_W-1:0] alloc0_preg_o,
  input alloc1_valid_i,
  output alloc1_ready_o,
  output [PHY_REG_ADDR_W-1:0] alloc1_preg_o,

  input free0_valid_i,
  input [PHY_REG_ADDR_W-1:0] free0_preg_i,
  input free1_valid_i,
  input [PHY_REG_ADDR_W-1:0] free1_preg_i,

  output [FREE_COUNT_W-1:0] free_count_o,
  output empty_o,
  output full_o
);

  localparam [FREE_COUNT_W-1:0] INIT_FREE_COUNT = PHY_REG_COUNT - ARCH_REG_COUNT;
  localparam [FREE_COUNT_W-1:0] PHY_REG_COUNT_COUNT = PHY_REG_COUNT[FREE_COUNT_W-1:0];
  localparam [PHY_REG_ADDR_W-1:0] ARCH_REG_BASE = ARCH_REG_COUNT[PHY_REG_ADDR_W-1:0];

  reg [PHY_REG_ADDR_W-1:0] fifo_q [0:PHY_REG_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] head_q;
  reg [PHY_REG_ADDR_W-1:0] tail_q;
  reg [FREE_COUNT_W-1:0] count_q;
  reg [PHY_REG_ADDR_W-1:0] checkpoint_fifo_q [0:PHY_REG_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_head_q;
  reg [PHY_REG_ADDR_W-1:0] checkpoint_tail_q;
  reg [FREE_COUNT_W-1:0] checkpoint_count_q;

  wire alloc0_fire_w;
  wire alloc1_fire_w;
  wire [1:0] alloc_count_w;

  integer idx;
  reg [1:0] push_count;
  reg [FREE_COUNT_W-1:0] next_count;

  function [PHY_REG_ADDR_W-1:0] ptr_add;
    input [PHY_REG_ADDR_W-1:0] base;
    input [1:0] inc;
    begin
      ptr_add = base + {{(PHY_REG_ADDR_W-2){1'b0}}, inc};
    end
  endfunction

  assign alloc0_ready_o = (count_q != {FREE_COUNT_W{1'b0}});
  assign alloc0_fire_w = alloc0_valid_i && alloc0_ready_o;
  assign alloc1_ready_o = (count_q > {{(FREE_COUNT_W-1){1'b0}}, alloc0_fire_w});
  assign alloc1_fire_w = alloc1_valid_i && alloc1_ready_o;
  assign alloc_count_w = {1'b0, alloc0_fire_w} + {1'b0, alloc1_fire_w};

  assign alloc0_preg_o = fifo_q[head_q];
  assign alloc1_preg_o = fifo_q[ptr_add(head_q, {1'b0, alloc0_fire_w})];
  assign free_count_o = count_q;
  assign empty_o = (count_q == {FREE_COUNT_W{1'b0}});
  assign full_o = (count_q == PHY_REG_COUNT_COUNT);

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        if (idx < INIT_FREE_COUNT) begin
          fifo_q[idx] <= ARCH_REG_BASE + idx[PHY_REG_ADDR_W-1:0];
          checkpoint_fifo_q[idx] <= ARCH_REG_BASE + idx[PHY_REG_ADDR_W-1:0];
        end else begin
          fifo_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
          checkpoint_fifo_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        end
      end
      head_q <= {PHY_REG_ADDR_W{1'b0}};
      tail_q <= INIT_FREE_COUNT[PHY_REG_ADDR_W-1:0];
      count_q <= INIT_FREE_COUNT;
      checkpoint_head_q <= {PHY_REG_ADDR_W{1'b0}};
      checkpoint_tail_q <= INIT_FREE_COUNT[PHY_REG_ADDR_W-1:0];
      checkpoint_count_q <= INIT_FREE_COUNT;
    end else if (checkpoint_restore_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        fifo_q[idx] <= checkpoint_fifo_q[idx];
      end
      head_q <= checkpoint_head_q;
      tail_q <= checkpoint_tail_q;
      count_q <= checkpoint_count_q;
    end else if (checkpoint_capture_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        checkpoint_fifo_q[idx] <= fifo_q[idx];
      end
      checkpoint_head_q <= head_q;
      checkpoint_tail_q <= tail_q;
      checkpoint_count_q <= count_q;
    end else begin
      /* verilator lint_off BLKSEQ */
      push_count = 2'd0;
      next_count = count_q - {{(FREE_COUNT_W-2){1'b0}}, alloc_count_w};

      if (free0_valid_i && (free0_preg_i != {PHY_REG_ADDR_W{1'b0}}) &&
          (next_count < PHY_REG_COUNT_COUNT)) begin
        fifo_q[ptr_add(tail_q, push_count[1:0])] <= free0_preg_i;
        push_count = push_count + 2'd1;
        next_count = next_count + {{(FREE_COUNT_W-1){1'b0}}, 1'b1};
      end

      if (free1_valid_i && (free1_preg_i != {PHY_REG_ADDR_W{1'b0}}) &&
          (next_count < PHY_REG_COUNT_COUNT)) begin
        fifo_q[ptr_add(tail_q, push_count[1:0])] <= free1_preg_i;
        push_count = push_count + 2'd1;
        next_count = next_count + {{(FREE_COUNT_W-1){1'b0}}, 1'b1};
      end
      /* verilator lint_on BLKSEQ */

      head_q <= ptr_add(head_q, alloc_count_w);
      tail_q <= ptr_add(tail_q, push_count[1:0]);
      count_q <= next_count[FREE_COUNT_W-1:0];
    end
  end

endmodule
