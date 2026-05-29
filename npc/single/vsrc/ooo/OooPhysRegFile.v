`include "define.v"

// 乱序后端使用物理寄存器承载 speculative 结果；这里先提供 4R2W 基础件，
// 让后续两个整数发射端口可以同拍读取操作数，writeback 同拍通过旁路被新发射 uop 看到。
module OooPhysRegFile #(
  parameter PHY_REG_COUNT = 64,
  parameter PHY_REG_ADDR_W = 6
) (
  input clk,
  input rst,

  input [PHY_REG_ADDR_W-1:0] read0_addr_i,
  output [`XLEN-1:0] read0_data_o,
  input [PHY_REG_ADDR_W-1:0] read1_addr_i,
  output [`XLEN-1:0] read1_data_o,
  input [PHY_REG_ADDR_W-1:0] read2_addr_i,
  output [`XLEN-1:0] read2_data_o,
  input [PHY_REG_ADDR_W-1:0] read3_addr_i,
  output [`XLEN-1:0] read3_data_o,
  input [PHY_REG_ADDR_W-1:0] read4_addr_i,
  output [`XLEN-1:0] read4_data_o,
  input [PHY_REG_ADDR_W-1:0] read5_addr_i,
  output [`XLEN-1:0] read5_data_o,

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
      if (addr == {PHY_REG_ADDR_W{1'b0}}) begin
        read_port_data = {`XLEN{1'b0}};
      end else if (write1_valid && (write1_addr == addr) &&
                   (write1_addr != {PHY_REG_ADDR_W{1'b0}})) begin
        read_port_data = write1_data;
      end else if (write0_valid && (write0_addr == addr) &&
                   (write0_addr != {PHY_REG_ADDR_W{1'b0}})) begin
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
  assign read4_data_o = read_port_data(read4_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);
  assign read5_data_o = read_port_data(read5_addr_i,
                                       write0_valid_i, write0_addr_i, write0_data_i,
                                       write1_valid_i, write1_addr_i, write1_data_i);

  always @(posedge clk) begin
    if (rst) begin
      for (idx = 0; idx < PHY_REG_COUNT; idx = idx + 1) begin
        regs_q[idx] <= {`XLEN{1'b0}};
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
