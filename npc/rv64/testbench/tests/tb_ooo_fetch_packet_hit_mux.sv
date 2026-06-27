`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_packet_hit_mux;
  reg rsp_select;

  reg [`XLEN-1:0] rsp_pc0;
  reg [`XLEN-1:0] rsp_pc1;
  reg [`XLEN-1:0] rsp_next_pc0;
  reg [`XLEN-1:0] rsp_next_pc1;
  reg [`XLEN-1:0] rsp_packet_next_pc;
  reg [`INST_W-1:0] rsp_inst0;
  reg [`INST_W-1:0] rsp_inst1;
  reg [1:0] rsp_resp0;
  reg [1:0] rsp_resp1;

  reg [`XLEN-1:0] buf_pc0;
  reg [`XLEN-1:0] buf_pc1;
  reg [`XLEN-1:0] buf_next_pc0;
  reg [`XLEN-1:0] buf_next_pc1;
  reg [`XLEN-1:0] buf_packet_next_pc;
  reg [`INST_W-1:0] buf_inst0;
  reg [`INST_W-1:0] buf_inst1;
  reg [1:0] buf_resp0;
  reg [1:0] buf_resp1;

  wire [`XLEN-1:0] hit_pc0;
  wire [`XLEN-1:0] hit_pc1;
  wire [`XLEN-1:0] hit_next_pc0;
  wire [`XLEN-1:0] hit_next_pc1;
  wire [`XLEN-1:0] hit_packet_next_pc;
  wire [`INST_W-1:0] hit_inst0;
  wire [`INST_W-1:0] hit_inst1;
  wire [1:0] hit_resp0;
  wire [1:0] hit_resp1;

  OooFetchPacketHitMux dut (
    .rsp_select_i(rsp_select),
    .rsp_pc0_i(rsp_pc0),
    .rsp_pc1_i(rsp_pc1),
    .rsp_next_pc0_i(rsp_next_pc0),
    .rsp_next_pc1_i(rsp_next_pc1),
    .rsp_packet_next_pc_i(rsp_packet_next_pc),
    .rsp_inst0_i(rsp_inst0),
    .rsp_inst1_i(rsp_inst1),
    .rsp_resp0_i(rsp_resp0),
    .rsp_resp1_i(rsp_resp1),
    .buf_pc0_i(buf_pc0),
    .buf_pc1_i(buf_pc1),
    .buf_next_pc0_i(buf_next_pc0),
    .buf_next_pc1_i(buf_next_pc1),
    .buf_packet_next_pc_i(buf_packet_next_pc),
    .buf_inst0_i(buf_inst0),
    .buf_inst1_i(buf_inst1),
    .buf_resp0_i(buf_resp0),
    .buf_resp1_i(buf_resp1),
    .hit_pc0_o(hit_pc0),
    .hit_pc1_o(hit_pc1),
    .hit_next_pc0_o(hit_next_pc0),
    .hit_next_pc1_o(hit_next_pc1),
    .hit_packet_next_pc_o(hit_packet_next_pc),
    .hit_inst0_o(hit_inst0),
    .hit_inst1_o(hit_inst1),
    .hit_resp0_o(hit_resp0),
    .hit_resp1_o(hit_resp1)
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
      check_xlen({tag, " pc0"}, hit_pc0, exp_pc0);
      check_xlen({tag, " pc1"}, hit_pc1, exp_pc1);
      check_xlen({tag, " next0"}, hit_next_pc0, exp_next_pc0);
      check_xlen({tag, " next1"}, hit_next_pc1, exp_next_pc1);
      check_xlen({tag, " packet next"}, hit_packet_next_pc,
                 exp_packet_next_pc);
      tb_check32({tag, " inst0"}, hit_inst0, exp_inst0);
      tb_check32({tag, " inst1"}, hit_inst1, exp_inst1);
      tb_check32({tag, " resp0"}, {30'b0, hit_resp0}, {30'b0, exp_resp0});
      tb_check32({tag, " resp1"}, {30'b0, hit_resp1}, {30'b0, exp_resp1});
    end
  endtask

  task automatic drive_defaults;
    begin
      rsp_select = 1'b0;
      rsp_pc0 = 64'h0000_0000_0000_1000;
      rsp_pc1 = 64'h0000_0000_0000_1004;
      rsp_next_pc0 = 64'h0000_0000_0000_1004;
      rsp_next_pc1 = 64'h0000_0000_0000_1008;
      rsp_packet_next_pc = 64'h0000_0000_0000_1008;
      rsp_inst0 = 32'h0000_0013;
      rsp_inst1 = 32'h0010_0093;
      rsp_resp0 = 2'b01;
      rsp_resp1 = 2'b10;
      buf_pc0 = 64'h0000_0000_0000_2000;
      buf_pc1 = 64'h0000_0000_0000_2002;
      buf_next_pc0 = 64'h0000_0000_0000_2002;
      buf_next_pc1 = 64'h0000_0000_0000_2004;
      buf_packet_next_pc = 64'h0000_0000_0000_2004;
      buf_inst0 = 32'h0020_0113;
      buf_inst1 = 32'h0030_0193;
      buf_resp0 = 2'b00;
      buf_resp1 = 2'b11;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    drive_defaults();
    check_packet("buffer selected", buf_pc0, buf_pc1, buf_next_pc0,
                 buf_next_pc1, buf_packet_next_pc, buf_inst0, buf_inst1,
                 buf_resp0, buf_resp1);

    drive_defaults();
    rsp_select = 1'b1;
    #1;
    check_packet("response selected", rsp_pc0, rsp_pc1, rsp_next_pc0,
                 rsp_next_pc1, rsp_packet_next_pc, rsp_inst0, rsp_inst1,
                 rsp_resp0, rsp_resp1);

    tb_finish("tb_ooo_fetch_packet_hit_mux");
  end

endmodule

