`timescale 1ns/1ps
module tb_r64_tlb;
reg clk=0;always #5 clk=~clk;
reg rst=1,fill=0,global_bit=0,napot=0,inv=0,all_va=0,all_asid=0;
reg[63:0] va=0;
reg[26:0] fvpn=0,ivpn=0;
reg[43:0] ppn=0;
reg[15:0] asid=0,fasid=0,iasid=0;
reg[1:0] level=0,pbmt=0;
reg[7:0] flags=8'hdf;
wire hit;wire[55:0] pa;wire[7:0] oflags;wire[1:0] opbmt;
R64Tlb dut(clk,rst,va,asid,hit,pa,oflags,opbmt,fill,fvpn,ppn,fasid,
 global_bit,level,napot,flags,pbmt,inv,all_va,all_asid,ivpn,iasid);
integer i,j,checks=0;
task put(input[63:0] address,input[43:0] physical,input[15:0] id,
         input g,input[1:0] lev,input nap,input[1:0] memtype);
begin
@(negedge clk);fill=1;fvpn=address[38:12];ppn=physical;fasid=id;global_bit=g;level=lev;napot=nap;pbmt=memtype;
@(negedge clk);fill=0;
end
endtask
task get(input[63:0] address,input[15:0] id,input expected_hit,input[55:0] physical,input[1:0] memtype);
begin
va=address;asid=id;#1;checks=checks+1;
if(hit!==expected_hit||(hit&&(pa!==physical||opbmt!==memtype||oflags!==8'hdf)))
$fatal(1,"TLB VA=%h ASID=%d hit=%d PA=%h expected %d/%h",address,id,hit,pa,expected_hit,physical);
end
endtask
task fence(input all_address,input all_id,input[63:0] address,input[15:0] id);
begin
@(negedge clk);inv=1;all_va=all_address;all_asid=all_id;ivpn=address[38:12];iasid=id;
@(negedge clk);inv=0;
end
endtask
initial begin
repeat(3) @(negedge clk);rst=0;
get(64'h10000,1,0,0,0);
put(64'h10000,44'h80010,1,0,0,0,0);
put(64'h10000,44'h81010,2,0,0,0,1);
for(i=0;i<4096;i=i+31) begin
get(64'h10000+i,1,1,56'h80010000+i,0);
get(64'h10000+i,2,1,56'h81010000+i,1);
end
get(64'h10000,3,0,0,0);
put(64'h20000,44'h82008,3,0,0,1,2);
for(i=0;i<65536;i=i+997) get(64'h20000+i,3,1,56'h82000000+i,2);
put(64'h400000,44'h84000,4,0,1,0,0);
for(i=0;i<2097152;i=i+16537) get(64'h400000+i,4,1,56'h84000000+i,0);
put(64'h80000000,44'hc0000,5,1,2,0,1);
for(i=0;i<128;i=i+1) get(64'h80000000+i*1234567,100,1,56'hc0000000+i*1234567,1);
// A lookup with noncanonical upper bits cannot hit an otherwise equal VPN.
get(64'h0000010000010000,1,0,0,0);
// ASID-specific fences preserve a global mapping, and distinguish equal VPNs.
fence(1,0,0,1);
get(64'h10000,1,0,0,0);get(64'h10000,2,1,56'h81010000,1);
fence(1,0,0,5);
get(64'h80012345,5,1,56'hc0012345,1);
// A byte in a leaf invalidates that leaf, including all NAPOT constituent pages.
fence(0,0,64'h2a123,3);
get(64'h20000,3,0,0,0);get(64'h2f000,3,0,0,0);
fence(0,1,64'h81234567,0);get(64'h80000000,5,0,0,0);
// Replacing a superpage with a base page removes overlap in the same context.
put(64'h401000,44'h85001,4,0,0,0,2);
get(64'h401abc,4,1,56'h85001abc,2);get(64'h402000,4,0,0,0);
// A new global mapping displaces both ASID-specific copies at this VPN.
put(64'h10000,44'h86010,0,1,0,0,0);
get(64'h10123,1,1,56'h86010123,0);get(64'h10123,2,1,56'h86010123,0);
fence(1,1,0,0);
// Fill more than capacity: every latest fill must be visible, stale entries
// may miss but can never alias a different VPN or ASID.
for(i=0;i<80;i=i+1) begin
put(64'h1000000+i*4096,44'h90000+i,7,0,0,0,0);
get(64'h1000000+i*4096+16,7,1,56'h90000000+i*4096+16,0);
get(64'h1000000+i*4096+16,8,0,0,0);
end
// Same-edge invalidation suppresses the fill.
@(negedge clk);fill=1;fvpn=27'h12345;ppn=44'habcd;inv=1;all_va=1;all_asid=1;
@(negedge clk);fill=0;inv=0;
get(64'h12345000,7,0,0,0);
$display("[PASS] tb_r64_tlb");$display("COVERAGE queries=%0d page_sizes=4 asid_global_sfence=1 overlap_replacement=1",checks);
$finish;
end
endmodule
