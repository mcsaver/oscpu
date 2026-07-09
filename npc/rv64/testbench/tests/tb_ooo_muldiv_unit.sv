`include "define.v"

module tb_ooo_muldiv_unit;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;

  reg clk;
  reg rst;
  reg flush;

  reg req_valid;
  wire req_ready;
  reg [ROB_INDEX_W-1:0] req_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] req_pdest;
  reg [`INST_W-1:0] req_inst;
  reg [`XLEN-1:0] req_src1;
  reg [`XLEN-1:0] req_src2;
  reg req_word;

  wire resp_valid;
  reg resp_ready;
  wire [ROB_INDEX_W-1:0] resp_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] resp_pdest;
  wire [`XLEN-1:0] resp_data;

  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;

  OooMulDivUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .req_valid_i(req_valid),
    .req_ready_o(req_ready),
    .req_rob_idx_i(req_rob_idx),
    .req_pdest_i(req_pdest),
    .req_inst_i(req_inst),
    .req_src1_i(req_src1),
    .req_src2_i(req_src2),
    .req_word_i(req_word),
    .resp_valid_o(resp_valid),
    .resp_ready_i(resp_ready),
    .resp_rob_idx_o(resp_rob_idx),
    .resp_pdest_o(resp_pdest),
    .resp_data_o(resp_data)
  );

  function [`INST_W-1:0] rv64m_inst;
    input [2:0] funct3;
    begin
      rv64m_inst = {7'b0000001, 5'd2, 5'd1, funct3, 5'd3, `OPCODE_OP};
    end
  endfunction

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      req_valid = 1'b0;
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
      req_inst = {`INST_W{1'b0}};
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      req_word = 1'b0;
      resp_ready = 1'b0;
      kill_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
      rob_head_idx = {ROB_INDEX_W{1'b0}};
      `TB_TICK(clk)
      `TB_TICK(clk)
      rst = 1'b0;
      `TB_TICK(clk)
    end
  endtask

  // 独立金标准: 65×65 位 signed 乘一次覆盖 MULH/MULHU/MULHSU 三种符号组合
  // (操作数按变体带符号位扩 1 位再乘, 与 DUT 的 abs+末拍取反结构完全异构)。
  function [`XLEN-1:0] mul_golden;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg [`XLEN-1:0] o1, o2;
    reg s1, s2;
    reg signed [`XLEN:0] e1, e2;
    reg signed [(`XLEN+1)*2-1:0] sp;
    reg [`XLEN-1:0] raw;
    begin
      o1 = word_op ? {{32{src1[31]}}, src1[31:0]} : src1;
      o2 = word_op ? {{32{src2[31]}}, src2[31:0]} : src2;
      s1 = (funct3 == 3'b001) || (funct3 == 3'b010);
      s2 = (funct3 == 3'b001);
      e1 = $signed({s1 & o1[`XLEN-1], o1});
      e2 = $signed({s2 & o2[`XLEN-1], o2});
      sp = e1 * e2;
      raw = (funct3 == 3'b000) ? sp[`XLEN-1:0] : sp[(`XLEN*2)-1:`XLEN];
      mul_golden = word_op ? {{32{raw[31]}}, raw[31:0]} : raw;
    end
  endfunction

  task automatic issue_req;
    input [1023:0] name;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      tb_check1({name, " ready before request"}, req_ready, 1'b1);
      req_valid = 1'b1;
      req_inst = rv64m_inst(funct3);
      req_src1 = src1;
      req_src2 = src2;
      req_word = word_op;
      req_rob_idx = rob_idx;
      req_pdest = pdest;
      `TB_TICK(clk)
      req_valid = 1'b0;
      req_inst = {`INST_W{1'b0}};
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      req_word = 1'b0;
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
    end
  endtask

  task automatic expect_resp;
    input [1023:0] name;
    input [`XLEN-1:0] exp_data;
    input [ROB_INDEX_W-1:0] exp_rob_idx;
    input [PHY_REG_ADDR_W-1:0] exp_pdest;
    input integer max_cycles;
    integer wait_i;
    begin
      wait_i = 0;
      while (!resp_valid && wait_i < max_cycles) begin
        wait_i = wait_i + 1;
        `TB_TICK(clk)
      end
      if (!resp_valid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s resp_valid timeout after %0d cycles (max=%0d)",
                 name, wait_i, max_cycles);
      end
      tb_check64({name, " resp_data"}, resp_data, exp_data);
      if (resp_valid) begin
        if (resp_rob_idx !== exp_rob_idx) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s rob got=%0d expected=%0d",
                   name, resp_rob_idx, exp_rob_idx);
        end
        if (resp_pdest !== exp_pdest) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s pdest got=%0d expected=%0d",
                   name, resp_pdest, exp_pdest);
        end
      end
      resp_ready = 1'b1;
      `TB_TICK(clk)
      resp_ready = 1'b0;
    end
  endtask

  task automatic run_case;
    input [1023:0] name;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [`XLEN-1:0] exp_data;
    begin
      issue_req(name, funct3, word_op, src1, src2, 4'ha, 6'd21);
      expect_resp(name, exp_data, 4'ha, 6'd21, 80);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    run_case("mul low signed operands", 3'b000, 1'b0, 64'd7,
             64'hffff_ffff_ffff_fffd, 64'hffff_ffff_ffff_ffeb);
    run_case("mulh signed signed", 3'b001, 1'b0,
             64'hffff_ffff_ffff_fffe, 64'd3,
             64'hffff_ffff_ffff_ffff);
    run_case("mulhsu signed unsigned", 3'b010, 1'b0,
             64'hffff_ffff_ffff_fffe, 64'd3,
             64'hffff_ffff_ffff_ffff);
    run_case("mulhu unsigned high", 3'b011, 1'b0,
             64'h8000_0000_0000_0000, 64'd2,
             64'h0000_0000_0000_0001);
    run_case("mulw sign extend", 3'b000, 1'b1,
             64'h0000_0001_0000_0003, 64'd2,
             64'h0000_0000_0000_0006);

    run_case("div signed", 3'b100, 1'b0,
             64'hffff_ffff_ffff_ff9c, 64'd7,
             64'hffff_ffff_ffff_fff2);
    run_case("rem signed", 3'b110, 1'b0,
             64'hffff_ffff_ffff_ff9c, 64'd7,
             64'hffff_ffff_ffff_fffe);
    run_case("divu unsigned", 3'b101, 1'b0, 64'd100, 64'd7, 64'd14);
    run_case("remu unsigned", 3'b111, 1'b0, 64'd100, 64'd7, 64'd2);
    run_case("div by zero", 3'b100, 1'b0,
             64'h1234_5678_9abc_def0, 64'd0,
             64'hffff_ffff_ffff_ffff);
    run_case("rem by zero", 3'b110, 1'b0,
             64'h1234_5678_9abc_def0, 64'd0,
             64'h1234_5678_9abc_def0);
    run_case("div overflow", 3'b100, 1'b0,
             64'h8000_0000_0000_0000, 64'hffff_ffff_ffff_ffff,
             64'h8000_0000_0000_0000);
    run_case("divw overflow", 3'b100, 1'b1,
             64'hffff_ffff_8000_0000, 64'hffff_ffff_ffff_ffff,
             64'hffff_ffff_8000_0000);
    run_case("divuw", 3'b101, 1'b1,
             64'h0000_0000_ffff_ffff, 64'd2,
             64'h0000_0000_7fff_ffff);
    run_case("remuw", 3'b111, 1'b1,
             64'h0000_0000_ffff_ffff, 64'd2,
             64'h0000_0000_0000_0001);

    issue_req("busy div", 3'b100, 1'b0, 64'd100, 64'd3, 4'h3, 6'd9);
    tb_check1("div run not ready", req_ready, 1'b0);
    req_valid = 1'b1;
    req_inst = rv64m_inst(3'b000);
    req_src1 = 64'd5;
    req_src2 = 64'd5;
    req_word = 1'b0;
    req_rob_idx = 4'h4;
    req_pdest = 6'd10;
    `TB_TICK(clk)
    req_valid = 1'b0;
    tb_check1("busy request ignored", req_ready, 1'b0);
    expect_resp("busy div original response", 64'd33, 4'h3, 6'd9, 80);

    issue_req("flush div", 3'b100, 1'b0, 64'd77, 64'd5, 4'h5, 6'd11);
    `TB_TICK(clk)
    `TB_TICK(clk)
    flush = 1'b1;
    `TB_TICK(clk)
    flush = 1'b0;
    tb_check1("flush clears response", resp_valid, 1'b0);
    tb_check1("flush returns ready", req_ready, 1'b1);

    // ===== 刀X 扩充: MUL 角例矩阵(零/±1/±2^63/小×大/奇有效位/swap 两向) =====
    // MUL×0 / 0×MUL 双向: R1(零特判漏 swap 侧→count 绕回)的定向杀手,
    // max_cycles=6 收紧——绕回形态 ~34 拍必超时暴露。
    run_case_tight("mul x zero", 3'b000, 1'b0, 64'hdead_beef_cafe_f00d, 64'd0, 6);
    run_case_tight("zero x mul", 3'b000, 1'b0, 64'd0, 64'hdead_beef_cafe_f00d, 6);
    run_case_tight("mulh zero", 3'b011, 1'b0, 64'd0, 64'hffff_ffff_ffff_ffff, 6);
    run_case_tight("mulw zero wraps", 3'b000, 1'b1, 64'h1_0000_0000, 64'd7, 6);
    // 小值早退出行为验证: eff<=6 → 迭代 <=3 拍,max_cycles=8;无早退出(32+拍)必超时
    run_case_tight("small early-exit", 3'b000, 1'b0, 64'd63, 64'd63, 8);
    run_case_tight("one x one", 3'b000, 1'b0, 64'd1, 64'd1, 8);
    // swap 两向 + 小×大(CLZ 打在 min 侧)
    run_case_tight("swap small x big", 3'b000, 1'b0, 64'd5, 64'h7fff_ffff_ffff_ffff, 10);
    run_case_tight("swap big x small", 3'b000, 1'b0, 64'h7fff_ffff_ffff_ffff, 64'd5, 10);
    // ±2^63 幅值(abs wrap 回 0x8000..0 非零,CLZ=0 全 32 拍)与 -1(abs=1 最短)
    run_case_g("int_min x int_min", 3'b001, 1'b0, 64'h8000_0000_0000_0000,
               64'h8000_0000_0000_0000);
    run_case_g("int_min mulhu", 3'b011, 1'b0, 64'h8000_0000_0000_0000, 64'd3);
    run_case_g("neg1 x neg1", 3'b000, 1'b0, 64'hffff_ffff_ffff_ffff,
               64'hffff_ffff_ffff_ffff);
    run_case_g("neg1 mulh", 3'b001, 1'b0, 64'hffff_ffff_ffff_ffff, 64'd7);
    // MULHSU 高危: 负 × 大无符号(混合符号矩阵)
    run_case_g("mulhsu neg x maxu", 3'b010, 1'b0, 64'hffff_ffff_ffff_fffe,
               64'hffff_ffff_ffff_ffff);
    run_case_g("mulhsu min x maxu", 3'b010, 1'b0, 64'h8000_0000_0000_0000,
               64'hffff_ffff_ffff_ffff);
    run_case_g("mulhsu neg x small", 3'b010, 1'b0, 64'hffff_ffff_0000_0000, 64'd9);
    // 奇有效位(eff=5,clz 向下取偶多跑一组)
    run_case_g("odd eff bits", 3'b000, 1'b0, 64'd21, 64'd19);
    run_case_g("odd eff mulh", 3'b001, 1'b0, 64'h1f, 64'hffff_ffff_ffff_fff1);

    // ===== 8×8 穷举(64×64 小值全交叉 × 4 变体, 杀末拍 off-by-one) =====
    begin : exhaustive_small
      integer ei, ej;
      reg [`XLEN-1:0] eva, evb;
      for (ei = 0; ei < 64; ei = ei + 1) begin
        for (ej = 0; ej < 64; ej = ej + 1) begin
          eva = ei;  // integer→64 位経由中转,禁止对 32 位 integer 做 [63:0] 越界切片(高位 X)
          evb = ej;
          run_case_g("exh low mul", 3'b000, 1'b0, eva, evb);
          run_case_g("exh mulh", 3'b001, 1'b0,
                     {eva[5:0], 58'h0}, {evb[5:0], 58'h0});
          run_case_g("exh mulhsu", 3'b010, 1'b0,
                     {eva[5:0], 58'h2a}, evb);
          run_case_g("exh mulhu", 3'b011, 1'b0,
                     {eva[5:0], 58'h15}, {evb[5:0], 58'h0});
        end
      end
    end

    // ===== 随机 64 位全宽(500 组 × 5 变体) =====
    begin : random_wide
      integer ri;
      reg [`XLEN-1:0] ra, rb;
      for (ri = 0; ri < 500; ri = ri + 1) begin
        ra = {$random, $random};
        rb = {$random, $random};
        run_case_g("rand mul", 3'b000, 1'b0, ra, rb);
        run_case_g("rand mulh", 3'b001, 1'b0, ra, rb);
        run_case_g("rand mulhsu", 3'b010, 1'b0, ra, rb);
        run_case_g("rand mulhu", 3'b011, 1'b0, ra, rb);
        run_case_g("rand mulw", 3'b000, 1'b1, ra, rb);
      end
    end

    // ===== kill 用例(解除恒 0——RTL kill 防线此前零测试覆盖) =====
    // kill 中途: 全宽 MUL(32 拍窗口), 第 3 拍 kill 命中(req rob=8 严格年轻于 kill=4)
    rob_head_idx = 4'h0;
    issue_req("kill mid mul", 3'b000, 1'b0, 64'hffff_ffff_ffff_fff7,
              64'hf777_7777_7777_7771, 4'h8, 6'd17);
    `TB_TICK(clk)
    `TB_TICK(clk)
    kill_valid = 1'b1;
    kill_rob_idx = 4'h4;
    `TB_TICK(clk)
    kill_valid = 1'b0;
    tb_check1("kill mid mul no resp", resp_valid, 1'b0);
    tb_check1("kill mid mul ready", req_ready, 1'b1);
    // RESP 拍 kill: 小操作数 MUL 完成驻留 RESP(不给 ready), kill 当拍组合抹 resp_valid
    issue_req("kill at resp", 3'b000, 1'b0, 64'd6, 64'd7, 4'h9, 6'd18);
    begin : kill_resp_wait
      integer kw;
      kw = 0;
      while (!resp_valid && kw < 10) begin
        kw = kw + 1;
        `TB_TICK(clk)
      end
      tb_check1("resp reached before kill", resp_valid, 1'b1);
      kill_valid = 1'b1;
      kill_rob_idx = 4'h4;
      #1;  // 组合传播稳定(clk 无边沿),验证 kill 对 resp_valid 的当拍组合抹
      tb_check1("kill at resp combinationally masks", resp_valid, 1'b0);
      `TB_TICK(clk)
      kill_valid = 1'b0;
      tb_check1("kill at resp back to ready", req_ready, 1'b1);
    end
    // kill 不命中(req 更老): MUL 正常完成
    issue_req("kill miss older", 3'b000, 1'b0, 64'd11, 64'd13, 4'h2, 6'd19);
    `TB_TICK(clk)
    kill_valid = 1'b1;
    kill_rob_idx = 4'h6;  // req rob=2 更老(2-0 <= 6-0), 不该被杀
    `TB_TICK(clk)
    kill_valid = 1'b0;
    expect_resp("kill miss survives", 64'd143, 4'h2, 6'd19, 20);
    // flush MUL 中途(既有用例只测 DIV)
    issue_req("flush mid mul", 3'b000, 1'b0, 64'hffff_ffff_ffff_fff7,
              64'hf777_7777_7777_7771, 4'h5, 6'd11);
    `TB_TICK(clk)
    `TB_TICK(clk)
    flush = 1'b1;
    `TB_TICK(clk)
    flush = 1'b0;
    tb_check1("flush mid mul clears response", resp_valid, 1'b0);
    tb_check1("flush mid mul returns ready", req_ready, 1'b1);

    tb_finish("tb_ooo_muldiv_unit");
  end

  // golden 自动期望版 run_case(穷举/随机用)
  task automatic run_case_g;
    input [1023:0] name;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    begin
      issue_req(name, funct3, word_op, src1, src2, 4'ha, 6'd21);
      expect_resp(name, mul_golden(funct3, word_op, src1, src2), 4'ha, 6'd21, 80);
    end
  endtask

  // 收紧 max_cycles 版(早退出行为级验证: 无早退出必超时)
  task automatic run_case_tight;
    input [1023:0] name;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input integer max_cycles;
    begin
      issue_req(name, funct3, word_op, src1, src2, 4'ha, 6'd21);
      expect_resp(name, mul_golden(funct3, word_op, src1, src2), 4'ha, 6'd21,
                  max_cycles);
    end
  endtask

endmodule
