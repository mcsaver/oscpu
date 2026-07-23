`include "define.v"
`include "common/OooSlotFacts.v"
`include "tb_common.svh"

module tb_ooo_fetch_packet_fifo;
  localparam FETCH_PACKET_COUNT_W = 2;
  localparam FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1;

  reg clk;
  reg rst;
  reg clear;
  reg enqueue;
  reg [`XLEN-1:0] enqueue_pc0;
  reg [`XLEN-1:0] enqueue_pc1;
  reg [`XLEN-1:0] enqueue_next_pc0;
  reg [`XLEN-1:0] enqueue_next_pc1;
  reg [`XLEN-1:0] enqueue_packet_next_pc;
  reg [`XLEN-1:0] enqueue_fault_tval;
  reg [`INST_W-1:0] enqueue_inst0;
  reg [`INST_W-1:0] enqueue_inst1;
  reg [`CTRL_BUS_W-1:0] enqueue_ctrl0;
  reg [`CTRL_BUS_W-1:0] enqueue_ctrl1;
  reg [`OOO_SLOT_STATIC_FACTS_W-1:0] enqueue_static_facts0;
  reg [`OOO_SLOT_STATIC_FACTS_W-1:0] enqueue_static_facts1;
  reg [`REG_ADDR_W-1:0] enqueue_rs1_0;
  reg [`REG_ADDR_W-1:0] enqueue_rs2_0;
  reg [`REG_ADDR_W-1:0] enqueue_rd0;
  reg [`XLEN-1:0] enqueue_imm0;
  reg [`REG_ADDR_W-1:0] enqueue_rs1_1;
  reg [`REG_ADDR_W-1:0] enqueue_rs2_1;
  reg [`REG_ADDR_W-1:0] enqueue_rd1;
  reg [`XLEN-1:0] enqueue_imm1;
  reg [1:0] enqueue_resp0;
  reg [1:0] enqueue_resp1;
  reg enqueue_pred_taken0;
  reg enqueue_pred_taken1;
  reg [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx0;
  reg [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx1;
  reg enqueue_bht_valid0;
  reg enqueue_bht_valid1;
  reg enqueue_slot1_valid;
  reg pop;
  wire head_valid;
  wire [`XLEN-1:0] head_pc0;
  wire [`XLEN-1:0] head_pc1;
  wire [`XLEN-1:0] head_next_pc0;
  wire [`XLEN-1:0] head_next_pc1;
  wire [`XLEN-1:0] head_packet_next_pc;
  wire [`XLEN-1:0] head_fault_tval;
  wire [`INST_W-1:0] head_inst0;
  wire [`INST_W-1:0] head_inst1;
  wire [`CTRL_BUS_W-1:0] head_ctrl0;
  wire [`CTRL_BUS_W-1:0] head_ctrl1;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts0;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts1;
  wire [`REG_ADDR_W-1:0] head_rs1_0;
  wire [`REG_ADDR_W-1:0] head_rs2_0;
  wire [`REG_ADDR_W-1:0] head_rd0;
  wire [`XLEN-1:0] head_imm0;
  wire [`REG_ADDR_W-1:0] head_rs1_1;
  wire [`REG_ADDR_W-1:0] head_rs2_1;
  wire [`REG_ADDR_W-1:0] head_rd1;
  wire [`XLEN-1:0] head_imm1;
  wire [1:0] head_resp0;
  wire [1:0] head_resp1;
  wire head_pred_taken0;
  wire head_pred_taken1;
  wire [`BPU_BHT_INDEX_W-1:0] head_bht_idx0;
  wire [`BPU_BHT_INDEX_W-1:0] head_bht_idx1;
  wire head_bht_valid0;
  wire head_bht_valid1;
  wire head_slot1_valid;
  wire [FETCH_COUNT_W-1:0] count;

  OooFetchPacketFifo #(
    .FETCH_PACKET_COUNT_W(FETCH_PACKET_COUNT_W),
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .enqueue_i(enqueue),
    .enqueue_pc0_i(enqueue_pc0),
    .enqueue_pc1_i(enqueue_pc1),
    .enqueue_next_pc0_i(enqueue_next_pc0),
    .enqueue_next_pc1_i(enqueue_next_pc1),
    .enqueue_packet_next_pc_i(enqueue_packet_next_pc),
    .enqueue_fault_tval_i(enqueue_fault_tval),
    .enqueue_inst0_i(enqueue_inst0),
    .enqueue_inst1_i(enqueue_inst1),
    .enqueue_ctrl0_i(enqueue_ctrl0),
    .enqueue_ctrl1_i(enqueue_ctrl1),
    .enqueue_static_facts0_i(enqueue_static_facts0),
    .enqueue_static_facts1_i(enqueue_static_facts1),
    .enqueue_rs1_0_i(enqueue_rs1_0),
    .enqueue_rs2_0_i(enqueue_rs2_0),
    .enqueue_rd0_i(enqueue_rd0),
    .enqueue_imm0_i(enqueue_imm0),
    .enqueue_rs1_1_i(enqueue_rs1_1),
    .enqueue_rs2_1_i(enqueue_rs2_1),
    .enqueue_rd1_i(enqueue_rd1),
    .enqueue_imm1_i(enqueue_imm1),
    .enqueue_resp0_i(enqueue_resp0),
    .enqueue_resp1_i(enqueue_resp1),
    .enqueue_pred_taken0_i(enqueue_pred_taken0),
    .enqueue_pred_taken1_i(enqueue_pred_taken1),
    .enqueue_bht_idx0_i(enqueue_bht_idx0),
    .enqueue_bht_idx1_i(enqueue_bht_idx1),
    .enqueue_bht_valid0_i(enqueue_bht_valid0),
    .enqueue_bht_valid1_i(enqueue_bht_valid1),
    .enqueue_slot1_valid_i(enqueue_slot1_valid),
    .pop_i(pop),
    .head_valid_o(head_valid),
    .head_pc0_o(head_pc0),
    .head_pc1_o(head_pc1),
    .head_next_pc0_o(head_next_pc0),
    .head_next_pc1_o(head_next_pc1),
    .head_packet_next_pc_o(head_packet_next_pc),
    .head_fault_tval_o(head_fault_tval),
    .head_inst0_o(head_inst0),
    .head_inst1_o(head_inst1),
    .head_ctrl0_o(head_ctrl0),
    .head_ctrl1_o(head_ctrl1),
    .head_static_facts0_o(head_static_facts0),
    .head_static_facts1_o(head_static_facts1),
    .head_rs1_0_o(head_rs1_0),
    .head_rs2_0_o(head_rs2_0),
    .head_rd0_o(head_rd0),
    .head_imm0_o(head_imm0),
    .head_rs1_1_o(head_rs1_1),
    .head_rs2_1_o(head_rs2_1),
    .head_rd1_o(head_rd1),
    .head_imm1_o(head_imm1),
    .head_resp0_o(head_resp0),
    .head_resp1_o(head_resp1),
    .head_pred_taken0_o(head_pred_taken0),
    .head_pred_taken1_o(head_pred_taken1),
    .head_bht_idx0_o(head_bht_idx0),
    .head_bht_idx1_o(head_bht_idx1),
    .head_bht_valid0_o(head_bht_valid0),
    .head_bht_valid1_o(head_bht_valid1),
    .head_slot1_valid_o(head_slot1_valid),
    .count_o(count)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  task automatic tb_check3;
    input [1023:0] what;
    input [FETCH_COUNT_W-1:0] got;
    input [FETCH_COUNT_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%0d expected=%0d", what, got, exp);
      end
    end
  endtask

  task automatic tb_check64_local;
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

  // B2 S1: per-packet 预测位由 pc 派生(每包唯一)——head 读出必须与写入包逐位一致
  function automatic pred_taken0_of;
    input [`XLEN-1:0] pc;
    begin pred_taken0_of = pc[12]; end
  endfunction
  function automatic pred_taken1_of;
    input [`XLEN-1:0] pc;
    begin pred_taken1_of = ~pc[12]; end
  endfunction
  function automatic [`BPU_BHT_INDEX_W-1:0] bht_idx0_of;
    input [`XLEN-1:0] pc;
    begin bht_idx0_of = pc[`BPU_BHT_INDEX_W+1:2]; end
  endfunction
  function automatic [`BPU_BHT_INDEX_W-1:0] bht_idx1_of;
    input [`XLEN-1:0] pc;
    begin bht_idx1_of = ~pc[`BPU_BHT_INDEX_W+1:2]; end
  endfunction
  function automatic bht_valid1_of;
    input [`XLEN-1:0] pc;
    begin bht_valid1_of = pc[13]; end
  endfunction
  function automatic [`CTRL_BUS_W-1:0] ctrl0_of;
    input [`INST_W-1:0] inst;
    begin ctrl0_of = {{(`CTRL_BUS_W-`INST_W){1'b0}}, inst}; end
  endfunction
  function automatic [`CTRL_BUS_W-1:0] ctrl1_of;
    input [`INST_W-1:0] inst;
    begin ctrl1_of = ~{{(`CTRL_BUS_W-`INST_W){1'b0}}, inst}; end
  endfunction
  function automatic [`OOO_SLOT_STATIC_FACTS_W-1:0] static0_of;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin static0_of = pc[`OOO_SLOT_STATIC_FACTS_W-1:0] ^
                       inst[`OOO_SLOT_STATIC_FACTS_W-1:0]; end
  endfunction
  function automatic [`OOO_SLOT_STATIC_FACTS_W-1:0] static1_of;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin static1_of = ~(pc[`OOO_SLOT_STATIC_FACTS_W-1:0] ^
                         inst[`OOO_SLOT_STATIC_FACTS_W-1:0]); end
  endfunction
  function automatic [`XLEN-1:0] imm0_of;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin imm0_of = {{32{inst[31]}}, inst}; end
  endfunction
  function automatic [`XLEN-1:0] imm1_of;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin imm1_of = {{32{~inst[31]}}, ~inst}; end
  endfunction
  // B2 S2: 截断位与 slot0 pred-taken 语义互斥(taken 则截断)
  function automatic slot1_valid_of;
    input [`XLEN-1:0] pc;
    begin slot1_valid_of = ~pred_taken0_of(pc); end
  endfunction

  task automatic drive_enqueue_packet;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    begin
      enqueue = 1'b1;
      enqueue_pc0 = pc;
      enqueue_pc1 = pc + 64'd4;
      enqueue_next_pc0 = pc + 64'd4;
      enqueue_next_pc1 = pc + 64'd8;
      enqueue_packet_next_pc = pc + 64'd8;
      enqueue_fault_tval = pc + 64'd6;
      enqueue_inst0 = inst0;
      enqueue_inst1 = inst1;
      enqueue_ctrl0 = ctrl0_of(inst0);
      enqueue_ctrl1 = ctrl1_of(inst1);
      enqueue_static_facts0 = static0_of(pc, inst0);
      enqueue_static_facts1 = static1_of(pc, inst1);
      enqueue_rs1_0 = inst0[19:15];
      enqueue_rs2_0 = inst0[24:20];
      enqueue_rd0 = inst0[11:7];
      enqueue_imm0 = imm0_of(pc, inst0);
      enqueue_rs1_1 = inst1[19:15];
      enqueue_rs2_1 = inst1[24:20];
      enqueue_rd1 = inst1[11:7];
      enqueue_imm1 = imm1_of(pc, inst1);
      enqueue_resp0 = 2'b00;
      enqueue_resp1 = 2'b00;
      enqueue_pred_taken0 = pred_taken0_of(pc);
      enqueue_pred_taken1 = pred_taken1_of(pc);
      enqueue_bht_idx0 = bht_idx0_of(pc);
      enqueue_bht_idx1 = bht_idx1_of(pc);
      enqueue_bht_valid0 = 1'b1;
      enqueue_bht_valid1 = bht_valid1_of(pc);
      enqueue_slot1_valid = slot1_valid_of(pc);
    end
  endtask

  task automatic clear_controls;
    begin
      clear = 1'b0;
      enqueue = 1'b0;
      pop = 1'b0;
    end
  endtask

  task automatic check_head_presence;
    input [1023:0] what;
    input [2:0] expected_count;
    input expected_valid;
    begin
      tb_check3({what, " count"}, count, expected_count);
      tb_check1({what, " output"}, head_valid, expected_valid);
      tb_check1({what, " registered projection"}, dut.head_valid_q,
                expected_valid);
      tb_check1({what, " occupancy equivalence"}, dut.head_valid_q,
                (count != 3'd0));
    end
  endtask

  task automatic check_head_packet;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp1;
    begin
      tb_check1({what, " valid"}, head_valid, 1'b1);
      tb_check64_local({what, " pc0"}, head_pc0, pc);
      tb_check64_local({what, " pc1"}, head_pc1, pc + 64'd4);
      tb_check64_local({what, " next0"}, head_next_pc0, pc + 64'd4);
      tb_check64_local({what, " next1"}, head_next_pc1, pc + 64'd8);
      tb_check64_local({what, " packet-next"}, head_packet_next_pc, pc + 64'd8);
      tb_check64_local({what, " fault-tval"}, head_fault_tval, pc + 64'd6);
      tb_check32({what, " inst0"}, head_inst0, inst0);
      tb_check32({what, " inst1"}, head_inst1, inst1);
      if ({head_ctrl0, head_rs1_0, head_rs2_0, head_rd0, head_imm0} !==
          {ctrl0_of(inst0), inst0[19:15], inst0[24:20], inst0[11:7],
           imm0_of(pc, inst0)}) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s lane0 stored predecode mismatch", what);
      end
      if ({head_ctrl1, head_rs1_1, head_rs2_1, head_rd1, head_imm1} !==
          {ctrl1_of(inst1), inst1[19:15], inst1[24:20], inst1[11:7],
           imm1_of(pc, inst1)}) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s lane1 stored predecode mismatch", what);
      end
      if ({head_static_facts0, head_static_facts1} !==
          {static0_of(pc, inst0), static1_of(pc, inst1)}) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s static facts lost packet atomicity", what);
      end
      tb_check1({what, " resp0 bit0"}, head_resp0[0], 1'b0);
      tb_check1({what, " resp0 bit1"}, head_resp0[1], 1'b0);
      tb_check1({what, " resp1 bit0"}, head_resp1[0], resp1[0]);
      tb_check1({what, " resp1 bit1"}, head_resp1[1], resp1[1]);
      // B2 S1: 预测位随包(写入拍定格, head 读出与包内容逐位一致)
      tb_check1({what, " pred_taken0"}, head_pred_taken0, pred_taken0_of(pc));
      tb_check1({what, " pred_taken1"}, head_pred_taken1, pred_taken1_of(pc));
      tb_check32({what, " bht_idx0"},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, head_bht_idx0},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, bht_idx0_of(pc)});
      tb_check32({what, " bht_idx1"},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, head_bht_idx1},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, bht_idx1_of(pc)});
      tb_check1({what, " bht_valid0"}, head_bht_valid0, 1'b1);
      tb_check1({what, " bht_valid1"}, head_bht_valid1, bht_valid1_of(pc));
      // B2 S2: 截断位随包(写入拍定格)
      tb_check1({what, " slot1_valid"}, head_slot1_valid, slot1_valid_of(pc));
    end
  endtask

  task automatic run_fault_tval_offset_packet;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [2:0] offset;
    begin
      drive_enqueue_packet(pc, 32'h0010_0093, 32'h0020_0113);
      enqueue_fault_tval = pc + {{(`XLEN-3){1'b0}}, offset};
      tick();
      clear_controls();
      check_head_presence({what, " present"}, 3'd1, 1'b1);
      tb_check64_local({what, " packet pc"}, head_pc0, pc);
      tb_check64_local({what, " fault-tval"}, head_fault_tval,
                       pc + {{(`XLEN-3){1'b0}}, offset});
      $display("[TVAL-G1-FIFO-OFFSET-PASS] %0s F=%0d pc=%h tval=%h",
               what, offset, pc, head_fault_tval);
      pop = 1'b1;
      tick();
      clear_controls();
      check_head_presence({what, " drained"}, 3'd0, 1'b0);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear = 1'b0;
    enqueue = 1'b0;
    enqueue_pc0 = {`XLEN{1'b0}};
    enqueue_pc1 = {`XLEN{1'b0}};
    enqueue_next_pc0 = {`XLEN{1'b0}};
    enqueue_next_pc1 = {`XLEN{1'b0}};
    enqueue_packet_next_pc = {`XLEN{1'b0}};
    enqueue_fault_tval = {`XLEN{1'b0}};
    enqueue_inst0 = {`INST_W{1'b0}};
    enqueue_inst1 = {`INST_W{1'b0}};
    enqueue_ctrl0 = {`CTRL_BUS_W{1'b0}};
    enqueue_ctrl1 = {`CTRL_BUS_W{1'b0}};
    enqueue_static_facts0 = {`OOO_SLOT_STATIC_FACTS_W{1'b0}};
    enqueue_static_facts1 = {`OOO_SLOT_STATIC_FACTS_W{1'b0}};
    enqueue_rs1_0 = {`REG_ADDR_W{1'b0}};
    enqueue_rs2_0 = {`REG_ADDR_W{1'b0}};
    enqueue_rd0 = {`REG_ADDR_W{1'b0}};
    enqueue_imm0 = {`XLEN{1'b0}};
    enqueue_rs1_1 = {`REG_ADDR_W{1'b0}};
    enqueue_rs2_1 = {`REG_ADDR_W{1'b0}};
    enqueue_rd1 = {`REG_ADDR_W{1'b0}};
    enqueue_imm1 = {`XLEN{1'b0}};
    enqueue_resp0 = 2'b00;
    enqueue_resp1 = 2'b00;
    enqueue_pred_taken0 = 1'b0;
    enqueue_pred_taken1 = 1'b0;
    enqueue_bht_idx0 = {`BPU_BHT_INDEX_W{1'b0}};
    enqueue_bht_idx1 = {`BPU_BHT_INDEX_W{1'b0}};
    enqueue_bht_valid0 = 1'b0;
    enqueue_bht_valid1 = 1'b0;
    enqueue_slot1_valid = 1'b1;
    pop = 1'b0;
    tb_errors = 0;

    tick();
    check_head_presence("reset clears presence", 3'd0, 1'b0);

    rst = 1'b0;
    drive_enqueue_packet(64'h0000_0000_8000_1000, 32'h0000_0013,
                         32'h0010_0093);
    tick();
    clear_controls();
    check_head_presence("empty enqueue sets presence", 3'd1, 1'b1);
    check_head_packet("packet A", 64'h0000_0000_8000_1000,
                      32'h0000_0013, 32'h0010_0093, 2'b00);

    // With no ownership transfer, changing every enqueue-side static field
    // must not alter the registered head packet.
    drive_enqueue_packet(64'h0000_0000_8bad_f000, 32'hdead_beef,
                         32'hcafe_babe);
    enqueue = 1'b0;
    tick();
    clear_controls();
    check_head_presence("idle holds presence", 3'd1, 1'b1);
    check_head_packet("hold keeps packet A", 64'h0000_0000_8000_1000,
                      32'h0000_0013, 32'h0010_0093, 2'b00);

    drive_enqueue_packet(64'h0000_0000_8000_2000, 32'h0020_0113,
                         32'h0030_0193);
    tick();
    clear_controls();
    tb_check3("two enqueue count", count, 3'd2);
    check_head_packet("still packet A", 64'h0000_0000_8000_1000,
                      32'h0000_0013, 32'h0010_0093, 2'b00);

    pop = 1'b1;
    tick();
    clear_controls();
    check_head_presence("multi-entry pop keeps presence", 3'd1, 1'b1);
    check_head_packet("packet B", 64'h0000_0000_8000_2000,
                      32'h0020_0113, 32'h0030_0193, 2'b00);

    pop = 1'b1;
    drive_enqueue_packet(64'h0000_0000_8000_3000, 32'h0040_0213,
                         32'h0050_0293);
    tick();
    clear_controls();
    check_head_presence("one-entry pop enqueue keeps presence", 3'd1, 1'b1);
    check_head_packet("packet C", 64'h0000_0000_8000_3000,
                      32'h0040_0213, 32'h0050_0293, 2'b00);

    drive_enqueue_packet(64'h0000_0000_8000_4000, 32'h0060_0313,
                         32'h0070_0393);
    tick();
    drive_enqueue_packet(64'h0000_0000_8000_5000, 32'h0080_0413,
                         32'h0090_0493);
    tick();
    drive_enqueue_packet(64'h0000_0000_8000_6000, 32'h00a0_0513,
                         32'h00b0_0593);
    tick();
    clear_controls();
    tb_check3("full count", count, 3'd4);
    check_head_packet("full still packet C", 64'h0000_0000_8000_3000,
                      32'h0040_0213, 32'h0050_0293, 2'b00);

    pop = 1'b1;
    drive_enqueue_packet(64'h0000_0000_8000_7000, 32'h00c0_0613,
                         32'h00d0_0693);
    tick();
    clear_controls();
    check_head_presence("full pop enqueue keeps presence", 3'd4, 1'b1);
    check_head_packet("packet D after full pop", 64'h0000_0000_8000_4000,
                      32'h0060_0313, 32'h0070_0393, 2'b00);

    // Drain across the physical wrap boundary.  check_head_packet compares
    // the complete atomic entry, including ctrl/rs*/rd/imm/static facts and
    // prediction metadata, so E/F/G prove that wrapped storage preserves the
    // cached T3W facts together with the decode bundle.
    pop = 1'b1;
    tick();
    clear_controls();
    tb_check3("wrap pop exposes packet E count", count, 3'd3);
    check_head_packet("wrapped packet E", 64'h0000_0000_8000_5000,
                      32'h0080_0413, 32'h0090_0493, 2'b00);
    $display("[T3W-FIFO-WRAP] packet E atomic static/decode readback");

    pop = 1'b1;
    tick();
    clear_controls();
    tb_check3("wrap pop exposes packet F count", count, 3'd2);
    check_head_packet("wrapped packet F", 64'h0000_0000_8000_6000,
                      32'h00a0_0513, 32'h00b0_0593, 2'b00);
    $display("[T3W-FIFO-WRAP] packet F atomic static/decode readback");

    pop = 1'b1;
    tick();
    clear_controls();
    tb_check3("wrap pop exposes packet G count", count, 3'd1);
    check_head_packet("wrapped packet G", 64'h0000_0000_8000_7000,
                      32'h00c0_0613, 32'h00d0_0693, 2'b00);
    $display("[T3W-FIFO-WRAP] packet G atomic static/decode readback");

    pop = 1'b1;
    tick();
    clear_controls();
    check_head_presence("last pop clears presence", 3'd0, 1'b0);

    // clear 是 normal event 的严格上位动作：即使带 empty-pop，也只能清空，
    // underflow 断言不能把这个被吞掉的 pop 误报成事务。
    clear = 1'b1;
    pop = 1'b1;
    tick();
    clear_controls();
    check_head_presence("empty clear dominates pop", 3'd0, 1'b0);

    // Refill to full so clear+enqueue also exercises the old full-count
    // boundary；clear 必须胜出且 overflow-request 断言不得误报。
    drive_enqueue_packet(64'h0000_0000_8000_8000, 32'h00e0_0713,
                         32'h00f0_0793);
    tick();
    clear_controls();
    tb_check3("refill before clear count", count, 3'd1);
    check_head_packet("packet H before clear", 64'h0000_0000_8000_8000,
                      32'h00e0_0713, 32'h00f0_0793, 2'b00);

    drive_enqueue_packet(64'h0000_0000_8000_9000, 32'h0100_0813,
                         32'h0110_0893);
    tick();
    drive_enqueue_packet(64'h0000_0000_8000_a000, 32'h0120_0913,
                         32'h0130_0993);
    tick();
    drive_enqueue_packet(64'h0000_0000_8000_b000, 32'h0140_0a13,
                         32'h0150_0a93);
    tick();
    clear_controls();
    check_head_presence("full before clear enqueue", 3'd4, 1'b1);

    clear = 1'b1;
    drive_enqueue_packet(64'h0000_0000_8000_c000, 32'h0160_0b13,
                         32'h0170_0b93);
    tick();
    clear_controls();
    check_head_presence("full clear dominates enqueue", 3'd0, 1'b0);
    run_fault_tval_offset_packet("fault frontier two bytes",
                                 64'h0000_0000_8000_d000, 3'd2);
    run_fault_tval_offset_packet("fault frontier four bytes",
                                 64'h0000_0000_8000_e000, 3'd4);
    run_fault_tval_offset_packet("fault frontier six bytes",
                                 64'h0000_0000_8000_f000, 3'd6);
    $display("[TVAL-G1-FIFO-OFFSETS] F2=1 F4=1 F6=1 atomic=3 PASS");
    $display("[T4B-FIFO-HEAD-PRESENCE-EVENTS] reset/enqueue/hold/pop/swap/clear-collision covered");
    $display("[T4G-FETCH-FAULT-TVAL-FIFO] fault frontier survives direct-head/ring/wrap ownership");

    tb_finish("tb_ooo_fetch_packet_fifo");
  end

endmodule
