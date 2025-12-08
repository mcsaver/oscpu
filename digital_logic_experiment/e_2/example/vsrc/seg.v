module seg(
  input clk,
  input rst,
  input en,
  input input_f,
  input  [31:0] num,
  output [7:0] o_seg0,
  output [7:0] o_seg1,
  output [7:0] o_seg2,
  output [7:0] o_seg3,
  output [7:0] o_seg4,
  output [7:0] o_seg5,
  output [7:0] o_seg6,
  output [7:0] o_seg7
);


reg [0:0] out;
parameter CLK_NUM = 5000000;

reg [35:0] count;
//reg [0:0] flag;

wire [7:0] shuzi [9:0];
//num是要输出的数字
//wire [31:0] num;
//reg [31:0] num ;
wire [63:0] seg_o;

assign  shuzi[0] = 8'b11111101;
assign  shuzi[1] = 8'b01100000;
assign  shuzi[2] = 8'b11011010;
assign  shuzi[3] = 8'b11110010;
assign  shuzi[4] = 8'b01100110;
assign  shuzi[5] = 8'b10110110;
assign  shuzi[6] = 8'b10111110;
assign  shuzi[7] = 8'b11100000;
assign  shuzi[8] = 8'b11111110;
assign  shuzi[9] = 8'b11110110;
//wire [31:0] init;
//assign init[31:0] = 32'h76543210;
// pack nibbles into a single 32-bit value: {7,6,5,4,3,2,1,0} = 0x76543210
//assign num = 32'h76543210;
/* always @(posedge clk) begin
    num <= init;
  if (rst) begin
    num <= 32'h76543210;
  end
  else begin
    if (out) begin
      num <= {num[31:28] + 4'd1,
      num[27:24] + 4'd1,
      num[23:20] + 4'd1,
      num[19:16] + 4'd1,
      num[15:12] + 4'd1,
      num[11:8] + 4'd1,
      num[7:4] + 4'd1,
      num[3:0] + 4'd1};
    end
  end

end */

always @(posedge clk) begin
  //num <= 3'b111;
  if(rst) begin
    count <= 0;
    out <= 0;
    //flag <= 1;
  end
  else begin
    if(count == CLK_NUM)
      begin
        out <= ~out;
      end
    count <= (count == CLK_NUM) ? 0 : count + 1;
  end
end

reg [63:0] seg_buffer;
always @(posedge clk) begin
  seg_buffer <= seg_o ;
end


assign seg_o[7:0] = out ?
                    (
                      8'b0 |
                      ({8{num[3:0] == 4'b1001}} & shuzi[9]) |
                      ({8{num[3:0] == 4'b1000}} & shuzi[8]) |
                      ({8{num[3:0] == 4'b0111}} & shuzi[7]) |
                      ({8{num[3:0] == 4'b0110}} & shuzi[6]) |
                      ({8{num[3:0] == 4'b0101}} & shuzi[5]) |
                      ({8{num[3:0] == 4'b0100}} & shuzi[4]) |
                      ({8{num[3:0] == 4'b0011}} & shuzi[3]) |
                      ({8{num[3:0] == 4'b0010}} & shuzi[2]) |
                      ({8{num[3:0] == 4'b0001}} & shuzi[1]) |
                      ({8{num[3:0] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[7:0];

assign seg_o[15:8] = out ?
                    (
                      8'b0 |
                      ({8{num[7:4] == 4'b1001}} & shuzi[9]) |
                      ({8{num[7:4] == 4'b1000}} & shuzi[8]) |
                      ({8{num[7:4] == 4'b0111}} & shuzi[7]) |
                      ({8{num[7:4] == 4'b0110}} & shuzi[6]) |
                      ({8{num[7:4] == 4'b0101}} & shuzi[5]) |
                      ({8{num[7:4] == 4'b0100}} & shuzi[4]) |
                      ({8{num[7:4] == 4'b0011}} & shuzi[3]) |
                      ({8{num[7:4] == 4'b0010}} & shuzi[2]) |
                      ({8{num[7:4] == 4'b0001}} & shuzi[1]) |
                      ({8{num[7:4] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[15:8];

assign seg_o[23:16] = out ?
                    (
                      8'b0 |
                      ({8{num[11:8] == 4'b1001}} & shuzi[9]) |
                      ({8{num[11:8] == 4'b1000}} & shuzi[8]) |
                      ({8{num[11:8] == 4'b0111}} & shuzi[7]) |
                      ({8{num[11:8] == 4'b0110}} & shuzi[6]) |
                      ({8{num[11:8] == 4'b0101}} & shuzi[5]) |
                      ({8{num[11:8] == 4'b0100}} & shuzi[4]) |
                      ({8{num[11:8] == 4'b0011}} & shuzi[3]) |
                      ({8{num[11:8] == 4'b0010}} & shuzi[2]) |
                      ({8{num[11:8] == 4'b0001}} & shuzi[1]) |
                      ({8{num[11:8] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[23:16];

assign seg_o[31:24] = out ?
                    (
                      8'b0 |
                      ({8{num[15:12] == 4'b1001}} & shuzi[9]) |
                      ({8{num[15:12] == 4'b1000}} & shuzi[8]) |
                      ({8{num[15:12] == 4'b0111}} & shuzi[7]) |
                      ({8{num[15:12] == 4'b0110}} & shuzi[6]) |
                      ({8{num[15:12] == 4'b0101}} & shuzi[5]) |
                      ({8{num[15:12] == 4'b0100}} & shuzi[4]) |
                      ({8{num[15:12] == 4'b0011}} & shuzi[3]) |
                      ({8{num[15:12] == 4'b0010}} & shuzi[2]) |
                      ({8{num[15:12] == 4'b0001}} & shuzi[1]) |
                      ({8{num[15:12] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[31:24];



assign seg_o[39:32] = out ?
                    (
                      8'b0 |
                      ({8{num[19:16] == 4'b1001}} & shuzi[9]) |
                      ({8{num[19:16] == 4'b1000}} & shuzi[8]) |
                      ({8{num[19:16] == 4'b0111}} & shuzi[7]) |
                      ({8{num[19:16] == 4'b0110}} & shuzi[6]) |
                      ({8{num[19:16] == 4'b0101}} & shuzi[5]) |
                      ({8{num[19:16] == 4'b0100}} & shuzi[4]) |
                      ({8{num[19:16] == 4'b0011}} & shuzi[3]) |
                      ({8{num[19:16] == 4'b0010}} & shuzi[2]) |
                      ({8{num[19:16] == 4'b0001}} & shuzi[1]) |
                      ({8{num[19:16] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[39:32];

assign seg_o[47:40] = out ?
                    (
                      8'b0 |
                      ({8{num[23:20] == 4'b1001}} & shuzi[9]) |
                      ({8{num[23:20] == 4'b1000}} & shuzi[8]) |
                      ({8{num[23:20] == 4'b0111}} & shuzi[7]) |
                      ({8{num[23:20] == 4'b0110}} & shuzi[6]) |
                      ({8{num[23:20] == 4'b0101}} & shuzi[5]) |
                      ({8{num[23:20] == 4'b0100}} & shuzi[4]) |
                      ({8{num[23:20] == 4'b0011}} & shuzi[3]) |
                      ({8{num[23:20] == 4'b0010}} & shuzi[2]) |
                      ({8{num[23:20] == 4'b0001}} & shuzi[1]) |
                      ({8{num[23:20] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[47:40];

assign seg_o[55:48] = out ?
                    (
                      8'b0 |
                      ({8{num[27:24] == 4'b1001}} & shuzi[9]) |
                      ({8{num[27:24] == 4'b1000}} & shuzi[8]) |
                      ({8{num[27:24] == 4'b0111}} & shuzi[7]) |
                      ({8{num[27:24] == 4'b0110}} & shuzi[6]) |
                      ({8{num[27:24] == 4'b0101}} & shuzi[5]) |
                      ({8{num[27:24] == 4'b0100}} & shuzi[4]) |
                      ({8{num[27:24] == 4'b0011}} & shuzi[3]) |
                      ({8{num[27:24] == 4'b0010}} & shuzi[2]) |
                      ({8{num[27:24] == 4'b0001}} & shuzi[1]) |
                      ({8{num[27:24] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[55:48];

assign seg_o[63:56] = out ?
                    (
                      8'b0 |
                      ({8{num[31:28] == 4'b1001}} & shuzi[9]) |
                      ({8{num[31:28] == 4'b1000}} & shuzi[8]) |
                      ({8{num[31:28] == 4'b0111}} & shuzi[7]) |
                      ({8{num[31:28] == 4'b0110}} & shuzi[6]) |
                      ({8{num[31:28] == 4'b0101}} & shuzi[5]) |
                      ({8{num[31:28] == 4'b0100}} & shuzi[4]) |
                      ({8{num[31:28] == 4'b0011}} & shuzi[3]) |
                      ({8{num[31:28] == 4'b0010}} & shuzi[2]) |
                      ({8{num[31:28] == 4'b0001}} & shuzi[1]) |
                      ({8{num[31:28] == 4'b0000}} & shuzi[0])
                    ) : seg_buffer[63:56];



assign o_seg0 = en ? (~seg_o[7:0]  )  : (~8'b00000000);
assign o_seg1 = en ? (~seg_o[15:8] )  : (~8'b00000000);
assign o_seg2 = en ? (~seg_o[23:16])  : (~8'b00000000);
assign o_seg3 = en ? (~seg_o[31:24])  : (~8'b00000000);//~seg_o[31:24];
assign o_seg4 = ~8'b00000000;//~seg_o[39:32];
assign o_seg5 = ~8'b00000000;//~seg_o[47:40];
assign o_seg6 = ~8'b00000000;//~seg_o[55:48];
assign o_seg7 = en ? (~((input_f) ? shuzi[1] : shuzi[0])) : (~8'b00000000);//~seg_o[63:56];

endmodule
