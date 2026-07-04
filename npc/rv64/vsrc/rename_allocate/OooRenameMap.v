`include "define.v"

// OoO 第一阶段先把重命名表做成独立基础件：它只维护 speculative map，
// 误预测精确恢复由 ROB-walk 反向 restore（restore_valid_i 端口）在统一边界上完成。
/* verilator lint_off UNOPTFLAT */
// FP 交叉查询面的保守判环族(见 OooIntBackend 头注), 行为由全量测试守。
module OooRenameMap #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input flush_i,

  input rename0_valid_i,
  input [`REG_ADDR_W-1:0] rename0_rs1_arch_i,
  input [`REG_ADDR_W-1:0] rename0_rs2_arch_i,
  input rename0_rd_en_i,
  input [`REG_ADDR_W-1:0] rename0_rd_arch_i,
  input [PHY_REG_ADDR_W-1:0] rename0_new_pdest_i,
  output [PHY_REG_ADDR_W-1:0] rename0_rs1_preg_o,
  output [PHY_REG_ADDR_W-1:0] rename0_rs2_preg_o,
  output [PHY_REG_ADDR_W-1:0] rename0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] rename0_new_pdest_o,

  input rename1_valid_i,
  input [`REG_ADDR_W-1:0] rename1_rs1_arch_i,
  input [`REG_ADDR_W-1:0] rename1_rs2_arch_i,
  input rename1_rd_en_i,
  input [`REG_ADDR_W-1:0] rename1_rd_arch_i,
  input [PHY_REG_ADDR_W-1:0] rename1_new_pdest_i,
  output [PHY_REG_ADDR_W-1:0] rename1_rs1_preg_o,
  output [PHY_REG_ADDR_W-1:0] rename1_rs2_preg_o,
  output [PHY_REG_ADDR_W-1:0] rename1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] rename1_new_pdest_o,

  // B2 ROB-walk 反向恢复端口：把 squashed uop 的 arch_rd 还原到其 old_pdest。
  // 消费 OooRob 的 walk{0,1}_{arch_rd,old_pdest,valid&&rd_en}。lane1 程序序更老 → 同拍 WAW 覆盖 lane0
  // （源序后写胜）→ 最老 squashed 写者的 old_pdest 最终留存=分支处的精确映射。详见 b2-branch-spec-redirect.md §4.1。
  // in-core 暂接 0（投机未启用）→ 行为中性。
  input restore_valid_i,
  input restore0_en_i,
  input [`REG_ADDR_W-1:0] restore0_arch_i,
  input [PHY_REG_ADDR_W-1:0] restore0_pdest_i,
  input restore1_en_i,
  input [`REG_ADDR_W-1:0] restore1_arch_i,
  input [PHY_REG_ADDR_W-1:0] restore1_pdest_i,

  output [PHY_REG_ADDR_W * `REG_NUM - 1:0] debug_map_o
);

  reg [PHY_REG_ADDR_W-1:0] map_q [0:`REG_NUM-1];

  wire lane0_writes_w = rename0_valid_i && rename0_rd_en_i &&
                        (rename0_rd_arch_i != {`REG_ADDR_W{1'b0}});
  wire lane1_writes_w = rename1_valid_i && rename1_rd_en_i &&
                        (rename1_rd_arch_i != {`REG_ADDR_W{1'b0}});

  integer idx;
  genvar dbg_i;

  function [PHY_REG_ADDR_W-1:0] map_after_lane0;
    input [`REG_ADDR_W-1:0] arch_idx;
    input lane0_writes;
    input [`REG_ADDR_W-1:0] lane0_rd_arch;
    input [PHY_REG_ADDR_W-1:0] lane0_new_pdest;
    begin
      if (arch_idx == {`REG_ADDR_W{1'b0}}) begin
        map_after_lane0 = {PHY_REG_ADDR_W{1'b0}};
      end else if (lane0_writes && (arch_idx == lane0_rd_arch)) begin
        map_after_lane0 = lane0_new_pdest;
      end else begin
        map_after_lane0 = map_q[arch_idx];
      end
    end
  endfunction

  assign rename0_rs1_preg_o = (rename0_rs1_arch_i == {`REG_ADDR_W{1'b0}}) ?
                              {PHY_REG_ADDR_W{1'b0}} : map_q[rename0_rs1_arch_i];
  assign rename0_rs2_preg_o = (rename0_rs2_arch_i == {`REG_ADDR_W{1'b0}}) ?
                              {PHY_REG_ADDR_W{1'b0}} : map_q[rename0_rs2_arch_i];
  assign rename0_old_pdest_o = (rename0_rd_arch_i == {`REG_ADDR_W{1'b0}}) ?
                               {PHY_REG_ADDR_W{1'b0}} : map_q[rename0_rd_arch_i];
  assign rename0_new_pdest_o = lane0_writes_w ? rename0_new_pdest_i : {PHY_REG_ADDR_W{1'b0}};

  assign rename1_rs1_preg_o = map_after_lane0(rename1_rs1_arch_i,
                                              lane0_writes_w,
                                              rename0_rd_arch_i,
                                              rename0_new_pdest_i);
  assign rename1_rs2_preg_o = map_after_lane0(rename1_rs2_arch_i,
                                              lane0_writes_w,
                                              rename0_rd_arch_i,
                                              rename0_new_pdest_i);
  assign rename1_old_pdest_o = map_after_lane0(rename1_rd_arch_i,
                                               lane0_writes_w,
                                               rename0_rd_arch_i,
                                               rename0_new_pdest_i);
  assign rename1_new_pdest_o = lane1_writes_w ? rename1_new_pdest_i : {PHY_REG_ADDR_W{1'b0}};

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (idx = 0; idx < `REG_NUM; idx = idx + 1) begin
        map_q[idx] <= idx[PHY_REG_ADDR_W-1:0];
      end
    end else if (restore_valid_i) begin
      // ROB-walk 恢复：lane0=较年轻、lane1=较老；同拍 WAW 时 lane1 源序在后写胜（最老者留存）。
      if (restore0_en_i && (restore0_arch_i != {`REG_ADDR_W{1'b0}})) begin
        map_q[restore0_arch_i] <= restore0_pdest_i;
      end
      if (restore1_en_i && (restore1_arch_i != {`REG_ADDR_W{1'b0}})) begin
        map_q[restore1_arch_i] <= restore1_pdest_i;
      end
    end else begin
      if (lane0_writes_w) begin
        map_q[rename0_rd_arch_i] <= rename0_new_pdest_i;
      end
      if (lane1_writes_w) begin
        // lane1 程序序更年轻，同拍 WAW 时覆盖 lane0，保证 speculative map 指向最新定义。
        map_q[rename1_rd_arch_i] <= rename1_new_pdest_i;
      end
    end
  end

  generate
    for (dbg_i = 0; dbg_i < `REG_NUM; dbg_i = dbg_i + 1) begin : gen_debug_map
      assign debug_map_o[dbg_i * PHY_REG_ADDR_W +: PHY_REG_ADDR_W] = map_q[dbg_i];
    end
  endgenerate

endmodule
/* verilator lint_on UNOPTFLAT */
