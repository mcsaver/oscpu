`include "define.v"

module WBU (
  input [2:0] wb_sel_i,
  input [`XLEN-1:0] alu_data_i,
  input [`XLEN-1:0] pc_plus4_i,
  input [`XLEN-1:0] imm_data_i,
  input [`XLEN-1:0] csr_data_i,
  output reg [`XLEN-1:0] wb_data_o
);

  // 写回源统一在这里收口，能保证“有结果”和“允许提交”是两套独立逻辑。
  // WB_SEL_LOAD 源臂已删除（死硅）：两实例 load_data_i 恒接 0，load 结果走 mem rsp 通道，
  // 故 WB_SEL_LOAD 落入 default→0，与原 load_data_i(=0) 逐位等价。
  always @(*) begin
    case (wb_sel_i)
      `WB_SEL_ALU:  wb_data_o = alu_data_i;
      `WB_SEL_PC4:  wb_data_o = pc_plus4_i;
      `WB_SEL_IMM:  wb_data_o = imm_data_i;
      `WB_SEL_CSR:  wb_data_o = csr_data_i;
      default:      wb_data_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
