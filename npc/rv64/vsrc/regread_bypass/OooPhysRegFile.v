`include "define.v"

// 乱序后端使用物理寄存器承载 speculative 结果；这里提供 5R2W 基础件（read0-3=双发
// 整数发射源，read8=FP GPR 读；read4-7/9 死读口已随各自死硅族物理删除）。
// T3B：full write 只负责落 regs_q；read0-3 只消费显式 fast-bypass 子集，避免完整
// WB payload 反灌整数执行快路径。T3F：read8 只读已落账 regs_q，与 FP IQ
// integer sticky wake 周期对齐，禁止 full/fast WB 组合路径进入 FP convert。
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

  input bypass0_valid_i,
  input [PHY_REG_ADDR_W-1:0] bypass0_addr_i,
  input [`XLEN-1:0] bypass0_data_i,
  input bypass1_valid_i,
  input [PHY_REG_ADDR_W-1:0] bypass1_addr_i,
  input [`XLEN-1:0] bypass1_data_i,

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
    input [`XLEN-1:0] stored_data;
    input source0_valid;
    input [PHY_REG_ADDR_W-1:0] source0_addr;
    input [`XLEN-1:0] source0_data;
    input source1_valid;
    input [PHY_REG_ADDR_W-1:0] source1_addr;
    input [`XLEN-1:0] source1_data;
    begin
      if (addr == {PHY_REG_ADDR_W{1'b0}}) begin
        read_port_data = {`XLEN{1'b0}};
      end else if (source1_valid && (source1_addr == addr) &&
                   (source1_addr != {PHY_REG_ADDR_W{1'b0}})) begin
        read_port_data = source1_data;
      end else if (source0_valid && (source0_addr == addr) &&
                   (source0_addr != {PHY_REG_ADDR_W{1'b0}})) begin
        read_port_data = source0_data;
      end else begin
        // regs_q 必须作为显式实参进入连续赋值依赖；iverilog 不可靠追踪
        // function 对模块级数组的 hidden dependency，会让 full-only 写后读停在旧值。
        read_port_data = stored_data;
      end
    end
  endfunction

  assign read0_data_o = read_port_data(read0_addr_i,
                                       regs_q[read0_addr_i],
                                       bypass0_valid_i, bypass0_addr_i, bypass0_data_i,
                                       bypass1_valid_i, bypass1_addr_i, bypass1_data_i);
  assign read1_data_o = read_port_data(read1_addr_i,
                                       regs_q[read1_addr_i],
                                       bypass0_valid_i, bypass0_addr_i, bypass0_data_i,
                                       bypass1_valid_i, bypass1_addr_i, bypass1_data_i);
  assign read2_data_o = read_port_data(read2_addr_i,
                                       regs_q[read2_addr_i],
                                       bypass0_valid_i, bypass0_addr_i, bypass0_data_i,
                                       bypass1_valid_i, bypass1_addr_i, bypass1_data_i);
  assign read3_data_o = read_port_data(read3_addr_i,
                                       regs_q[read3_addr_i],
                                       bypass0_valid_i, bypass0_addr_i, bypass0_data_i,
                                       bypass1_valid_i, bypass1_addr_i, bypass1_data_i);
  assign read8_data_o =
      (read8_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read8_addr_i];

`ifdef OOO_ASSERT
  // fast-bypass 只能收窄 full write 广播，禁止伪造另一份 tag/data 身份。
  always @(posedge clk) begin
    if (!rst && (bypass0_valid_i === 1'b1) &&
        !((write0_valid_i === 1'b1) &&
          (bypass0_addr_i === write0_addr_i) &&
          (bypass0_data_i === write0_data_i))) begin
      $error("[PRF-FAST-WB-SUBSET] lane0 bypass does not match full write");
    end
    if (!rst && (bypass1_valid_i === 1'b1) &&
        !((write1_valid_i === 1'b1) &&
          (bypass1_addr_i === write1_addr_i) &&
          (bypass1_data_i === write1_data_i))) begin
      $error("[PRF-FAST-WB-SUBSET] lane1 bypass does not match full write");
    end
    if (!rst && (read8_data_o !==
        ((read8_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                   regs_q[read8_addr_i]))) begin
      $error("[PRF-READ8-STORED-ONLY] read8 differs from registered state");
    end
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
