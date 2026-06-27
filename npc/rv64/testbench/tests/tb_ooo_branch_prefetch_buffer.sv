`include "define.v"
`include "tb_common.svh"

module tb_ooo_branch_prefetch_buffer;
  reg clk;
  reg rst;
  reg clear;
  reg req_fire;
  reg [`XLEN-1:0] req_pc;
  reg rsp_capture;
  reg [`XLEN-1:0] rsp_pc0;
  reg [`XLEN-1:0] rsp_pc1;
  reg [`XLEN-1:0] rsp_next_pc0;
  reg [`XLEN-1:0] rsp_next_pc1;
  reg [`XLEN-1:0] rsp_packet_next_pc;
  reg [`INST_W-1:0] rsp_inst0;
  reg [`INST_W-1:0] rsp_inst1;
  reg [1:0] rsp_resp0;
  reg [1:0] rsp_resp1;

  wire active;
  wire buffer_valid;
  wire [`XLEN-1:0] pc;
  wire [`XLEN-1:0] buf_pc0;
  wire [`XLEN-1:0] buf_pc1;
  wire [`XLEN-1:0] buf_next_pc0;
  wire [`XLEN-1:0] buf_next_pc1;
  wire [`XLEN-1:0] buf_packet_next_pc;
  wire [`INST_W-1:0] buf_inst0;
  wire [`INST_W-1:0] buf_inst1;
  wire [1:0] buf_resp0;
  wire [1:0] buf_resp1;

  OooBranchPrefetchBuffer dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .req_fire_i(req_fire),
    .req_pc_i(req_pc),
    .rsp_capture_i(rsp_capture),
    .rsp_pc0_i(rsp_pc0),
    .rsp_pc1_i(rsp_pc1),
    .rsp_next_pc0_i(rsp_next_pc0),
    .rsp_next_pc1_i(rsp_next_pc1),
    .rsp_packet_next_pc_i(rsp_packet_next_pc),
    .rsp_inst0_i(rsp_inst0),
    .rsp_inst1_i(rsp_inst1),
    .rsp_resp0_i(rsp_resp0),
    .rsp_resp1_i(rsp_resp1),
    .active_o(active),
    .buffer_valid_o(buffer_valid),
    .pc_o(pc),
    .buf_pc0_o(buf_pc0),
    .buf_pc1_o(buf_pc1),
    .buf_next_pc0_o(buf_next_pc0),
    .buf_next_pc1_o(buf_next_pc1),
    .buf_packet_next_pc_o(buf_packet_next_pc),
    .buf_inst0_o(buf_inst0),
    .buf_inst1_o(buf_inst1),
    .buf_resp0_o(buf_resp0),
    .buf_resp1_o(buf_resp1)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
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

  task automatic clear_inputs;
    begin
      clear = 1'b0;
      req_fire = 1'b0;
      rsp_capture = 1'b0;
    end
  endtask

  task automatic drive_packet;
    input [`XLEN-1:0] base_pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp0;
    input [1:0] resp1;
    begin
      rsp_pc0 = base_pc;
      rsp_pc1 = base_pc + 64'd4;
      rsp_next_pc0 = base_pc + 64'd4;
      rsp_next_pc1 = base_pc + 64'd8;
      rsp_packet_next_pc = base_pc + 64'd8;
      rsp_inst0 = inst0;
      rsp_inst1 = inst1;
      rsp_resp0 = resp0;
      rsp_resp1 = resp1;
    end
  endtask

  task automatic check_packet;
    input [1023:0] what;
    input [`XLEN-1:0] base_pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp0;
    input [1:0] resp1;
    begin
      tb_check64_local({what, " pc0"}, buf_pc0, base_pc);
      tb_check64_local({what, " pc1"}, buf_pc1, base_pc + 64'd4);
      tb_check64_local({what, " next0"}, buf_next_pc0, base_pc + 64'd4);
      tb_check64_local({what, " next1"}, buf_next_pc1, base_pc + 64'd8);
      tb_check64_local({what, " packet-next"}, buf_packet_next_pc,
                       base_pc + 64'd8);
      tb_check32({what, " inst0"}, buf_inst0, inst0);
      tb_check32({what, " inst1"}, buf_inst1, inst1);
      tb_check1({what, " resp0 bit0"}, buf_resp0[0], resp0[0]);
      tb_check1({what, " resp0 bit1"}, buf_resp0[1], resp0[1]);
      tb_check1({what, " resp1 bit0"}, buf_resp1[0], resp1[0]);
      tb_check1({what, " resp1 bit1"}, buf_resp1[1], resp1[1]);
    end
  endtask

  task automatic check_zero_packet;
    input [1023:0] what;
    begin
      tb_check64_local({what, " pc0"}, buf_pc0, {`XLEN{1'b0}});
      tb_check64_local({what, " pc1"}, buf_pc1, {`XLEN{1'b0}});
      tb_check64_local({what, " next0"}, buf_next_pc0, {`XLEN{1'b0}});
      tb_check64_local({what, " next1"}, buf_next_pc1, {`XLEN{1'b0}});
      tb_check64_local({what, " packet-next"}, buf_packet_next_pc,
                       {`XLEN{1'b0}});
      tb_check32({what, " inst0"}, buf_inst0, 32'h0000_0000);
      tb_check32({what, " inst1"}, buf_inst1, 32'h0000_0000);
      tb_check1({what, " resp0 bit0"}, buf_resp0[0], 1'b0);
      tb_check1({what, " resp0 bit1"}, buf_resp0[1], 1'b0);
      tb_check1({what, " resp1 bit0"}, buf_resp1[0], 1'b0);
      tb_check1({what, " resp1 bit1"}, buf_resp1[1], 1'b0);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear = 1'b0;
    req_fire = 1'b0;
    req_pc = {`XLEN{1'b0}};
    rsp_capture = 1'b0;
    drive_packet(64'h0, 32'h0, 32'h0, 2'b00, 2'b00);
    tb_errors = 0;

    tick();
    tb_check1("reset clears active", active, 1'b0);
    tb_check1("reset clears buffer valid", buffer_valid, 1'b0);
    tb_check64_local("reset clears pc", pc, {`XLEN{1'b0}});
    check_zero_packet("reset clears payload");

    rst = 1'b0;
    req_fire = 1'b1;
    req_pc = 64'h0000_0000_8000_1000;
    tick();
    clear_inputs();
    tb_check1("request sets active", active, 1'b1);
    tb_check1("request clears buffer valid", buffer_valid, 1'b0);
    tb_check64_local("request stores pc", pc, 64'h0000_0000_8000_1000);

    rsp_capture = 1'b1;
    drive_packet(64'h0000_0000_8000_2000, 32'h0000_0013,
                 32'h0010_0093, 2'b00, 2'b10);
    tick();
    clear_inputs();
    tb_check1("capture keeps active", active, 1'b1);
    tb_check1("capture sets buffer valid", buffer_valid, 1'b1);
    check_packet("capture payload", 64'h0000_0000_8000_2000,
                 32'h0000_0013, 32'h0010_0093, 2'b00, 2'b10);

    req_fire = 1'b1;
    req_pc = 64'h0000_0000_8000_3000;
    tick();
    clear_inputs();
    tb_check1("new request keeps active", active, 1'b1);
    tb_check1("new request drops old buffer valid", buffer_valid, 1'b0);
    tb_check64_local("new request stores pc", pc, 64'h0000_0000_8000_3000);
    check_packet("new request retains old payload", 64'h0000_0000_8000_2000,
                 32'h0000_0013, 32'h0010_0093, 2'b00, 2'b10);

    req_fire = 1'b1;
    req_pc = 64'h0000_0000_8000_4000;
    rsp_capture = 1'b1;
    drive_packet(64'h0000_0000_8000_5000, 32'h0020_0113,
                 32'h0030_0193, 2'b01, 2'b00);
    tick();
    clear_inputs();
    tb_check1("request plus capture active", active, 1'b1);
    tb_check1("request plus capture valid", buffer_valid, 1'b1);
    tb_check64_local("request plus capture pc", pc, 64'h0000_0000_8000_4000);
    check_packet("request plus capture payload", 64'h0000_0000_8000_5000,
                 32'h0020_0113, 32'h0030_0193, 2'b01, 2'b00);

    clear = 1'b1;
    req_fire = 1'b1;
    req_pc = 64'h0000_0000_8000_6000;
    rsp_capture = 1'b1;
    drive_packet(64'h0000_0000_8000_7000, 32'h0040_0213,
                 32'h0050_0293, 2'b11, 2'b01);
    tick();
    clear_inputs();
    tb_check1("clear wins over request active", active, 1'b0);
    tb_check1("clear wins over capture valid", buffer_valid, 1'b0);
    tb_check64_local("clear clears pc", pc, {`XLEN{1'b0}});
    check_packet("clear retains payload", 64'h0000_0000_8000_5000,
                 32'h0020_0113, 32'h0030_0193, 2'b01, 2'b00);

    rst = 1'b1;
    tick();
    rst = 1'b0;
    tb_check1("reset after payload clears active", active, 1'b0);
    tb_check1("reset after payload clears valid", buffer_valid, 1'b0);
    check_zero_packet("reset after payload clears payload");

    tb_finish("tb_ooo_branch_prefetch_buffer");
  end
endmodule
