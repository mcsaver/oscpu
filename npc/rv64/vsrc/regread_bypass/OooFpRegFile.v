`include "define.v"

// FPR 独立于前端取指/CSR 控制；该模块只负责 FP 寄存器状态、读端口和两类写回。
module OooFpRegFile (
  input clk,
  input rst,
  input flush_i,

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
  input [`XLEN-1:0] result_write_data_i
);

  reg [`XLEN-1:0] fpr_q [0:`REG_NUM-1];
  integer reset_idx;

  assign read0_data_o = fpr_q[read0_addr_i];
  assign read1_data_o = fpr_q[read1_addr_i];
  assign read2_data_o = fpr_q[read2_addr_i];

  always @(posedge clk) begin
    if (rst || flush_i) begin
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
