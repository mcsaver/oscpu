// Complete combinational platform check for existing IF/PTW clients.
module R64Pma(
 input [63:0] address_i,input [4:0] size_i,
 output fault_o,output [1:0] class_o
);
 wire [64:0] last_w={1'b0,address_i}+{60'b0,size_i}-65'd1;
 R64PmaRange classify(.address_i(address_i),.last_i(last_w),.size_i(size_i),
  .fault_o(fault_o),.class_o(class_o));
endmodule
