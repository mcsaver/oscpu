`include "define.v"

module alu (
    //input clk,
    input rst,
    input en,

    input [3:0] select_mod,//选择运算模式
    input [`DATA_WIDTH_reg-1:0] src1,
    input [`DATA_WIDTH_reg-1:0] src2,
    output zero,//BEQ / BNE
    output less_than,//BLT / BGE(有符号
    output less_than_u,//BLTU / BGEU(无符号)
    output reg [`DATA_WIDTH_reg-1:0] result
);
    //{funct7[5], funct3}
    localparam s_add  = 4'b0_000;  // ADD / ADDI
    localparam s_sub  = 4'b1_000;  // SUB
    localparam s_sll  = 4'b0_001;  // SLL / SLLI
    localparam s_slt  = 4'b0_010;  // SLT / SLTI
    localparam s_sltu = 4'b0_011;  // SLTU / SLTIU
    localparam s_xor  = 4'b0_100;  // XOR / XORI
    localparam s_srl  = 4'b0_101;  // SRL / SRLI
    localparam s_sra  = 4'b1_101;  // SRA / SRAI
    localparam s_or   = 4'b0_110;  // OR / ORI
    localparam s_and  = 4'b0_111;  // AND / ANDI

    always @(*) begin
        if (!rst) begin
            result = {`DATA_WIDTH_reg{1'b0}};
        end else if (en) begin
            case (select_mod)
                //s_def: result = {`DATA_WIDTH_reg{1'b0}};
                s_add: result = src1 + src2;
                s_sub: result = src1 - src2;
                s_and: result = src1 & src2;
                s_or : result = src1 | src2;
                s_xor: result = src1 ^ src2;
                s_sll: result = src1 << src2[`ADDR_WIDTH_reg-1:0];
                s_srl: result = src1 >> src2[`ADDR_WIDTH_reg-1:0];
                s_sra: result = $signed(src1) >>> src2[`ADDR_WIDTH_reg-1:0];
                s_slt: result = ($signed(src1) < $signed(src2)) ? {{(`DATA_WIDTH_reg - 1){1'b0}}, 1'b1} : {`DATA_WIDTH_reg{1'b0}};
                s_sltu: result = (src1 < src2) ? {{(`DATA_WIDTH_reg - 1){1'b0}}, 1'b1} : {`DATA_WIDTH_reg{1'b0}};

                default: result = {`DATA_WIDTH_reg{1'b0}};
            endcase
        end else begin
            result = {`DATA_WIDTH_reg{1'b0}};
        end
    end

    assign zero = (src1 == src2);
    assign less_than = ($signed(src1)) < ($signed(src2));
    assign less_than_u = (src1 < src2);

endmodule

