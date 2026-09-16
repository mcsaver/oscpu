function [31:0] rv32_r;
  input [6:0] funct7;
  input [4:0] rs2;
  input [4:0] rs1;
  input [2:0] funct3;
  input [4:0] rd;
  input [6:0] opcode;
  begin
    rv32_r = {funct7, rs2, rs1, funct3, rd, opcode};
  end
endfunction

function [31:0] rv32_i;
  input [11:0] imm;
  input [4:0] rs1;
  input [2:0] funct3;
  input [4:0] rd;
  input [6:0] opcode;
  begin
    rv32_i = {imm, rs1, funct3, rd, opcode};
  end
endfunction

function [31:0] rv32_s;
  input [11:0] imm;
  input [4:0] rs2;
  input [4:0] rs1;
  input [2:0] funct3;
  begin
    rv32_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], `OPCODE_STORE};
  end
endfunction

function [31:0] rv32_b;
  input [12:0] imm;
  input [4:0] rs2;
  input [4:0] rs1;
  input [2:0] funct3;
  begin
    rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], `OPCODE_BRANCH};
  end
endfunction

function [31:0] rv32_u;
  input [19:0] imm;
  input [4:0] rd;
  input [6:0] opcode;
  begin
    rv32_u = {imm, rd, opcode};
  end
endfunction

function [31:0] rv32_j;
  input [20:0] imm;
  input [4:0] rd;
  begin
    rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, `OPCODE_JAL};
  end
endfunction
