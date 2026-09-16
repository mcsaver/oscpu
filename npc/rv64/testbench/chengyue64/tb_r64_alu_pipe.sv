`timescale 1ns/1ps
module tb_r64_alu_pipe;
 reg clk=0;always #5 clk=~clk;
 reg [63:0] a=0,b=0;reg [7:0] fn=0;reg word_op=0;
 wire [63:0] expected,result;reg [63:0] sample;
 R64Alu reference_alu(.a_i(a),.b_i(b),.function_i(fn),.word_i(word_op),.result_o(expected));
 R64AluPipe dut(.clk(clk),.a_i(a),.b_i(b),.function_i(fn),.word_i(word_op),.result_o(result));
 reg [31:0] seed=32'h39a72e51;
 function [31:0] random_word;
  input [31:0] old;reg [31:0] v;
  begin v=old^(old<<13);v=v^(v>>17);random_word=v^(v<<5);end
 endfunction
 integer f,w,n,total;
 initial begin
  total=0;
  for(f=0;f<256;f=f+1)for(w=0;w<2;w=w+1)for(n=0;n<80;n=n+1)begin
   @(negedge clk);fn=8'(f);word_op=w[0];
   seed=random_word(seed);a[31:0]=seed;seed=random_word(seed);a[63:32]=seed;
   seed=random_word(seed);b[31:0]=seed;seed=random_word(seed);b[63:32]=seed;
   if(n<64)begin
    b=64'(n);
    case(n%8)
     0:a=0;1:a=~64'b0;2:a=64'h8000000000000000;3:a=64'h7fffffffffffffff;
     4:a=64'h0000000080000000;5:a=64'hffffffff7fffffff;
     6:a=64'b1<<n;7:a=~(64'b1<<n);
    endcase
   end
   #1;sample=expected;@(posedge clk);#1;
   if(result!==sample)$fatal(1,"ALU pipeline fn=%h word=%b a=%h b=%h got=%h expected=%h",
     fn,word_op,a,b,result,sample);
   total=total+1;
  end
  $display("[PASS] tb_r64_alu_pipe %0d cases all opcodes/word modes, shifts, carry/count boundaries II1",total);
  $finish;
 end
endmodule
