`include "define.v"

module tb_pipe_regs;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg ifid_clear;
  reg ifid_consume;
  reg ifid_load;
  reg [`XLEN-1:0] ifid_load_pc;
  reg [`INST_W-1:0] ifid_load_inst;
  reg [`XLEN-1:0] ifid_load_len;
  reg [`XLEN-1:0] ifid_load_pred;
  reg ifid_load_error;
  wire ifid_valid;
  wire [`XLEN-1:0] ifid_pc;
  wire [`INST_W-1:0] ifid_inst;
  wire [`XLEN-1:0] ifid_len;
  wire [`XLEN-1:0] ifid_pred;
  wire ifid_error;

  reg idex_clear;
  reg idex_kill;
  reg idex_load;
  reg [`XLEN-1:0] idex_load_pc;
  reg [`INST_W-1:0] idex_load_inst;
  reg [`XLEN-1:0] idex_load_len;
  reg [`XLEN-1:0] idex_load_pred;
  reg [`CTRL_BUS_W-1:0] idex_load_ctrl;
  reg [`XLEN-1:0] idex_load_imm;
  reg [`REG_ADDR_W-1:0] idex_load_rs1;
  reg [`REG_ADDR_W-1:0] idex_load_rs2;
  reg [`REG_ADDR_W-1:0] idex_load_rd;
  reg [`XLEN-1:0] idex_load_rs1_data;
  reg [`XLEN-1:0] idex_load_rs2_data;
  reg idex_load_error;
  wire idex_valid;
  wire [`XLEN-1:0] idex_pc;
  wire [`CTRL_BUS_W-1:0] idex_ctrl;
  wire [`XLEN-1:0] idex_imm;
  wire [`REG_ADDR_W-1:0] idex_rd;

  reg exmem_clear;
  reg exmem_leave;
  reg exmem_load;
  reg [`XLEN-1:0] exmem_load_pc;
  reg [`INST_W-1:0] exmem_load_inst;
  reg [`XLEN-1:0] exmem_load_next;
  reg exmem_load_is_load;
  reg exmem_load_is_store;
  reg exmem_load_rd_en;
  reg exmem_load_need_wb;
  reg [1:0] exmem_load_mem_size;
  reg exmem_load_unsigned;
  reg [`REG_ADDR_W-1:0] exmem_load_rd;
  reg [`XLEN-1:0] exmem_load_wb;
  reg [`XLEN-1:0] exmem_load_addr;
  reg [`XLEN-1:0] exmem_load_store_data;
  wire exmem_valid;
  wire [`XLEN-1:0] exmem_pc;
  wire exmem_is_load;
  wire [`XLEN-1:0] exmem_wb;

  reg memwb_load;
  reg [`XLEN-1:0] memwb_load_pc;
  reg [`INST_W-1:0] memwb_load_inst;
  reg [`XLEN-1:0] memwb_load_next;
  reg memwb_load_rd_en;
  reg memwb_load_need_wb;
  reg [`REG_ADDR_W-1:0] memwb_load_rd;
  reg [`XLEN-1:0] memwb_load_wb;
  wire memwb_valid;
  wire [`XLEN-1:0] memwb_pc;
  wire memwb_rd_en;
  wire [`REG_ADDR_W-1:0] memwb_rd;
  wire [`XLEN-1:0] memwb_wb;

  IfIdPipeReg u_ifid (
    .clk(clk), .rst(rst), .clear_i(ifid_clear), .consume_i(ifid_consume), .load_i(ifid_load),
    .load_pc_i(ifid_load_pc), .load_inst_i(ifid_load_inst), .load_inst_len_i(ifid_load_len),
    .load_pred_pc_i(ifid_load_pred), .load_error_i(ifid_load_error),
    .valid_o(ifid_valid), .pc_o(ifid_pc), .inst_o(ifid_inst), .inst_len_o(ifid_len),
    .pred_pc_o(ifid_pred), .error_o(ifid_error)
  );

  IdExPipeReg u_idex (
    .clk(clk), .rst(rst), .clear_i(idex_clear), .kill_i(idex_kill), .load_i(idex_load),
    .load_pc_i(idex_load_pc), .load_inst_i(idex_load_inst), .load_inst_len_i(idex_load_len),
    .load_pred_pc_i(idex_load_pred), .load_ctrl_i(idex_load_ctrl), .load_imm_i(idex_load_imm),
    .load_rs1_idx_i(idex_load_rs1), .load_rs2_idx_i(idex_load_rs2), .load_rd_idx_i(idex_load_rd),
    .load_rs1_data_i(idex_load_rs1_data), .load_rs2_data_i(idex_load_rs2_data),
    .load_fetch_error_i(idex_load_error), .valid_o(idex_valid), .pc_o(idex_pc), .inst_o(),
    .inst_len_o(), .pred_pc_o(), .ctrl_o(idex_ctrl), .imm_o(idex_imm),
    .rs1_idx_o(), .rs2_idx_o(), .rd_idx_o(idex_rd), .rs1_data_o(), .rs2_data_o(),
    .fetch_error_o()
  );

  ExMemPipeReg u_exmem (
    .clk(clk), .rst(rst), .clear_i(exmem_clear), .leave_i(exmem_leave), .load_i(exmem_load),
    .load_pc_i(exmem_load_pc), .load_inst_i(exmem_load_inst), .load_next_pc_i(exmem_load_next),
    .load_is_load_i(exmem_load_is_load), .load_is_store_i(exmem_load_is_store),
    .load_rd_en_i(exmem_load_rd_en), .load_need_wb_i(exmem_load_need_wb),
    .load_mem_size_i(exmem_load_mem_size), .load_mem_unsigned_i(exmem_load_unsigned),
    .load_rd_idx_i(exmem_load_rd), .load_wb_data_i(exmem_load_wb),
    .load_mem_addr_i(exmem_load_addr), .load_store_data_i(exmem_load_store_data),
    .valid_o(exmem_valid), .pc_o(exmem_pc), .inst_o(), .next_pc_o(), .is_load_o(exmem_is_load),
    .is_store_o(), .rd_en_o(), .need_wb_o(), .mem_size_o(), .mem_unsigned_o(),
    .rd_idx_o(), .wb_data_o(exmem_wb), .mem_addr_o(), .store_data_o()
  );

  MemWbPipeReg u_memwb (
    .clk(clk), .rst(rst), .load_i(memwb_load),
    .load_pc_i(memwb_load_pc), .load_inst_i(memwb_load_inst), .load_next_pc_i(memwb_load_next),
    .load_rd_en_i(memwb_load_rd_en), .load_need_wb_i(memwb_load_need_wb),
    .load_rd_idx_i(memwb_load_rd), .load_wb_data_i(memwb_load_wb),
    .valid_o(memwb_valid), .pc_o(memwb_pc), .inst_o(), .next_pc_o(),
    .rd_en_o(memwb_rd_en), .need_wb_o(), .rd_idx_o(memwb_rd), .wb_data_o(memwb_wb)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    ifid_clear = 1'b0; ifid_consume = 1'b0; ifid_load = 1'b0;
    ifid_load_pc = 32'h1000; ifid_load_inst = 32'h13; ifid_load_len = 32'd4; ifid_load_pred = 32'h1004; ifid_load_error = 1'b0;
    idex_clear = 1'b0; idex_kill = 1'b0; idex_load = 1'b0;
    idex_load_pc = 32'h2000; idex_load_inst = 32'h13; idex_load_len = 32'd4; idex_load_pred = 32'h2004;
    idex_load_ctrl = {`CTRL_BUS_W{1'b0}}; idex_load_ctrl[`CTRL_VALID_BIT] = 1'b1;
    idex_load_imm = 32'h1234; idex_load_rs1 = 5'd1; idex_load_rs2 = 5'd2; idex_load_rd = 5'd3;
    idex_load_rs1_data = 32'h1111; idex_load_rs2_data = 32'h2222; idex_load_error = 1'b0;
    exmem_clear = 1'b0; exmem_leave = 1'b0; exmem_load = 1'b0;
    exmem_load_pc = 32'h3000; exmem_load_inst = 32'h13; exmem_load_next = 32'h3004;
    exmem_load_is_load = 1'b1; exmem_load_is_store = 1'b0; exmem_load_rd_en = 1'b1; exmem_load_need_wb = 1'b1;
    exmem_load_mem_size = `MEM_SIZE_WORD; exmem_load_unsigned = 1'b0; exmem_load_rd = 5'd4;
    exmem_load_wb = 32'h4444; exmem_load_addr = 32'h8000_0000; exmem_load_store_data = 32'h5555;
    memwb_load = 1'b0; memwb_load_pc = 32'h4000; memwb_load_inst = 32'h13; memwb_load_next = 32'h4004;
    memwb_load_rd_en = 1'b1; memwb_load_need_wb = 1'b1; memwb_load_rd = 5'd5; memwb_load_wb = 32'h5555;
    `TB_TICK(clk);
    rst = 1'b0;
    #1;
    tb_check1("ifid reset valid", ifid_valid, 1'b0);
    tb_check1("idex reset valid", idex_valid, 1'b0);
    tb_check1("exmem reset valid", exmem_valid, 1'b0);
    tb_check1("memwb reset valid", memwb_valid, 1'b0);

    ifid_load = 1'b1; `TB_TICK(clk); ifid_load = 1'b0; #1;
    tb_check1("ifid load valid", ifid_valid, 1'b1);
    tb_check32("ifid pc", ifid_pc, 32'h1000);
    ifid_consume = 1'b1; `TB_TICK(clk); ifid_consume = 1'b0; #1;
    tb_check1("ifid consume", ifid_valid, 1'b0);
    ifid_clear = 1'b1; ifid_load = 1'b1; `TB_TICK(clk); ifid_clear = 1'b0; ifid_load = 1'b0; #1;
    tb_check1("ifid clear priority", ifid_valid, 1'b0);

    idex_load = 1'b1; `TB_TICK(clk); idex_load = 1'b0; #1;
    tb_check1("idex load valid", idex_valid, 1'b1);
    tb_check32("idex ctrl valid", {31'b0, idex_ctrl[`CTRL_VALID_BIT]}, 32'd1);
    tb_check32("idex imm", idex_imm, 32'h1234);
    tb_check32("idex rd", {27'b0, idex_rd}, 32'd3);
    idex_kill = 1'b1; `TB_TICK(clk); idex_kill = 1'b0; #1;
    tb_check1("idex kill", idex_valid, 1'b0);
    idex_clear = 1'b1; idex_load = 1'b1; `TB_TICK(clk); idex_clear = 1'b0; idex_load = 1'b0; #1;
    tb_check1("idex clear priority", idex_valid, 1'b0);

    exmem_load = 1'b1; `TB_TICK(clk); exmem_load = 1'b0; #1;
    tb_check1("exmem load valid", exmem_valid, 1'b1);
    tb_check1("exmem load bit", exmem_is_load, 1'b1);
    tb_check32("exmem wb", exmem_wb, 32'h4444);
    exmem_leave = 1'b1; `TB_TICK(clk); exmem_leave = 1'b0; #1;
    tb_check1("exmem leave", exmem_valid, 1'b0);
    exmem_leave = 1'b1; exmem_load = 1'b1; exmem_load_wb = 32'haaaa_0001; `TB_TICK(clk);
    exmem_leave = 1'b0; exmem_load = 1'b0; #1;
    tb_check1("exmem load wins leave", exmem_valid, 1'b1);
    tb_check32("exmem new wb", exmem_wb, 32'haaaa_0001);
    exmem_clear = 1'b1; exmem_load = 1'b1; `TB_TICK(clk); exmem_clear = 1'b0; exmem_load = 1'b0; #1;
    tb_check1("exmem clear priority", exmem_valid, 1'b0);

    memwb_load = 1'b1; `TB_TICK(clk); memwb_load = 1'b0; #1;
    tb_check1("memwb load valid", memwb_valid, 1'b1);
    tb_check32("memwb pc", memwb_pc, 32'h4000);
    tb_check1("memwb rd_en", memwb_rd_en, 1'b1);
    tb_check32("memwb rd", {27'b0, memwb_rd}, 32'd5);
    tb_check32("memwb wb", memwb_wb, 32'h5555);
    `TB_TICK(clk); #1;
    tb_check1("memwb one-cycle valid", memwb_valid, 1'b0);

    tb_finish("tb_pipe_regs");
  end
endmodule
