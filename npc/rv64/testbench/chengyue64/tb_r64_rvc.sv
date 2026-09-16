`timescale 1ns/1ps
module tb_r64_rvc;
reg [15:0] bits;
wire [31:0] native_word, reference_word;
wire illegal;
R64Rvc dut(bits,native_word,illegal);
OooRvcDecompressor reference_decoder(bits,reference_word);
integer n,legal=0;
initial begin
for(n=0;n<65536;n=n+1) begin
bits=n;#1;
if(native_word!==reference_word || illegal!==(reference_word==0))
$fatal(1,"RVC %h got %h expected %h",bits,native_word,reference_word);
if(!illegal) legal=legal+1;
end
$display("[PASS] tb_r64_rvc");
$display("COVERAGE exhaustive=65536 legal=%0d",legal);
$finish;
end
endmodule
