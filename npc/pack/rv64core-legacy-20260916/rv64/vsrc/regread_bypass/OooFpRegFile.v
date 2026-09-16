`include "define.v"

// FPR 独立于前端取指/CSR 控制；该模块只负责 FP 寄存器状态、读端口和两类写回。
// 架构 FPR: 只随 rst 清零。flush 清零语义已删除(体检 footgun: 架构寄存器堆若被误接
// 真实流水线 flush 会摧毁架构 FP 状态; 原端口恒接 1'b0 属死代码)。
module OooFpRegFile (
  input clk,
  input rst,

  input [`REG_ADDR_W-1:0] read0_addr_i,
  output [`XLEN-1:0] read0_data_o,
  input [`REG_ADDR_W-1:0] read1_addr_i,
  output [`XLEN-1:0] read1_data_o,
  input [`REG_ADDR_W-1:0] read2_addr_i,
  output [`XLEN-1:0] read2_data_o,

  input load_write_valid_i,
  input [`REG_ADDR_W-1:0] load_write_addr_i,
  input [`XLEN-1:0] load_write_data_i,

  input result_write_valid_i,
  input [`REG_ADDR_W-1:0] result_write_addr_i,
  input [`XLEN-1:0] result_write_data_i,

  // 【B-FP 簇】全量平铺导出: FP 物理堆 flush 恢复源(恒等模式, 照抄整数
  // ArchRegFile→PhysRegFile.recover 的 bulk 拷贝)。
  output [`XLEN * `REG_NUM - 1:0] fprs_o
);

  reg [`XLEN-1:0] fpr_q [0:`REG_NUM-1];
  integer reset_idx;

  genvar gf;
  generate
    for (gf = 0; gf < `REG_NUM; gf = gf + 1) begin : gen_fprs_flat
      assign fprs_o[gf * `XLEN +: `XLEN] = fpr_q[gf];
    end
  endgenerate

  assign read0_data_o = fpr_q[read0_addr_i];
  assign read1_data_o = fpr_q[read1_addr_i];
  assign read2_data_o = fpr_q[read2_addr_i];

  always @(posedge clk) begin
    if (rst) begin
      for (reset_idx = 0; reset_idx < `REG_NUM; reset_idx = reset_idx + 1) begin
        fpr_q[reset_idx] <= {`XLEN{1'b0}};
      end
    end else begin
      if (load_write_valid_i)
        fpr_q[load_write_addr_i] <= load_write_data_i;

      if (result_write_valid_i)
        fpr_q[result_write_addr_i] <= result_write_data_i;
    end
  end

endmodule
