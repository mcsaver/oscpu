`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_control_pipeline;
 localparam M=`R64_META_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;reg [1:0] valid=0,ex=0,ready=3;
 reg [2*M-1:0] meta=0;reg [127:0] data=0,tval=0;reg[11:0] causes=0;
 wire[1:0] fire,retired,robready;wire[127:0] npc;
 wire trap,irq,prepare,flush,stop,effect,serial;wire[5:0] cause;
 wire[63:0] epc,tvalue,target,redirect;
 wire pending;wire[5:0] pending_cause;
 reg ext=0,setup_commit=0,query=0,return_prepare=0,return_supervisor=0;
 reg [11:0] address=0;reg[2:0] operation=1;reg[4:0] rs=1;reg[63:0] operand=0;
 wire[63:0] select,read_value,write_value,status,return_target;
 wire query_valid,illegal;wire[1:0] privilege;
 wire csr_commit=setup_commit||(serial&&meta[203:196]==`R64_K_CSR);
 wire[1:0] return_commit=serial?(meta[203:196]==`R64_K_MRET?2'd1:
   (meta[203:196]==`R64_K_SRET?2'd2:2'd0)):2'd0;
 integer cycles=0,retire_total=0,trap_total=0,prepare_total=0,flush_total=0;
 integer prep_cycle=-10,old_retired,old_traps,j;
 reg[63:0] last_pc,last_value,last_target;reg[5:0] last_cause;reg last_irq;
 always @(posedge clk)if(!rst)begin
  cycles=cycles+1;retire_total=retire_total+retired;
  if(prepare)begin prep_cycle=cycles;prepare_total=prepare_total+1;
   if(flush||trap||effect||(|fire)||!stop)$fatal(1,"prepare did not freeze exact boundary");
  end
  if(flush)flush_total=flush_total+1;
  if(trap)begin
   if(cycles!=prep_cycle+1)$fatal(1,"trap preparation latency changed");
   trap_total=trap_total+1;last_pc=epc;last_value=tvalue;
   last_target=redirect;last_cause=cause;last_irq=irq;
   if(|fire)$fatal(1,"exception retired");
  end
 end
 R64Commit commit(.clk_i(clk),.rst_i(rst),.rob_valid_i(valid),.rob_ready_o(robready),.commit1_allow_o(),
  .rob_tag_i(18'd1),.rob_meta_i(meta),.rob_data_i(data),.rob_exception_i(ex),
  .rob_cause_i(causes),.rob_tval_i(tval),.rob_rd_write_i(2'b0),.rob_rd_fp_i(2'b0),
  .rob_fflags_i(10'b0),.retire_ready_i(ready),.rob_empty_i(valid==0),.recover_i(1'b0),
  .lsu_irrevocable_i(1'b0),.serial_irrevocable_i(1'b0),
  .irq_pending_i(pending),.irq_cause_i(pending_cause),.trap_target_i(target),
  .retire_fire_o(fire),.retire_npc_o(npc),.retired_count_o(retired),.fp_dirty_o(),.fp_flags_o(),
  .serial_commit_o(serial),.serial_tag_o(),.trap_o(trap),.trap_interrupt_o(irq),
  .trap_cause_o(cause),.trap_pc_o(epc),.trap_tval_o(tvalue),.stop_birth_o(stop),
  .full_flush_o(flush),.redirect_o(),.redirect_target_o(redirect),
  .effect_allow_o(effect),.serial_allow_o(),.trap_prepare_o(prepare));
 R64CsrDecode decode(address,select);
 R64Csr csr(.clk_i(clk),.rst_i(rst),.count_enable_i(1'b1),.time_i(64'b0),.retired_i(retired),
  .address_i(address),.operation_i(operation),.rs1_i(rs),.operand_i(operand),.commit_i(csr_commit),
  .read_o(read_value),.illegal_o(illegal),.fp_dirty_i(1'b0),.fp_flags_i(5'b0),
  .trap_i(trap),.trap_interrupt_i(irq),.trap_cause_i(cause),.trap_pc_i(epc),.trap_tval_i(tvalue),
  .return_i(return_commit),.return_target_o(return_target),
  .irq_software_i(1'b0),.irq_timer_i(1'b0),.irq_external_i(ext),.irq_supervisor_external_i(1'b0),
  .wfi_wake_o(),.irq_pending_o(pending),.irq_cause_o(pending_cause),.trap_target_o(target),
  .privilege_o(privilege),.mstatus_o(status),.satp_o(),.frm_o(),.pbmt_enable_o(),
  .pmp_config_o(),.pmp_address_o(),.write_value_o(write_value),.commit_value_i(write_value),
  .return_supervisor_i(return_supervisor),.select_i(select),.trigger_enable_o(),.trigger_address_o(),
  .query_i(query),.query_valid_o(query_valid),.trap_prepare_i(prepare),.return_prepare_i(return_prepare));
 function [M-1:0] md(input[63:0] pc,input[63:0] raw,input[63:0] nextpc,input[3:0] len,input[7:0] kind);
  md={kind,len,nextpc,raw,pc};
 endfunction
 task request(input[11:0] addr,input[63:0] value);
 begin
  @(negedge clk);address=addr;operand=value;operation=1;rs=1;query=1;
  @(negedge clk);query=0;
  @(negedge clk);
  if(!query_valid||illegal)$fatal(1,"CSR query did not capture legal snapshot %h",addr);
 end endtask
 task configure(input[11:0] addr,input[63:0] value);
 begin request(addr,value);setup_commit=1;@(negedge clk);setup_commit=0;end endtask
 task await_trap(input integer before_count);
 begin
  j=0;while(trap_total==before_count&&j<12)begin @(negedge clk);j=j+1;end
  if(trap_total!=before_count+1)$fatal(1,"trap not consumed once");
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=0;
  configure(12'h304,64'h800);configure(12'h300,64'h8);
  // An older mtvec CSR is truly committed before pending IRQ takes the empty ROB.
  request(12'h305,64'h80002001);
  meta={ {M{1'b0}}, md(64'h80000100,64'h30509073,64'h80000104,4,`R64_K_CSR)};
  valid=1;ext=1;old_retired=retire_total;old_traps=trap_total;
  @(negedge clk);valid=0;
  if(retire_total!=old_retired+1||!flush||trap||redirect!=64'h80000104)
   $fatal(1,"serial commit flush was not exactly next cycle");
  await_trap(old_traps);
  if(last_cause!=11||!last_irq||last_pc!=64'h80000104||last_target!=64'h8000202c)
   $fatal(1,"older CSR vector/IRQ ordering target=%h pc=%h cause=%d",last_target,last_pc,last_cause);
  if(status[3]||privilege!=3)$fatal(1,"trap state not visible");
  old_traps=trap_total;repeat(5)@(negedge clk);
  if(trap_total!=old_traps||pending)$fatal(1,"stale eligible IRQ survived trap-cleared MIE");
  ext=0;repeat(2)@(negedge clk);
  // Fault record must outlive ROB inputs; original compressed encoding is tval.
  old_retired=retire_total;old_traps=trap_total;ready=0;
  meta={ {M{1'b0}}, md(64'h900,64'h123456780000abcd,64'h902,2,`R64_K_FAULT)};
  valid=1;ex=1;causes=2;tval=128'hffff;
  @(negedge clk);
  if(!prepare||trap||flush)$fatal(1,"fault capture/preparation boundary");
  valid=0;ex=0;causes=7;tval=0;meta=0;
  await_trap(old_traps);
  if(last_cause!=2||last_irq||last_pc!=64'h900||last_value!=64'habcd||
     last_target!=64'h80002000||retire_total!=old_retired)
   $fatal(1,"synchronous fault record changed or retired");
  ready=3;
  // Prefetch xRET target at admission; retirement applies privilege before next-cycle recovery.
  configure(12'h341,64'h80004002);configure(12'h300,64'h80);
  @(negedge clk);return_prepare=1;return_supervisor=0;
  @(negedge clk);return_prepare=0;
  if(return_target!=64'h80004002)$fatal(1,"MRET target prepare");
  meta={ {M{1'b0}}, md(64'h80000300,64'h30200073,64'h80000304,4,`R64_K_MRET)};
  data={64'b0,return_target};valid=1;old_retired=retire_total;
  @(negedge clk);valid=0;
  if(privilege!=0||!flush||trap||redirect!=64'h80004002||retire_total!=old_retired+1)
   $fatal(1,"MRET state/target recovery ordering");
  @(negedge clk);
  // No trap/CSR: true two-wide retirement consumes exactly one cycle per pair.
  old_retired=retire_total;
  repeat(100)begin
   meta={md(64'h80005004,0,64'h80005008,4,0),md(64'h80005000,0,64'h80005004,4,0)};
   valid=3;@(negedge clk);
  end
  valid=0;
  if(retire_total-old_retired!=200)$fatal(1,"ordinary dual retire lost throughput");
  $display("[PASS] tb_r64_control_pipeline coupled: older CSR->IRQ vector, live privilege, original fault tval, trap+1, xRET unchanged, ordinary 200/100");
  $display("retired=%0d traps=%0d prepares=%0d flushes=%0d",retire_total,trap_total,prepare_total,flush_total);
  $finish;
 end
 initial begin #100000;$fatal(1,"control coupled timeout");end
endmodule
