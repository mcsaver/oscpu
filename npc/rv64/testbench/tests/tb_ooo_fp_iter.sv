`include "define.v"

module tb_ooo_fp_iter;
  `include "tb_common.svh"

  localparam DIVIDEND_W = 108;
  localparam DIVISOR_W = 53;
  localparam QUOTIENT_W = 56;
  localparam SQRT_VALUE_W = 112;
  localparam SQRT_ROOT_W = 56;

  reg clk;
  reg rst;
  reg flush;

  reg div_start;
  reg [DIVIDEND_W-1:0] div_dividend;
  reg [DIVISOR_W-1:0] div_divisor;
  wire div_busy;
  wire div_done;
  wire [QUOTIENT_W-1:0] div_quotient;
  wire div_remainder_nonzero;

  reg sqrt_start;
  reg [SQRT_VALUE_W-1:0] sqrt_value;
  wire sqrt_busy;
  wire sqrt_done;
  wire [SQRT_ROOT_W-1:0] sqrt_root;
  wire sqrt_remainder_nonzero;

  OooFpDivIter u_div (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .start_i(div_start),
    .dividend_i(div_dividend),
    .divisor_i(div_divisor),
    .busy_o(div_busy),
    .done_o(div_done),
    .quotient_o(div_quotient),
    .remainder_nonzero_o(div_remainder_nonzero)
  );

  OooFpSqrtIter u_sqrt (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .start_i(sqrt_start),
    .value_i(sqrt_value),
    .busy_o(sqrt_busy),
    .done_o(sqrt_done),
    .root_o(sqrt_root),
    .remainder_nonzero_o(sqrt_remainder_nonzero)
  );

  task automatic tb_check56;
    input [1023:0] what;
    input [55:0] got;
    input [55:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%014x expected=0x%014x",
                 what, got, exp);
      end
    end
  endtask

  function automatic [55:0] isqrt112;
    input [111:0] value;
    integer bit_idx;
    reg [55:0] root;
    reg [55:0] trial_root;
    reg [113:0] trial_square;
    begin
      root = 56'b0;
      for (bit_idx = 55; bit_idx >= 0; bit_idx = bit_idx - 1) begin
        trial_root = root | (56'h1 << bit_idx);
        trial_square = {58'b0, trial_root} * {58'b0, trial_root};
        if (trial_square <= {2'b0, value}) begin
          root = trial_root;
        end
      end
      isqrt112 = root;
    end
  endfunction

  task automatic reset_dut;
    begin
      rst = 1'b1;
      flush = 1'b0;
      div_start = 1'b0;
      div_dividend = {DIVIDEND_W{1'b0}};
      div_divisor = {DIVISOR_W{1'b0}};
      sqrt_start = 1'b0;
      sqrt_value = {SQRT_VALUE_W{1'b0}};
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic wait_div_done;
    input [1023:0] name;
    input [55:0] exp_quotient;
    input exp_remainder_nonzero;
    integer guard;
    begin
      guard = 0;
      while (!div_done && guard < 80) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " done"}, div_done, 1'b1);
      tb_check56({name, " quotient"}, div_quotient, exp_quotient);
      tb_check1({name, " remainder"}, div_remainder_nonzero,
                exp_remainder_nonzero);
      `TB_TICK(clk);
      #1;
      tb_check1({name, " done pulse"}, div_done, 1'b0);
    end
  endtask

  task automatic run_div_case;
    input [1023:0] name;
    input [107:0] dividend;
    input [52:0] divisor;
    reg [107:0] divisor_ext;
    reg [55:0] exp_quotient;
    reg exp_remainder_nonzero;
    begin
      divisor_ext = {{(DIVIDEND_W-DIVISOR_W){1'b0}}, divisor};
      exp_quotient = dividend / divisor_ext;
      exp_remainder_nonzero = |(dividend % divisor_ext);

      div_dividend = dividend;
      div_divisor = divisor;
      div_start = 1'b1;
      `TB_TICK(clk);
      div_start = 1'b0;
      tb_check1({name, " busy after start"}, div_busy, 1'b1);
      wait_div_done(name, exp_quotient, exp_remainder_nonzero);
    end
  endtask

  task automatic run_div_busy_ignores_start;
    reg [107:0] divisor_ext;
    reg [55:0] exp_quotient;
    reg exp_remainder_nonzero;
    begin
      div_dividend = 108'd768;
      div_divisor = 53'h0000_0000_0003;
      divisor_ext = {{(DIVIDEND_W-DIVISOR_W){1'b0}}, div_divisor};
      exp_quotient = div_dividend / divisor_ext;
      exp_remainder_nonzero = |(div_dividend % divisor_ext);
      div_start = 1'b1;
      `TB_TICK(clk);

      div_dividend = 108'd32;
      div_divisor = 53'h0000_0000_0002;
      `TB_TICK(clk);
      div_start = 1'b0;
      wait_div_done("div ignores busy start", exp_quotient,
                    exp_remainder_nonzero);
    end
  endtask

  task automatic run_div_flush_case;
    begin
      div_dividend = 108'h000_0000_0000_0000_0000_0012_3456;
      div_divisor = 53'h0000_0000_1234;
      div_start = 1'b1;
      `TB_TICK(clk);
      div_start = 1'b0;
      repeat (4) `TB_TICK(clk);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      tb_check1("div flush clears busy", div_busy, 1'b0);
      tb_check1("div flush clears done", div_done, 1'b0);
    end
  endtask

  task automatic wait_sqrt_done;
    input [1023:0] name;
    input [55:0] exp_root;
    input exp_remainder_nonzero;
    integer guard;
    begin
      guard = 0;
      while (!sqrt_done && guard < 80) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " done"}, sqrt_done, 1'b1);
      tb_check56({name, " root"}, sqrt_root, exp_root);
      tb_check1({name, " remainder"}, sqrt_remainder_nonzero,
                exp_remainder_nonzero);
      `TB_TICK(clk);
      #1;
      tb_check1({name, " done pulse"}, sqrt_done, 1'b0);
    end
  endtask

  task automatic run_sqrt_case;
    input [1023:0] name;
    input [111:0] value;
    reg [55:0] exp_root;
    reg [113:0] root_square;
    reg exp_remainder_nonzero;
    begin
      exp_root = isqrt112(value);
      root_square = {58'b0, exp_root} * {58'b0, exp_root};
      exp_remainder_nonzero = root_square != {2'b0, value};

      sqrt_value = value;
      sqrt_start = 1'b1;
      `TB_TICK(clk);
      sqrt_start = 1'b0;
      tb_check1({name, " busy after start"}, sqrt_busy, 1'b1);
      wait_sqrt_done(name, exp_root, exp_remainder_nonzero);
    end
  endtask

  task automatic run_sqrt_busy_ignores_start;
    reg [111:0] first_value;
    reg [55:0] exp_root;
    reg [113:0] root_square;
    reg exp_remainder_nonzero;
    begin
      first_value = 112'h0000_0000_0000_0000_0000_0000_0400;
      exp_root = isqrt112(first_value);
      root_square = {58'b0, exp_root} * {58'b0, exp_root};
      exp_remainder_nonzero = root_square != {2'b0, first_value};

      sqrt_value = first_value;
      sqrt_start = 1'b1;
      `TB_TICK(clk);
      sqrt_value = 112'h0000_0000_0000_0000_0000_0000_0009;
      `TB_TICK(clk);
      sqrt_start = 1'b0;
      wait_sqrt_done("sqrt ignores busy start", exp_root,
                     exp_remainder_nonzero);
    end
  endtask

  task automatic run_sqrt_flush_case;
    begin
      sqrt_value = 112'h0000_0000_0000_0000_0000_1234_5678;
      sqrt_start = 1'b1;
      `TB_TICK(clk);
      sqrt_start = 1'b0;
      repeat (4) `TB_TICK(clk);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      tb_check1("sqrt flush clears busy", sqrt_busy, 1'b0);
      tb_check1("sqrt flush clears done", sqrt_done, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();

    run_div_case("div zero dividend", 108'h0, 53'h1);
    run_div_case("div exact", 108'd768,
                 53'h0000_0000_0003);
    run_div_case("div remainder", 108'h000_0000_0000_0000_0012_3456_789b,
                 53'h0000_0000_0123);
    run_div_case("div max quotient",
                 {52'b0, 56'hffff_ffff_ffff_fe},
                 53'h0000_0000_0002);
    run_div_busy_ignores_start();
    run_div_flush_case();

    run_sqrt_case("sqrt zero", 112'h0);
    run_sqrt_case("sqrt one", 112'h1);
    run_sqrt_case("sqrt non-square", 112'h2);
    run_sqrt_case("sqrt medium",
                  112'h0000_0000_0000_0000_0001_2345_6789);
    run_sqrt_case("sqrt high",
                  112'h0000_0000_0000_ffff_ffff_ffff_ffff);
    run_sqrt_busy_ignores_start();
    run_sqrt_flush_case();

    tb_finish("tb_ooo_fp_iter");
  end
endmodule
