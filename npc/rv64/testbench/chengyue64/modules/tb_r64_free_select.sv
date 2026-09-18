module tb_r64_free_select;
 reg [63:0] mask;
 wire [63:0] f64,s64;wire a64,t64;
 wire [19:0] f20,s20;wire a20,t20;
 wire [7:0] f8,s8;wire a8,t8;
 R64FreeSelect #(.N(64)) wide(mask,f64,s64,a64,t64);
 R64FreeSelect #(.N(20)) partial(mask[19:0],f20,s20,a20,t20);
 R64FreeSelect #(.N(8)) narrow(mask[7:0],f8,s8,a8,t8);
 task check;
  input integer width;
  input [63:0] actual_first,actual_second;
  input actual_any,actual_two;
  reg [63:0] first,second;
  integer k,count;
  begin
   first=0;second=0;count=0;
   for(k=0;k<width;k=k+1)if(mask[k])begin
    if(count==0)first[k]=1;
    if(count==1)second[k]=1;
    count=count+1;
   end
   if(actual_first!==first||actual_second!==second||actual_any!==(count!=0)||actual_two!==(count>=2))
    $fatal(1,"free select width=%0d mask=%h first=%h/%h second=%h/%h",width,mask,actual_first,first,actual_second,second);
  end
 endtask
 task sample;
  begin
   #1;
   check(64,f64,s64,a64,t64);
   check(20,{44'b0,f20},{44'b0,s20},a20,t20);
   check(8,{56'b0,f8},{56'b0,s8},a8,t8);
  end
 endtask
 integer i,j;reg [63:0] random_q=64'h7348be6123abcdef;
 initial begin
  mask=0;sample();mask=~64'b0;sample();
  for(i=0;i<256;i=i+1)begin mask={56'b0,i[7:0]};sample();end
  for(i=0;i<64;i=i+1)for(j=0;j<64;j=j+1)begin mask=(64'b1<<i)|(64'b1<<j);sample();end
  for(i=0;i<10000;i=i+1)begin
   random_q=random_q^(random_q<<13);random_q=random_q^(random_q>>7);random_q=random_q^(random_q<<17);
   mask=random_q;sample();
  end
  $display("[PASS] tb_r64_free_select exhaustive8=256 pairs64=4096 random=10000 widths=8,20,64");$finish;
 end
endmodule
