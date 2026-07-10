`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_packet_fifo;
  localparam FETCH_PACKET_COUNT_W = 2;
  localparam FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1;

  reg clk;
  reg rst;
  reg clear;
  reg seed_valid;
  reg [`XLEN-1:0] seed_pc0;
  reg [`XLEN-1:0] seed_pc1;
  reg [`XLEN-1:0] seed_next_pc0;
  reg [`XLEN-1:0] seed_next_pc1;
  reg [`XLEN-1:0] seed_packet_next_pc;
  reg [`INST_W-1:0] seed_inst0;
  reg [`INST_W-1:0] seed_inst1;
  reg [1:0] seed_resp0;
  reg [1:0] seed_resp1;
  // B2 S1: per-slot 预测位随包存储
  reg seed_pred_taken0;
  reg seed_pred_taken1;
  reg [`BPU_BHT_INDEX_W-1:0] seed_bht_idx0;
  reg [`BPU_BHT_INDEX_W-1:0] seed_bht_idx1;
  reg seed_bht_valid0;
  reg seed_bht_valid1;
  reg enqueue;
  reg [`XLEN-1:0] enqueue_pc0;
  reg [`XLEN-1:0] enqueue_pc1;
  reg [`XLEN-1:0] enqueue_next_pc0;
  reg [`XLEN-1:0] enqueue_next_pc1;
  reg [`XLEN-1:0] enqueue_packet_next_pc;
  reg [`INST_W-1:0] enqueue_inst0;
  reg [`INST_W-1:0] enqueue_inst1;
  reg [1:0] enqueue_resp0;
  reg [1:0] enqueue_resp1;
  reg enqueue_pred_taken0;
  reg enqueue_pred_taken1;
  reg [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx0;
  reg [`BPU_BHT_INDEX_W-1:0] enqueue_bht_idx1;
  reg enqueue_bht_valid0;
  reg enqueue_bht_valid1;
  reg pop;
  wire head_valid;
  wire [`XLEN-1:0] head_pc0;
  wire [`XLEN-1:0] head_pc1;
  wire [`XLEN-1:0] head_next_pc0;
  wire [`XLEN-1:0] head_next_pc1;
  wire [`XLEN-1:0] head_packet_next_pc;
  wire [`INST_W-1:0] head_inst0;
  wire [`INST_W-1:0] head_inst1;
  wire [1:0] head_resp0;
  wire [1:0] head_resp1;
  wire head_pred_taken0;
  wire head_pred_taken1;
  wire [`BPU_BHT_INDEX_W-1:0] head_bht_idx0;
  wire [`BPU_BHT_INDEX_W-1:0] head_bht_idx1;
  wire head_bht_valid0;
  wire head_bht_valid1;
  wire [FETCH_COUNT_W-1:0] count;

  OooFetchPacketFifo #(
    .FETCH_PACKET_COUNT_W(FETCH_PACKET_COUNT_W),
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .seed_valid_i(seed_valid),
    .seed_pc0_i(seed_pc0),
    .seed_pc1_i(seed_pc1),
    .seed_next_pc0_i(seed_next_pc0),
    .seed_next_pc1_i(seed_next_pc1),
    .seed_packet_next_pc_i(seed_packet_next_pc),
    .seed_inst0_i(seed_inst0),
    .seed_inst1_i(seed_inst1),
    .seed_resp0_i(seed_resp0),
    .seed_resp1_i(seed_resp1),
    .seed_pred_taken0_i(seed_pred_taken0),
    .seed_pred_taken1_i(seed_pred_taken1),
    .seed_bht_idx0_i(seed_bht_idx0),
    .seed_bht_idx1_i(seed_bht_idx1),
    .seed_bht_valid0_i(seed_bht_valid0),
    .seed_bht_valid1_i(seed_bht_valid1),
    .enqueue_i(enqueue),
    .enqueue_pc0_i(enqueue_pc0),
    .enqueue_pc1_i(enqueue_pc1),
    .enqueue_next_pc0_i(enqueue_next_pc0),
    .enqueue_next_pc1_i(enqueue_next_pc1),
    .enqueue_packet_next_pc_i(enqueue_packet_next_pc),
    .enqueue_inst0_i(enqueue_inst0),
    .enqueue_inst1_i(enqueue_inst1),
    .enqueue_resp0_i(enqueue_resp0),
    .enqueue_resp1_i(enqueue_resp1),
    .enqueue_pred_taken0_i(enqueue_pred_taken0),
    .enqueue_pred_taken1_i(enqueue_pred_taken1),
    .enqueue_bht_idx0_i(enqueue_bht_idx0),
    .enqueue_bht_idx1_i(enqueue_bht_idx1),
    .enqueue_bht_valid0_i(enqueue_bht_valid0),
    .enqueue_bht_valid1_i(enqueue_bht_valid1),
    .pop_i(pop),
    .head_valid_o(head_valid),
    .head_pc0_o(head_pc0),
    .head_pc1_o(head_pc1),
    .head_next_pc0_o(head_next_pc0),
    .head_next_pc1_o(head_next_pc1),
    .head_packet_next_pc_o(head_packet_next_pc),
    .head_inst0_o(head_inst0),
    .head_inst1_o(head_inst1),
    .head_resp0_o(head_resp0),
    .head_resp1_o(head_resp1),
    .head_pred_taken0_o(head_pred_taken0),
    .head_pred_taken1_o(head_pred_taken1),
    .head_bht_idx0_o(head_bht_idx0),
    .head_bht_idx1_o(head_bht_idx1),
    .head_bht_valid0_o(head_bht_valid0),
    .head_bht_valid1_o(head_bht_valid1),
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
      enqueue_inst0 = inst0;
      enqueue_inst1 = inst1;
      enqueue_resp0 = 2'b00;
      enqueue_resp1 = 2'b00;
      enqueue_pred_taken0 = pred_taken0_of(pc);
      enqueue_pred_taken1 = pred_taken1_of(pc);
      enqueue_bht_idx0 = bht_idx0_of(pc);
      enqueue_bht_idx1 = bht_idx1_of(pc);
      enqueue_bht_valid0 = 1'b1;
      enqueue_bht_valid1 = bht_valid1_of(pc);
    end
  endtask

  task automatic drive_seed_packet;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    begin
      seed_valid = 1'b1;
      seed_pc0 = pc;
      seed_pc1 = pc + 64'd4;
      seed_next_pc0 = pc + 64'd4;
      seed_next_pc1 = pc + 64'd8;
      seed_packet_next_pc = pc + 64'd8;
      seed_inst0 = inst0;
      seed_inst1 = inst1;
      seed_resp0 = 2'b00;
      seed_resp1 = 2'b01;
      seed_pred_taken0 = pred_taken0_of(pc);
      seed_pred_taken1 = pred_taken1_of(pc);
      seed_bht_idx0 = bht_idx0_of(pc);
      seed_bht_idx1 = bht_idx1_of(pc);
      seed_bht_valid0 = 1'b1;
      seed_bht_valid1 = bht_valid1_of(pc);
    end
  endtask

  task automatic clear_controls;
    begin
      clear = 1'b0;
      seed_valid = 1'b0;
      enqueue = 1'b0;
      pop = 1'b0;
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
      tb_check32({what, " inst0"}, head_inst0, inst0);
      tb_check32({what, " inst1"}, head_inst1, inst1);
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
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear = 1'b0;
    seed_valid = 1'b0;
    seed_pc0 = {`XLEN{1'b0}};
    seed_pc1 = {`XLEN{1'b0}};
    seed_next_pc0 = {`XLEN{1'b0}};
    seed_next_pc1 = {`XLEN{1'b0}};
    seed_packet_next_pc = {`XLEN{1'b0}};
    seed_inst0 = {`INST_W{1'b0}};
    seed_inst1 = {`INST_W{1'b0}};
    seed_resp0 = 2'b00;
    seed_resp1 = 2'b00;
    seed_pred_taken0 = 1'b0;
    seed_pred_taken1 = 1'b0;
    seed_bht_idx0 = {`BPU_BHT_INDEX_W{1'b0}};
    seed_bht_idx1 = {`BPU_BHT_INDEX_W{1'b0}};
    seed_bht_valid0 = 1'b0;
    seed_bht_valid1 = 1'b0;
    enqueue = 1'b0;
    enqueue_pc0 = {`XLEN{1'b0}};
    enqueue_pc1 = {`XLEN{1'b0}};
    enqueue_next_pc0 = {`XLEN{1'b0}};
    enqueue_next_pc1 = {`XLEN{1'b0}};
    enqueue_packet_next_pc = {`XLEN{1'b0}};
    enqueue_inst0 = {`INST_W{1'b0}};
    enqueue_inst1 = {`INST_W{1'b0}};
    enqueue_resp0 = 2'b00;
    enqueue_resp1 = 2'b00;
    enqueue_pred_taken0 = 1'b0;
    enqueue_pred_taken1 = 1'b0;
    enqueue_bht_idx0 = {`BPU_BHT_INDEX_W{1'b0}};
    enqueue_bht_idx1 = {`BPU_BHT_INDEX_W{1'b0}};
    enqueue_bht_valid0 = 1'b0;
    enqueue_bht_valid1 = 1'b0;
    pop = 1'b0;
    tb_errors = 0;

    tick();
    tb_check1("reset clears valid", head_valid, 1'b0);
    tb_check3("reset clears count", count, 3'd0);

    rst = 1'b0;
    drive_enqueue_packet(64'h0000_0000_8000_1000, 32'h0000_0013,
                         32'h0010_0093);
    tick();
    clear_controls();
    tb_check3("one enqueue count", count, 3'd1);
    check_head_packet("packet A", 64'h0000_0000_8000_1000,
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
    tb_check3("pop exposes packet B count", count, 3'd1);
    check_head_packet("packet B", 64'h0000_0000_8000_2000,
                      32'h0020_0113, 32'h0030_0193, 2'b00);

    pop = 1'b1;
    drive_enqueue_packet(64'h0000_0000_8000_3000, 32'h0040_0213,
                         32'h0050_0293);
    tick();
    clear_controls();
    tb_check3("simultaneous enqueue pop keeps count", count, 3'd1);
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
    tb_check3("full simultaneous keeps full count", count, 3'd4);
    check_head_packet("packet D after full pop", 64'h0000_0000_8000_4000,
                      32'h0060_0313, 32'h0070_0393, 2'b00);

    clear = 1'b1;
    drive_enqueue_packet(64'h0000_0000_8000_8000, 32'h00e0_0713,
                         32'h00f0_0793);
    tick();
    clear_controls();
    tb_check1("clear drops valid", head_valid, 1'b0);
    tb_check3("clear drops count", count, 3'd0);

    drive_enqueue_packet(64'h0000_0000_8000_9000, 32'h0100_0813,
                         32'h0110_0893);
    drive_seed_packet(64'h0000_0000_8000_a000, 32'h0120_0913,
                      32'h0130_0993);
    pop = 1'b1;
    tick();
    clear_controls();
    tb_check3("seed overrides normal count", count, 3'd1);
    check_head_packet("seed packet", 64'h0000_0000_8000_a000,
                      32'h0120_0913, 32'h0130_0993, 2'b01);

    tb_finish("tb_ooo_fetch_packet_fifo");
  end

endmodule
