`include "define.v"

module WBU (
  input [2:0] wb_sel_i,
  input [`XLEN-1:0] alu_data_i,
  input [`XLEN-1:0] load_data_i,
  input [`XLEN-1:0] pc_plus4_i,
  input [`XLEN-1:0] imm_data_i,
  input [`XLEN-1:0] csr_data_i,
  output reg [`XLEN-1:0] wb_data_o
);

  // 写回源统一在这里收口，能保证“有结果”和“允许提交”是两套独立逻辑。
  always @(*) begin
    case (wb_sel_i)
      `WB_SEL_ALU:  wb_data_o = alu_data_i;
      `WB_SEL_LOAD: wb_data_o = load_data_i;
      `WB_SEL_PC4:  wb_data_o = pc_plus4_i;
      `WB_SEL_IMM:  wb_data_o = imm_data_i;
      `WB_SEL_CSR:  wb_data_o = csr_data_i;
      default:      wb_data_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
