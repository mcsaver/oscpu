`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_direct_mem_execute;
  localparam U = `R64_UOP_W, T = 9, S = 5;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg [4:0] head = 0;
  reg [1:0] valid = 0, local_alu_valid = 3;
  reg [17:0] tags = 0;
  reg [9:0] slots = 0;
  reg [2*U-1:0] uops = 0;
  reg [383:0] operands = 0;
  reg [5:0] classes = 0;
  reg fpready = 1, sready = 1;
  wire [1:0] ready[0:1], fire[0:1];
  wire [17:0] ltag[0:1];
  wire [9:0] lslot[0:1];
  wire [2*U-1:0] luop[0:1];
  wire [383:0] lop[0:1];
  wire ff[0:1], sf[0:1];
  wire [8:0] ft[0:1], st[0:1];
  wire [U-1:0] fu[0:1], su[0:1];
  wire [191:0] fo[0:1], so[0:1];
  R64ExecuteReference #(
    .RAW_MEM(1),
    .RAW_FP(1),
    .RAW_SERIAL(1)
  ) dut0 (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .cancel_candidates_i(32'b0),
    .cancel_active_i(1'b0),
    .rob_head_i(head),
    .in_valid_i(valid),
    .in_ready_o(ready[0]),
    .in_tag_i(tags),
    .in_mem_slot_i(slots),
    .in_uop_i(uops),
    .in_class_i(classes),
    .in_operand_i(operands),
    .in_gpr_dst_i(12'b0),
    .in_alu_control_i(74'b0),
    .in_add_source_i(10'b0),
    .in_shift_amount_i(12'b0),
    .in_branch_imm_i(42'b0),
    .in_branch_control_i(10'b0),
    .result_ready_i(5'b11111),
    .lsu_ready_i(2'b11),
    .lsu_fire_o(fire[0]),
    .lsu_tag_o(ltag[0]),
    .lsu_slot_o(lslot[0]),
    .lsu_uop_o(luop[0]),
    .lsu_operand_o(lop[0]),
    .fp_ready_i(fpready),
    .fp_fire_o(ff[0]),
    .fp_tag_o(ft[0]),
    .fp_uop_o(fu[0]),
    .fp_operand_o(fo[0]),
    .serial_ready_i(sready),
    .serial_fire_o(sf[0]),
    .serial_tag_o(st[0]),
    .serial_uop_o(su[0]),
    .serial_operand_o(so[0])
  );
  R64Execute #(
    .RAW_MEM(1),
    .RAW_FP(1),
    .RAW_SERIAL(1),
    .DIRECT_MEM_BIND(1),
    .SPLIT_VALUE_VALID(1)
  ) dut1 (
    .in_local_alu_valid_i(local_alu_valid),
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .cancel_candidates_i(32'b0),
    .cancel_active_i(1'b0),
    .rob_head_i(head),
    .in_valid_i(valid),
    .in_ready_o(ready[1]),
    .in_tag_i(tags),
    .in_mem_slot_i(slots),
    .in_uop_i(uops),
    .in_class_i(classes),
    .in_operand_i(operands),
    .in_gpr_dst_i(12'b0),
    .in_alu_control_i(74'b0),
    .in_add_source_i(10'b0),
    .in_shift_amount_i(12'b0),
    .in_branch_imm_i(42'b0),
    .in_branch_control_i(10'b0),
    .result_ready_i(5'b11111),
    .lsu_ready_i(2'b11),
    .lsu_fire_o(fire[1]),
    .lsu_tag_o(ltag[1]),
    .lsu_slot_o(lslot[1]),
    .lsu_uop_o(luop[1]),
    .lsu_operand_o(lop[1]),
    .fp_ready_i(fpready),
    .fp_fire_o(ff[1]),
    .fp_tag_o(ft[1]),
    .fp_uop_o(fu[1]),
    .fp_operand_o(fo[1]),
    .serial_ready_i(sready),
    .serial_fire_o(sf[1]),
    .serial_tag_o(st[1]),
    .serial_uop_o(su[1]),
    .serial_operand_o(so[1])
  );
  reg [31:0] rng = 32'h93d21679;
  function [31:0] random_word;
    begin
      rng = rng ^ (rng << 13);
      rng = rng ^ (rng >> 17);
      rng = rng ^ (rng << 5);
      random_word = rng;
    end
  endfunction
  integer
      i,
      j,
      k,
      m,
      age0,
      age1,
      cut,
      idx,
      match_count,
      accepted = 0,
      swapped = 0,
      lane1_only = 0,
      canceled = 0,
      mixed = 0;
  reg count_vector = 1;
  task check;
    begin
      if (ready[0] !== ready[1]) $fatal(1, "direct MEM changes accepted RR set iter%0d", i);
      if (ff[0] !== ff[1] || sf[0] !== sf[1]) $fatal(1, "direct MEM changes shared FP/Serial fire");
      if (ff[0] && {ft[0], fu[0], fo[0]} !== {ft[1], fu[1], fo[1]}) $fatal(1, "FP owner changed");
      if (sf[0] && {st[0], su[0], so[0]} !== {st[1], su[1], so[1]})
        $fatal(1, "Serial owner changed");
      if ((integer'(fire[0][0]) + integer'(fire[0][1])) !=
          (integer'(fire[1][0]) + integer'(fire[1][1])))
        $fatal(1, "MEM bind cardinality changed");
      for (j = 0; j < 2; j = j + 1)
      if (fire[0][j]) begin
        match_count = 0;
        for (k = 0; k < 2; k = k + 1)
        if (fire[1][k] && ltag[0][j*T+:T] == ltag[1][k*T+:T]) begin
          match_count = match_count + 1;
          if ({lslot[0][j*S+:S], luop[0][j*U+:U], lop[0][j*192+:192]} !==
              {lslot[1][k*S+:S], luop[1][k*U+:U], lop[1][k*192+:192]})
            $fatal(1, "MEM full owner payload changed");
          if (count_vector && j != k) swapped = swapped + 1;
        end
        if (match_count != 1) $fatal(1, "MEM bind missing/duplicate fulltag");
        if (count_vector) accepted = accepted + 1;
      end
      if (count_vector && fire[1] == 2'b10) lane1_only = lane1_only + 1;
      if (count_vector && |kill) canceled = canceled + 1;
      if (count_vector && (ff[1] || sf[1]) && |fire[1]) mixed = mixed + 1;
    end
  endtask
  initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    for (i = 0; i < 20000; i = i + 1) begin
      @(negedge clk);
      head = 5'(random_word());
      age0 = integer'(random_word() & 31);
      age1 = (age0 + 1 + integer'(random_word() % 31)) % 32;
      tags = {4'(i >> 4), 5'(integer'(head) + age1), 4'(i), 5'(integer'(head) + age0)};
      slots = {5'(i % 20), 5'((i + 3) % 20)};
      valid = 2'(random_word());
      classes[0+:3] = (i % 5 == 0) ? `R64_C_FP : `R64_C_MEM;
      classes[3+:3] = (i % 7 == 0) ? `R64_C_SERIAL : ((i % 3 == 0) ? `R64_C_FP : `R64_C_MEM);
      fpready = 1'(random_word());
      sready = 1'(random_word());
      flush = i % 47 == 0;
      rst = i % 211 == 0;
      kill = 0;
      cut = integer'(random_word() & 31);
      if (i % 4 == 0)
        for (m = 0; m < 32; m = m + 1) begin
          idx = (integer'(head) + m) % 32;
          if (m > cut) kill[idx] = 1;
        end
      for (m = 0; m < 2 * U; m = m + 1) uops[m] = 1'(random_word());
      for (m = 0; m < 384; m = m + 1) operands[m] = 1'(random_word());
      // Toggling the fast channel cannot influence any shared resource, even
      // for mixed classes, cancellation, ordering and two physical MEM lanes.
      count_vector=0;local_alu_valid=0;#1;check();
      count_vector=1;local_alu_valid=3;#1;check();
    end
    @(negedge clk);
    valid = 0;
    rst   = 0;
    flush = 0;
    kill  = 0;
    if (accepted < 5000 || swapped < 3000 || lane1_only < 1000 || mixed < 300 || canceled < 1000)
      $fatal(1, "direct MEM coverage not reached");
    // A local-only ALU can consume alongside a registered MEM, without
    // exposing that ALU to shared priority or inventing a MEM fire.
    @(negedge clk);head=0;classes={`R64_C_MEM,`R64_C_ALU};
    tags={9'd2,9'd1};slots={5'd4,5'd3};uops=0;operands=0;
    valid=2;local_alu_valid=1;fpready=1;sready=1;#1;
    if(ready[1]!==3||fire[1]!==2||ltag[1][9+:9]!==9'd2||ff[1]||sf[1])
      $fatal(1,"local ALU/shared MEM split acceptance failed");
    @(negedge clk);valid=0;local_alu_valid=0;
    repeat(5)@(negedge clk);
    // Fast branch candidates use their own age arbitration when Q-ready=0.
    classes={`R64_C_BRANCH,`R64_C_BRANCH};tags={9'd4,9'd3};
    local_alu_valid=3;#1;
    if(ready[1]!==1||fire[1]!==0||ff[1]||sf[1])
      $fatal(1,"local-only dual branch arbitration failed");
    @(negedge clk);local_alu_valid=0;
    repeat(5)@(negedge clk);
    $display("EXECUTE_SPLIT_VALID shared_vectors=20000 fast_toggles=2 mixed_ALU_MEM=1 dual_branch=1");
    $display(
        "[PASS] tb_r64_direct_mem_execute vectors=%0d accepted=%0d swapped=%0d lane1_only=%0d mixed=%0d canceled=%0d",
        i, accepted, swapped, lane1_only, mixed, canceled);
    $finish;
  end
endmodule
