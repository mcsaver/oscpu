`include "define.v"

// 乱序后端使用物理寄存器承载 speculative 结果；这里提供 5R2W 基础件（read0-3=双发
// 整数发射源，read8=FP/Tensor 共享 GPR 源读；read4-7/9 死读口已随各自
// 死硅族物理删除）。
// T3M：全部读口只读已落账 regs_q，与整数/FP IQ sticky wake 周期对齐，禁止
// formal WB payload 组合反灌整数或 FP execute。
module OooPhysRegFile #(
  parameter PHY_REG_COUNT = `OOO_PHY_REG_COUNT,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input recover_i,
  input [`XLEN * `REG_NUM - 1:0] recover_gprs_i,

  input [PHY_REG_ADDR_W-1:0] read0_addr_i,
  output [`XLEN-1:0] read0_data_o,
  input [PHY_REG_ADDR_W-1:0] read1_addr_i,
  output [`XLEN-1:0] read1_data_o,
  input [PHY_REG_ADDR_W-1:0] read2_addr_i,
  output [`XLEN-1:0] read2_data_o,
  input [PHY_REG_ADDR_W-1:0] read3_addr_i,
  output [`XLEN-1:0] read3_data_o,
  input [PHY_REG_ADDR_W-1:0] read8_addr_i,
  output [`XLEN-1:0] read8_data_o,

  input write0_valid_i,
  input [PHY_REG_ADDR_W-1:0] write0_addr_i,
  input [`XLEN-1:0] write0_data_i,
  input write1_valid_i,
  input [PHY_REG_ADDR_W-1:0] write1_addr_i,
  input [`XLEN-1:0] write1_data_i
);

  reg [`XLEN-1:0] regs_q [0:PHY_REG_COUNT-1];
  integer idx;

  assign read0_data_o =
      (read0_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read0_addr_i];
  assign read1_data_o =
      (read1_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read1_addr_i];
  assign read2_data_o =
      (read2_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read2_addr_i];
  assign read3_data_o =
      (read3_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read3_addr_i];
  assign read8_data_o =
      (read8_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read8_addr_i];

`ifdef OOO_ASSERT
  // T3M：五个读口都必须只观察沿上已落账状态。force 输出的负探针与
  // 可编译 write-through mutation 分别证明 marker 和行为检查不是空绿。
  always @(posedge clk) begin
    if (!rst &&
        ({read0_data_o, read1_data_o, read2_data_o, read3_data_o,
          read8_data_o} !==
         {(read0_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                     regs_q[read0_addr_i],
          (read1_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                     regs_q[read1_addr_i],
          (read2_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                     regs_q[read2_addr_i],
          (read3_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                     regs_q[read3_addr_i],
          (read8_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                     regs_q[read8_addr_i]}))
      $error("[PRF-INT-READ-STORED-ONLY] integer PRF read differs from registered state");
  end
`endif

  always @(posedge clk) begin
    if (rst) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        regs_q[idx] <= {`XLEN{1'b0}};
      end
    end else if (recover_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        if (idx < `REG_NUM) begin
          regs_q[idx] <= (idx == 0) ? {`XLEN{1'b0}} :
                         recover_gprs_i[idx * `XLEN +: `XLEN];
        end else begin
          regs_q[idx] <= {`XLEN{1'b0}};
        end
      end
    end else begin
      if (write0_valid_i && (write0_addr_i != {PHY_REG_ADDR_W{1'b0}})) begin
        regs_q[write0_addr_i] <= write0_data_i;
      end
      if (write1_valid_i && (write1_addr_i != {PHY_REG_ADDR_W{1'b0}})) begin
        // 双写端口理论上不会写同一物理寄存器；若上游出错，端口 1 作为更高优先级覆盖，便于暴露确定行为。
        regs_q[write1_addr_i] <= write1_data_i;
      end
    end
  end

endmodule
