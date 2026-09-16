`timescale 1ns/1ps
module tb_r64_protection;
reg [127:0] cfg=0;reg [863:0] addresses=0;
wire [15:0] active;wire [895:0] lower,upper;wire [63:0] permission;
reg [63:0] address=64'h80000000;reg [4:0] size=8;reg [1:0] priv=3;
reg [2:0] access=1;
wire fault,pma_fault,nc;wire [1:0] memory_class;wire [7:0] mask;
R64PmpDecode dec(cfg,addresses,active,lower,upper,permission);
R64PmpCheck u_check(address,size,priv,access,active,lower,upper,permission,fault);
R64Pma pma(address,size,pma_fault,memory_class);
R64FetchProtection fetch(address,priv,active,lower,upper,permission,mask,nc);
integer n,k,j,queries=0,regions;
reg [31:0] random_q=32'h8c6e0913;
function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
function reference_fault;
integer i,b,ones;
reg found,bad,partial,enforce;
reg [7:0] c;reg [53:0] a;
reg [63:0] lo,hi,endaddr,span;
reg [64:0] endext;
begin
 endext={1'b0,address}+size-1;endaddr=endext[63:0];
 found=0;bad=priv!=3;
 for(i=0;i<16;i=i+1)begin
  c=cfg[i*8+:8];a=addresses[i*54+:54];lo=0;hi=0;
  case(c[4:3])
   1:begin lo=i==0?0:({10'b0,addresses[(i-1)*54+:54]}<<2);hi=({10'b0,a}<<2)-1;end
   2:begin lo={10'b0,a}<<2;hi=lo+3;end
   3:begin
    ones=0;for(b=0;b<54;b=b+1)if(a[b]&&ones==b)ones=ones+1;
    span=0;for(b=0;b<56;b=b+1)if(b<ones+3)span[b]=1;
    lo=({10'b0,a}<<2)&~span;hi=lo|span;
   end
   default:begin end
  endcase
  if(!found&&c[4:3]!=0&&(c[4:3]!=1||({10'b0,a}<<2)>lo)&&
      address<=hi&&endaddr>=lo)begin
   found=1;partial=address<lo||endaddr>hi;enforce=priv!=3||c[7];
   bad=partial||(enforce&&((access&~c[2:0])!=0));
  end
 end
 reference_fault=access!=0&&(size==0||endext[64]||bad);
end endfunction
task check;
begin #1;if(fault!==reference_fault())$fatal(1,"PMP mismatch pa=%h size=%d priv=%d access=%b got=%d exp=%d cfg=%h",
 address,size,priv,access,fault,reference_fault(),cfg);queries=queries+1;end
endtask
task expect_pma(input [63:0] a,input [4:0] s,input [1:0] c);
begin address=a;size=s;#1;if(memory_class!==c||pma_fault!==(c==3))$fatal(1,"PMA pa=%h size=%d class=%d expected=%d",a,s,memory_class,c);end
endtask
initial begin
 check;priv=1;check;
 cfg[7:0]=8'h1f;addresses[53:0]=54'h3fffffffffffff;
 check;if(fault)$fatal(1,"whole PA NAPOT failed");
 // A lowest matching NA4 entry overlaps only half of a load. Unlocked M
 // ignores permission bits but must still fail this partial match.
 cfg=0;addresses=0;cfg[7:0]=8'h10;addresses[53:0]=54'h20000001;
 address=64'h80000000;size=8;priv=3;check;
 if(!fault)$fatal(1,"M mode ignored partial matching PMP");
 size=4;address=64'h80000004;check;if(fault)$fatal(1,"M unlocked full match denied");
 priv=1;check;if(!fault)$fatal(1,"S permission bypass");
 cfg[7:0]=8'h91;priv=3;check;if(fault)$fatal(1,"locked read denied");
 access=2;check;if(!fault)$fatal(1,"locked M store permitted");
 // A protected word within the fetch sector only faults its own halfwords.
 cfg=0;addresses=0;cfg[7:0]=8'h90;addresses[53:0]=54'h20000001;
 address=64'h80000000;size=16;priv=3;#1;
 if(mask!=8'h0c)$fatal(1,"PMP sector fault mask %h",mask);
 cfg=0;addresses=0;cfg[7:0]=8'h9c;addresses[53:0]=54'h20000001;
 #1;if(mask!=0)$fatal(1,"execute-only region rejected fetch");
 // Random range/priority/permission checks use a loop-based independent
 // NAPOT decoder, not the DUT's x^(x+1) transformation.
 for(n=0;n<30000;n=n+1)begin
  random_q=rng(random_q);address=64'h80000000+random_q[14:0];
  size=1<<random_q[17:15]%5;priv=random_q[19:18];access=random_q[22:20];
  for(k=0;k<16;k=k+1)begin
   random_q=rng(random_q);cfg[k*8+:8]={random_q[0],2'b0,random_q[2:1],random_q[5:3]};
   addresses[k*54+:54]=54'h20000000+random_q[17:6];
  end
  if(n%19==0)begin address=64'hfffffffffffffffc;size=8;end
  check;
 end
 expect_pma(64'h80000000,16,0);expect_pma(64'h8ffffff8,8,0);
 expect_pma(64'h8ffffff8,16,3);expect_pma(64'h90000000,8,1);
 expect_pma(64'h9ffffff8,16,3);expect_pma(64'ha0000000,16,1);
 expect_pma(64'h02000000,8,3);expect_pma(64'h02000000,4,2);
 expect_pma(64'h0200bff8,8,2);expect_pma(64'h0200bffc,4,2);expect_pma(64'h02000004,4,3);
 expect_pma(64'h0c000002,4,3);expect_pma(64'h10003000,4,2);expect_pma(64'h10003000,8,3);expect_pma(64'h0f000000,4,2);
 expect_pma(64'h10000000,1,2);expect_pma(64'h10001000,4,2);
 expect_pma(64'h00100000,4,2);expect_pma(64'h12000000,8,2);
 expect_pma(64'h10002000,4,3);expect_pma(64'h20000000,4,3);
 expect_pma(64'hffffffffffffffff,2,3);
 $display("[PASS] tb_r64_protection");
 $display("COVERAGE PMP_queries=%0d TOR_NA4_NAPOT_priority_lock_partial=1 PMA_boundaries=15 fetch_partial_mask=1",queries);
 $finish;
end
endmodule
