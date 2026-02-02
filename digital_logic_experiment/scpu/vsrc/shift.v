module shift (
    input clk_en,
    input rst,
    output [7:0] zt
);
    
reg [7:0] data;
always @(posedge clk_en or posedge rst) begin
    if (rst) begin
        data <= 8'b00000001; // 复位时赋初值
    end
    else begin
        // 正常逻辑
        data <= (data == 8'b0) ? 8'b1 : {data[4]^data[3]^data[2]^data[0], data[7:1]};
    end
end

assign zt = data;

endmodule
