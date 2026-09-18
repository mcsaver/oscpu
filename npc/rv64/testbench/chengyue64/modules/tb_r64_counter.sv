module tb_r64_counter;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,en=0,wr=0;reg [1:0] inc=0;
 reg [63:0] data=0,expected=0;wire [63:0] value;
 reg [63:0] random_q=64'h94d049bb133111eb;
 integer i,b,checks=0;
 R64Counter dut(.clk_i(clk),.rst_i(rst),.enable_i(en),.increment_i(inc),
  .write_i(wr),.write_value_i(data),.value_o(value));
 task step;
  begin
   @(posedge clk);
   if(rst)expected=0;
   else if(wr)expected=data;
   else if(en)expected=expected+{62'b0,inc};
   #1;if(value!==expected)$fatal(1,"counter mismatch value=%h expected=%h",value,expected);
   checks=checks+1;
   @(negedge clk);
  end
 endtask
 initial begin
  step();rst=0;
  // Cross every byte boundary for all retirement widths, including full wrap.
  for(b=1;b<=8;b=b+1)begin
   data=b==8 ? 64'hfffffffffffffff0:((64'd1<<(b*8))-16);
   wr=1;en=1;inc=3;step();wr=0;
   for(i=0;i<48;i=i+1)begin inc=i%4;step();end
  end
  // Mixed writes, inhibit, zero-to-three retirements and reset pulses.
  for(i=0;i<50000;i=i+1)begin
   random_q=random_q^(random_q<<13);
   random_q=random_q^(random_q>>7);
   random_q=random_q^(random_q<<17);
   en=random_q[0];inc=random_q[2:1];wr=random_q[8:3]==0;rst=i%997==996;
   data=random_q;
   if(wr&&random_q[9]) data=64'hfffffffffffffffa+{61'b0,random_q[12:10]};
   step();
  end
  $display("[PASS] tb_r64_counter checks=%0d",checks);$finish;
 end
endmodule
