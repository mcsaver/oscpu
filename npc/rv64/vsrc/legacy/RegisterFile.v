`include "define.v"

module RegisterFile (
  input clk,
  input rst,
  input [`REG_ADDR_W-1:0] rs1_addr_i,
  input [`REG_ADDR_W-1:0] rs2_addr_i,
  output [`XLEN-1:0] rs1_data_o,
  output [`XLEN-1:0] rs2_data_o,
  output [`XLEN-1:0] a0_data_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o,
  input wen_i,
  input [`REG_ADDR_W-1:0] waddr_i,
  input [`XLEN-1:0] wdata_i
);

  // 用双读单写和 x0 硬屏蔽建立稳定的架构状态接口，后续接 difftest/CSR 时不用再返工寄存器堆。
  reg [`XLEN-1:0] rf [0:`REG_NUM-1];
  integer idx;
  genvar dbg_i;

  always @(posedge clk) begin
    if (rst) begin
      for (idx = 0; idx < `REG_NUM; idx = idx + 1) begin
        rf[idx] <= {`XLEN{1'b0}};
      end
    end else if (wen_i && (waddr_i != {`REG_ADDR_W{1'b0}})) begin
      rf[waddr_i] <= wdata_i;
    end
  end

  assign rs1_data_o = (rs1_addr_i == {`REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} : rf[rs1_addr_i];
  assign rs2_data_o = (rs2_addr_i == {`REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} : rf[rs2_addr_i];
  assign a0_data_o = rf[10];

  // 这里把 32 个 GPR 压平成一条调试总线，方便 C++ monitor 统一读取寄存器快照而不侵入执行路径。
  // 改完后 info r / 表达式 / 监视点都能直接基于真实架构寄存器状态工作。
  generate
    for (dbg_i = 0; dbg_i < `REG_NUM; dbg_i = dbg_i + 1) begin : gen_debug_gprs
      assign debug_gprs_o[dbg_i * `XLEN +: `XLEN] = rf[dbg_i];
    end
  endgenerate
endmodule

