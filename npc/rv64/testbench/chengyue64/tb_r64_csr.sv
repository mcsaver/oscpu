`timescale 1ns/1ps
module tb_r64_csr;
reg clk=0;always #5 clk=~clk;
reg rst=1,commit=0,fpdirty=0,trap=0,interrupt=0,query=0,trap_prepare=0,return_prepare=0,return_supervisor=0;wire query_valid;
reg [63:0] time_value=64'hb6251729,operand=0,tpc=64'h80001234,tvalue=0;
reg [1:0] retired=0,ret=0;
reg [11:0] address=12'h300;
reg [2:0] op=2;
reg [4:0] rs=0,fflags=0;
reg [5:0] tcause=0;
reg sw=0,timer=0,ext=0,sext=0;
reg [3:0] oracle_irq_q=0;
always @(posedge clk)begin
 if(rst)oracle_irq_q<=0;
 else oracle_irq_q<={ext,sext,timer,sw};
end
wire [63:0] value,target,rtarget,status,satp;
wire illegal,pending,pbmt;
wire [5:0] cause;wire [1:0] priv;wire [2:0] frm;
wire [127:0] cfg;wire [863:0] pa;
wire [63:0] write_value;reg snapshot_enable=0;reg [63:0] snapshot=0;
wire [63:0] commit_value=snapshot_enable?snapshot:write_value;
wire [63:0] selected;
R64CsrDecode decode_csr(address,selected);
R64Csr dut(clk,rst,1'b1,time_value,retired,address,op,rs,operand,commit,value,illegal,
 fpdirty,fflags,trap,interrupt,tcause,tpc,tvalue,ret,rtarget,sw,timer,ext,sext,,pending,cause,
 target,priv,status,satp,frm,pbmt,cfg,pa,write_value,commit_value,return_supervisor,selected,,,query,query_valid,trap_prepare,return_prepare);
wire [63:0] refvalue,reftarget,refrtarget,refstatus,refsatp,refwrite;
wire refillegal,refpending,refpbmt;
wire [5:0] refcause;wire [1:0] refpriv;wire [2:0] reffrm;
wire [127:0] refcfg;wire [863:0] refpa;
reg [63:0] captured_read,captured_write;reg captured_illegal;
R64CsrBaseline reference(clk,rst,1'b1,time_value,retired,address,op,rs,operand,commit,refvalue,refillegal,
 fpdirty,fflags,trap,interrupt,tcause,tpc,tvalue,ret,refrtarget,oracle_irq_q[0],oracle_irq_q[1],oracle_irq_q[3],oracle_irq_q[2],,refpending,refcause,
 reftarget,refpriv,refstatus,refsatp,reffrm,refpbmt,refcfg,refpa,refwrite,commit_value,return_supervisor,selected,,);
integer n,j,k,checks=0;
reg oracle_enabled=1;
reg [31:0] random_q=32'h5e76da01;
reg [11:0] regs[0:31];
reg [63:0] saved;
function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
task compare;
begin
 @(negedge clk);query=1;
 @(posedge clk);captured_read=refvalue;captured_write=refwrite;captured_illegal=refillegal;
 @(negedge clk);query=0;
 @(negedge clk);#1;checks=checks+1;
 if(!query_valid)$fatal(1,"CSR query did not produce exact two-stage response");
 if(value!==captured_read||write_value!==captured_write||illegal!==captured_illegal)
  $fatal(1,"CSR query snapshot mismatch address=%h actual=%h/%h/%b expected=%h/%h/%b",
   address,value,write_value,illegal,captured_read,captured_write,captured_illegal);
 if(oracle_enabled)begin
  if(address==12'h7a0||address==12'h7a1||address==12'h7a2||address==12'h7a4)begin
   // The old CSR oracle predates Sdtrig. Its reset CSR values are checked
   // against the extension's defined register interface here instead.
   if(illegal||value!==(address==12'h7a1 ? 64'hf000000000000000:
       (address==12'h7a4 ? 64'h1008044:64'b0)))$fatal(1,"Sdtrig reset CSR %h",address);
  end else if(illegal!==captured_illegal||(!illegal&&value!==captured_read))
   $fatal(1,"CSR oracle addr=%h op=%h rs=%d priv=%d got=%h/%d ref=%h/%d",
     address,op,rs,priv,value,illegal,captured_read,captured_illegal);
  if(priv!==refpriv||satp!==refsatp||cfg!==refcfg||frm!==reffrm||pbmt!==refpbmt||
     (status&64'h7fffffffffffffff)!==(refstatus&64'h7fffffffffffffff)||
     pending!==refpending||(pending&&cause!==refcause)||(trap&&target!==reftarget))
   $fatal(1,"CSR state/IRQ/delegation divergence priv=%d status=%h ref=%h pending=%d/%d cause=%d/%d",
     priv,status,refstatus,pending,refpending,cause,refcause);
  for(j=0;j<16;j=j+1)if(pa[j*54+:54]!==refpa[j*54+:54])$fatal(1,"PMP CSR state mismatch");
 end
end endtask
task write_csr(input [11:0] a,input [63:0] data);
begin
 @(negedge clk);address=a;operand=data;op=1;rs=1;compare;
 if(illegal)$fatal(1,"unexpected CSR write illegal %h",address);
 commit=1;@(negedge clk);commit=0;op=2;rs=0;compare;
end endtask
task read_csr(input [11:0] a,input [63:0] data);
begin
 @(negedge clk);address=a;op=2;rs=0;compare;
 if(illegal||value!==data)$fatal(1,"CSR read addr=%h value=%h expected=%h illegal=%d",a,value,data,illegal);
end endtask
task enter_trap(input irq,input [5:0] code,input [63:0] epc,input [63:0] val);
begin
 @(negedge clk);interrupt=irq;tcause=code;tpc=epc;tvalue=val;trap_prepare=1;
 @(negedge clk);trap_prepare=0;
 if(target!==reftarget)$fatal(1,"prepared trap target mismatch");
 trap=1;@(negedge clk);trap=0;compare;
end endtask
task do_return(input [1:0] kind);
begin
 @(negedge clk);return_supervisor=kind==2;return_prepare=1;
 @(negedge clk);return_prepare=0;
 if(rtarget!==refrtarget)$fatal(1,"xRET admission target snapshot");
 ret=kind;@(negedge clk);ret=0;compare;
end
endtask
initial begin
 regs[0]=12'h300;regs[1]=12'h100;regs[2]=12'h301;regs[3]=12'h302;
 regs[4]=12'h303;regs[5]=12'h304;regs[6]=12'h104;regs[7]=12'h305;
 regs[8]=12'h105;regs[9]=12'h306;regs[10]=12'h106;regs[11]=12'h320;
 regs[12]=12'h30a;regs[13]=12'h340;regs[14]=12'h140;regs[15]=12'h341;
 regs[16]=12'h141;regs[17]=12'h342;regs[18]=12'h142;regs[19]=12'h343;
 regs[20]=12'h143;regs[21]=12'h344;regs[22]=12'h144;regs[23]=12'h3a0;
 regs[24]=12'h3a2;regs[25]=12'h3b0;regs[26]=12'h3bf;regs[27]=12'hb00;
 regs[28]=12'hb02;regs[29]=12'h001;regs[30]=12'h002;regs[31]=12'h003;
 repeat(3)@(negedge clk);rst=0;
 for(n=0;n<4096;n=n+1)begin address=n;op=2;rs=0;compare;end
 write_csr(12'h300,64'hffffffffffffffff);
 read_csr(12'h100,64'h80000002000c6722);
 for(n=0;n<1500;n=n+1)begin
  @(negedge clk);random_q=rng(random_q);address=regs[random_q[4:0]];
  operand={random_q,rng(random_q)};rs=random_q[9:5];op={random_q[10],2'(1+random_q[12:11]%3)};
  retired=random_q[14:13]%3;compare;
  commit=!illegal;
  @(negedge clk);commit=0;compare;
 end
 // Canonical privilege routes remain checked against the original CSR model.
 retired=0;write_csr(12'h300,64'h00006000);write_csr(12'h303,0);write_csr(12'h304,0);
 write_csr(12'h344,0);write_csr(12'h302,64'hffff);write_csr(12'h305,64'h80002001);
 write_csr(12'h105,64'h80003001);write_csr(12'h341,64'h80004003);
 write_csr(12'h300,64'h00006880);do_return(1);
 if(priv!=1)$fatal(1,"MRET did not restore S");
 enter_trap(0,13,64'h40001235,64'h4000ffff);
 if(priv!=1)$fatal(1,"S exception delegation");
 read_csr(12'h141,64'h40001234);read_csr(12'h142,13);read_csr(12'h143,64'h4000ffff);
 do_return(2);if(priv!=1)$fatal(1,"SRET lost SPP");
 enter_trap(0,11,64'h40002222,0);if(priv!=3)$fatal(1,"nondelegated cause failed M trap");
 // The native design fixes the old OR-ed PLIC context and CLINT alias model.
 oracle_enabled=0;
 write_csr(12'h303,64'h222);write_csr(12'h304,64'haaa);write_csr(12'h300,64'h6088);
 @(negedge clk);sw=1;timer=1;ext=1;sext=1;compare;if(!pending||cause!=11)$fatal(1,"machine IRQ priority");
 @(negedge clk);sw=0;timer=0;ext=0;
 read_csr(12'h344,64'h200);
 write_csr(12'h300,64'h6800);do_return(1); // S with SIE=0; delegated sources masked.
 compare;if(pending)$fatal(1,"delegated IRQ bypassed SIE");
 write_csr(12'h100,64'h6002);compare;if(!pending||cause!=9)$fatal(1,"supervisor IRQ priority");
 enter_trap(1,9,64'h40003333,0);read_csr(12'h142,64'h8000000000000009);
 @(negedge clk);sw=0;timer=0;ext=0;sext=0;
 enter_trap(0,11,64'h40004444,0);
 // These native semantics fix specification violations in the old oracle:
 // unsupported SATP writes have no effect; pending hardware isn't a RMW bit.
 oracle_enabled=0;
 write_csr(12'h180,64'h8000100000012345);saved=satp;
 write_csr(12'h180,64'hf000000000000000);
 if(satp!==saved)$fatal(1,"unsupported SATP MODE modified state");
 write_csr(12'h344,0);write_csr(12'h303,64'h222);
 @(negedge clk);ext=1;address=12'h344;op=2;rs=1;operand=2;compare;commit=1;
 @(negedge clk);commit=0;ext=0;read_csr(12'h344,2);
 write_csr(12'h300,64'h00026900);do_return(2);
 if(status[17]||priv!=1)$fatal(1,"SRET failed to clear MPRV");
 // A CSR RMW returns and later writes one atomic snapshot of a live counter.
 enter_trap(0,11,64'h40005555,0);
 write_csr(12'h320,0);
 @(negedge clk);address=12'hb00;op=2;rs=1;operand=64'h100;compare;
 snapshot=write_value;snapshot_enable=1;
 repeat(5)@(negedge clk);
 commit=1;@(negedge clk);commit=0;op=2;rs=0;#1;
 if(dut.cycle_q!==snapshot)$fatal(1,"counter RMW did not commit captured value");
 snapshot_enable=0;
 // One enumerated native trigger; unused trigger registers stay illegal.
 read_csr(12'h7a0,0);
 write_csr(12'h7a0,1);read_csr(12'h7a0,0);
 read_csr(12'h7a4,64'h1008044);
 write_csr(12'h7a4,0);read_csr(12'h7a4,64'h1008044);
 write_csr(12'h7a2,64'hffffffffff001000);
 write_csr(12'h7a1,64'h600000000000005f);
 read_csr(12'h7a1,64'h600000000000005f);
 read_csr(12'h7a2,64'hffffffffff001000);
 // WARL capability bounds: unsupported modes never become armed features.
 write_csr(12'h7a1,64'h6fffffffffffffff);
 read_csr(12'h7a1,64'h600000000000005f);
 write_csr(12'h7a1,64'h2fffffffffffffff);
 read_csr(12'h7a1,64'h200000000000005f);
 write_csr(12'h7a1,64'h7fffffffffffffff);
 read_csr(12'h7a1,64'hf000000000000000);
 write_csr(12'h7a0,64'hffffffffffffffff);read_csr(12'h7a0,0);
 write_csr(12'h7a1,0);read_csr(12'h7a1,64'hf000000000000000);
 read_csr(12'h7a2,64'hffffffffff001000);
 @(negedge clk);address=12'h7a3;op=2;rs=0;compare;
 if(!illegal)$fatal(1,"unused tdata3 CSR became legal");
 // Every query fragment and RMW source must retain the single acceptance edge.
 @(negedge clk);address=12'hc01;op=2;rs=0;operand=0;time_value=64'hfedc987612345678;query=1;
 @(posedge clk);captured_read=refvalue;captured_write=refwrite;
 @(negedge clk);query=0;time_value=64'h0123456789abcdef;address=12'h340;op=1;rs=31;operand=64'hffffffffffffffff;
 @(negedge clk);#1;
 if(!query_valid||value!==captured_read||write_value!==captured_write)
  $fatal(1,"query assembled values or RMW metadata from different cycles");
 $display("[R64-CSR-QUERY] two-stage single-edge snapshot survives subsequent time/address/operation/source changes PASS");
 $display("[PASS] tb_r64_csr");
 $display("COVERAGE oracle_comparisons=%0d CSR4096_random1500_privilege_IRQ_PMP=1 SATP_WARL_pending_RMW_SRET_MPRV=1",checks);
 $finish;
end
endmodule
