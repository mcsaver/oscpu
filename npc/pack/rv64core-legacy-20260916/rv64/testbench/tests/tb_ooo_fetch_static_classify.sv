`timescale 1ns/1ps
`include "define.v"
`include "common/OooSlotFacts.v"

module tb_ooo_fetch_static_classify;
  `include "tb_common.svh"

  reg [`INST_W-1:0] inst;
  reg [`INST_W-1:0] peer_inst;
  reg peer_is_enter;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts;

  wire fp_load;
  wire fp_store;
  wire fp_move_to_fpr;
  wire fp_move_to_gpr;
  wire fp_class;
  wire fp_sgnj;
  wire fp_addsub;
  wire fp_mul;
  wire fp_fma;
  wire fp_div;
  wire fp_sqrt;
  wire fp_minmax;
  wire fp_compare;
  wire fp_convert_to_fpr;
  wire fp_convert_to_gpr;
  wire fp_unused;
  wire fp_double;
  wire fp_gpr_write_unused;

  integer i;
  reg [`OOO_SLOT_STATIC_FACTS_W-1:0] expected;

  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST  = 32'h4070_5013;

  OooFetchStaticClassify dut (
    .inst_i(inst),
    .semihost_peer_inst_i(peer_inst),
    .semihost_peer_is_enter_i(peer_is_enter),
    .static_facts_o(static_facts)
  );

  OooFpDecode legacy_fp_decode (
    .decode_valid_i(1'b1),
    .inst_i(inst),
    .fp_load_o(fp_load),
    .fp_store_o(fp_store),
    .fp_move_to_fpr_o(fp_move_to_fpr),
    .fp_move_to_gpr_o(fp_move_to_gpr),
    .fp_class_o(fp_class),
    .fp_sgnj_o(fp_sgnj),
    .fp_addsub_o(fp_addsub),
    .fp_mul_o(fp_mul),
    .fp_fma_o(fp_fma),
    .fp_div_o(fp_div),
    .fp_sqrt_o(fp_sqrt),
    .fp_minmax_o(fp_minmax),
    .fp_compare_o(fp_compare),
    .fp_convert_to_fpr_o(fp_convert_to_fpr),
    .fp_convert_to_gpr_o(fp_convert_to_gpr),
    .fp_o(fp_unused),
    .fp_double_o(fp_double),
    .fp_gpr_write_o(fp_gpr_write_unused)
  );

  task automatic check_current;
    input [8*48-1:0] label;
    begin
      #1;
      expected = {`OOO_SLOT_STATIC_FACTS_W{1'b0}};
      expected[`OOO_SLOT_STATIC_FACT_FP_LOAD] = fp_load;
      expected[`OOO_SLOT_STATIC_FACT_FP_STORE] = fp_store;
      expected[`OOO_SLOT_STATIC_FACT_FP_MOVE_TO_FPR] = fp_move_to_fpr;
      expected[`OOO_SLOT_STATIC_FACT_FP_MOVE_TO_GPR] = fp_move_to_gpr;
      expected[`OOO_SLOT_STATIC_FACT_FP_CLASS] = fp_class;
      expected[`OOO_SLOT_STATIC_FACT_FP_SGNJ] = fp_sgnj;
      expected[`OOO_SLOT_STATIC_FACT_FP_ADDSUB] = fp_addsub;
      expected[`OOO_SLOT_STATIC_FACT_FP_MUL] = fp_mul;
      expected[`OOO_SLOT_STATIC_FACT_FP_FMA] = fp_fma;
      expected[`OOO_SLOT_STATIC_FACT_FP_DIV] = fp_div;
      expected[`OOO_SLOT_STATIC_FACT_FP_SQRT] = fp_sqrt;
      expected[`OOO_SLOT_STATIC_FACT_FP_MINMAX] = fp_minmax;
      expected[`OOO_SLOT_STATIC_FACT_FP_COMPARE] = fp_compare;
      expected[`OOO_SLOT_STATIC_FACT_FP_CONVERT_TO_FPR] = fp_convert_to_fpr;
      expected[`OOO_SLOT_STATIC_FACT_FP_CONVERT_TO_GPR] = fp_convert_to_gpr;
      expected[`OOO_SLOT_STATIC_FACT_FP_DOUBLE_RAW] = fp_double;
      expected[`OOO_SLOT_STATIC_FACT_FP_DYN_RM_BEARING] =
          (fp_addsub || fp_mul || fp_fma || fp_div || fp_sqrt ||
           fp_convert_to_fpr || fp_convert_to_gpr) &&
          (inst[14:12] == 3'b111);
      expected[`OOO_SLOT_STATIC_FACT_SEMIHOST_PEER_SIGNATURE] =
          peer_is_enter ? (peer_inst == SEMIHOST_ENTER_INST) :
                          (peer_inst == SEMIHOST_EXIT_INST);
      if (static_facts !== expected) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s inst=%h peer=%h orient=%b got=%h expected=%h",
                 label, inst, peer_inst, peer_is_enter,
                 static_facts, expected);
      end
    end
  endtask

  task automatic directed;
    input [`INST_W-1:0] test_inst;
    input [8*48-1:0] label;
    begin
      inst = test_inst;
      peer_inst = 32'h0000_0013;
      peer_is_enter = 1'b0;
      check_current(label);
    end
  endtask

  initial begin
    tb_errors = 0;
    directed({12'h000, 5'd2, `FUNCT3_LW, 5'd1, `OPCODE_LOAD_FP},
             "fp load");
    directed({7'h00, 5'd3, 5'd2, `FUNCT3_SW, 5'h00, `OPCODE_STORE_FP},
             "fp store");
    directed({7'b1111000, 5'd0, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "move to fpr");
    directed({7'b1110000, 5'd0, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "move to gpr");
    directed({7'b1110000, 5'd0, 5'd2, 3'b001, 5'd1, `OPCODE_OP_FP},
             "class");
    directed({7'b0010000, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "sgnj");
    directed({7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "addsub");
    directed({7'b0001000, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "mul");
    directed({5'd4, 2'b00, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_MADD},
             "fma");
    directed({7'b0001100, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "div");
    directed({7'b0101100, 5'd0, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "sqrt");
    directed({7'b0010100, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "minmax");
    directed({7'b1010000, 5'd3, 5'd2, 3'b010, 5'd1, `OPCODE_OP_FP},
             "compare");
    directed({7'b1101000, 5'd0, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "convert to fpr");
    directed({7'b1100000, 5'd0, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "convert to gpr");
    directed({7'b0000001, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
             "double raw");
    directed({7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, `OPCODE_OP_FP},
             "dynamic rm bearing");

    inst = 32'h0010_0073;
    peer_inst = SEMIHOST_EXIT_INST;
    peer_is_enter = 1'b0;
    check_current("slot0 semihost peer signature");
    peer_inst = SEMIHOST_ENTER_INST;
    peer_is_enter = 1'b1;
    check_current("slot1 semihost peer signature");
    peer_inst = SEMIHOST_EXIT_INST ^ 32'h1;
    peer_is_enter = 1'b0;
    check_current("semihost near miss");

    for (i = 0; i < 1000; i = i + 1) begin
      inst = $urandom;
      peer_inst = $urandom;
      peer_is_enter = $urandom_range(0, 1);
      check_current("random legacy fp equivalence");
    end

    tb_finish("tb_ooo_fetch_static_classify");
  end
endmodule
