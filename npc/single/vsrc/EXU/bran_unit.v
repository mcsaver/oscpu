`include "define.v"

module bran_unit (
    //input clk,
    //input rst,
    //input en,

    input [`DATA_WIDTH_reg-1:0] src1,
    input [`DATA_WIDTH_reg-1:0] src2,
    input [2:0] sel_fun3,

    output result_bran
);
    //BEQ\BNE\BLT\BGE\BLTU\BGEU
    localparam s_beq = 3'b000;
    localparam s_bne = 3'b001;
    localparam s_blt = 3'b100;
    localparam s_bge = 3'b101;
    localparam s_bltu = 3'b110;
    localparam s_bgeu = 3'b111;

    wire eq  = (src1 == src2);
    wire lt  = ($signed(src1) < $signed(src2));
    wire ltu = (src1 < src2);

    reg branch_taken;
always @(*) begin
    case (sel_fun3)
        s_beq: branch_taken = eq;        // BEQ
        s_bne: branch_taken = !eq;       // BNE
        s_blt: branch_taken = lt;        // BLT
        s_bge: branch_taken = !lt;       // BGE
        s_bltu: branch_taken = ltu;       // BLTU
        s_bgeu: branch_taken = !ltu;      // BGEU
        default: branch_taken = 1'b0;
    endcase
end

assign result_bran = branch_taken;

endmodule
