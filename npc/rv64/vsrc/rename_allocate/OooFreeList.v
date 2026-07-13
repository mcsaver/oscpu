`include "define.v"

// 物理寄存器 freelist 先作为 OoO 后端的独立环形队列验证。
// 释放项下一拍再可分配，避免和 ROB commit/rename 的时序边界过早耦合。
module OooFreeList #(
  parameter PHY_REG_COUNT = `OOO_PHY_REG_COUNT,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ARCH_REG_COUNT = `REG_NUM,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W
) (
  input clk,
  input rst,
  input flush_i,

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

  wire alloc0_fire_w;
  wire alloc1_fire_w;
  wire [1:0] alloc_count_w;

  integer idx;

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

  // 时序优化：原 alloc1 = fifo_q[head+alloc0_fire] 把 alloc0_fire 喂进 64:1 mux 索引,
  // 处于关键路径(count→alloc0_fire→alloc1→busy_table)。改为并行读 head 与 head+1,
  // alloc0_fire 只过一个浅 2:1 select。行为完全等价(fifo[head+fire])。
  wire [PHY_REG_ADDR_W-1:0] fifo_head0_w = fifo_q[head_q];
  wire [PHY_REG_ADDR_W-1:0] fifo_head1_w = fifo_q[ptr_add(head_q, 2'd1)];
  assign alloc0_preg_o = fifo_head0_w;
  assign alloc1_preg_o = alloc0_fire_w ? fifo_head1_w : fifo_head0_w;
  assign free_count_o = count_q;
  assign empty_o = (count_q == {FREE_COUNT_W{1'b0}});
  assign full_o = (count_q == PHY_REG_COUNT_COUNT);

  wire [FREE_COUNT_W-1:0] post_alloc_count_w =
      count_q - {{(FREE_COUNT_W-2){1'b0}}, alloc_count_w};
  wire free0_push_w =
      free0_valid_i && (free0_preg_i != {PHY_REG_ADDR_W{1'b0}}) &&
      (post_alloc_count_w < PHY_REG_COUNT_COUNT);
  wire [FREE_COUNT_W-1:0] post_free0_count_w =
      post_alloc_count_w + {{(FREE_COUNT_W-1){1'b0}}, free0_push_w};
  wire free1_push_w =
      free1_valid_i && (free1_preg_i != {PHY_REG_ADDR_W{1'b0}}) &&
      (post_free0_count_w < PHY_REG_COUNT_COUNT);
  wire [1:0] push_count_w =
      {1'b0, free0_push_w} + {1'b0, free1_push_w};
  wire [FREE_COUNT_W-1:0] next_count_w =
      post_free0_count_w + {{(FREE_COUNT_W-1){1'b0}}, free1_push_w};
  wire [PHY_REG_ADDR_W-1:0] free1_tail_w =
      ptr_add(tail_q, {1'b0, free0_push_w});

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        if (idx < INIT_FREE_COUNT) begin
          fifo_q[idx] <= ARCH_REG_BASE + idx[PHY_REG_ADDR_W-1:0];
        end else begin
          fifo_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        end
      end
      head_q <= {PHY_REG_ADDR_W{1'b0}};
      tail_q <= INIT_FREE_COUNT[PHY_REG_ADDR_W-1:0];
      count_q <= INIT_FREE_COUNT;
    end else begin
      // 正常路径的 push/count 先由组合逻辑推导，时序块只落状态。
      if (free0_push_w) begin
        fifo_q[tail_q] <= free0_preg_i;
      end

      if (free1_push_w) begin
        fifo_q[free1_tail_w] <= free1_preg_i;
      end

      head_q <= ptr_add(head_q, alloc_count_w);
      tail_q <= ptr_add(tail_q, push_count_w);
      count_q <= next_count_w;
    end
  end

endmodule
