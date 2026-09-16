`include "define.v"

// Parameterized pure-combinational whitelist for front-end fast-path uops.
module OooFrontendUopSafety #(
  parameter REQUIRE_RESP_OK = 1'b0,
  parameter REJECT_SEMIHOST_ENTER = 1'b0,
  parameter ALLOW_LOAD = 1'b1,
  parameter ALLOW_STORE = 1'b0,
  parameter ALLOW_MULDIV = 1'b0,
  parameter ALLOW_BITMANIP = 1'b0,
  parameter ALLOW_SFENCE = 1'b0,
  parameter ALLOW_SRET = 1'b0,
  parameter ALLOW_AMO = 1'b0,
  parameter CHECK_RD_HAZARD = 1'b0
) (
  input [`CTRL_BUS_W-1:0] ctrl_i,
  input [1:0] resp_i,
  input [`INST_W-1:0] inst_i,
  input [`REG_ADDR_W-1:0] rd_i,
  input [`REG_ADDR_W-1:0] hazard_rs_i,
  output safe_o
);

  wire base_safe_w =
      ctrl_i[`CTRL_VALID_BIT] &&
      !ctrl_i[`CTRL_ILLEGAL_BIT] &&
      ctrl_i[`CTRL_NEED_EXEC_BIT] &&
      !ctrl_i[`CTRL_BRANCH_BIT] &&
      !ctrl_i[`CTRL_JAL_BIT] &&
      !ctrl_i[`CTRL_JALR_BIT] &&
      !ctrl_i[`CTRL_ECALL_BIT] &&
      !ctrl_i[`CTRL_EBREAK_BIT] &&
      !ctrl_i[`CTRL_SYSTEM_BIT] &&
      !ctrl_i[`CTRL_CSR_BIT] &&
      !ctrl_i[`CTRL_FENCE_BIT] &&
      !ctrl_i[`CTRL_MISC_MEM_BIT] &&
      !ctrl_i[`CTRL_MRET_BIT] &&
      !ctrl_i[`CTRL_WFI_BIT];

  wire optional_safe_w =
      (ALLOW_LOAD || !ctrl_i[`CTRL_LOAD_BIT]) &&
      (ALLOW_STORE || !ctrl_i[`CTRL_STORE_BIT]) &&
      (ALLOW_MULDIV || !ctrl_i[`CTRL_MULDIV_BIT]) &&
      (ALLOW_BITMANIP || !ctrl_i[`CTRL_BITMANIP_BIT]) &&
      (ALLOW_SFENCE || !ctrl_i[`CTRL_SFENCE_VMA_BIT]) &&
      (ALLOW_SRET || !ctrl_i[`CTRL_SRET_BIT]) &&
      (ALLOW_AMO || !ctrl_i[`CTRL_AMO_BIT]);

  wire resp_safe_w = !REQUIRE_RESP_OK || (resp_i == 2'b00);
  wire semihost_safe_w = !REJECT_SEMIHOST_ENTER ||
                         (inst_i != 32'h0010_0073);
  wire rd_hazard_safe_w =
      !CHECK_RD_HAZARD ||
      !ctrl_i[`CTRL_RD_EN_BIT] ||
      (rd_i == {`REG_ADDR_W{1'b0}}) ||
      (rd_i != hazard_rs_i);

  assign safe_o = base_safe_w && optional_safe_w && resp_safe_w &&
                  semihost_safe_w && rd_hazard_safe_w;

endmodule

