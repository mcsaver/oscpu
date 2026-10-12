`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_backend_ranked_credit;
  reg clk=0;always #5 clk=~clk;
  reg rst=1;
  reg [1:0] fv=0, offer=0;
  reg [9:0] slots=0;
  reg [127:0] raw=0;
  wire [1:0] fr,want,fire;
  wire [9:0] chosen;
  wire [17:0] tag;
  R64Backend dut(
    .serial_retire_candidate_o(),
    .direction_invalidate_i(1'b0),.direction_train_valid_o(),.direction_train_pc_o(),.direction_train_taken_o(),
    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .resolved_value_valid_i(2'b0), .resolved_value_tag_i(18'b0), .resolved_value_data_i(128'b0),
    .clk(clk),.rst(rst),.flush_i(1'b0),.stop_i(1'b0),.effect_i(12'b0),
    .reuse_block_i(32'b0),.fetch_valid_i(fv),.fetch_ready_o(fr),
    .fetch_canonical_i(66'b0),.fetch_control_i(70'b0),
    .fetch_sequential_npc_i({64'd8,64'd4}),.fetch_pc_i({64'd4,64'd0}),
    .fetch_raw_i(raw),.fetch_pred_npc_i({64'd8,64'd4}),.fetch_length_i(8'h44),
    .fetch_exception_i(2'b0),.fetch_cause_i(12'b0),.fetch_tval_i(128'b0),
    .commit_ready_i(2'b11),
    .lsu_reserve_want_o(want),.lsu_reserve_fire_o(fire),
    .lsu_reserve_ready_i(offer),.lsu_reserve_slot_i(slots),
    .lsu_reserve_slot_o(chosen),.lsu_reserve_tag_o(tag),
    .lsu_ready_i(2'b0),.fp_ready_i(1'b0),.serial_ready_i(1'b0),
    .store_done_valid_i(1'b0),.store_done_tag_i(9'b0),
    .store_done_error_i(1'b0),.store_done_tval_i(64'b0),
    .external_valid_i(4'b0),.external_request_i(4'b0),
    .external_tag_i(36'b0),.external_result_i({(4*`R64_RESULT_W){1'b0}})
  );
  task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
  task check;input yes;input[511:0] why;begin if(yes!==1'b1)$fatal(1,"%0s",why);end endtask
  task reset;
    begin fv=0;rst=1;tick();rst=0;end
  endtask
  task enqueue;input[31:0] first,second;
    begin
      raw={32'b0,second,32'b0,first};fv=3;#1;
      check(fr==3,"empty decode did not accept a dense pair");tick();fv=0;#1;
    end
  endtask
  task await_reserve;integer waited;
    begin
      waited=0;
      while(fire==0 && waited<12)begin tick();waited=waited+1;end
      check(fire!=0,"ranked offer failed bounded dispatch progress");
    end
  endtask
  reg[8:0] first_tag;
  initial begin
    reset();offer=1;slots={5'd19,5'd7};
    enqueue(32'h00100093,32'h00003103); // ADDI then LD: MEM rank zero is lane one.
    await_reserve();
    check(fire==2 && dut.birth_w==3 && chosen[5+:5]==7,
          "one credit was not assigned to the lone lane-one MEM");
    tick();
    reset();offer=1;slots={5'd19,5'd7};
    enqueue(32'h00003083,32'h00003103);
    await_reserve();
    check(fire==1 && dut.birth_w==1 && chosen[0+:5]==7,
          "one credit overbooked a dual-MEM pair");
    first_tag=tag[0+:9];tick();offer=0;
    repeat(5)begin #1;check(fire==0,"consumed credit was reused");tick();end
    offer=1;slots={5'd19,5'd11};#1;await_reserve();
    check(fire==1 && chosen[0+:5]==11 && tag[0+:9]!=first_tag,
          "remaining MEM lost dense compaction or unique ownership");
    tick();
    reset();offer=3;slots={5'd9,5'd4};
    enqueue(32'h00003083,32'h00003103);await_reserve();
    check(fire==3 && chosen=={5'd9,5'd4} && tag[0+:5]!=tag[9+:5],
          "two ranked credits failed atomic distinct-slot dual birth");
    tick();
    $display("[PASS] tb_r64_backend_ranked_credit lane1-only/single-credit/compaction/dual");$finish;
  end
endmodule
