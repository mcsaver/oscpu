`include "R64Uop.vh"
// Static encoding legality and source namespaces are decoded once. Dynamic
// privilege/FS/rounding checks belong to the head-authorized external owner.
module R64Decode #(parameter PREDECODED=0,parameter DEFER_ILLEGAL_TVAL=0,parameter PREPARED_NPC=0,parameter PRECONTROLLED=0)(
  // In predecoded mode: {compressed illegal, canonical instruction32}.
  input [32:0] canonical_i,input [34:0] control_i,
  input [63:0] pc_i, input [63:0] raw_i, input [3:0] length_i,
  input [63:0] pred_npc_i,input [63:0] sequential_npc_i,
  input fetch_exception_i, input [5:0] fetch_cause_i, input [63:0] fetch_tval_i,
  output reg [`R64_UOP_W-1:0] uop_o,
  output reg [`R64_META_W-1:0] meta_o,
  output reg [2:0] class_o,
  output reg rd_write_o,output reg rd_fp_o,output [4:0] rd_arch_o,
  output [14:0] src_arch_o,output reg [2:0] src_fp_o,output reg [2:0] src_used_o,
  output serial_o,output illegal_o
);
  wire [31:0] rvc_w;
  wire local_rvc_illegal_w;
  generate if(PREDECODED)begin:gen_predecoded
    assign {local_rvc_illegal_w,rvc_w}=canonical_i;
  end else begin:gen_local_rvc
    R64Rvc rvc(.c_i(raw_i[15:0]),.inst_o(rvc_w),.illegal_o(local_rvc_illegal_w));
  end endgenerate
  wire [31:0] inst_w=PREDECODED ? canonical_i[31:0] : length_i==2 ? rvc_w:raw_i[31:0];
  wire [34:0] encoding_control_w;
  wire [32:0] local_canonical_w={PREDECODED ? canonical_i[32] : (length_i==2&&local_rvc_illegal_w),inst_w};
  generate if(PRECONTROLLED)begin:gen_precontrolled
    assign encoding_control_w=control_i;
  end else begin:gen_local_control
    R64DecodeControl control(.canonical_i(local_canonical_w),.raw_i(raw_i),
      .length_i(length_i),.control_o(encoding_control_w));
  end endgenerate
  wire legal_w,raw_rd_write_w,raw_rd_fp_w;
  wire [2:0] argument_kind_w,raw_class_w,raw_used_w,raw_fp_w;
  wire [7:0] function_w,raw_kind_w;wire [3:0] raw_flags_w;
  assign {legal_w,argument_kind_w,raw_kind_w,raw_flags_w,function_w,
      raw_used_w,raw_fp_w,raw_rd_fp_w,raw_rd_write_w,raw_class_w}=encoding_control_w;
  assign rd_arch_o=inst_w[11:7];
  assign src_arch_o={inst_w[31:27],inst_w[24:20],inst_w[19:15]};
  assign serial_o=class_o==`R64_C_SERIAL;
  assign illegal_o=!legal_w;
  reg [63:0] argument_w;
  reg [7:0] flags_w,kind_w;
  always @(*)begin
    class_o=raw_class_w;rd_write_o=raw_rd_write_w;rd_fp_o=raw_rd_fp_w;
    src_used_o=raw_used_w;src_fp_o=raw_fp_w;
    flags_w={4'b0,raw_flags_w};kind_w=raw_kind_w;
    case(argument_kind_w)
      1:argument_w={{52{inst_w[31]}},inst_w[31:20]};
      2:argument_w={{52{inst_w[31]}},inst_w[31:25],inst_w[11:7]};
      3:argument_w={{32{inst_w[31]}},inst_w[31:12],12'b0};
      4:argument_w=pred_npc_i;
      5:argument_w={59'b0,inst_w[19:15]};
      default:argument_w=0;
    endcase
    if(!legal_w||fetch_exception_i)begin
      class_o=`R64_C_ALU;kind_w=`R64_K_FAULT;
      rd_write_o=0;src_used_o=0;src_fp_o=0;flags_w=8'h10;
      if(fetch_exception_i)argument_w=fetch_tval_i;
      else if(!DEFER_ILLEGAL_TVAL)
        argument_w=length_i==2 ? {48'b0,raw_i[15:0]}:{32'b0,raw_i[31:0]};
    end
    uop_o=0;
    uop_o[`R64_U_PC]=pc_i;
    uop_o[`R64_U_ARG]=argument_w;
    uop_o[`R64_U_CMD]=length_i==8 ? raw_i:{32'b0,inst_w};
    uop_o[`R64_U_LEN]=length_i;
    uop_o[`R64_U_FUNC]=function_w;
    uop_o[`R64_U_FLAGS]=flags_w;
    uop_o[`R64_U_CAUSE]=fetch_exception_i ? fetch_cause_i:6'd2;
    meta_o={kind_w,length_i,(PREPARED_NPC ? sequential_npc_i : pc_i+{60'b0,length_i}),raw_i,pc_i};
  end
endmodule
