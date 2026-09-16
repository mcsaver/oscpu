`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_serial;
reg clk=0;always #5 clk=~clk;
reg rst=1,flush=0,fire=0,rr=0,commit=0,memidle=1;
reg [31:0] kill=0;
reg [8:0] tag=9'd3;
reg [63:0] raw=0,pc=64'h80000000;
reg [3:0] len=4;
reg [191:0] operand=0;
wire [`R64_UOP_W-1:0] uop;
R64Decode decode(.pc_i(pc),.raw_i(raw),.length_i(len),.pred_npc_i(pc+len),
 .fetch_exception_i(1'b0),.fetch_cause_i(6'b0),.fetch_tval_i(64'b0),
 .uop_o(uop),.meta_o(),.class_o(),.rd_write_o(),.rd_fp_o(),.rd_arch_o(),
 .src_arch_o(),.src_fp_o(),.src_used_o(),.serial_o(),.illegal_o());
wire ready,rv,ccommit,rsuper,icin,tlin,allva,allasid,tcv,ttr,irrev,idle;
wire [8:0] resulttag,tct;
wire [`R64_RESULT_W-1:0] result;
wire [11:0] ca;wire [2:0] cop;wire [4:0] crs;
wire [63:0] coperand,cread,cnew,rtarget,tcommand,toperand,status,satp;
wire cillegal;wire [1:0] ret,priv;
wire [26:0] vpn;wire [15:0] asid;
wire pair;wire [7:0] tclass;wire [31:0] reuse;
reg tready=0,ttv=0,terr=0;reg [8:0] ttag=0;reg [7:0] terror=0;
wire [63:0] cselect;wire query,query_valid,return_prepare;
reg wb_mode=0;wire [1:0] wbv;wire [17:0] wbt;wire [279:0] wbr;
wire [1:0] wbsready;integer wbcount=0;
R64Writeback #(.SOURCES(2),.SOURCE_W(1)) wb(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .source_valid_i({1'b0,rv&&wb_mode}),.source_ready_o(wbsready),
 .source_tag_i({9'b0,resulttag}),.source_result_i({140'b0,result}),
 .wb_valid_o(wbv),.wb_tag_o(wbt),.wb_result_o(wbr));
always @(posedge clk)if(!rst)begin
 if(wbv[0])wbcount=wbcount+1;
 if(wbv[1])wbcount=wbcount+1;
end
R64Serial dut(
 .csr_query_o(query),.csr_query_valid_i(query_valid),.return_prepare_o(return_prepare),
 .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),.fire_i(fire),.ready_o(ready),
 .tag_i(tag),.head_tag_i(tag),.uop_i(uop),.operand_i(operand),.memory_idle_i(memidle),.wfi_wake_i(1'b1),
 .result_valid_o(rv),.result_ready_i(wb_mode?wbsready[0]:rr),.result_tag_o(resulttag),.result_o(result),
 .commit_i(commit),.commit_tag_i(tag),.privilege_i(priv),.mstatus_i(status),
 .csr_address_o(ca),.csr_select_o(cselect),.csr_operation_o(cop),.csr_rs1_o(crs),.csr_operand_o(coperand),
 .csr_commit_o(ccommit),.csr_read_i(cread),.csr_write_value_i(cnew),.csr_illegal_i(cillegal),
 .return_supervisor_o(rsuper),.return_commit_o(ret),.return_target_i(rtarget),
 .icache_invalidate_o(icin),.tlb_invalidate_o(tlin),.tlb_all_vaddr_o(allva),
 .tlb_all_asid_o(allasid),.tlb_vpn_o(vpn),.tlb_asid_o(asid),
 .tensor_cmd_valid_o(tcv),.tensor_cmd_ready_i(tready),.tensor_cmd_tag_o(tct),
 .tensor_cmd_o(tcommand),.tensor_operand_o(toperand),.tensor_pair_o(pair),.tensor_class_o(tclass),
 .tensor_terminal_valid_i(ttv),.tensor_terminal_ready_o(ttr),.tensor_terminal_tag_i(ttag),
 .tensor_error_i(terr),.tensor_error_code_i(terror),.irrevocable_o(irrev),
 .reuse_block_o(reuse),.idle_o(idle)
);
R64Csr csr(
 .query_i(query),.query_valid_o(query_valid),.trap_prepare_i(1'b0),.return_prepare_i(return_prepare),
 .clk_i(clk),.rst_i(rst),.count_enable_i(1'b1),.time_i(64'b0),.retired_i({1'b0,commit}),
 .address_i(ca),.select_i(cselect),.operation_i(cop),.rs1_i(crs),.operand_i(coperand),.commit_i(ccommit),
 .read_o(cread),.illegal_o(cillegal),.fp_dirty_i(1'b0),.fp_flags_i(5'b0),
 .trap_i(1'b0),.trap_interrupt_i(1'b0),.trap_cause_i(6'b0),.trap_pc_i(64'b0),.trap_tval_i(64'b0),
 .return_i(ret),.return_target_o(rtarget),.irq_software_i(1'b0),.irq_timer_i(1'b0),
 .irq_external_i(1'b0),.irq_supervisor_external_i(1'b0),.wfi_wake_o(),.irq_pending_o(),.irq_cause_o(),.trap_target_o(),
 .privilege_o(priv),.mstatus_o(status),.satp_o(satp),.frm_o(),.pbmt_enable_o(),
 .pmp_config_o(),.pmp_address_o(),.write_value_o(cnew),.commit_value_i(coperand),
 .return_supervisor_i(rsuper),.trigger_enable_o(),.trigger_address_o()
);
integer delivered=0,retired_count=0,tensor_sent=0,cycles=0,n;
reg [`R64_RESULT_W-1:0] saved_result;
reg [63:0] saved_counter;
reg expect_sfence=0,expect_ifence=0;
function [31:0] csr_inst(input [11:0] addr,input [2:0] op);
csr_inst={addr,5'd5,op,5'd1,7'h73};endfunction
always @(posedge clk)if(!rst)begin
 cycles=cycles+1;
 if(cycles>3000)$fatal(1,"serial timeout");
 if(tcv&&tready)tensor_sent=tensor_sent+1;
 if(commit)retired_count=retired_count+1;
 if(icin!== (commit&&expect_ifence)||tlin!==(commit&&expect_sfence))
  $fatal(1,"cache/TLB effect escaped exact serial commit");
end
task launch(input [63:0] bits,input [63:0] a,input [63:0] b,input [3:0] length);
begin
 @(negedge clk);while(!ready)@(negedge clk);
 raw=bits;operand={64'b0,b,a};len=length;fire=1;
 @(negedge clk);fire=0;
end endtask
task complete_result(input ex,input [5:0] ecause,input [63:0] tv,input check_data,input [63:0] data);
begin
 while(!rv)@(negedge clk);
 if(resulttag!==tag||result[`R64_R_EXCEPTION]!==ex||
   (ex&&(result[`R64_R_CAUSE]!==ecause||result[`R64_R_TVAL]!==tv))||
   (!ex&&check_data&&result[`R64_R_DATA]!==data))
  $fatal(1,"serial result cmd=%h data=%h exception=%d cause=%0d tval=%h",
   raw,result[`R64_R_DATA],result[`R64_R_EXCEPTION],result[`R64_R_CAUSE],result[`R64_R_TVAL]);
 saved_result=result;delivered=delivered+1;
 repeat(4)begin @(negedge clk);if(!rv||result!==saved_result||ccommit||ret!=0)
  $fatal(1,"serial output changed or committed under backpressure");end
 rr=1;@(negedge clk);rr=0;
end endtask
task retire_owner;
begin
 @(negedge clk);commit=1;#1;
 if(expect_sfence&&(allva||allasid||vpn!=27'h40003||asid!=16'hab))$fatal(1,"SFENCE captured wrong operands");
 @(negedge clk);commit=0;tag=tag+1;expect_sfence=0;expect_ifence=0;
end endtask
task flush_owner;
begin @(negedge clk);flush=1;@(negedge clk);flush=0;tag=tag+1;end
endtask
task write_csr(input [11:0] a,input [63:0] data);
begin launch(csr_inst(a,1),data,0,4);complete_result(0,0,0,0,0);retire_owner;end
endtask
initial begin
 repeat(3)@(negedge clk);rst=0;
 launch(csr_inst(12'h340,1),64'h1234,0,4);
 complete_result(0,0,0,1,0);
 if(cread!=0)$fatal(1,"CSR mutated before ROB commit");
 retire_owner;if(csr.mscratch_q!=64'h1234)$fatal(1,"CSR commit failed");
 launch(csr_inst(12'h340,2),64'h4000,0,4);complete_result(0,0,0,1,64'h1234);
 retire_owner;if(csr.mscratch_q!=64'h5234)$fatal(1,"CSR RMW snapshot failed");
 launch(csr_inst(12'hb00,2),64'h10000,0,4);complete_result(0,0,0,0,0);
 saved_counter=saved_result[`R64_R_DATA]|64'h10000;
 repeat(7)@(negedge clk);
 retire_owner;if(csr.cycle_q!==saved_counter)$fatal(1,"serial counter write was recomputed at retirement");
 launch(csr_inst(12'h7a3,2),0,0,4);complete_result(1,2,csr_inst(12'h7a3,2),0,0);flush_owner;
 launch(32'h00000073,0,0,4);complete_result(1,11,0,0,0);flush_owner;
 launch(32'h00100073,0,0,4);complete_result(1,3,0,0,0);flush_owner;
 launch(32'h0000100f,0,0,4);complete_result(0,0,0,0,0);expect_ifence=1;retire_owner;
 write_csr(12'h341,64'h80006000);write_csr(12'h300,64'h6800);
 launch(32'h30200073,0,0,4);complete_result(0,0,0,1,64'h80006000);
 if(priv!=3)$fatal(1,"MRET executed before commit");retire_owner;
 if(priv!=1)$fatal(1,"MRET commit privilege");
 memidle=0;launch(32'h12628073,64'h40003456,64'hab,4);
 repeat(6)begin @(negedge clk);if(rv||tlin)$fatal(1,"SFENCE bypassed drain");end
 memidle=1;complete_result(0,0,0,0,0);expect_sfence=1;retire_owner;
 launch(32'h30200073,0,0,4);complete_result(1,2,32'h30200073,0,0);flush_owner;
 // Tensor launch is stable under command backpressure and its owner survives WB.
 launch(64'h0a00305b0200305b,0,0,8);
 while(!tcv)@(negedge clk);
 repeat(6)begin
  @(negedge clk);
  if(!tcv||!irrev||tct!==tag||tcommand!==raw||!pair||tclass!=1||reuse!=(32'b1<<tag[4:0]))
   $fatal(1,"Tensor launch owner unstable");
 end
 tready=1;@(negedge clk);tready=0;
 ttag=tag+1;ttv=1;@(negedge clk);ttv=0;
 if(rv||reuse==0)$fatal(1,"stale Tensor terminal completed owner");
 repeat(3)@(negedge clk);
 ttag=tag;ttv=1;@(negedge clk);ttv=0;
 complete_result(0,0,0,1,0);
 if(!irrev||reuse!=0)$fatal(1,"Tensor retirement owner lost after terminal");
 retire_owner;if(irrev)$fatal(1,"Tensor owner not retired");
 // A failed terminal becomes an exact NPU fault after external ownership drains.
 launch(64'h0e00305b0200305b,0,0,8);
 while(!tcv)@(negedge clk);tready=1;@(negedge clk);tready=0;
 ttag=tag;ttv=1;terr=1;terror=8'h7e;@(negedge clk);ttv=0;terr=0;
 complete_result(1,24,{8'h7e,tag[7:0],8'd2,1'b1,1'b1,6'd1,32'h0200305b},0,0);
 if(irrev||reuse!=0)$fatal(1,"failed Tensor result blocked precise trap");
 flush_owner;
 // Prelaunch kill produces neither a command nor a completion.
 memidle=0;launch(64'h0a00305b0200305b,0,0,8);
 kill=32'b1<<tag[4:0];@(negedge clk);kill=0;
 repeat(4)begin @(negedge clk);if(tcv||rv||reuse!=0)$fatal(1,"killed serial work survived");end
 if(!ready||tensor_sent!=2)$fatal(1,"serial coverage ownership");
 // Pure snapshot query can coincide with cancellation, but cannot write CSR.
 memidle=1;tag=tag+1;
 for(n=0;n<2;n=n+1)begin
 launch(csr_inst(12'h140,1),64'ha55a,0,4);
 if(n==0)kill=32'b1<<tag[4:0];else flush=1;
 if(!query)$fatal(1,"CSR query expected at cancelled EVALUATE");
 @(negedge clk);kill=0;flush=0;tag=tag+32;#1;
 // Admit at the FIRST possible edge after cancellation, exactly when the
 // old two-stage query returns. New EVALUATE must not consume that response.
 if(!ready)$fatal(1,"cancel did not release next-edge serial admission");
 raw=csr_inst(12'h140,2);operand=0;len=4;fire=1;
 @(negedge clk);fire=0;
 if(!query_valid||cnew!=64'ha55a||dut.state_q!=dut.EVALUATE)
  $fatal(1,"test failed to overlap old query reply with earliest new owner");

 complete_result(0,0,0,1,0);retire_owner;
 if(csr.sscratch_q!=0)$fatal(1,"cancelled query acquired architectural write");
 end
 // A held raw result cancelled exactly at an actual WB grant must not capture.
 wb_mode=1;launch(csr_inst(12'h140,2),0,0,4);
 while(!rv||!wbsready[0])@(negedge clk);
 kill=32'b1<<tag[4:0];
 if(!rv)$fatal(1,"test must exercise raw valid on kill edge");
 @(negedge clk);kill=0;
 repeat(5)@(negedge clk);
 if(wbcount!=0||!ready||ccommit)$fatal(1,"WB copied same-edge killed Serial owner");
 tag=tag+32;
 launch(csr_inst(12'h140,2),0,0,4);
 while(wbcount==0)@(negedge clk);
 if(wbcount!=1||wbt[8:0]!=tag&&wbt[17:9]!=tag)$fatal(1,"new generation did not complete once");
 wb_mode=0;commit=1;@(negedge clk);commit=0;
 $display("[R64-SERIAL-CANCEL] orphan query/no write, real WB kill+grant, same-slot generation reuse PASS");
 // Accepted completion predecodes effects, yet never bypasses tag identity.
 tag=tag+1;launch(csr_inst(12'h140,1),64'h6789,0,4);
 complete_result(0,0,0,1,0);
 if(dut.retire_effect_q!==5'b00001)$fatal(1,"CSR accepted effect not prepared");
 tag=tag+32;commit=1;#1;
 if(ccommit||ret!=0||icin||tlin)$fatal(1,"wrong generation committed effect");
 @(negedge clk);commit=0;tag=tag-32;
 if(csr.sscratch_q!=0||ready)$fatal(1,"wrong tag released owner");
 retire_owner;if(csr.sscratch_q!=64'h6789)$fatal(1,"prepared CSR effect lost");
 // An accepted result cancelled while waiting for commit loses all authority.
 for(n=0;n<2;n=n+1)begin
  launch(csr_inst(12'h140,1),64'hdead,0,4);complete_result(0,0,0,1,64'h6789);
  if(n==0)kill=32'b1<<tag[4:0];else flush=1;
  @(negedge clk);kill=0;flush=0;tag=tag+32;#1;
  if(!ready||dut.retire_effect_q!=0||csr.sscratch_q!=64'h6789)
   $fatal(1,"cancelled accepted completion retained effect");
  // First legal post-cancel edge births a different serial class, with no
  // inherited CSR authority; the FENCE.I effect remains exact tagged commit.
  raw=32'h0000100f;operand=0;len=4;fire=1;
  @(negedge clk);fire=0;complete_result(0,0,0,0,0);
  if(dut.retire_effect_q!==5'b01000||ccommit)$fatal(1,"next owner inherited effects");
  expect_ifence=1;retire_owner;
 end
 // Accepted exception completion is never an architectural side-effect owner.
 launch(csr_inst(12'h7a3,2),0,0,4);complete_result(1,2,csr_inst(12'h7a3,2),0,0);
 if(dut.retire_effect_q!=0||ccommit||ret!=0||icin||tlin)$fatal(1,"fault acquired effect");
 flush_owner;
 $display("[R64-SERIAL-EFFECT] accepted owner, full generation compare, held/kill/flush/fault/Tensor/reuse PASS");
 $display("[PASS] tb_r64_serial");
 $display("COVERAGE completions=%0d committed=%0d Tensor_transactions=%0d CSR_snapshot_xRET_SFENCE_precise_exception=1",
  delivered,retired_count,tensor_sent);
 $finish;
end
endmodule
