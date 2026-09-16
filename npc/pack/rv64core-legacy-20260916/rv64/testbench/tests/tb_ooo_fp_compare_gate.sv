`include "define.v"

// OooFpCompareGate 专属 testbench：FEQ/FLT/FLE 与 FMIN/FMAX（含 NaN/sNaN/±0）。
module tb_ooo_fp_compare_gate;
  `include "tb_common.svh"

  reg [`XLEN-1:0] frs1, frs2;
  reg dbl;
  reg [2:0] cmp_op;
  reg is_max;
  wire [`XLEN-1:0] cmp_val, mm_val;
  wire [4:0] cmp_ff, mm_ff;

  OooFpCompareGate dut (
    .frs1_value_i(frs1),
    .frs2_value_i(frs2),
    .double_i(dbl),
    .cmp_op_i(cmp_op),
    .is_max_i(is_max),
    .compare_value_o(cmp_val),
    .compare_fflags_o(cmp_ff),
    .minmax_value_o(mm_val),
    .minmax_fflags_o(mm_ff)
  );

  task automatic chk_cmp;
    input [1023:0] what;
    input got_bit;
    input [4:0] exp_ff;
    begin
      #1;
      if (cmp_val !== {{(`XLEN-1){1'b0}}, got_bit})
        begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp bit=%0b", what, cmp_val, got_bit); end
      if (cmp_ff !== exp_ff)
        begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, cmp_ff, exp_ff); end
    end
  endtask

  task automatic chk_mm;
    input [1023:0] what;
    input [`XLEN-1:0] exp_val;
    input [4:0] exp_ff;
    begin
      #1;
      if (mm_val !== exp_val)
        begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp=0x%016x", what, mm_val, exp_val); end
      if (mm_ff !== exp_ff)
        begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, mm_ff, exp_ff); end
    end
  endtask

  localparam [`XLEN-1:0] D1   = 64'h3ff0000000000000; // 1.0
  localparam [`XLEN-1:0] D2   = 64'h4000000000000000; // 2.0
  localparam [`XLEN-1:0] DN1  = 64'hbff0000000000000; // -1.0
  localparam [`XLEN-1:0] DPZ  = 64'h0000000000000000; // +0
  localparam [`XLEN-1:0] DNZ  = 64'h8000000000000000; // -0
  localparam [`XLEN-1:0] DQNAN= 64'h7ff8000000000000;
  localparam [`XLEN-1:0] DSNAN= 64'h7ff0000000000001;

  initial begin
    tb_errors = 0;
    dbl = 1;

    // FEQ (op=010)
    cmp_op = 3'b010; frs1 = D1; frs2 = D1; chk_cmp("FEQ 1==1", 1'b1, 5'b00000);
    cmp_op = 3'b010; frs1 = D1; frs2 = D2; chk_cmp("FEQ 1==2", 1'b0, 5'b00000);
    cmp_op = 3'b010; frs1 = DPZ; frs2 = DNZ; chk_cmp("FEQ +0==-0", 1'b1, 5'b00000);
    cmp_op = 3'b010; frs1 = DQNAN; frs2 = D1; chk_cmp("FEQ qNaN", 1'b0, 5'b00000); // qNaN 不置 NV
    cmp_op = 3'b010; frs1 = DSNAN; frs2 = D1; chk_cmp("FEQ sNaN", 1'b0, 5'b10000);

    // FLT (op=001)
    cmp_op = 3'b001; frs1 = D1; frs2 = D2; chk_cmp("FLT 1<2", 1'b1, 5'b00000);
    cmp_op = 3'b001; frs1 = D2; frs2 = D1; chk_cmp("FLT 2<1", 1'b0, 5'b00000);
    cmp_op = 3'b001; frs1 = DN1; frs2 = D1; chk_cmp("FLT -1<1", 1'b1, 5'b00000);
    cmp_op = 3'b001; frs1 = DQNAN; frs2 = D1; chk_cmp("FLT qNaN", 1'b0, 5'b10000); // FLT/FLE qNaN 置 NV

    // FLE (op=000)
    cmp_op = 3'b000; frs1 = D1; frs2 = D1; chk_cmp("FLE 1<=1", 1'b1, 5'b00000);
    cmp_op = 3'b000; frs1 = D2; frs2 = D1; chk_cmp("FLE 2<=1", 1'b0, 5'b00000);

    // FMIN (is_max=0)
    is_max = 0;
    frs1 = D1; frs2 = D2; chk_mm("FMIN(1,2)", D1, 5'b00000);
    frs1 = DQNAN; frs2 = D2; chk_mm("FMIN(qNaN,2)", D2, 5'b00000);
    frs1 = D1; frs2 = DSNAN; chk_mm("FMIN(1,sNaN)", D1, 5'b10000);
    frs1 = DPZ; frs2 = DNZ; chk_mm("FMIN(+0,-0)", DNZ, 5'b00000);

    // FMAX (is_max=1)
    is_max = 1;
    frs1 = D1; frs2 = D2; chk_mm("FMAX(1,2)", D2, 5'b00000);
    frs1 = DPZ; frs2 = DNZ; chk_mm("FMAX(+0,-0)", DPZ, 5'b00000);
    frs1 = DQNAN; frs2 = DQNAN; chk_mm("FMAX(qNaN,qNaN)", DQNAN, 5'b00000);

    tb_finish("tb_ooo_fp_compare_gate");
  end
endmodule
