// RV64C expansion: one parallel major-op decode, narrow immediate wiring.
// The expanded word is zero for reserved encodings; hints retain their
// architecturally harmless base instruction. FP register f0 remains legal.
module R64Rvc (
  input [15:0] c_i,
  output reg [31:0] inst_o,
  output illegal_o
);
  wire [4:0] rd_w = c_i[11:7], rs2_w = c_i[6:2];
  wire [4:0] rp1_w = {2'b01,c_i[9:7]}, rp2_w = {2'b01,c_i[4:2]};
  wire [11:0] imm6_w = {{6{c_i[12]}},c_i[12],c_i[6:2]};
  wire [11:0] addi4_w = {2'b0,c_i[10:7],c_i[12:11],c_i[5],c_i[6],2'b0};
  wire [11:0] addi16_w = {{2{c_i[12]}},c_i[12],c_i[4:3],c_i[5],c_i[2],c_i[6],4'b0};
  wire [11:0] word_off_w = {5'b0,c_i[5],c_i[12:10],c_i[6],2'b0};
  wire [11:0] dword_off_w = {4'b0,c_i[6:5],c_i[12:10],3'b0};
  wire [11:0] lwsp_w = {4'b0,c_i[3:2],c_i[12],c_i[6:4],2'b0};
  wire [11:0] ldsp_w = {3'b0,c_i[4:2],c_i[12],c_i[6:5],3'b0};
  wire [11:0] swsp_w = {4'b0,c_i[8:7],c_i[12:9],2'b0};
  wire [11:0] sdsp_w = {3'b0,c_i[9:7],c_i[12:10],3'b0};
  wire [12:1] branch_w = {{4{c_i[12]}},c_i[12],c_i[6:5],c_i[2],c_i[11:10],c_i[4:3]};
  wire [20:1] jump_w = {{9{c_i[12]}},c_i[12],c_i[8],c_i[10:9],c_i[6],
                         c_i[7],c_i[2],c_i[11],c_i[5:3]};
  wire [5:0] shamt_w = {c_i[12],c_i[6:2]};

  function [31:0] enc_i;
    input [6:0] opcode;
    input [2:0] funct3;
    input [4:0] rd,rs1;
    input [11:0] imm;
    enc_i={imm,rs1,funct3,rd,opcode};
  endfunction
  function [31:0] enc_s;
    input [6:0] opcode;
    input [2:0] funct3;
    input [4:0] rs1,rs2;
    input [11:0] imm;
    enc_s={imm[11:5],rs2,rs1,funct3,imm[4:0],opcode};
  endfunction
  function [31:0] enc_r;
    input [6:0] opcode,funct7;
    input [2:0] funct3;
    input [4:0] rd,rs1,rs2;
    enc_r={funct7,rs2,rs1,funct3,rd,opcode};
  endfunction

  always @(*) begin
    inst_o=32'b0;
    case ({c_i[15:13],c_i[1:0]})
      5'b00000: if (addi4_w!=0) inst_o=enc_i(7'h13,3'd0,rp2_w,5'd2,addi4_w);
      5'b00100: inst_o=enc_i(7'h07,3'd3,rp2_w,rp1_w,dword_off_w);
      5'b01000: inst_o=enc_i(7'h03,3'd2,rp2_w,rp1_w,word_off_w);
      5'b01100: inst_o=enc_i(7'h03,3'd3,rp2_w,rp1_w,dword_off_w);
      5'b10100: inst_o=enc_s(7'h27,3'd3,rp1_w,rp2_w,dword_off_w);
      5'b11000: inst_o=enc_s(7'h23,3'd2,rp1_w,rp2_w,word_off_w);
      5'b11100: inst_o=enc_s(7'h23,3'd3,rp1_w,rp2_w,dword_off_w);

      5'b00001: inst_o=enc_i(7'h13,3'd0,rd_w,rd_w,imm6_w);
      5'b00101: if(rd_w!=0) inst_o=enc_i(7'h1b,3'd0,rd_w,rd_w,imm6_w);
      5'b01001: inst_o=enc_i(7'h13,3'd0,rd_w,5'b0,imm6_w);
      5'b01101: begin
        if(rd_w==2) begin
          if(addi16_w!=0) inst_o=enc_i(7'h13,3'd0,5'd2,5'd2,addi16_w);
        end else if(imm6_w!=0)
          inst_o=(rd_w==0)?32'h13:{{14{c_i[12]}},c_i[12],c_i[6:2],rd_w,7'h37};
      end
      5'b10001: begin
        case(c_i[11:10])
          2'b00: inst_o=enc_i(7'h13,3'd5,rp1_w,rp1_w,{6'b0,shamt_w});
          2'b01: inst_o=enc_i(7'h13,3'd5,rp1_w,rp1_w,{6'b010000,shamt_w});
          2'b10: inst_o=enc_i(7'h13,3'd7,rp1_w,rp1_w,imm6_w);
          2'b11: begin
            case({c_i[12],c_i[6:5]})
              3'b000: inst_o=enc_r(7'h33,7'h20,3'd0,rp1_w,rp1_w,rp2_w);
              3'b001: inst_o=enc_r(7'h33,7'h00,3'd4,rp1_w,rp1_w,rp2_w);
              3'b010: inst_o=enc_r(7'h33,7'h00,3'd6,rp1_w,rp1_w,rp2_w);
              3'b011: inst_o=enc_r(7'h33,7'h00,3'd7,rp1_w,rp1_w,rp2_w);
              3'b100: inst_o=enc_r(7'h3b,7'h20,3'd0,rp1_w,rp1_w,rp2_w);
              3'b101: inst_o=enc_r(7'h3b,7'h00,3'd0,rp1_w,rp1_w,rp2_w);
              default: begin end
            endcase
          end
        endcase
      end
      5'b10101: inst_o={jump_w[20],jump_w[10:1],jump_w[11],jump_w[19:12],5'b0,7'h6f};
      5'b11001,5'b11101:
        inst_o={branch_w[12],branch_w[10:5],5'b0,rp1_w,2'b00,c_i[13],
                branch_w[4:1],branch_w[11],7'h63};

      5'b00010: inst_o=enc_i(7'h13,3'd1,rd_w,rd_w,{6'b0,shamt_w});
      5'b00110: inst_o=enc_i(7'h07,3'd3,rd_w,5'd2,ldsp_w);
      5'b01010: if(rd_w!=0) inst_o=enc_i(7'h03,3'd2,rd_w,5'd2,lwsp_w);
      5'b01110: if(rd_w!=0) inst_o=enc_i(7'h03,3'd3,rd_w,5'd2,ldsp_w);
      5'b10010: begin
        if(rs2_w!=0)
          inst_o=enc_r(7'h33,7'b0,3'b0,rd_w,c_i[12]?rd_w:5'b0,rs2_w);
        else if(rd_w!=0)
          inst_o=enc_i(7'h67,3'b0,c_i[12]?5'd1:5'd0,rd_w,12'b0);
        else if(c_i[12]) inst_o=32'h00100073;
      end
      5'b10110: inst_o=enc_s(7'h27,3'd3,5'd2,rs2_w,sdsp_w);
      5'b11010: inst_o=enc_s(7'h23,3'd2,5'd2,rs2_w,swsp_w);
      5'b11110: inst_o=enc_s(7'h23,3'd3,5'd2,rs2_w,sdsp_w);
      default: begin end
    endcase
  end
  assign illegal_o=inst_o==0;
endmodule
