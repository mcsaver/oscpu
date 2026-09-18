module tb_r64_trap_vector;
 reg [63:0] vector=0,random_q=64'h4d595df4d0f33173,expected;
 reg interrupt=0;reg [5:0] cause=0;wire [63:0] target;
 integer i,b,c,checks=0;
 R64TrapVector dut(.vector_i(vector),.interrupt_i(interrupt),.cause_i(cause),.target_o(target));
 task check;
  begin
   #1;expected={vector[63:2],2'b0}+((interrupt&&vector[0]) ? {56'b0,cause,2'b0}:64'b0);
   if(target!==expected)$fatal(1,"trap vector base=%h cause=%d irq=%b got=%h expected=%h",vector,cause,interrupt,target,expected);
   checks=checks+1;
  end
 endtask
 initial begin
  for(b=1;b<=8;b=b+1)begin
   for(c=0;c<64;c=c+1)begin
    vector=(b==8 ? 64'hfffffffffffffffc:((64'd1<<(b*8))-4))|1;
    interrupt=1;cause=c[5:0];check();
    interrupt=0;check();
   end
  end
  for(i=0;i<50000;i=i+1)begin
   random_q=random_q^(random_q<<13);
   random_q=random_q^(random_q>>7);
   random_q=random_q^(random_q<<17);
   vector=random_q;interrupt=random_q[23];cause=random_q[12:7];check();
  end
  $display("[PASS] tb_r64_trap_vector checks=%0d",checks);$finish;
 end
endmodule
