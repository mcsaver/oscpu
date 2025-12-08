module alu(
    input [2:0] func_sl,
    input [3:0] a,
    input [3:0] b,
    output [3:0] c
);
    
    wire bigornot;
    wire equal;

    assign bigornot = 1'b0 |
                    ((a[3]==0 & b[3]==1) & 1'b1) |
                    ((a[3]==1 & b[3]==0) & 1'b0) |
                    ((a[3]==0 & b[3]==0) & (a < b) ? 1 : 0) |
                    ((a[3]==1 & b[3]==1) & (a > b) ? 1 : 0) ;

    assign equal = a==b;

    assign c =  4'b0 |
                {4{(func_sl == 3'b000)}} &  (a + b) |
                {4{(func_sl == 3'b001)}} &  (a - b) |
                {4{(func_sl == 3'b010)}} &  (~a)    |
                {4{(func_sl == 3'b011)}} &  (a & b) |
                {4{(func_sl == 3'b100)}} &  (a | b) |
                {4{(func_sl == 3'b101)}} &  (a ^ b) |
                {4{(func_sl == 3'b110)}} &  ((bigornot) ? 4'b0001 : 4'b0000) |
                {4{(func_sl == 3'b111)}} &  ((equal)    ? 4'b0001 : 4'b0000);
endmodule

