`timescale 1ns/1ps
module tb_r64_pagewalk;
reg clk=0;always #5 clk=~clk;
reg rst=1,qv=0,rr=0;
wire qr,rv,mv,mo,mrr;reg mr=1,mrv=0,merr=0,mok=0;
reg[63:0] va=64'h40001234;reg[43:0] root=1;
reg[1:0] access=1,priv=1;reg sum=0,mxr=0,ad=1,pbmt_enable=1;
wire[55:0] pa,ptea,ma;wire[7:0] flags;wire[1:0] pbmt,level;
wire napot,global_bit,needs_ad,fault;wire[4:0] cause;
wire[63:0] pte,expected,mask;reg[63:0] md=0;
R64PageWalk dut(clk,rst,qv,qr,va,root,access,priv,sum,mxr,ad,pbmt_enable,
rv,rr,pa,flags,pbmt,level,napot,global_bit,needs_ad,fault,cause,ptea,pte,
mv,mr,mo,ma,expected,mask,mrv,mrr,md,merr,mok);
reg[63:0] memory[0:2047];
integer delay=0,requests=0,cas=0,walks=0,n,timeout_count;
reg[63:0] pending_data;
reg pending_error,pending_ok;
reg race=0,update_error=0;
reg[55:0] error_address=56'hffffffffffffff;
reg[31:0] random_q=32'h208adc3e;
function[63:0] leaf(input[43:0] ppn,input[7:0] bits,input[1:0] type_bits,input nbit);
leaf={nbit,type_bits,7'b0,ppn,2'b0,bits};endfunction
function[31:0] rng(input[31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
always @(posedge clk) if(!rst) begin
 if(mrv&&mrr) mrv<=0;
 if(delay>0) begin
  delay=delay-1;
  if(delay==0) begin mrv<=1;md<=pending_data;merr<=pending_error;mok<=pending_ok;end
 end
 if(mv&&mr) begin
  if(delay!=0||mrv||ma>=16384||ma[2:0]!=0) $fatal(1,"memory service ownership");
  requests=requests+1;pending_data=memory[ma>>3];pending_error=ma==error_address;
  pending_ok=0;delay=2+random_q[2:1];
  if(mo) begin
   cas=cas+1;
   if(mask!==(access==2?64'hc0:64'h40)) $fatal(1,"incorrect atomic A/D mask");
   pending_error=pending_error||update_error;
   if(race) begin memory[ma>>3]=leaf(44'h90001,8'h0f,0,0);race=0;end
   else if(!pending_error&&memory[ma>>3]===expected) begin
    memory[ma>>3]=memory[ma>>3]|mask;pending_ok=1;
   end
  end
 end
end
always @(negedge clk) begin random_q=rng(random_q);mr=random_q[0]||random_q[1];end

task run(input expected_fault,input[4:0] expected_cause,input[55:0] expected_pa,input expected_ad);
reg[55:0] saved_pa;reg[4:0] saved_cause;reg saved_fault;
begin
@(negedge clk);qv=1;
@(posedge clk);while(!qr) @(posedge clk);
@(negedge clk);qv=0;timeout_count=0;
while(!rv) begin
@(negedge clk);timeout_count=timeout_count+1;
if(timeout_count>200) $fatal(1,"walker timeout");
end
if(fault!==expected_fault || (fault&&cause!==expected_cause) ||
   (!fault&&(pa!==expected_pa||needs_ad!==expected_ad)))
$fatal(1,"walk result fault=%d cause=%d pa=%h A/D=%d expected %d/%d/%h/%d",
 fault,cause,pa,needs_ad,expected_fault,expected_cause,expected_pa,expected_ad);
saved_pa=pa;saved_cause=cause;saved_fault=fault;
repeat(3) begin @(negedge clk);if(!rv||pa!==saved_pa||cause!==saved_cause||fault!==saved_fault)
$fatal(1,"walker response changed under backpressure");end
rr=1;@(negedge clk);rr=0;walks=walks+1;
end
endtask
task base_tables;
begin
memory[513]=leaf(2,8'h21,0,0);
memory[1024]=leaf(3,8'h01,0,0);
memory[1537]=leaf(44'h80001,8'hcf,0,0);
va=64'h40001234;access=1;priv=1;sum=0;mxr=0;ad=1;
end
endtask

integer before_requests,before_cas;
initial begin
for(n=0;n<2048;n=n+1)memory[n]=0;
repeat(3) @(negedge clk);rst=0;base_tables;
run(0,0,56'h80001234,0);
if(!global_bit||level!=0||ptea!=56'h3008) $fatal(1,"ancestor G or leaf provenance lost");
memory[1537]=leaf(44'h80001,8'h0f,2,0);ad=0;
before_cas=cas;run(0,0,56'h80001234,1);
pbmt_enable=0;run(1,13,0,0);pbmt_enable=1;
if(cas!=before_cas||memory[1537][7:6]!=0||pbmt!=2)
$fatal(1,"speculative probe mutated A/D or lost PBMT");
ad=1;run(0,0,56'h80001234,0);
if(memory[1537][7:6]!=1) $fatal(1,"read A update altered D");
access=2;run(0,0,56'h80001234,0);
if(memory[1537][7:6]!=3) $fatal(1,"store D update missing");
memory[1537]=leaf(44'h80001,8'h0f,0,0);race=1;before_requests=requests;before_cas=cas;
run(0,0,56'h90001234,0);
if(cas!=before_cas+2||requests!=before_requests+8) $fatal(1,"CAS race did not restart full walk");

base_tables;va=64'h0000010040001234;before_requests=requests;
run(1,13,0,0);if(requests!=before_requests)$fatal(1,"noncanonical address touched memory");
base_tables;memory[1537]=leaf(44'h80001,8'hd9,0,0);
run(1,13,0,0);mxr=1;priv=0;run(0,0,56'h80001234,0);
priv=1;sum=1;access=0;run(1,12,0,0);
access=1;run(0,0,56'h80001234,0);
access=2;run(1,15,0,0);

base_tables;memory[513]=leaf(44'hc0000,8'hcf,1,0);
run(0,0,56'hc0001234,0);if(level!=2||pbmt!=1)$fatal(1,"1G leaf attrs");
memory[513]=leaf(44'hc0001,8'hcf,0,0);run(1,13,0,0);
base_tables;memory[1024]=leaf(44'h88000,8'hcf,0,0);
run(0,0,56'h88001234,0);if(level!=1)$fatal(1,"2M leaf");
base_tables;memory[1537]=leaf(44'h89008,8'hcf,2,1);
run(0,0,56'h89001234,0);if(!napot||pbmt!=2)$fatal(1,"NAPOT leaf");
memory[1537]=leaf(44'h89009,8'hcf,2,1);run(1,13,0,0);
base_tables;memory[1537]=leaf(44'h80001,8'hcf,3,0);run(1,13,0,0);
base_tables;memory[1024]=leaf(3,8'h41,0,0);run(1,13,0,0);
base_tables;memory[1537]=leaf(44'h80001,8'hc5,0,0);run(1,13,0,0);
base_tables;error_address=56'h2000;access=0;run(1,1,0,0);
access=2;run(1,7,0,0);error_address=56'hffffffffffffff;
base_tables;memory[1537]=leaf(44'h80001,8'h0f,0,0);access=2;update_error=1;run(1,7,0,0);
if(memory[1537][7:6]!=0)$fatal(1,"failed atomic update changed PTE");
$display("[PASS] tb_r64_pagewalk");
$display("COVERAGE walks=%0d memory_ops=%0d CAS=%0d permission_A_D_Svnapot_PBMT_races=1",walks,requests,cas);
$finish;
end
endmodule
