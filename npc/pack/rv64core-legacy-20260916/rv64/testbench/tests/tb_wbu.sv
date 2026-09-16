`include "define.v"

module tb_wbu;
  `include "tb_common.svh"

  reg [2:0] wb_sel;
  reg [`XLEN-1:0] alu_data;
  reg [`XLEN-1:0] pc_plus4;
  reg [`XLEN-1:0] imm_data;
  reg [`XLEN-1:0] csr_data;
  wire [`XLEN-1:0] wb_data;

  WBU dut (
    .wb_sel_i(wb_sel),
    .alu_data_i(alu_data),
    .pc_plus4_i(pc_plus4),
    .imm_data_i(imm_data),
    .csr_data_i(csr_data),
    .wb_data_o(wb_data)
  );

  initial begin
    tb_errors = 0;
    alu_data = 32'h1111_1111;
    pc_plus4 = 32'h3333_3333;
    imm_data = 32'h4444_4444;
    csr_data = 32'h5555_5555;

    wb_sel = `WB_SEL_ALU;  #1; tb_check32("alu", wb_data, alu_data);
    // WB_SEL_LOAD 源臂已删除（死硅）：落入 default→0，与原 load_data_i(=0) 逐位等价。
    wb_sel = `WB_SEL_LOAD; #1; tb_check32("load", wb_data, 32'h0000_0000);
    wb_sel = `WB_SEL_PC4;  #1; tb_check32("pc4", wb_data, pc_plus4);
    wb_sel = `WB_SEL_IMM;  #1; tb_check32("imm", wb_data, imm_data);
    wb_sel = `WB_SEL_CSR;  #1; tb_check32("csr", wb_data, csr_data);
    wb_sel = `WB_SEL_NONE; #1; tb_check32("none", wb_data, 32'h0000_0000);

    tb_finish("tb_wbu");
  end
endmodule
