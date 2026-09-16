`include "R64Uop.vh"
// Pure instruction-encoding controls. No privilege, FS, trigger or fetch-fault
// state is observed here. The packet may be prepared before backend admission.
// Control = {legal, argument kind, retire kind, flags[3:0], function,
//            source used, source FP, destination FP, destination write, class}.
module R64DecodeControl(
 input [32:0] canonical_i,input [63:0] raw_i,input [3:0] length_i,
 output [34:0] control_o
);
 wire [31:0] inst_w=canonical_i[31:0];
 wire [4:0] rd_arch_o;wire [14:0] src_arch_o;
 reg [2:0] class_o,src_fp_o,src_used_o;
 reg rd_write_o,rd_fp_o,legal_w;
 reg [7:0] function_w,flags_w,kind_w;
 reg [2:0] argument_kind_w;
  wire [6:0] opcode_w=inst_w[6:0],f7_w=inst_w[31:25];
  wire [5:0] f6_w=inst_w[31:26];
  wire [2:0] f3_w=inst_w[14:12];
  wire [4:0] rs1_w=inst_w[19:15],rs2_w=inst_w[24:20];
  wire rounding_w=f3_w<=4||f3_w==7;
  wire format_w=inst_w[26:25]<=1;
  wire tensor_low_w=raw_i[6:0]==7'h5b&&raw_i[14:12]==3&&raw_i[31:27]==0&&raw_i[25];
  wire tensor_high_w=raw_i[38:32]==7'h5b&&raw_i[46:44]==3&&
      (raw_i[63:57]==7'h05||raw_i[63:57]==7'h07);
  assign rd_arch_o=inst_w[11:7];
  assign src_arch_o={inst_w[31:27],rs2_w,rs1_w};
  always @(*) begin
    legal_w=0;class_o=`R64_C_ALU;rd_write_o=0;rd_fp_o=0;
    src_fp_o=0;src_used_o=0;function_w=0;flags_w=0;kind_w=`R64_K_NORMAL;
    argument_kind_w=3'd0;
    case(opcode_w)
      7'h37,7'h17:begin
        legal_w=1;rd_write_o=1;argument_kind_w=3'd3;flags_w[3]=1;
        flags_w[1]=opcode_w==7'h17;
        function_w=opcode_w==7'h37 ? `R64_F_COPY_B:`R64_F_ADD;
      end
      7'h6f,7'h67,7'h63:begin
        class_o=`R64_C_BRANCH;kind_w=`R64_K_BRANCH;argument_kind_w=3'd4;
        if(opcode_w==7'h6f)begin legal_w=1;rd_write_o=1;function_w=8;end
        else if(opcode_w==7'h67)begin legal_w=f3_w==0;rd_write_o=1;src_used_o=1;function_w=9;end
        else begin
          legal_w=f3_w==0||f3_w==1||f3_w>=4;src_used_o=3;function_w={5'b0,f3_w};
        end
      end
      7'h03,7'h23,7'h07,7'h27:begin
        class_o=`R64_C_MEM;src_used_o=1;
        function_w={1'b0,opcode_w[2],opcode_w[5],2'b0,f3_w};
        if(opcode_w[5])begin
          kind_w=`R64_K_STORE;src_used_o=3;src_fp_o[1]=opcode_w[2];argument_kind_w=3'd2;
          legal_w=opcode_w[2] ? (f3_w==2||f3_w==3):f3_w<=3;
        end else begin
          kind_w=`R64_K_LOAD;rd_write_o=1;rd_fp_o=opcode_w[2];argument_kind_w=3'd1;
          legal_w=opcode_w[2] ? (f3_w==2||f3_w==3):f3_w<=6;
        end
      end
      7'h2f:begin
        class_o=`R64_C_MEM;kind_w=`R64_K_AMO;rd_write_o=1;src_used_o=3;
        function_w={3'b101,2'b0,f3_w};
        case(inst_w[31:27])
          0,1,3,4,8,12,16,20,24,28:legal_w=f3_w==2||f3_w==3;
          2:begin legal_w=(f3_w==2||f3_w==3)&&rs2_w==0;src_used_o=1;end
          default:begin end
        endcase
      end
      7'h13,7'h1b:begin
        rd_write_o=1;src_used_o=1;flags_w[3]=1;flags_w[0]=opcode_w==7'h1b;
        argument_kind_w=3'd1;function_w={5'b0,f3_w};
        case(f3_w)
          0:legal_w=1;
          2,3,4,6,7:legal_w=opcode_w==7'h13;
          1:legal_w=opcode_w==7'h13 ? f6_w==0:f7_w==0;
          5:begin
            legal_w=opcode_w==7'h13 ? (f6_w==0||f6_w==6'h10):(f7_w==0||f7_w==7'h20);
            if(inst_w[30])function_w=`R64_F_SRA;
          end
          default:begin end
        endcase
        if(opcode_w==7'h13)begin
          if(f3_w==1)case(f6_w)
            6'h0a:begin legal_w=1;function_w=`R64_F_BSET;end
            6'h12:begin legal_w=1;function_w=`R64_F_BCLR;end
            6'h1a:begin legal_w=1;function_w=`R64_F_BINV;end
            default:begin end
          endcase
          if(f3_w==5)case(f6_w)
            6'h18:begin legal_w=1;function_w=`R64_F_ROR;end
            6'h12:begin legal_w=1;function_w=`R64_F_BEXT;end
            default:begin end
          endcase
          if(f3_w==5&&f7_w==7'h14&&rs2_w==7)begin legal_w=1;function_w=`R64_F_ORCB;end
          if(f3_w==5&&f7_w==7'h35&&rs2_w==24)begin legal_w=1;function_w=`R64_F_REV8;end
        end else begin
          if(f3_w==1&&f6_w==6'h02)begin legal_w=1;function_w=`R64_F_SLLIUW;flags_w[0]=0;end
          if(f3_w==5&&f7_w==7'h30)begin legal_w=1;function_w=`R64_F_ROR;end
        end
        if(f3_w==1&&f7_w==7'h30)case(rs2_w)
          0:begin legal_w=1;function_w=`R64_F_CLZ;end
          1:begin legal_w=1;function_w=`R64_F_CTZ;end
          2:begin legal_w=1;function_w=`R64_F_CPOP;end
          4:if(opcode_w==7'h13)begin legal_w=1;function_w=`R64_F_SEXTB;end
          5:if(opcode_w==7'h13)begin legal_w=1;function_w=`R64_F_SEXTH;end
          default:begin end
        endcase
      end
      7'h33,7'h3b:begin
        rd_write_o=1;src_used_o=3;flags_w[0]=opcode_w==7'h3b;function_w={5'b0,f3_w};
        if(f7_w==0)legal_w=opcode_w==7'h33||f3_w==0||f3_w==1||f3_w==5;
        if(f7_w==7'h20&&(f3_w==0||f3_w==5))begin
          legal_w=1;function_w=f3_w==0 ? `R64_F_SUB:`R64_F_SRA;
        end
        if(f7_w==1)begin
          legal_w=opcode_w==7'h33||f3_w==0||f3_w>=4;class_o=`R64_C_MDU;
        end
        case({f7_w,f3_w})
          {7'h10,3'd2}:begin legal_w=1;function_w=flags_w[0] ? `R64_F_SH1ADDUW:`R64_F_SH1ADD;flags_w[0]=0;end
          {7'h10,3'd4}:begin legal_w=1;function_w=flags_w[0] ? `R64_F_SH2ADDUW:`R64_F_SH2ADD;flags_w[0]=0;end
          {7'h10,3'd6}:begin legal_w=1;function_w=flags_w[0] ? `R64_F_SH3ADDUW:`R64_F_SH3ADD;flags_w[0]=0;end
          {7'h30,3'd1}:begin legal_w=1;function_w=`R64_F_ROL;end
          {7'h30,3'd5}:begin legal_w=1;function_w=`R64_F_ROR;end
          {7'h04,3'd0}:if(opcode_w==7'h3b)begin legal_w=1;function_w=`R64_F_ADDUW;flags_w[0]=0;end
          {7'h04,3'd4}:if(opcode_w==7'h3b&&rs2_w==0)begin legal_w=1;function_w=`R64_F_ZEXTH;flags_w[0]=0;src_used_o=1;end
          default:begin end
        endcase
        if(opcode_w==7'h33)case({f7_w,f3_w})
          {7'h20,3'd7}:begin legal_w=1;function_w=`R64_F_ANDN;end
          {7'h20,3'd6}:begin legal_w=1;function_w=`R64_F_ORN;end
          {7'h20,3'd4}:begin legal_w=1;function_w=`R64_F_XNOR;end
          {7'h05,3'd4}:begin legal_w=1;function_w=`R64_F_MIN;end
          {7'h05,3'd5}:begin legal_w=1;function_w=`R64_F_MINU;end
          {7'h05,3'd6}:begin legal_w=1;function_w=`R64_F_MAX;end
          {7'h05,3'd7}:begin legal_w=1;function_w=`R64_F_MAXU;end
          {7'h05,3'd1},{7'h05,3'd2},{7'h05,3'd3}:begin
            legal_w=1;function_w={5'b00001,f3_w};class_o=`R64_C_MDU;
          end
          {7'h14,3'd1}:begin legal_w=1;function_w=`R64_F_BSET;end
          {7'h24,3'd1}:begin legal_w=1;function_w=`R64_F_BCLR;end
          {7'h24,3'd5}:begin legal_w=1;function_w=`R64_F_BEXT;end
          {7'h34,3'd1}:begin legal_w=1;function_w=`R64_F_BINV;end
          default:begin end
        endcase
      end
      7'h43,7'h47,7'h4b,7'h4f:begin
        legal_w=format_w&&rounding_w;class_o=`R64_C_FP;kind_w=`R64_K_FP;
        rd_write_o=1;rd_fp_o=1;src_used_o=7;src_fp_o=7;function_w={1'b0,opcode_w};
      end
      7'h53:begin
        class_o=`R64_C_FP;kind_w=`R64_K_FP;rd_write_o=1;rd_fp_o=1;
        src_used_o=3;src_fp_o=3;function_w={1'b0,f7_w};
        case(f7_w)
          7'h00,7'h01,7'h04,7'h05,7'h08,7'h09,7'h0c,7'h0d:legal_w=rounding_w;
          7'h2c,7'h2d:begin legal_w=rounding_w&&rs2_w==0;src_used_o=1;end
          7'h10,7'h11:legal_w=f3_w<=2;
          7'h14,7'h15:legal_w=f3_w<=1;
          7'h20:begin legal_w=rounding_w&&rs2_w==1;src_used_o=1;end
          7'h21:begin legal_w=rounding_w&&rs2_w==0;src_used_o=1;end
          7'h50,7'h51:begin legal_w=f3_w<=2;rd_fp_o=0;end
          7'h60,7'h61:begin legal_w=rounding_w&&rs2_w<=3;src_used_o=1;rd_fp_o=0;end
          7'h68,7'h69:begin legal_w=rounding_w&&rs2_w<=3;src_used_o=1;src_fp_o=0;end
          7'h70,7'h71:begin legal_w=f3_w<=1&&rs2_w==0;src_used_o=1;rd_fp_o=0;end
          7'h78,7'h79:begin legal_w=f3_w==0&&rs2_w==0;src_used_o=1;src_fp_o=0;end
          default:begin end
        endcase
      end
      7'h73:begin
        class_o=`R64_C_SERIAL;kind_w=`R64_K_CSR;
        if(f3_w!=0&&f3_w!=4)begin
          legal_w=1;rd_write_o=1;src_used_o=f3_w[2] ? 0:1;argument_kind_w=3'd5;
        end else if(f3_w==0&&inst_w[11:7]==0)begin
          if(f7_w==7'h09||f7_w==7'h0b)begin legal_w=1;kind_w=`R64_K_SFENCE;src_used_o=3;end
          else if(f7_w==7'h0c&&rs1_w==0&&rs2_w<=1)begin legal_w=1;kind_w=`R64_K_SFENCE;end
          else if(rs1_w==0)case(inst_w[31:20])
            12'h000:begin legal_w=1;kind_w=`R64_K_ECALL;end
            12'h001:begin legal_w=1;kind_w=`R64_K_EBREAK;end
            12'h302:begin legal_w=1;kind_w=`R64_K_MRET;end
            12'h102:begin legal_w=1;kind_w=`R64_K_SRET;end
            12'h105:begin legal_w=1;kind_w=`R64_K_WFI;end
            default:begin end
          endcase
        end
        function_w=kind_w;
      end
      7'h0f:begin
        legal_w=f3_w<=1;class_o=`R64_C_SERIAL;
        kind_w=f3_w==0 ? `R64_K_FENCE:`R64_K_FENCEI;function_w=kind_w;
      end
      7'h5b:begin
        class_o=`R64_C_SERIAL;kind_w=`R64_K_TENSOR;
        if(length_i==4&&f3_w==4)begin legal_w=1;src_used_o=1;function_w=0;end
        if(length_i==8&&tensor_low_w&&tensor_high_w)begin
          legal_w=1;function_w=raw_i[63:57]==7'h07 ? 2:1;
        end
      end
      default:begin end
    endcase
    if(length_i!=2&&length_i!=4&&length_i!=8)legal_w=0;
    if(canonical_i[32])legal_w=0;
    if(length_i==8&&opcode_w!=7'h5b)legal_w=0;
    if(!rd_fp_o&&rd_arch_o==0)rd_write_o=0;

  end
  assign control_o={legal_w,argument_kind_w,kind_w,flags_w[3:0],function_w,
      src_used_o,src_fp_o,rd_fp_o,rd_write_o,class_o};
endmodule
