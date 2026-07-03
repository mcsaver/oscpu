`include "define.v"

// 【B-FP 簇】FP 物理寄存器堆(spec ooo-fp-cluster-implementation-plan.md §7)。
// 与 OooPhysRegFile 同构但**无 x0 特判**——f0 是真寄存器, 可读写可分配。
// 4R: FP 算术三源(fs1/fs2/fs3) + FP store 发射拍数据读(fs2, 来自整数 IQ mem 通道);
// 2W: FP 算术/跨域结果 + FP load 响应。写-读同拍旁路与整数堆同款。
// recover: trap flush 时低 32 项单拍拷入架构 FPR(committed 承载区), 高 32 清 0,
// 配合 FP RenameMap 恒等重置(照抄整数恢复模式)。
module OooFpPhysRegFile #(
  parameter PHY_REG_COUNT = `OOO_PHY_REG_COUNT,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input recover_i,
  input [`XLEN * `REG_NUM - 1:0] recover_fprs_i,

  input [PHY_REG_ADDR_W-1:0] read0_addr_i,
  output [`XLEN-1:0] read0_data_o,
  input [PHY_REG_ADDR_W-1:0] read1_addr_i,
  output [`XLEN-1:0] read1_data_o,
  input [PHY_REG_ADDR_W-1:0] read2_addr_i,
  output [`XLEN-1:0] read2_data_o,
  input [PHY_REG_ADDR_W-1:0] read3_addr_i,
  output [`XLEN-1:0] read3_data_o,

  input write0_valid_i,
  input [PHY_REG_ADDR_W-1:0] write0_addr_i,
  input [`XLEN-1:0] write0_data_i,
  input write1_valid_i,
  input [PHY_REG_ADDR_W-1:0] write1_addr_i,
  input [`XLEN-1:0] write1_data_i
);

  reg [`XLEN-1:0] regs_q [0:PHY_REG_COUNT-1];
  integer idx;

  function [`XLEN-1:0] read_port_data;
    input [PHY_REG_ADDR_W-1:0] addr;
    input write0_valid;
    input [PHY_REG_ADDR_W-1:0] write0_addr;
    input [`XLEN-1:0] write0_data;
    input write1_valid;
    input [PHY_REG_ADDR_W-1:0] write1_addr;
    input [`XLEN-1:0] write1_data;
    begin
      if (write1_valid && (write1_addr == addr)) begin
        read_port_data = write1_data;
      end else if (write0_valid && (write0_addr == addr)) begin
        read_port_data = write0_data;
      end else begin
        read_port_data = regs_q[addr];
      end
    end
  endfunction

  assign read0_data_o = read_port_data(read0_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);
  assign read1_data_o = read_port_data(read1_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);
  assign read2_data_o = read_port_data(read2_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);
  assign read3_data_o = read_port_data(read3_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);

  always @(posedge clk) begin
    if (rst) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        regs_q[idx] <= {`XLEN{1'b0}};
      end
    end else if (recover_i) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        if (idx < `REG_NUM) begin
          regs_q[idx] <= recover_fprs_i[idx * `XLEN +: `XLEN];
        end else begin
          regs_q[idx] <= {`XLEN{1'b0}};
        end
      end
    end else begin
      if (write0_valid_i) begin
        regs_q[write0_addr_i] <= write0_data_i;
      end
      if (write1_valid_i) begin
        // 双写端口不应写同一物理寄存器；若上游出错, 端口 1 覆盖以暴露确定行为。
        regs_q[write1_addr_i] <= write1_data_i;
      end
    end
  end

endmodule
