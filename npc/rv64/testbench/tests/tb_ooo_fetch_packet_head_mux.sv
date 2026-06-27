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

  reg [`XLEN-1:0] fifo_pc0;
  reg [`XLEN-1:0] fifo_pc1;
  reg [`XLEN-1:0] fifo_next_pc0;
  reg [`XLEN-1:0] fifo_next_pc1;
  reg [`XLEN-1:0] fifo_packet_next_pc;
  reg [`INST_W-1:0] fifo_inst0;
  reg [`INST_W-1:0] fifo_inst1;
  reg [1:0] fifo_resp0;
  reg [1:0] fifo_resp1;

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
    .fifo_pc0_i(fifo_pc0),
    .fifo_pc1_i(fifo_pc1),
    .fifo_next_pc0_i(fifo_next_pc0),
    .fifo_next_pc1_i(fifo_next_pc1),
    .fifo_packet_next_pc_i(fifo_packet_next_pc),
    .fifo_inst0_i(fifo_inst0),
    .fifo_inst1_i(fifo_inst1),
    .fifo_resp0_i(fifo_resp0),
    .fifo_resp1_i(fifo_resp1),
    .head_has_packet_o(head_has_packet),
    .head_pc0_o(head_pc0),
    .head_pc1_o(head_pc1),
    .head_next_pc0_o(head_next_pc0),
    .head_next_pc1_o(head_next_pc1),
    .head_packet_next_pc_o(head_packet_next_pc),
    .head_inst0_o(head_inst0),
    .head_inst1_o(head_inst1),
    .head_resp0_o(head_resp0),
    .head_resp1_o(head_resp1)
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

    drive_defaults();
    bypass_valid = 1'b1;
    #1;
    tb_check1("bypass source has packet", head_has_packet, 1'b1);
    check_packet("bypass selected", bypass_pc0, bypass_pc1, bypass_next_pc0,
                 bypass_next_pc1, bypass_packet_next_pc, bypass_inst0,
                 bypass_inst1, bypass_resp0, bypass_resp1);

    drive_defaults();
    bypass_valid = 1'b1;
    fifo_head_valid = 1'b1;
    #1;
    tb_check1("both sources have packet", head_has_packet, 1'b1);
    check_packet("bypass wins over fifo", bypass_pc0, bypass_pc1,
                 bypass_next_pc0, bypass_next_pc1, bypass_packet_next_pc,
                 bypass_inst0, bypass_inst1, bypass_resp0, bypass_resp1);

    tb_finish("tb_ooo_fetch_packet_head_mux");
  end

endmodule

