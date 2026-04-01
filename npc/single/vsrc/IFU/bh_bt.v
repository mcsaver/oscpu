`include "define.v"

module bh_bt (
    //input clk,
    input rst,
    input en,

    input [`DATA_WIDTH_pc:-1] pc_wb,//写回时候使用
    input update_pre,//写回时候使用
    input pc_lookup//查询时使用
);

    localparam SNT = 2'b00;//强不跳转
    localparam WNT = 2'b01;//弱不跳转
    localparam WT = 2'b10;//弱跳转
    localparam ST = 2'b11;//强跳转

    //localparam jump = 1'b1;
    //localparam nojump = 1'b0;

    reg[`DATA_WIDTH_pc-1:0] bht_reg [`DATA_WIDTH_reg-2-`BHT_ADDR_WIDTH+2-1:0];//24
    //BHT历史分支表
    reg jump_if = WT;//初始默认跳转

    wire [`DATA_WIDTH_reg-2-`BHT_ADDR_WIDTH-1:0] tag;//22

    assign tag =  pc_wb[31:10];
    assign index = pc_wb[9:2];//8
    
    reg pre_state = WT;

    //BHT
    integer bht_c;
    always @(*) begin
        if (!rst) begin
                for (bht_c = 0; bht_c < 2**`BHT_ADDR_WIDTH - 1; bht_c = bht_c + 1 ) begin
                    bht_reg[bht_c] <= {24'b0};
            end
        end
        else begin
            //bht_reg[index] <= {tag, jump_if}
            if (update_pre == 1'b1) begin
                
            end
        end

    end

    


endmodule
