`include "define.v"

// ROB commit 之后才更新架构 GPR：乱序执行可以提前写物理寄存器，
// 但 debug/difftest/异常边界只能观察已经按程序序退休的架构状态。
module OooArchRegFile (
  input clk,
  input rst,

  input commit0_valid_i,
  input commit0_rd_en_i,
  input [`REG_ADDR_W-1:0] commit0_arch_rd_i,
  input [`XLEN-1:0] commit0_data_i,
  input commit0_exception_i,

  input commit1_valid_i,
  input commit1_rd_en_i,
  input [`REG_ADDR_W-1:0] commit1_arch_rd_i,
  input [`XLEN-1:0] commit1_data_i,
  input commit1_exception_i,

  input serial_write_valid_i,
  input [`REG_ADDR_W-1:0] serial_write_arch_rd_i,
  input [`XLEN-1:0] serial_write_data_i,

  output commit0_write_o,
  output commit1_write_o,
  output [`XLEN-1:0] a0_data_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o
);

  reg [`XLEN-1:0] rf [0:`REG_NUM-1];
  integer idx;
  genvar dbg_i;
  wire serial_write_w;

  assign commit0_write_o = commit0_valid_i &&
                           commit0_rd_en_i &&
                           !commit0_exception_i &&
                           (commit0_arch_rd_i != {`REG_ADDR_W{1'b0}});
  assign commit1_write_o = commit1_valid_i &&
                           commit1_rd_en_i &&
                           !commit1_exception_i &&
                           (commit1_arch_rd_i != {`REG_ADDR_W{1'b0}});
  assign serial_write_w = serial_write_valid_i &&
                          (serial_write_arch_rd_i != {`REG_ADDR_W{1'b0}});

  always @(posedge clk) begin
    if (rst) begin
      for (idx = 0; idx < `REG_NUM; idx = idx + 1) begin
        rf[idx] <= {`XLEN{1'b0}};
      end
    end else begin
      if (commit0_write_o) begin
        rf[commit0_arch_rd_i] <= commit0_data_i;
      end
      if (commit1_write_o) begin
        rf[commit1_arch_rd_i] <= commit1_data_i;
      end
      if (serial_write_w) begin
        rf[serial_write_arch_rd_i] <= serial_write_data_i;
      end
    end
  end

  assign a0_data_o = rf[10];

  generate
    for (dbg_i = 0; dbg_i < `REG_NUM; dbg_i = dbg_i + 1) begin : gen_debug_gprs
      assign debug_gprs_o[dbg_i * `XLEN +: `XLEN] =
          (dbg_i == 0) ? {`XLEN{1'b0}} : rf[dbg_i];
    end
  endgenerate

endmodule
