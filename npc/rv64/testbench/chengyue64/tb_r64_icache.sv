`timescale 1ns/1ps
module tb_r64_icache;
reg clk=0;always #5 clk=~clk;
reg rst=1,invalidate=0,qv=0,qfault=0,rr=1,cmdready=1,uncached=0;
reg[63:0] qa=0;reg[4:0] qcause=0;
wire qr,rv,rf,cv,br;
wire[127:0] rd;wire[4:0] rc;wire[63:0] ca;wire[7:0] clen;wire[2:0] csize;
reg bv=0,bl=0;reg[63:0] bd=0;reg[1:0] bp=0;
R64ICache #(.SET_W(2)) dut(clk,rst,invalidate,qv,qr,qa,uncached,qfault,qcause,8'b0,130'b0,
rv,rr,rd,rf,rc,,cv,cmdready,ca,clen,csize,bv,br,bd,bp,bl);
reg busy=0;reg[63:0] memaddr=0;integer beat=0,gen=0,fillgen=0,last_beat=7;
integer fills=0,responses=0,errors=0,cycles=0;
integer error_beat=-1;
reg[63:0] expected_addr[0:4095];
integer expected_gen[0:4095];
reg expected_fault[0:4095];reg[4:0] expected_cause[0:4095];
integer head=0,tail=0,n,before_fills,wait_count;
reg[31:0] random_q=32'hfa1c320e;
reg random_stall=1,hold_request=0;reg[63:0] old_request;
function[63:0] value(input[63:0] addr,input integer generation);
value=addr^64'hd71c_fe94_0214_780e^{32'b0,generation[31:0]};endfunction
function[31:0] rng(input[31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction

always @(posedge clk) if(!rst) begin
 cycles=cycles+1;
 if(qv&&qr) begin
 expected_addr[tail]=qa;expected_gen[tail]=gen;
 expected_fault[tail]=qfault||error_beat>=0;
 expected_cause[tail]=qfault?qcause:1;
 tail=tail+1;
 end
 if(rv&&rr) begin
 if(head>=tail || rf!==expected_fault[head] ||
    (rf&&rc!==expected_cause[head]) ||
    (!rf&&rd!=={value(expected_addr[head]+8,expected_gen[head]),value(expected_addr[head],expected_gen[head])}))
 $fatal(1,"cache response head=%0d addr=%h data=%h fault=%d cause=%d",head,expected_addr[head],rd,rf,rc);
 responses=responses+1;head=head+1;if(rf)errors=errors+1;
 end
 if(cv&&cmdready) begin
 if(busy||(clen!=7&&clen!=1)||csize!=3||(clen==7?ca[5:0]!=0:ca[3:0]!=0)) $fatal(1,"refill command protocol");
 busy=1;memaddr=ca;beat=0;last_beat=clen;fillgen=gen;fills=fills+1;
 end
 if(bv&&br) begin
 if(beat==last_beat) busy=0;
 beat=beat+1;
 end
end
always @(negedge clk) begin
 random_q=rng(random_q);
 bv=busy&&(!random_stall||random_q[0]);
 bd=value(memaddr+beat*8,fillgen);bl=beat==last_beat;
 bp=beat==error_beat?2'b10:2'b0;
end

task request(input[63:0] address,input fault,input[4:0] cause);
integer done;
begin
 @(negedge clk);qa=address;qfault=fault;qcause=cause;qv=1;
 @(posedge clk);while(!qr) @(posedge clk);
 @(negedge clk);qv=0;
 done=tail;
 wait_count=0;
 while(head<done) begin
 @(negedge clk);wait_count=wait_count+1;
 rr=random_stall?(random_q[2]||random_q[3]):1;
 if(wait_count>200) $fatal(1,"cache request timeout");
 end
 rr=1;
end
endtask

initial begin
repeat(3) @(negedge clk);rst=0;
for(n=0;n<32;n=n+1) request(64'h80000000+n*16,0,0);
if(fills!=8) $fatal(1,"warmup expected eight lines, got %d",fills);
before_fills=fills;random_stall=0;
// After warmup, all 32 sectors fit exactly. No input/output wait is permitted.
@(negedge clk);qv=1;qfault=0;
for(n=0;n<160;n=n+1) begin
qa=64'h80000000+(n%32)*16;
@(posedge clk);
if(!qr) $fatal(1,"hot hit input bubble");
@(negedge clk);
end
qv=0;
while(head<tail) @(negedge clk);
if(fills!=before_fills) $fatal(1,"spurious hot refill");
// Translation faults are terminal without an AXI read.
request(64'h00004000,1,12);
if(fills!=before_fills) $fatal(1,"translation fault issued bus traffic");

// Failed replacement overwrites data RAM but must never retain the old tag.
// Addresses 0x000, 0x100, and 0x200 map to the same two-way set.
error_beat=3;
request(64'h80000200,0,0);error_beat=-1;
before_fills=fills;
request(64'h80000000,0,0);
if(fills!=before_fills+1) $fatal(1,"failed fill retained corrupt victim tag");

// Invalidate during a live refill: still drain and deliver that transaction,
// then require a new fill on the next access to its line.
@(negedge clk);qv=1;qa=64'h80000400;
@(posedge clk);while(!qr) @(posedge clk);
@(negedge clk);qv=0;
while(!busy||beat<3) @(negedge clk);
invalidate=1;
@(negedge clk);invalidate=0;
while(head<tail) @(negedge clk);
before_fills=fills;gen=1;
request(64'h80000400,0,0);
if(fills!=before_fills+1) $fatal(1,"invalidated refill resurrected line");
request(64'h80000410,0,0);
if(fills!=before_fills+1) $fatal(1,"filled neighbor sector missed");
// Noncacheable fetches must bypass a preexisting hit, never fill or corrupt it.
before_fills=fills;uncached=1;gen=2;
request(64'h80000410,0,0);
request(64'h80000410,0,0);
if(fills!=before_fills+2)$fatal(1,"uncached fetch hit or allocated");
uncached=0;gen=1;
request(64'h80000410,0,0);
if(fills!=before_fills+2)$fatal(1,"uncached fetch destroyed resident line");
if(errors!=2||responses!=201) $fatal(1,"coverage responses=%d errors=%d",responses,errors);
$display("[PASS] tb_r64_icache");
$display("COVERAGE responses=%0d fills=%0d faults=%0d hot_II1_cycles=160 invalidate_during_fill=1",responses,fills,errors);
$finish;
end
endmodule
