`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_alu_lane;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,branch_op=0,ready=1;
 reg [31:0] km=0;reg [8:0] tag=0;reg [5:0] preg_dst=1;
 reg [`R64_UOP_W-1:0] uop=0;reg [191:0] operands=0;
 wire credit,valid,early,bypass,resolve,redirect,conditional,indirect,taken;
 wire [8:0] result_tag,early_tag,resolve_tag;
 wire [5:0] early_preg,bypass_preg;
 wire [63:0] bypass_data,npc,rpc;
 wire [`R64_RESULT_W-1:0] result;
 wire [36:0] control;
 wire [4:0] addsource=branch_op ? {3'b100,!branchcontrol[1],branchcontrol[1]}:
     {1'b0,uop[207],!uop[207],uop[205],!uop[205]&&!uop[206]};reg [20:0] branchimm=0;reg [4:0] branchcontrol=0;
 R64AluControl decode(.function_i(uop[`R64_U_FUNC]),.control_o(control));
 R64AluLane dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
  .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_uop_i(uop),.in_branch_i(branch_op),
  .in_control_i(control),.in_add_source_i(addsource),.in_shift_amount_i(ref_b[5:0]),.in_branch_imm_i(branchimm),.in_branch_control_i(branchcontrol),.in_operand_i(operands),.in_preg_i(preg_dst),
  .early_valid_o(early),.early_preg_o(early_preg),.early_tag_o(early_tag),
  .bypass_valid_o(bypass),.bypass_preg_o(bypass_preg),.bypass_data_o(bypass_data),
  .out_valid_o(valid),.out_ready_i(ready),.out_tag_o(result_tag),.out_result_o(result),
  .recovery_preview_valid_o(),.recovery_preview_tag_o(),.resolve_valid_o(resolve),.redirect_o(redirect),.resolve_tag_o(resolve_tag),.resolve_npc_o(npc),
  .resolve_pc_o(rpc),.conditional_o(conditional),.indirect_o(indirect),.taken_o(taken));
 wire [63:0] ref_a=uop[`R64_U_OP1_PC] ? uop[`R64_U_PC]:
      uop[`R64_U_OP1_ZERO] ? 64'b0:operands[63:0];
 wire [63:0] ref_b=uop[`R64_U_OP2_ARG] ? uop[`R64_U_ARG]:operands[127:64];
 wire [63:0] reference_result;
 R64Alu golden(.a_i(ref_a),.b_i(ref_b),.function_i(uop[`R64_U_FUNC]),
  .word_i(uop[`R64_U_WORD]),.result_o(reference_result));
 reg pending[0:511],branch_pending[0:511];
 reg [`R64_RESULT_W-1:0] expected[0:511];
 reg [63:0] expected_pc[0:511],expected_npc[0:511];
 reg [2:0] expected_flags[0:511];
 reg expected_redirect[0:511];
 reg [63:0] branch_target=0;reg [2:0] branch_flags=0;
 integer accepted=0,completed=0,canceled=0,resolved=0,woken=0,i;
 reg hold_valid=0;reg [8:0] hold_tag;reg [`R64_RESULT_W-1:0] hold_result;
 reg check_future;reg [8:0] future_tag;
 always @(posedge clk)begin
  if(rst)begin
   for(i=0;i<512;i=i+1)begin pending[i]=0;branch_pending[i]=0;end
   accepted=0;completed=0;canceled=0;resolved=0;woken=0;hold_valid=0;check_future=0;
  end else begin
   for(i=0;i<512;i=i+1)if(pending[i]&&(flush||km[i%32]))begin
    pending[i]=0;branch_pending[i]=0;canceled=canceled+1;
   end
   if(!flush)begin
    if(hold_valid&&!km[hold_tag[4:0]]&&(!valid||result_tag!==hold_tag||result!==hold_result))
      $fatal(1,"ALU held terminal changed under backpressure");
    if(resolve)begin
     if(!branch_pending[resolve_tag]||rpc!==expected_pc[resolve_tag]||
         npc!==expected_npc[resolve_tag]||{conditional,indirect,taken}!==expected_flags[resolve_tag]||
         redirect!==expected_redirect[resolve_tag])
      $fatal(1,"ALU branch resolve owner/target tuple mismatch tag=%d npc=%h",resolve_tag,npc);
     branch_pending[resolve_tag]=0;resolved=resolved+1;
    end
    if(early&&!km[early_tag[4:0]])begin
     if(!pending[early_tag]||km[early_tag[4:0]]||early_preg==0||expected[early_tag][`R64_R_EXCEPTION])
      $fatal(1,"ALU early wake has no live eligible owner");
     woken=woken+1;
    end
    if(valid&&ready&&!km[result_tag[4:0]])begin
     if(!pending[result_tag]||result!==expected[result_tag])
      $fatal(1,"ALU completion missing/duplicate/wrong tag=%d got=%h expected=%h",result_tag,result,expected[result_tag]);
     pending[result_tag]=0;completed=completed+1;
    end
    if(fire)begin
     if(!credit||pending[tag]||km[tag[4:0]])$fatal(1,"ALU test admitted unavailable owner");
     pending[tag]=1;accepted=accepted+1;
     expected[tag]=0;
     expected[tag][`R64_R_DATA]=branch_op ? uop[`R64_U_PC]+{60'b0,uop[`R64_U_LEN]}:reference_result;
     expected[tag][`R64_R_EXCEPTION]=uop[`R64_U_EXCEPTION];
     expected[tag][`R64_R_CAUSE]=uop[`R64_U_CAUSE];
     expected[tag][`R64_R_TVAL]=uop[`R64_U_ARG];
     branch_pending[tag]=branch_op&&!uop[`R64_U_EXCEPTION];
     expected_pc[tag]=uop[`R64_U_PC];expected_npc[tag]=branch_target;
     expected_flags[tag]=branch_flags;expected_redirect[tag]=branch_target!=uop[`R64_U_ARG];
    end
   end
   check_future=!flush&&early&&!km[early_tag[4:0]]&&!(bypass&&early_tag==result_tag);
   future_tag=early_tag;
   hold_valid=!flush&&valid&&!ready&&!km[result_tag[4:0]];
   hold_tag=result_tag;hold_result=result;
   #1;
   if(check_future&&(!bypass||result_tag!=future_tag))
    $fatal(1,"ALU wake did not produce the promised next-cycle bypass head");
  end
 end
 task tick;begin @(posedge clk);#2;end endtask
 task send;
  input integer id,func;input [63:0] a,b;input word_mode;
  begin
   @(negedge clk);while(!credit)@(negedge clk);
   tag=9'(id);preg_dst=6'((id%31)+1);branch_op=0;uop=0;
   uop[`R64_U_FUNC]=8'(func);uop[`R64_U_LEN]=4;uop[`R64_U_WORD]=word_mode;
   operands={64'b0,b,a};fire=1;tick();fire=0;
  end
 endtask
 task send_immediate;
  input integer id,func;input [63:0] pc,a,imm;input pc_source,word_mode;
  begin
   @(negedge clk);while(!credit)@(negedge clk);
   tag=9'(id);preg_dst=6'((id%31)+1);branch_op=0;uop=0;
   uop[63:0]=pc;uop[127:64]=imm;
   uop[203:196]=8'(func);uop[195:192]=4;uop[204]=word_mode;
   uop[205]=pc_source;uop[207]=1;
   operands={64'b0,64'hbad0bad0bad0bad0,a};fire=1;tick();fire=0;
  end
 endtask
 task drain;
  integer wait_cycles;
  begin
   ready=1;wait_cycles=0;
   while(accepted!=completed+canceled&&wait_cycles<40)begin tick();wait_cycles=wait_cycles+1;end
   if(accepted!=completed+canceled)$fatal(1,"ALU terminal failed to drain");
   tick();
  end
 endtask
 task send_branch;
  input integer id;input [31:0] inst;input [63:0] pc,a,b,predicted,target;
  input [3:0] len;input [2:0] flags;
  begin
   @(negedge clk);while(!credit)@(negedge clk);
   tag=9'(id);preg_dst=1;branch_op=1;uop=0;uop[159:128]=inst;
   uop[`R64_U_PC]=pc;uop[`R64_U_ARG]=predicted;uop[`R64_U_LEN]=len;
   operands={64'b0,b,a};branch_target=target;branch_flags=flags;
   // RR's predecode boundary is represented explicitly at this direct FU test.
   branchcontrol={inst[14:12],inst[6:0]==7'h67,inst[6:0]==7'h63};
   branchimm=inst[6:0]==7'h67 ? {{9{inst[31]}},inst[31:20]}:
       inst[6:0]==7'h63 ? {{8{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0}:
       {inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
   fire=1;tick();fire=0;
  end
 endtask
 reg [31:0] seed=32'h8e6c2731;
 function [31:0] next_seed;
  input [31:0] old;reg [31:0] v;
  begin v=old^(old<<13);v=v^(v>>17);next_seed=v^(v<<5);end
 endfunction
 integer n,before_count;reg [63:0] a,b;
 initial begin
  tick();rst=0;
  before_count=accepted;
  for(n=0;n<200;n=n+1)begin
   @(negedge clk);if(!credit)$fatal(1,"ALU II1 lost credit under an always-ready sink");
   tag=9'(n);preg_dst=6'((n%31)+1);uop=0;uop[`R64_U_FUNC]=8'(n%48);
   uop[`R64_U_LEN]=4;uop[`R64_U_WORD]=n[0];
   seed=next_seed(seed);a={seed,~seed};seed=next_seed(seed);b={seed,seed^32'h12345678};
   operands={64'b0,b,a};fire=1;tick();fire=0;
  end
  if(accepted-before_count!=200)$fatal(1,"ALU continuous acceptance count");
  drain();
  // AUIPC and branch target use the separate adder inputs. LUI and normal
  // immediates still use the original ALU oracle, including signed words.
  for(n=0;n<8;n=n+1)begin
   send_immediate(300+n,0,64'h80000000+n*4,64'h5555555555555555,
       64'hfffffffffffff000+n,1,0);
   send_immediate(320+n,14,0,64'h123456789abcdef0,64'hfedcba9876543000+n,0,0);
   send_immediate(340+n,13,0,64'h87654321fedcba98,64'(n*4),0,n[0]);
  end
  drain();
  // Four reservations must stop admission even though calculation keeps going.
  ready=0;send(201,0,11,12,0);send(202,8,31,7,0);
  send(203,22,64'h1234567887654321,13,0);send(204,37,~64'b0,0,0);
  tick();tick();if(credit||dut.reserved_q!=4||dut.count_q!=4)$fatal(1,"ALU terminal capacity accounting");
  repeat(16)tick();drain();
  // Kill a nonhead generation while its predecessor remains blocked. Its
  // replacement uses the same ROB slot before the canceled tombstone drains.
  ready=0;send(5,0,10,11,0);send(6,0,20,21,0);tick();tick();
  @(negedge clk);km=32'h40;tick();km=0;
  send(38,0,100,1,0);tick();tick();repeat(8)tick();drain();
  // Cancellation intersects both the numerical token and the terminal owner.
  ready=0;send(7,0,71,1,0);@(negedge clk);km=32'h80;tick();km=0;drain();
  ready=0;send(8,0,81,1,0);send(9,0,91,1,0);
  @(negedge clk);flush=1;tick();flush=0;drain();
  // All branch outcomes use literal architectural target oracles.
  send_branch(210,32'h00208463,64'h1000,5,5,64'h1004,64'h1008,4,3'b101);
  send_branch(211,32'h00209463,64'h1000,5,5,64'h1008,64'h1004,4,3'b100);
  send_branch(212,32'h0020c463,64'h1000,~64'b0,1,64'h1008,64'h1008,4,3'b101);
  send_branch(213,32'h0020e463,64'h1000,~64'b0,1,64'h1004,64'h1004,4,3'b100);
  send_branch(214,32'h008000ef,64'h1000,0,0,64'h1002,64'h1008,2,3'b001);
  send_branch(215,32'hffd080e7,64'h1000,64'h1010,0,64'h1002,64'h100c,2,3'b011);
  drain();
  if(resolved!=6)$fatal(1,"ALU branch cases were not exercised");
  $display("[PASS] tb_r64_alu_lane accepted=%0d completed=%0d canceled=%0d early=%0d resolve=%0d II1/full/hold/kill-generation/flush",accepted,completed,canceled,woken,resolved);
  $finish;
 end
endmodule
