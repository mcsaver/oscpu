`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_fetch_packet_decode;
  reg [`XLEN-1:0] rsp_pc;
  reg [`INST_W-1:0] rsp_inst0;
  reg [1:0] rsp_resp0;
  reg [`INST_W-1:0] rsp_inst1;
  reg [1:0] rsp_resp1;

  wire [`XLEN-1:0] dec0_pc;
  wire [`XLEN-1:0] dec0_next_pc;
  wire [`INST_W-1:0] dec0_inst;
  wire [1:0] dec0_resp;
  wire dec0_control_stop;
  wire [`XLEN-1:0] dec1_pc;
  wire [`XLEN-1:0] dec1_next_pc;
  wire [`INST_W-1:0] dec1_inst;
  wire [1:0] dec1_resp;
  wire dec1_control_stop;
  // B2 S1: per-slot 分支识别 + B-imm 提取
  wire dec0_branch;
  wire [`XLEN-1:0] dec0_bimm;
  wire dec1_branch;
  wire [`XLEN-1:0] dec1_bimm;
  wire [`XLEN-1:0] packet_next_pc;

  OooFetchPacketDecode dut (
    .rsp_pc_i(rsp_pc),
    .rsp_inst0_i(rsp_inst0),
    .rsp_resp0_i(rsp_resp0),
    .rsp_inst1_i(rsp_inst1),
    .rsp_resp1_i(rsp_resp1),
    .dec0_pc_o(dec0_pc),
    .dec0_next_pc_o(dec0_next_pc),
    .dec0_inst_o(dec0_inst),
    .dec0_resp_o(dec0_resp),
    .dec0_control_stop_o(dec0_control_stop),
    .dec1_pc_o(dec1_pc),
    .dec1_next_pc_o(dec1_next_pc),
    .dec1_inst_o(dec1_inst),
    .dec1_resp_o(dec1_resp),
    .dec1_control_stop_o(dec1_control_stop),
    .dec0_branch_o(dec0_branch),
    .dec0_bimm_o(dec0_bimm),
    .dec1_branch_o(dec1_branch),
    .dec1_bimm_o(dec1_bimm),
    .packet_next_pc_o(packet_next_pc)
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

  task automatic drive;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [1:0] resp0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp1;
    begin
      rsp_pc = pc;
      rsp_inst0 = inst0;
      rsp_resp0 = resp0;
      rsp_inst1 = inst1;
      rsp_resp1 = resp1;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    drive(64'h0000_0000_0000_1000, 32'h0000_0013, 2'b00,
          32'h0000_8067, 2'b00);
    check_xlen("u32 dec0 pc", dec0_pc, 64'h0000_0000_0000_1000);
    check_xlen("u32 dec0 next", dec0_next_pc, 64'h0000_0000_0000_1004);
    tb_check32("u32 dec0 inst", dec0_inst, 32'h0000_0013);
    tb_check1("u32 dec0 no control stop", dec0_control_stop, 1'b0);
    check_xlen("u32 dec1 pc", dec1_pc, 64'h0000_0000_0000_1004);
    check_xlen("u32 dec1 next", dec1_next_pc, 64'h0000_0000_0000_1008);
    tb_check32("u32 dec1 inst", dec1_inst, 32'h0000_8067);
    tb_check1("u32 dec1 jalr stop", dec1_control_stop, 1'b1);
    check_xlen("u32 packet next", packet_next_pc, 64'h0000_0000_0000_1008);

    drive(64'h0000_0000_0000_2000, 32'h0001_0001, 2'b00,
          32'hdead_beef, 2'b01);
    check_xlen("c+c dec0 next", dec0_next_pc, 64'h0000_0000_0000_2002);
    tb_check32("c+c dec0 c.nop", dec0_inst, 32'h0000_0013);
    check_xlen("c+c dec1 pc", dec1_pc, 64'h0000_0000_0000_2002);
    check_xlen("c+c dec1 next", dec1_next_pc, 64'h0000_0000_0000_2004);
    tb_check32("c+c dec1 c.nop", dec1_inst, 32'h0000_0013);
    tb_check32("c+c dec1 resp from word0", {30'b0, dec1_resp}, 32'h0000_0000);
    check_xlen("c+c packet next", packet_next_pc, 64'h0000_0000_0000_2004);

    drive(64'h0000_0000_0000_3000, 32'h0093_0001, 2'b00,
          32'hbabe_0010, 2'b10);
    check_xlen("c+u32 dec0 next", dec0_next_pc, 64'h0000_0000_0000_3002);
    check_xlen("c+u32 dec1 next", dec1_next_pc, 64'h0000_0000_0000_3006);
    tb_check32("c+u32 stitched inst", dec1_inst, 32'h0010_0093);
    tb_check32("c+u32 dec1 resp from word1", {30'b0, dec1_resp}, 32'h0000_0002);
    tb_check1("c+u32 resp creates stop", dec1_control_stop, 1'b1);

    drive(64'h0000_0000_0000_4000, 32'h0000_0063, 2'b00,
          32'h0010_0093, 2'b01);
    tb_check1("branch opcode stop", dec0_control_stop, 1'b1);
    tb_check32("u32+u32 dec1 resp from word1", {30'b0, dec1_resp}, 32'h0000_0001);
    tb_check1("u32+u32 resp1 stop", dec1_control_stop, 1'b1);
    tb_check1("beq slot0 branch flag", dec0_branch, 1'b1);
    check_xlen("beq x0,x0,0 bimm zero", dec0_bimm, 64'h0);
    tb_check1("addi slot1 not branch", dec1_branch, 1'b0);
    check_xlen("non-branch slot1 bimm gated zero", dec1_bimm, 64'h0);

    // B2 S1: 32b 分支 B-imm 提取(负/正偏移绝对锚, rv32_b 精确编码)
    drive(64'h0000_0000_0000_6000, rv32_b(-13'd8, 5'd0, 5'd0, 3'b000), 2'b00,
          rv32_b(13'd16, 5'd1, 5'd2, 3'b001), 2'b00);
    tb_check1("neg-offset beq slot0 branch flag", dec0_branch, 1'b1);
    check_xlen("neg-offset beq bimm -8", dec0_bimm,
               64'hffff_ffff_ffff_fff8);
    tb_check1("pos-offset bne slot1 branch flag", dec1_branch, 1'b1);
    check_xlen("pos-offset bne bimm +16", dec1_bimm, 64'd16);

    // B2 S1: RVC 分支(c.beqz x8,-4=0xdc75)经解压后识别+提取——bimm 必须与解压
    // inst 的 B 位域逐位一致(契约: bimm 在解压后 inst 上提取)且等于 -4
    drive(64'h0000_0000_0000_7000, {16'h0001, 16'hdc75}, 2'b00,
          32'h0000_0013, 2'b00);
    tb_check1("rvc c.beqz slot0 branch flag", dec0_branch, 1'b1);
    tb_check32("rvc c.beqz decompressed opcode",
               {25'b0, dec0_inst[6:0]}, {25'b0, `OPCODE_BRANCH});
    check_xlen("rvc c.beqz bimm -4", dec0_bimm,
               64'hffff_ffff_ffff_fffc);
    check_xlen("rvc c.beqz bimm matches decompressed B field", dec0_bimm,
               {{(`XLEN-13){dec0_inst[31]}}, dec0_inst[31], dec0_inst[7],
                dec0_inst[30:25], dec0_inst[11:8], 1'b0});
    tb_check1("rvc slot1 c.nop not branch", dec1_branch, 1'b0);
    check_xlen("rvc slot1 bimm zero", dec1_bimm, 64'h0);

    drive(64'h0000_0000_0000_5000, 32'h0001_0001, 2'b11,
          32'h0000_0013, 2'b00);
    tb_check1("word0 fault stops dec0", dec0_control_stop, 1'b1);
    tb_check32("c+c fault propagates dec1 resp", {30'b0, dec1_resp},
               32'h0000_0003);
    tb_check1("word0 fault stops dec1 when contained", dec1_control_stop, 1'b1);

    tb_finish("tb_ooo_fetch_packet_decode");
  end

endmodule
