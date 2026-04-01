`include "define.v"

module mux (
    input clk,
    input rst,
    input en,
    //input stall,

    input  [3:0] selce_mod_mux,//选择模式
    input  [`DATA_WIDTH_pc-1:0] pc_reg_in,
    input  [`DATA_WIDTH_pc-1:0] target,
    output [`DATA_WIDTH_pc-1:0] pc_reg_out_as
);

    reg [`DATA_WIDTH_pc-1:0] pc_reg_out;

    localparam  s_flush = 4'b0000;
    localparam  s_pc4 = 4'b0001;
    localparam  s_beq = 4'b0010;
    localparam  s_jal = 4'b0011;
    localparam  s_stall = 4'b0100;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc_reg_out <= {`DATA_WIDTH_pc{1'b0}};
        end else if(en) begin
            case (selce_mod_mux)
                s_flush:  pc_reg_out <= (target);
                s_pc4:   pc_reg_out  <= (pc_reg_in + 32'd4);
                s_beq:   pc_reg_out  <= (target);
                s_jal:   pc_reg_out  <= (target);
                s_stall: pc_reg_out  <= pc_reg_out;
                default: pc_reg_out  <= (pc_reg_in + 32'd4);

            endcase
        end
    end

    assign pc_reg_out_as = pc_reg_out;

endmodule




