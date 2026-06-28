`include "define.v"

// OooFpMemAccessGate 专属 testbench：验证 FP 访存操作数形成。
// 模块只从 inst 取立即数（load 用 I-type、store 用 S-type），load/double 单独传入，
// 故 opcode/funct3 不影响本模块，inst 只需放置正确的立即数位。
module tb_ooo_fp_mem_access_gate;
  `include "tb_common.svh"

  reg [`INST_W-1:0] inst;
  reg [`XLEN-1:0] rs1;
  reg [`XLEN-1:0] frs2;
  reg load;
  reg dbl;
  wire [`XLEN-1:0] mem_addr;
  wire [`XLEN-1:0] mem_aligned_addr;
  wire [`XLEN-1:0] mem_wdata;
  wire [`STRB_W-1:0] mem_wstrb;

  OooFpMemAccessGate dut (
    .inst_i(inst),
    .int_rs1_value_i(rs1),
    .frs2_value_i(frs2),
    .load_i(load),
    .double_i(dbl),
    .mem_addr_o(mem_addr),
    .mem_aligned_addr_o(mem_aligned_addr),
    .mem_wdata_o(mem_wdata),
    .mem_wstrb_o(mem_wstrb)
  );

  task automatic check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x", what, got, exp);
      end
    end
  endtask

  // I-type 立即数 inst：imm[11:0] 放在 inst[31:20]
  function [`INST_W-1:0] enc_i;
    input [11:0] imm;
    begin
      enc_i = {imm, 20'h0};
    end
  endfunction

  // S-type 立即数 inst：imm[11:5] 放 inst[31:25]，imm[4:0] 放 inst[11:7]
  function [`INST_W-1:0] enc_s;
    input [11:0] imm;
    begin
      enc_s = {imm[11:5], 13'h0, imm[4:0], 7'h0};
    end
  endfunction

  initial begin
    tb_errors = 0;

    // FLW load，i_imm=+8，rs1=0x1000 -> addr=0x1008，aligned=0x1008
    inst = enc_i(12'h008); rs1 = 64'h1000; frs2 = 0; load = 1; dbl = 0; #1;
    check64("FLW addr +8", mem_addr, 64'h1008);
    check64("FLW aligned +8", mem_aligned_addr, 64'h1008);

    // FLD load double，i_imm=-8 (0xff8)，rs1=0x1000 -> addr=0x0ff8
    inst = enc_i(12'hff8); rs1 = 64'h1000; load = 1; dbl = 1; #1;
    check64("FLD addr -8", mem_addr, 64'h0ff8);

    // 地址对齐：base 非对齐，aligned 应清低 3 位
    inst = enc_i(12'h000); rs1 = 64'h1007; load = 1; dbl = 1; #1;
    check64("aligned 0x1007->0x1000", mem_aligned_addr, 64'h1000);

    // FSW store single，s_imm=+4，rs1=0x2000 -> addr=0x2004，byte off=4
    // wdata = frs2[31:0] << 32；wstrb = 0xf << 4 = 0xf0
    inst = enc_s(12'h004); rs1 = 64'h2000; frs2 = 64'h1122334455667788;
    load = 0; dbl = 0; #1;
    check64("FSW addr +4", mem_addr, 64'h2004);
    check64("FSW wdata lane1", mem_wdata, 64'h5566778800000000);
    check64("FSW wstrb lane1", {{(`XLEN-`STRB_W){1'b0}}, mem_wstrb}, 64'h00000000000000f0);

    // FSW store single，addr 对齐 lane0 -> wdata 低 32 位，wstrb=0x0f
    inst = enc_s(12'h000); rs1 = 64'h3000; frs2 = 64'h1122334455667788;
    load = 0; dbl = 0; #1;
    check64("FSW wdata lane0", mem_wdata, 64'h0000000055667788);
    check64("FSW wstrb lane0", {{(`XLEN-`STRB_W){1'b0}}, mem_wstrb}, 64'h000000000000000f);

    // FSD store double -> wdata 全宽，wstrb=0xff
    inst = enc_s(12'h000); rs1 = 64'h4000; frs2 = 64'h1122334455667788;
    load = 0; dbl = 1; #1;
    check64("FSD wdata", mem_wdata, 64'h1122334455667788);
    check64("FSD wstrb", {{(`XLEN-`STRB_W){1'b0}}, mem_wstrb}, 64'h00000000000000ff);

    // 负 store 立即数：s_imm=-4，rs1=0x5000 -> addr=0x4ffc
    inst = enc_s(12'hffc); rs1 = 64'h5000; load = 0; dbl = 1; #1;
    check64("FSD addr -4", mem_addr, 64'h4ffc);

    tb_finish("tb_ooo_fp_mem_access_gate");
  end
endmodule
