`include "define.v"
`include "tb_common.svh"

module tb_ooo_frontend_uop_safety;
  reg [`CTRL_BUS_W-1:0] ctrl;
  reg [1:0] resp;
  reg [`INST_W-1:0] inst;
  reg [`REG_ADDR_W-1:0] rd;
  reg [`REG_ADDR_W-1:0] hazard_rs;

  wire lane0_before_ret_safe;
  wire return_cont_safe;
  wire fallthrough_safe;
  wire prefetch_safe;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b0),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b1),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b1)
  ) lane0_policy (
    .ctrl_i(ctrl),
    .resp_i(resp),
    .inst_i(inst),
    .rd_i(rd),
    .hazard_rs_i(hazard_rs),
    .safe_o(lane0_before_ret_safe)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b0),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b0),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b1),
    .ALLOW_SRET(1'b1),
    .ALLOW_AMO(1'b1),
    .CHECK_RD_HAZARD(1'b0)
  ) return_cont_policy (
    .ctrl_i(ctrl),
    .resp_i(resp),
    .inst_i(inst),
    .rd_i(rd),
    .hazard_rs_i(hazard_rs),
    .safe_o(return_cont_safe)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b1),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b1),
    .ALLOW_SRET(1'b1),
    .ALLOW_AMO(1'b1),
    .CHECK_RD_HAZARD(1'b0)
  ) fallthrough_policy (
    .ctrl_i(ctrl),
    .resp_i(resp),
    .inst_i(inst),
    .rd_i(rd),
    .hazard_rs_i(hazard_rs),
    .safe_o(fallthrough_safe)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b1),
    .ALLOW_BITMANIP(1'b1),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b0)
  ) prefetch_policy (
    .ctrl_i(ctrl),
    .resp_i(resp),
    .inst_i(inst),
    .rd_i(rd),
    .hazard_rs_i(hazard_rs),
    .safe_o(prefetch_safe)
  );

  task automatic clear_ctrl;
    begin
      ctrl = {`CTRL_BUS_W{1'b0}};
      ctrl[`CTRL_VALID_BIT] = 1'b1;
      ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      resp = 2'b00;
      inst = 32'h0000_0013;
      rd = 5'd7;
      hazard_rs = 5'd1;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    clear_ctrl();
    tb_check1("base lane0 safe", lane0_before_ret_safe, 1'b1);
    tb_check1("base return cont safe", return_cont_safe, 1'b1);
    tb_check1("base fallthrough safe", fallthrough_safe, 1'b1);
    tb_check1("base prefetch safe", prefetch_safe, 1'b1);

    ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    #1;
    tb_check1("branch rejected lane0", lane0_before_ret_safe, 1'b0);
    tb_check1("branch rejected prefetch", prefetch_safe, 1'b0);

    clear_ctrl();
    ctrl[`CTRL_LOAD_BIT] = 1'b1;
    #1;
    tb_check1("load allowed lane0", lane0_before_ret_safe, 1'b1);
    tb_check1("load rejected return-cont", return_cont_safe, 1'b0);
    tb_check1("load allowed fallthrough", fallthrough_safe, 1'b1);
    tb_check1("load allowed prefetch", prefetch_safe, 1'b1);

    clear_ctrl();
    ctrl[`CTRL_STORE_BIT] = 1'b1;
    #1;
    tb_check1("store allowed lane0", lane0_before_ret_safe, 1'b1);
    tb_check1("store rejected return-cont", return_cont_safe, 1'b0);
    tb_check1("store rejected fallthrough", fallthrough_safe, 1'b0);
    tb_check1("store rejected prefetch", prefetch_safe, 1'b0);

    clear_ctrl();
    ctrl[`CTRL_MULDIV_BIT] = 1'b1;
    #1;
    tb_check1("muldiv rejected lane0", lane0_before_ret_safe, 1'b0);
    tb_check1("muldiv rejected fallthrough", fallthrough_safe, 1'b0);
    tb_check1("muldiv allowed prefetch", prefetch_safe, 1'b1);

    clear_ctrl();
    ctrl[`CTRL_SFENCE_VMA_BIT] = 1'b1;
    #1;
    tb_check1("sfence rejected lane0", lane0_before_ret_safe, 1'b0);
    tb_check1("sfence allowed return-cont legacy", return_cont_safe, 1'b1);
    tb_check1("sfence allowed fallthrough legacy", fallthrough_safe, 1'b1);
    tb_check1("sfence rejected prefetch", prefetch_safe, 1'b0);

    clear_ctrl();
    resp = 2'b10;
    #1;
    tb_check1("resp ignored lane0", lane0_before_ret_safe, 1'b1);
    tb_check1("resp rejected fallthrough", fallthrough_safe, 1'b0);
    tb_check1("resp rejected prefetch", prefetch_safe, 1'b0);

    clear_ctrl();
    inst = 32'h0010_0073;
    #1;
    tb_check1("semihost ignored lane0", lane0_before_ret_safe, 1'b1);
    tb_check1("semihost rejected fallthrough", fallthrough_safe, 1'b0);
    tb_check1("semihost allowed prefetch", prefetch_safe, 1'b1);

    clear_ctrl();
    ctrl[`CTRL_RD_EN_BIT] = 1'b1;
    rd = 5'd1;
    hazard_rs = 5'd1;
    #1;
    tb_check1("rd hazard rejected lane0", lane0_before_ret_safe, 1'b0);
    tb_check1("rd hazard ignored return-cont", return_cont_safe, 1'b1);

    rd = 5'd0;
    #1;
    tb_check1("x0 write no hazard", lane0_before_ret_safe, 1'b1);

    tb_finish("tb_ooo_frontend_uop_safety");
  end

endmodule

