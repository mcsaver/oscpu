`include "R64Uop.vh"
// Precise architectural boundary. The normal path retires two instructions;
// exceptional/serial recovery is a registered event, never a combinational
// function from ROB VALID back to its FLUSH input. Only last-retired NPC and
// one pending event record are retained; CSR/privilege remain owned by R64Csr.
module R64Commit #(parameter [63:0] RESET_PC=64'h80000000,parameter HEAD_SERIAL_ISSUE=0,parameter HEAD_SERIAL_STOP=0,parameter HEAD_EXCEPTION_STOP=0,parameter HEAD_SERIAL_CLASS=0,parameter SCRATCH_READ_RESUME=0)(
 input clk_i,input rst_i,
 input [1:0] rob_serial_i,input [1:0] rob_valid_i,output [1:0] rob_ready_o,output commit1_allow_o,
 input [17:0] rob_tag_i,input [2*`R64_META_W-1:0] rob_meta_i,
 input [127:0] rob_data_i,input [1:0] rob_exception_i,
 input [11:0] rob_cause_i,input [127:0] rob_tval_i,
 input [1:0] rob_rd_write_i,rob_rd_fp_i,input [9:0] rob_fflags_i,
 input [1:0] retire_ready_i,
 input head_exception_i,input head_serial_i,input rob_empty_i,input recover_i,input lsu_irrevocable_i,input serial_irrevocable_i,
 input irq_pending_i,input [5:0] irq_cause_i,input [63:0] trap_target_i,
 output [1:0] retire_fire_o,output [127:0] retire_npc_o,output [1:0] retired_count_o,
 output fp_dirty_o,output [4:0] fp_flags_o,
 output serial_commit_o,output [8:0] serial_tag_o,
 output trap_o,output trap_interrupt_o,output [5:0] trap_cause_o,
 output [63:0] trap_pc_o,trap_tval_o,
 output stop_birth_o,output full_flush_o,output redirect_o,output [63:0] redirect_target_o,
 output effect_allow_o,output serial_allow_o,output trap_prepare_o
);
 localparam M=`R64_META_W;
 wire [7:0] kind0=rob_meta_i[203:196],kind1=rob_meta_i[M+196+:8];
 wire metadata_serial0=kind0>=`R64_K_CSR&&kind0<=`R64_K_TENSOR;
 wire metadata_serial1=kind1>=`R64_K_CSR&&kind1<=`R64_K_TENSOR;
 // Actual ROB retains this predecoded payload with META, including invalid
 // slots. A head-class lookup avoids selecting eight KIND bits then decoding.
 wire serial0=HEAD_SERIAL_CLASS ? rob_serial_i[0]:metadata_serial0;
 wire serial1=HEAD_SERIAL_CLASS ? rob_serial_i[1]:metadata_serial1;
 wire return0=kind0==`R64_K_MRET||kind0==`R64_K_SRET;
 wire return1=kind1==`R64_K_MRET||kind1==`R64_K_SRET;
 wire [63:0] npc0=return0 ? rob_data_i[63:0]:rob_meta_i[191:128];
 wire [63:0] npc1=return1 ? rob_data_i[127:64]:rob_meta_i[M+128+:64];
 assign retire_npc_o={npc1,npc0};
 reg [63:0] retired_npc_q;
 reg event_valid_q,event_trap_q,event_interrupt_q;reg event_prepared_q;
 // For a trap this is EPC; for serial recovery this same register is target.
 reg [63:0] event_pc_q,event_tval_q;
 reg [5:0] event_cause_q;
 wire active=!rst_i&&!event_valid_q&&!recover_i;
 wire head_exception=rob_valid_i[0]&&rob_exception_i[0];
 wire irrevocable=lsu_irrevocable_i||serial_irrevocable_i;
 assign rob_ready_o[0]=active&&retire_ready_i[0]&&!rob_exception_i[0];
 // commit1_allow must not depend on rob_valid_i[1]: ROB uses this permission
 // to generate that signal. Serial instructions always retire alone at head.
 assign commit1_allow_o=active&&!serial0&&!serial1;
 assign rob_ready_o[1]=active&&retire_ready_i[0]&&retire_ready_i[1]&&
   !rob_exception_i[1]&&!serial0&&!serial1;
 assign retire_fire_o=rob_valid_i&rob_ready_o&~rob_exception_i;
 assign retired_count_o={1'b0,retire_fire_o[0]}+{1'b0,retire_fire_o[1]};
 assign serial_commit_o=retire_fire_o[0]&&serial0;
 assign serial_tag_o=rob_tag_i[8:0];
 assign fp_flags_o=({5{retire_fire_o[0]}}&rob_fflags_i[4:0])|
                   ({5{retire_fire_o[1]}}&rob_fflags_i[9:5]);
 assign fp_dirty_o=(retire_fire_o[0]&&(kind0==`R64_K_FP||(rob_rd_write_i[0]&&rob_rd_fp_i[0])))||
                   (retire_fire_o[1]&&(kind1==`R64_K_FP||(rob_rd_write_i[1]&&rob_rd_fp_i[1])));
 wire capture_exception=active&&head_exception&&!irrevocable;
 wire capture_interrupt=active&&irq_pending_i&&rob_empty_i&&!irrevocable;
 assign trap_prepare_o=!rst_i&&event_valid_q&&event_trap_q&&!event_prepared_q;
 assign full_flush_o=!rst_i&&event_valid_q&&(!event_trap_q||event_prepared_q);
 assign redirect_o=full_flush_o;
 assign redirect_target_o=event_trap_q ? trap_target_i:event_pc_q;
 assign trap_o=full_flush_o&&event_trap_q;
 assign trap_interrupt_o=event_interrupt_q;
 assign trap_cause_o=event_cause_q;
 assign trap_pc_o=event_pc_q;
 assign trap_tval_o=event_tval_q;
 // IRQ requests prevent new births but must leave existing ROB-head effects
 // enabled: a successful external transaction cannot disappear before commit.
 // A resident Serial head stops younger births until its effect retires.
 // Non-whitelisted serials then create a restart; scratch reads resume.
 // This early stop leaves existing Issue, execution, drain and retirement live.
 assign stop_birth_o=rst_i||event_valid_q||recover_i||irq_pending_i||
   (HEAD_EXCEPTION_STOP ? head_exception_i:head_exception)||
   (HEAD_SERIAL_STOP ? head_serial_i:serial_commit_o);
 // Partial branch recovery preserves ROB head and its irreversible service
 // lease. It freezes retirement/rename undo, not the head's held request.
 // Revoking this authorization while VALID is backpressured would violate
 // ready/valid when that same request is later accepted during the undo walk.
 assign effect_allow_o=!rst_i&&!event_valid_q&&!head_exception;
 // Actual serial Issue owns the unfinished full-tag ROB head. It cannot
 // simultaneously be a completed exceptional head. The generic interface
 // keeps the old arbitrary-input permission; actual-only mode avoids feeding
 // retire-valid/recovery qualification back into the wide IQ selector.
 assign serial_allow_o=HEAD_SERIAL_ISSUE ? (!rst_i&&!event_valid_q):effect_allow_o;
 wire [63:0] original_instruction=rob_meta_i[195:192]==2 ? {48'b0,rob_meta_i[79:64]}:
   rob_meta_i[195:192]==4 ? {32'b0,rob_meta_i[95:64]}:rob_meta_i[127:64];
 // Zero-mask CSRRS/CSRRC (register or immediate) of scratch storage neither
 // writes the CSR nor changes fetch/translation/execution context. It still
 // executes at ROB head and retires through the original tagged Serial owner.
 // Keep this explicit whitelist; all context-changing serials still restart.
 wire [31:0] serial_inst_w=rob_meta_i[64+:32];
 wire scratch_read_w=SCRATCH_READ_RESUME!=0&&kind0==`R64_K_CSR&&
     rob_meta_i[192+:4]==4&&serial_inst_w[6:0]==7'h73&&
     serial_inst_w[13]&&serial_inst_w[19:15]==0&&
     (serial_inst_w[31:20]==12'h340||serial_inst_w[31:20]==12'h140);
 always @(posedge clk_i)begin
   if(rst_i)begin
     retired_npc_q<=RESET_PC;event_valid_q<=0;event_prepared_q<=0;event_trap_q<=0;
     event_interrupt_q<=0;event_pc_q<=0;event_tval_q<=0;event_cause_q<=0;
   end else begin
     if(full_flush_o)event_valid_q<=0;
     if(trap_prepare_o)event_prepared_q<=1;
     if(retire_fire_o[1])retired_npc_q<=npc1;
     else if(retire_fire_o[0])retired_npc_q<=npc0;
     if(trap_o)retired_npc_q<=trap_target_i;
     if(capture_exception)begin
       event_valid_q<=1;event_prepared_q<=0;event_trap_q<=1;event_interrupt_q<=0;
       event_pc_q<=rob_meta_i[63:0];event_cause_q<=rob_cause_i[5:0];
       event_tval_q<=rob_cause_i[5:0]==2 ? original_instruction:rob_tval_i[63:0];
     end else if(capture_interrupt)begin
       event_valid_q<=1;event_prepared_q<=0;event_trap_q<=1;event_interrupt_q<=1;
       event_pc_q<=retired_npc_q;event_cause_q<=irq_cause_i;event_tval_q<=0;
     end else if(serial_commit_o&&!scratch_read_w)begin
       // Non-whitelisted serials retain the original restart policy.
       // Scratch reads retire without creating this event.
       event_valid_q<=1;event_trap_q<=0;event_interrupt_q<=0;
       event_pc_q<=npc0;event_cause_q<=0;event_tval_q<=0;
     end
   end
 end
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
   if(HEAD_SERIAL_CLASS&&rob_serial_i!={metadata_serial1,metadata_serial0})
     $fatal(1,"ROB Serial class disagrees with retained metadata");
   if(retire_fire_o[1]&&!retire_fire_o[0])$fatal(1,"commit retired a non-prefix pair");
   if(full_flush_o&&(|retire_fire_o))$fatal(1,"commit flush overlapped retirement");
   if(full_flush_o&&irrevocable)$fatal(1,"commit flushed an irrevocable external owner");
   if(HEAD_SERIAL_STOP&&serial_commit_o&&!head_serial_i)
     $fatal(1,"serial retirement lacks resident head admission stop");
   if(serial_commit_o&&retire_fire_o[1])$fatal(1,"serial instruction shared retirement");
   if(rob_empty_i&&(|rob_valid_i))$fatal(1,"ROB empty disagrees with commit validity");
 end
`endif
endmodule
