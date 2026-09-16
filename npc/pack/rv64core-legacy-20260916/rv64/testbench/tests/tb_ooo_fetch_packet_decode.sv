`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_fetch_packet_decode;
  reg [`XLEN-1:0] rsp_pc;
  reg [`INST_W-1:0] rsp_inst0;
  reg [1:0] rsp_resp0;
  reg [`INST_W-1:0] rsp_inst1;
  reg [1:0] rsp_resp1;
  reg [2:0] rsp_resp0_bytes;

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
  wire [12:0] dec0_bimm;
  wire dec1_branch;
  wire [12:0] dec1_bimm;
  wire [`XLEN-1:0] packet_next_pc;
  wire [`XLEN-1:0] packet_raw_next_pc;
  wire [`XLEN-1:0] fault_tval;

  OooFetchPacketDecode dut (
    .rsp_pc_i(rsp_pc),
    .rsp_inst0_i(rsp_inst0),
    .rsp_resp0_i(rsp_resp0),
    .rsp_inst1_i(rsp_inst1),
    .rsp_resp1_i(rsp_resp1),
    .rsp_resp0_bytes_i(rsp_resp0_bytes),
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
    .packet_next_pc_o(packet_next_pc),
    .packet_raw_next_pc_o(packet_raw_next_pc),
    .fault_tval_o(fault_tval)
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

  task automatic check_bimm;
    input [1023:0] what;
    input [12:0] got;
    input [12:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%04x expected=0x%04x",
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
      rsp_resp0_bytes = 3'd4;
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
    check_xlen("u32 raw packet next", packet_raw_next_pc, 64'h0000_0000_0000_1008);

    drive(64'h0000_0000_0000_2000, 32'h0001_0001, 2'b00,
          32'hdead_beef, 2'b01);
    check_xlen("c+c dec0 next", dec0_next_pc, 64'h0000_0000_0000_2002);
    tb_check32("c+c dec0 c.nop", dec0_inst, 32'h0000_0013);
    check_xlen("c+c dec1 pc", dec1_pc, 64'h0000_0000_0000_2002);
    check_xlen("c+c dec1 next", dec1_next_pc, 64'h0000_0000_0000_2004);
    tb_check32("c+c dec1 c.nop", dec1_inst, 32'h0000_0013);
    tb_check32("c+c dec1 resp from word0", {30'b0, dec1_resp}, 32'h0000_0000);
    check_xlen("c+c packet next", packet_next_pc, 64'h0000_0000_0000_2004);
    check_xlen("c+c raw packet next", packet_raw_next_pc, 64'h0000_0000_0000_2004);

    // C.LUI with rd=x0 and a nonzero immediate is a HINT, not an illegal
    // instruction.  Preserve its no-op semantics through decompression.
    drive(64'h0000_0000_0000_2100, {16'h0001, 16'h6005}, 2'b00,
          32'h0000_0013, 2'b00);
    tb_check32("c.lui x0 hint decompresses to nop",
               dec0_inst, 32'h0000_0013);
    tb_check1("c.lui x0 hint does not stop control flow",
              dec0_control_stop, 1'b0);

    drive(64'h0000_0000_0000_3000, 32'h0093_0001, 2'b00,
          32'hbabe_0010, 2'b10);
    check_xlen("c+u32 dec0 next", dec0_next_pc, 64'h0000_0000_0000_3002);
    check_xlen("c+u32 dec1 next", dec1_next_pc, 64'h0000_0000_0000_3006);
    check_xlen("c+u32 raw packet next", packet_raw_next_pc, 64'h0000_0000_0000_3006);
    tb_check32("c+u32 faulted inst sanitized", dec1_inst, 32'h0000_0013);
    tb_check32("c+u32 dec1 resp from word1", {30'b0, dec1_resp}, 32'h0000_0002);
    tb_check1("c+u32 resp creates stop", dec1_control_stop, 1'b1);
    drive(64'h0000_0000_0000_3500, 32'h0000_0013, 2'b00,
          32'h0000_0001, 2'b00);
    check_xlen("u32+c semantic packet next", packet_next_pc,
               64'h0000_0000_0000_3506);
    check_xlen("u32+c raw packet next", packet_raw_next_pc, 64'h0000_0000_0000_3506);

    drive(64'h0000_0000_0000_4000, 32'h0000_0063, 2'b00,
          32'h0010_0093, 2'b01);
    tb_check1("branch opcode stop", dec0_control_stop, 1'b1);
    tb_check32("u32+u32 dec1 resp from word1", {30'b0, dec1_resp}, 32'h0000_0001);
    tb_check1("u32+u32 resp1 stop", dec1_control_stop, 1'b1);
    tb_check1("beq slot0 branch flag", dec0_branch, 1'b1);
    check_bimm("beq x0,x0,0 bimm zero", dec0_bimm, 13'h0000);
    tb_check1("addi slot1 not branch", dec1_branch, 1'b0);
    check_bimm("non-branch slot1 bimm gated zero", dec1_bimm, 13'h0000);

    // B2 S1: 32b 分支 B-imm 提取(负/正偏移绝对锚, rv32_b 精确编码)
    drive(64'h0000_0000_0000_6000, rv32_b(-13'd8, 5'd0, 5'd0, 3'b000), 2'b00,
          rv32_b(13'd16, 5'd1, 5'd2, 3'b001), 2'b00);
    tb_check1("neg-offset beq slot0 branch flag", dec0_branch, 1'b1);
    check_bimm("neg-offset beq bimm -8", dec0_bimm, 13'h1ff8);
    tb_check1("pos-offset bne slot1 branch flag", dec1_branch, 1'b1);
    check_bimm("pos-offset bne bimm +16", dec1_bimm, 13'h0010);

    // B2 S1: RVC 分支(c.beqz x8,-4=0xdc75)经解压后识别+提取——bimm 必须与解压
    // inst 的 B 位域逐位一致(契约: bimm 在解压后 inst 上提取)且等于 -4
    drive(64'h0000_0000_0000_7000, {16'h0001, 16'hdc75}, 2'b00,
          32'h0000_0013, 2'b00);
    tb_check1("rvc c.beqz slot0 branch flag", dec0_branch, 1'b1);
    tb_check32("rvc c.beqz decompressed opcode",
               {25'b0, dec0_inst[6:0]}, {25'b0, `OPCODE_BRANCH});
    check_bimm("rvc c.beqz bimm -4", dec0_bimm, 13'h1ffc);
    check_bimm("rvc c.beqz bimm matches decompressed B field", dec0_bimm,
               {dec0_inst[31], dec0_inst[7], dec0_inst[30:25],
                dec0_inst[11:8], 1'b0});
    tb_check1("rvc slot1 c.nop not branch", dec1_branch, 1'b0);
    check_bimm("rvc slot1 bimm zero", dec1_bimm, 13'h0000);

    drive(64'h0000_0000_0000_5000, 32'h0003_0003, 2'b11,
          32'h0000_0013, 2'b00);
    tb_check1("word0 fault stops dec0", dec0_control_stop, 1'b1);
    tb_check32("word0 fault sanitizes dec0", dec0_inst, 32'h0000_0013);
    tb_check32("c+c fault propagates dec1 resp", {30'b0, dec1_resp},
               32'h0000_0003);
    tb_check1("word0 fault stops dec1 when contained", dec1_control_stop, 1'b1);
    check_xlen("fault semantic packet next uses safe prefixes",
               packet_next_pc, 64'h0000_0000_0000_5004);
    check_xlen("fault raw packet next remains untrusted payload",
               packet_raw_next_pc, 64'h0000_0000_0000_5008);

    // IFU-FETCH-G2: split=4 时 slot1 的 32b prefix 在成功 segment0，upper half 在
    // fault segment1。特意把 fault tail 拼成 semihost exit sentinel；response 必须胜出，
    // 且 inst 必须净化成 NOP，不能让 head0 C.EBREAK 把垃圾 peer 误判成 semihost。
    rsp_pc = 64'h0000_0000_0000_8000;
    rsp_inst0 = {16'h5013, 16'h9002};
    rsp_resp0 = 2'b00;
    rsp_inst1 = {16'hdeaf, 16'h4070};
    rsp_resp1 = 2'b10;
    rsp_resp0_bytes = 3'd4;
    #1;
    tb_check32("fault-tail poison slot0 c.ebreak", dec0_inst, 32'h0010_0073);
    tb_check32("fault-tail poison slot1 response",
               {30'b0, dec1_resp}, 32'h0000_0002);
    tb_check32("fault-tail poison slot1 sanitized", dec1_inst, 32'h0000_0013);
    if (dec1_inst === 32'h4070_5013) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] fault-tail poison forged semihost exit peer");
    end
    $display("[G2-DECODE-POISON] split=4 resp=2 sanitized=1 forged=0 PASS");

    // F=0 是 response ABI 的首字节失败边界。没有任何 raw byte 属于成功 segment；
    // 两个 slot 均必须从 resp1 取得 fault，并在读取长度/分类前净化为 NOP。
    rsp_pc = 64'h0000_0000_0000_9000;
    rsp_inst0 = 32'hdeaf_9002;
    rsp_resp0 = 2'b00;
    rsp_inst1 = 32'h4070_5013;
    rsp_resp1 = 2'b10;
    rsp_resp0_bytes = 3'd0;
    #1;
    tb_check32("G2 F0 slot0 response", {30'b0, dec0_resp}, 32'h0000_0002);
    tb_check32("G2 F0 slot1 response", {30'b0, dec1_resp}, 32'h0000_0002);
    tb_check32("G2 F0 slot0 sanitized", dec0_inst, 32'h0000_0013);
    tb_check32("G2 F0 slot1 sanitized", dec1_inst, 32'h0000_0013);
    check_xlen("G2 F0 fault frontier", fault_tval,
               64'h0000_0000_0000_9000);
    $display("[G2-DECODE-F0] split=0 resp=2/2 sanitized=1/1 tval=pc PASS");

    // T4G: xEPC 仍是 faulting instruction 的 slot PC；xTVAL 必须是首个失败
    // 2B portion 的 frontier。覆盖跨页常见 F=2/4/6 三种布局。
    rsp_pc = 64'h0000_0000_0000_0ffe;
    rsp_resp0_bytes = 3'd2;
    #1;
    check_xlen("fault frontier F=2", fault_tval,
               64'h0000_0000_0000_1000);
    rsp_pc = 64'h0000_0000_0000_1ffc;
    rsp_resp0_bytes = 3'd4;
    #1;
    check_xlen("fault frontier F=4", fault_tval,
               64'h0000_0000_0000_2000);
    rsp_pc = 64'h0000_0000_0000_2ffa;
    rsp_resp0_bytes = 3'd6;
    #1;
    check_xlen("fault frontier F=6", fault_tval,
               64'h0000_0000_0000_3000);
    $display("[T4G-FETCH-FAULT-TVAL-FRONTIER] F=2/4/6 exact portion addresses covered");

    tb_finish("tb_ooo_fetch_packet_decode");
  end

endmodule
