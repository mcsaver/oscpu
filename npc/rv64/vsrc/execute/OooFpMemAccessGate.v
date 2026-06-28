`include "define.v"

// FP 访存操作数形成：从 OooFpPendingExec 抽出的纯组合 owner。
// 负责 FLW/FLD/FSW/FSD 的有效地址、对齐地址、store 写数据和写掩码，
// 与 FP 算术数据通路（classify/convert/fma/div/sqrt）完全解耦。
// 行为与原 OooFpPendingExec 内联实现等价：单精度 store 把 32 位数据按地址低位
// 左移到对应 64 位 lane，wstrb 同步左移；双精度直接全宽。
module OooFpMemAccessGate (
  input  [`INST_W-1:0] inst_i,
  input  [`XLEN-1:0]   int_rs1_value_i,
  input  [`XLEN-1:0]   frs2_value_i,
  input                load_i,
  input                double_i,
  output [`XLEN-1:0]   mem_addr_o,
  output [`XLEN-1:0]   mem_aligned_addr_o,
  output [`XLEN-1:0]   mem_wdata_o,
  output [`STRB_W-1:0] mem_wstrb_o
);

  function [`XLEN-1:0] fp_i_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_i_imm = {{(`XLEN-12){inst[31]}}, inst[31:20]};
    end
  endfunction

  function [`XLEN-1:0] fp_s_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_s_imm = {{(`XLEN-12){inst[31]}}, inst[31:25], inst[11:7]};
    end
  endfunction

  function [`XLEN-1:0] fp_aligned_addr;
    input [`XLEN-1:0] addr;
    begin
      fp_aligned_addr = addr & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}};
    end
  endfunction

  function [`STRB_W-1:0] fp_store_wstrb;
    input [`XLEN-1:0] addr;
    input is_double;
    begin
      fp_store_wstrb = is_double ? {`STRB_W{1'b1}} :
                       ({{(`STRB_W-4){1'b0}}, 4'b1111} << addr[`XLEN_BYTE_W-1:0]);
    end
  endfunction

  function [`XLEN-1:0] fp_store_wdata;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_store_wdata = is_double ? value :
                       ({{32{1'b0}}, value[31:0]} << {addr[`XLEN_BYTE_W-1:0], 3'b000});
    end
  endfunction

  // 有效地址：load 用 I-type 立即数，store 用 S-type 立即数
  wire [`XLEN-1:0] addr_w =
      int_rs1_value_i +
      (load_i ? fp_i_imm(inst_i) : fp_s_imm(inst_i));

  assign mem_addr_o         = addr_w;
  assign mem_aligned_addr_o = fp_aligned_addr(addr_w);
  assign mem_wdata_o        = fp_store_wdata(addr_w, frs2_value_i, double_i);
  assign mem_wstrb_o        = fp_store_wstrb(addr_w, double_i);

endmodule
