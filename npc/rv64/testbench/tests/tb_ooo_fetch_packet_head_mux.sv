`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_packet_head_mux;
  reg bypass_valid;
  reg fifo_head_valid;

  reg [`XLEN-1:0] bypass_pc0;
  reg [`XLEN-1:0] bypass_pc1;
  reg [`XLEN-1:0] bypass_next_pc0;
  reg [`XLEN-1:0] bypass_next_pc1;
  reg [`XLEN-1:0] bypass_packet_next_pc;
  reg [`INST_W-1:0] bypass_inst0;
  reg [`INST_W-1:0] bypass_inst1;
  reg [1:0] bypass_resp0;
  reg [1:0] bypass_resp1;
  // B2 S1: per-slot 预测位管道化
  reg bypass_pred_taken0;
  reg bypass_pred_taken1;
  reg [`BPU_BHT_INDEX_W-1:0] bypass_bht_idx0;
  reg [`BPU_BHT_INDEX_W-1:0] bypass_bht_idx1;
  reg bypass_bht_valid0;
  reg bypass_bht_valid1;

  reg [`XLEN-1:0] fifo_pc0;
  reg [`XLEN-1:0] fifo_pc1;
  reg [`XLEN-1:0] fifo_next_pc0;
  reg [`XLEN-1:0] fifo_next_pc1;
  reg [`XLEN-1:0] fifo_packet_next_pc;
  reg [`INST_W-1:0] fifo_inst0;
  reg [`INST_W-1:0] fifo_inst1;
  reg [1:0] fifo_resp0;
  reg [1:0] fifo_resp1;
  reg fifo_pred_taken0;
  reg fifo_pred_taken1;
  reg [`BPU_BHT_INDEX_W-1:0] fifo_bht_idx0;
  reg [`BPU_BHT_INDEX_W-1:0] fifo_bht_idx1;
  reg fifo_bht_valid0;
  reg fifo_bht_valid1;

  wire head_has_packet;
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

  OooFetchPacketHeadMux dut (
    .bypass_valid_i(bypass_valid),
    .fifo_head_valid_i(fifo_head_valid),
    .bypass_pc0_i(bypass_pc0),
    .bypass_pc1_i(bypass_pc1),
    .bypass_next_pc0_i(bypass_next_pc0),
    .bypass_next_pc1_i(bypass_next_pc1),
    .bypass_packet_next_pc_i(bypass_packet_next_pc),
    .bypass_inst0_i(bypass_inst0),
    .bypass_inst1_i(bypass_inst1),
    .bypass_resp0_i(bypass_resp0),
    .bypass_resp1_i(bypass_resp1),
    .bypass_pred_taken0_i(bypass_pred_taken0),
    .bypass_pred_taken1_i(bypass_pred_taken1),
    .bypass_bht_idx0_i(bypass_bht_idx0),
    .bypass_bht_idx1_i(bypass_bht_idx1),
    .bypass_bht_valid0_i(bypass_bht_valid0),
    .bypass_bht_valid1_i(bypass_bht_valid1),
    .fifo_pc0_i(fifo_pc0),
    .fifo_pc1_i(fifo_pc1),
    .fifo_next_pc0_i(fifo_next_pc0),
    .fifo_next_pc1_i(fifo_next_pc1),
    .fifo_packet_next_pc_i(fifo_packet_next_pc),
    .fifo_inst0_i(fifo_inst0),
    .fifo_inst1_i(fifo_inst1),
    .fifo_resp0_i(fifo_resp0),
    .fifo_resp1_i(fifo_resp1),
    .fifo_pred_taken0_i(fifo_pred_taken0),
    .fifo_pred_taken1_i(fifo_pred_taken1),
    .fifo_bht_idx0_i(fifo_bht_idx0),
    .fifo_bht_idx1_i(fifo_bht_idx1),
    .fifo_bht_valid0_i(fifo_bht_valid0),
    .fifo_bht_valid1_i(fifo_bht_valid1),
    .head_has_packet_o(head_has_packet),
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
    .head_bht_valid1_o(head_bht_valid1)
  );

  task automatic check_xlen;
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

  task automatic check_packet;
    input [1023:0] tag;
    input [`XLEN-1:0] exp_pc0;
    input [`XLEN-1:0] exp_pc1;
    input [`XLEN-1:0] exp_next_pc0;
    input [`XLEN-1:0] exp_next_pc1;
    input [`XLEN-1:0] exp_packet_next_pc;
    input [`INST_W-1:0] exp_inst0;
    input [`INST_W-1:0] exp_inst1;
    input [1:0] exp_resp0;
    input [1:0] exp_resp1;
    begin
      check_xlen({tag, " pc0"}, head_pc0, exp_pc0);
      check_xlen({tag, " pc1"}, head_pc1, exp_pc1);
      check_xlen({tag, " next0"}, head_next_pc0, exp_next_pc0);
      check_xlen({tag, " next1"}, head_next_pc1, exp_next_pc1);
      check_xlen({tag, " packet next"}, head_packet_next_pc,
                 exp_packet_next_pc);
      tb_check32({tag, " inst0"}, head_inst0, exp_inst0);
      tb_check32({tag, " inst1"}, head_inst1, exp_inst1);
      tb_check32({tag, " resp0"}, {30'b0, head_resp0}, {30'b0, exp_resp0});
      tb_check32({tag, " resp1"}, {30'b0, head_resp1}, {30'b0, exp_resp1});
    end
  endtask

  // B2 S1: 预测位随包管道化——头包预测字段必须与被选源逐位一致
  task automatic check_pred;
    input [1023:0] tag;
    input exp_pred_taken0;
    input exp_pred_taken1;
    input [`BPU_BHT_INDEX_W-1:0] exp_bht_idx0;
    input [`BPU_BHT_INDEX_W-1:0] exp_bht_idx1;
    input exp_bht_valid0;
    input exp_bht_valid1;
    begin
      tb_check1({tag, " pred_taken0"}, head_pred_taken0, exp_pred_taken0);
      tb_check1({tag, " pred_taken1"}, head_pred_taken1, exp_pred_taken1);
      tb_check32({tag, " bht_idx0"},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, head_bht_idx0},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, exp_bht_idx0});
      tb_check32({tag, " bht_idx1"},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, head_bht_idx1},
                 {{(32-`BPU_BHT_INDEX_W){1'b0}}, exp_bht_idx1});
      tb_check1({tag, " bht_valid0"}, head_bht_valid0, exp_bht_valid0);
      tb_check1({tag, " bht_valid1"}, head_bht_valid1, exp_bht_valid1);
    end
  endtask

  task automatic drive_defaults;
    begin
      bypass_valid = 1'b0;
      fifo_head_valid = 1'b0;
      bypass_pc0 = 64'h1000;
      bypass_pc1 = 64'h1004;
      bypass_next_pc0 = 64'h1004;
      bypass_next_pc1 = 64'h1008;
      bypass_packet_next_pc = 64'h1008;
      bypass_inst0 = 32'h0000_0013;
      bypass_inst1 = 32'h0010_0093;
      bypass_resp0 = 2'b01;
      bypass_resp1 = 2'b10;
      fifo_pc0 = 64'h2000;
      fifo_pc1 = 64'h2002;
      fifo_next_pc0 = 64'h2002;
      fifo_next_pc1 = 64'h2004;
      fifo_packet_next_pc = 64'h2004;
      fifo_inst0 = 32'h0020_0113;
      fifo_inst1 = 32'h0030_0193;
      fifo_resp0 = 2'b00;
      fifo_resp1 = 2'b11;
      bypass_pred_taken0 = 1'b1;
      bypass_pred_taken1 = 1'b0;
      bypass_bht_idx0 = `BPU_BHT_INDEX_W'h1a5;
      bypass_bht_idx1 = `BPU_BHT_INDEX_W'h05a;
      bypass_bht_valid0 = 1'b1;
      bypass_bht_valid1 = 1'b0;
      fifo_pred_taken0 = 1'b0;
      fifo_pred_taken1 = 1'b1;
      fifo_bht_idx0 = `BPU_BHT_INDEX_W'h233;
      fifo_bht_idx1 = `BPU_BHT_INDEX_W'h0cc;
      fifo_bht_valid0 = 1'b0;
      fifo_bht_valid1 = 1'b1;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    drive_defaults();
    tb_check1("no source has no packet", head_has_packet, 1'b0);
    check_packet("no source selects fifo payload", fifo_pc0, fifo_pc1,
                 fifo_next_pc0, fifo_next_pc1, fifo_packet_next_pc,
                 fifo_inst0, fifo_inst1, fifo_resp0, fifo_resp1);

    drive_defaults();
    fifo_head_valid = 1'b1;
    #1;
    tb_check1("fifo source has packet", head_has_packet, 1'b1);
    check_packet("fifo selected", fifo_pc0, fifo_pc1, fifo_next_pc0,
                 fifo_next_pc1, fifo_packet_next_pc, fifo_inst0, fifo_inst1,
                 fifo_resp0, fifo_resp1);
    check_pred("fifo selected", fifo_pred_taken0, fifo_pred_taken1,
               fifo_bht_idx0, fifo_bht_idx1, fifo_bht_valid0,
               fifo_bht_valid1);

    drive_defaults();
    bypass_valid = 1'b1;
    #1;
    tb_check1("bypass source has packet", head_has_packet, 1'b1);
    check_packet("bypass selected", bypass_pc0, bypass_pc1, bypass_next_pc0,
                 bypass_next_pc1, bypass_packet_next_pc, bypass_inst0,
                 bypass_inst1, bypass_resp0, bypass_resp1);
    check_pred("bypass selected", bypass_pred_taken0, bypass_pred_taken1,
               bypass_bht_idx0, bypass_bht_idx1, bypass_bht_valid0,
               bypass_bht_valid1);

    drive_defaults();
    bypass_valid = 1'b1;
    fifo_head_valid = 1'b1;
    #1;
    tb_check1("both sources have packet", head_has_packet, 1'b1);
    check_packet("bypass wins over fifo", bypass_pc0, bypass_pc1,
                 bypass_next_pc0, bypass_next_pc1, bypass_packet_next_pc,
                 bypass_inst0, bypass_inst1, bypass_resp0, bypass_resp1);
    check_pred("bypass wins over fifo", bypass_pred_taken0,
               bypass_pred_taken1, bypass_bht_idx0, bypass_bht_idx1,
               bypass_bht_valid0, bypass_bht_valid1);

    tb_finish("tb_ooo_fetch_packet_head_mux");
  end

endmodule

