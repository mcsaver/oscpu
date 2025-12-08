module bianmaqi(
    //input clk,
    //input rst,
    //input en,
    input [8:0] sw,
    output [31:0] num
);

    wire [2:0] A;

    // 优先编码器逻辑，按图片中的表达式实现（D7 为最高优先级）
    assign A[2] = (sw[4] | sw[5] | sw[6] | sw[7]);
    assign A[1] = (sw[6] | sw[7]) | ((sw[2] | sw[3]) & ~A[2]);
    assign A[0] = (sw[7])
                | (sw[5] & ~(sw[6] | sw[7]))
                | (sw[3] & ~A[2])
                | (sw[1] & ~((sw[2] | sw[3]) | A[2]));

    assign num[3:0] = {1'b0, 1'b0, 1'b0, A[0]};
    assign num[7:4] = {1'b0, 1'b0, 1'b0, A[1]};
    assign num[11:8] = {1'b0, 1'b0, 1'b0, A[2]};
    
    assign num[15:12] = {1'b0, A[2], A[1], A[0]};
    

endmodule
