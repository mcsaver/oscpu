`include "define.v"

// Busy table 是 rename/issue 之间的唤醒边界：分配新 pdest 时标记未就绪，
// 执行单元 writeback 时标记就绪，组合查询给 issue queue 判断操作数是否可发射。
module OooBusyTable #(
  parameter PHY_REG_COUNT = `OOO_PHY_REG_COUNT,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,

  input alloc0_valid_i,
  input [PHY_REG_ADDR_W-1:0] alloc0_pdest_i,
  input alloc1_valid_i,
  input [PHY_REG_ADDR_W-1:0] alloc1_pdest_i,

  input wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup0_pdest_i,
  input wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup1_pdest_i,

  input [PHY_REG_ADDR_W-1:0] query0_preg_i,
  output query0_ready_o,
  input [PHY_REG_ADDR_W-1:0] query1_preg_i,
  output query1_ready_o,
  input [PHY_REG_ADDR_W-1:0] query2_preg_i,
  output query2_ready_o,
  input [PHY_REG_ADDR_W-1:0] query3_preg_i,
  output query3_ready_o
);

  reg ready_q [0:PHY_REG_COUNT-1];
  reg checkpoint_ready_q [0:PHY_REG_COUNT-1];
  integer idx;

  wire alloc0_real_w = alloc0_valid_i && (alloc0_pdest_i != {PHY_REG_ADDR_W{1'b0}});
  wire alloc1_real_w = alloc1_valid_i && (alloc1_pdest_i != {PHY_REG_ADDR_W{1'b0}});
  wire wakeup0_real_w = wakeup0_valid_i && (wakeup0_pdest_i != {PHY_REG_ADDR_W{1'b0}});
  wire wakeup1_real_w = wakeup1_valid_i && (wakeup1_pdest_i != {PHY_REG_ADDR_W{1'b0}});

  function query_ready;
    input [PHY_REG_ADDR_W-1:0] preg;
    input alloc0_real;
    input [PHY_REG_ADDR_W-1:0] alloc0_pdest;
    input alloc1_real;
    input [PHY_REG_ADDR_W-1:0] alloc1_pdest;
    input wakeup0_real;
    input [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
    input wakeup1_real;
    input [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
    begin
      if (preg == {PHY_REG_ADDR_W{1'b0}}) begin
        query_ready = 1'b1;
      end else if ((alloc0_real && (alloc0_pdest == preg)) ||
                   (alloc1_real && (alloc1_pdest == preg))) begin
        query_ready = 1'b0;
      end else if ((wakeup0_real && (wakeup0_pdest == preg)) ||
                   (wakeup1_real && (wakeup1_pdest == preg))) begin
        query_ready = 1'b1;
      end else begin
        query_ready = ready_q[preg];
      end
    end
  endfunction

  assign query0_ready_o = query_ready(query0_preg_i,
                                      alloc0_real_w, alloc0_pdest_i,
                                      alloc1_real_w, alloc1_pdest_i,
                                      wakeup0_real_w, wakeup0_pdest_i,
                                      wakeup1_real_w, wakeup1_pdest_i);
  assign query1_ready_o = query_ready(query1_preg_i,
                                      alloc0_real_w, alloc0_pdest_i,
                                      alloc1_real_w, alloc1_pdest_i,
                                      wakeup0_real_w, wakeup0_pdest_i,
                                      wakeup1_real_w, wakeup1_pdest_i);
  assign query2_ready_o = query_ready(query2_preg_i,
                                      alloc0_real_w, alloc0_pdest_i,
                                      alloc1_real_w, alloc1_pdest_i,
                                      wakeup0_real_w, wakeup0_pdest_i,
                                      wakeup1_real_w, wakeup1_pdest_i);
  assign query3_ready_o = query_ready(query3_preg_i,
                                      alloc0_real_w, alloc0_pdest_i,
                                      alloc1_real_w, alloc1_pdest_i,
                                      wakeup0_real_w, wakeup0_pdest_i,
                                      wakeup1_real_w, wakeup1_pdest_i);

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        ready_q[idx] <= 1'b1;
        checkpoint_ready_q[idx] <= 1'b1;
      end
    end else if (checkpoint_restore_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        ready_q[idx] <= checkpoint_ready_q[idx];
      end
    end else if (checkpoint_capture_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        checkpoint_ready_q[idx] <= ready_q[idx];
      end
    end else begin
      if (wakeup0_real_w) begin
        ready_q[wakeup0_pdest_i] <= 1'b1;
      end
      if (wakeup1_real_w) begin
        ready_q[wakeup1_pdest_i] <= 1'b1;
      end
      if (alloc0_real_w) begin
        ready_q[alloc0_pdest_i] <= 1'b0;
      end
      if (alloc1_real_w) begin
        // allocate 晚于 wakeup 生效，避免同拍重用物理寄存器时被错误认为 ready。
        ready_q[alloc1_pdest_i] <= 1'b0;
      end
    end
  end

endmodule
